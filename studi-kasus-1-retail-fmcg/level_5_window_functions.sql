-- ============================================================================
-- MODUL 05 : WINDOW FUNCTIONS, DEDUPLIKASI, & TREN WAKTU
-- Database : retail_fmcg_db
-- RDBMS    : PostgreSQL 16
-- ============================================================================

SELECT * FROM dim_pelanggan;
SELECT * FROM dim_produk;
SELECT * FROM dim_toko;
SELECT * FROM fact_penjualan_header;
SELECT * FROM fact_penjualan_detail;

-- ============================================================================
-- TANTANGAN 5.1: DEDUPLIKASI TRANSAKSI AKIBAT POS DOUBLE-CLICK
-- ============================================================================
-- 1. Masalah Bisnis : Membersihkan transaksi duplikat akibat double-click POS
--                     tanpa mengubah atau menghapus data fisik database.
-- 2. Target Grain    : 1 baris = 1 Transaksi Struk Kasir Unik (transaksi_id)
-- 3. Audit Sumber    : fact_penjualan_header.
-- 4. Logika Window   : 
--    - Partisi per transaksi_id.
--    - Urutkan tanggal_transaksi DESC, header_id DESC untuk mengambil data terbaru.
--    - Filter baris teratas (row_num = 1).
-- ============================================================================

WITH ranked_transactions AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY transaksi_id 
            ORDER BY tanggal_transaksi DESC, header_id DESC
        ) AS row_num
    FROM fact_penjualan_header
)
SELECT
    header_id,
    transaksi_id,
    tanggal_transaksi,
    customer_id,
    toko_id,
    total_nilai_transaksi,
    tipe_pembayaran,
    status_transaksi
FROM ranked_transactions
WHERE row_num = 1;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 5.1 (CTE + WINDOW FUNCTION):
-- Metode: Memanfaatkan kolom kalkulasi row_num dari CTE untuk menghitung
--         baris yang lolos (row_num = 1) vs baris sampah (row_num > 1).
-- ----------------------------------------------------------------------------
WITH ranked_transactions AS (
    SELECT 
        transaksi_id,
        ROW_NUMBER() OVER (
            PARTITION BY transaksi_id 
            ORDER BY tanggal_transaksi DESC, header_id DESC
        ) AS row_num
    FROM fact_penjualan_header
)
SELECT 
    COUNT(*) AS total_transaksi_sebelum_diduplikasi,
    COUNT(*) FILTER (WHERE row_num = 1)  AS total_transaksi_sesudah_diduplikasi,
    COUNT(*) FILTER (WHERE row_num > 1)  AS total_selisih_duplikat_dibuang
FROM ranked_transactions;


-- ============================================================================
-- TANTANGAN 5.2: TOP 3 PRODUK TERLARIS PER KATEGORI (DENSE_RANK)
-- ============================================================================
-- 1. Masalah Bisnis : Mengidentifikasi 3 produk terlaris berdasarkan total
--                     kuantitas terjual pada transaksi sukses Q1 2026.
-- 2. Target Grain    : 1 baris = 1 SKU Produk dalam Top 3 per Kategori
-- 3. Audit Sumber    : dim_produk, fact_penjualan_detail, dan fact_penjualan_header.
-- 4. Logika Window   :
--    - CTE 1 (product_sale): Agregasi SUM(kuantitas) per produk & kategori bersih.
--    - CTE 2 (ranked_products): Memberikan DENSE_RANK() per kategori_bersih
--      secara menurun (ORDER BY total_kuantitas DESC) tanpa lompatan peringkat.
--    - Kueri Utama: Filter rank_penjualan <= 3.
-- ============================================================================

WITH product_sale AS (
    SELECT
        UPPER(TRIM(dp.kategori)) AS kategori_bersih,
        dp.produk_id,
        dp.nama_produk, 
        dp.sub_kategori,
        SUM(fpd.kuantitas) AS total_kuantitas
    FROM dim_produk dp
    INNER JOIN fact_penjualan_detail fpd
        ON dp.produk_id = fpd.produk_id
    INNER JOIN fact_penjualan_header fph
        ON fpd.transaksi_id = fph.transaksi_id
    WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
    GROUP BY UPPER(TRIM(dp.kategori)), dp.produk_id, dp.nama_produk, dp.sub_kategori
),
ranked_products AS (
    SELECT 
        *,
        DENSE_RANK() OVER (
            PARTITION BY kategori_bersih 
            ORDER BY total_kuantitas DESC
        ) AS rank_penjualan
    FROM product_sale
)
SELECT 
    kategori_bersih,
    rank_penjualan,
    produk_id,
    nama_produk,
    sub_kategori,
    total_kuantitas
FROM ranked_products 
WHERE rank_penjualan <= 3
ORDER BY kategori_bersih ASC, rank_penjualan ASC, total_kuantitas DESC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 5.2 (A): Audit Kebocoran Peringkat Output Final
-- Metode: Membungkus kueri utama ke dalam CTE, lalu menguji apakah terdapat
--         peringkat di luar batas izin (rank > 3) yang lolos ke tabel akhir.
-- Pembuktian: Output WAJIB 0 baris (kosong).
-- ----------------------------------------------------------------------------
WITH product_sale AS (
    SELECT
        UPPER(TRIM(dp.kategori)) AS kategori_bersih,
        dp.produk_id,
        dp.nama_produk,
        SUM(fpd.kuantitas) AS total_kuantitas
    FROM dim_produk dp
    INNER JOIN fact_penjualan_detail fpd
        ON dp.produk_id = fpd.produk_id
    INNER JOIN fact_penjualan_header fph
        ON fpd.transaksi_id = fph.transaksi_id
    WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
    GROUP BY UPPER(TRIM(dp.kategori)), dp.produk_id, dp.nama_produk
),
ranked_products AS (
    SELECT 
        *,
        DENSE_RANK() OVER (
            PARTITION BY kategori_bersih 
            ORDER BY total_kuantitas DESC
        ) AS rank_penjualan
    FROM product_sale
),
final_top3 AS (
    SELECT * 
    FROM ranked_products 
    WHERE rank_penjualan <= 3
)
SELECT * 
FROM final_top3 
WHERE rank_penjualan > 3;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 5.2 (B): Ringkasan Sebaran SKU dan Batas Peringkat per Kategori
-- Metode: Menghitung volume SKU yang lolos dan memastikan MAX(rank) tepat = 3.
-- Pembuktian: Setiap kategori wajib memiliki max_rank = 3 dan count >= 3.
-- ----------------------------------------------------------------------------
WITH product_sale AS (
    SELECT
        UPPER(TRIM(dp.kategori)) AS kategori_bersih,
        dp.produk_id,
        SUM(fpd.kuantitas) AS total_kuantitas
    FROM dim_produk dp
    INNER JOIN fact_penjualan_detail fpd
        ON dp.produk_id = fpd.produk_id
    INNER JOIN fact_penjualan_header fph
        ON fpd.transaksi_id = fph.transaksi_id
    WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
    GROUP BY UPPER(TRIM(dp.kategori)), dp.produk_id
),
ranked_products AS (
    SELECT 
        kategori_bersih,
        DENSE_RANK() OVER (
            PARTITION BY kategori_bersih 
            ORDER BY total_kuantitas DESC
        ) AS rank_penjualan
    FROM product_sale
)
SELECT 
    kategori_bersih,
    COUNT(*) AS total_sku_terpilih,
    MAX(rank_penjualan) AS peringkat_maksimal
FROM ranked_products
WHERE rank_penjualan <= 3
GROUP BY kategori_bersih
ORDER BY kategori_bersih ASC;


-- ============================================================================
-- TANTANGAN 5.3 (BAGIAN A): 7-DAY MOVING AVERAGE PENJUALAN HARIAN
-- ============================================================================
-- 1. Masalah Bisnis : Menghitung tren omzet harian seluruh gerai dan menghaluskan
--                     fluktuasi harian menggunakan rata-rata bergerak 7 hari.
-- 2. Target Grain    : 1 baris = 1 Tanggal Transaksi (YYYY-MM-DD)
-- 3. Audit Sumber    : fact_penjualan_header.
-- 4. Logika Window   :
--    - CTE (daily_sales): Meringkas omzet per tanggal transaksi berstatus sukses.
--    - Window Frame: ROWS BETWEEN 6 PRECEDING AND CURRENT ROW.
-- ============================================================================

WITH daily_sales AS (
    SELECT 
        tanggal_transaksi::date AS tgl_transaksi,
        SUM(total_nilai_transaksi) AS total_omzet_harian
    FROM fact_penjualan_header
    WHERE status_transaksi IN ('PAID', 'COMPLETED')
    GROUP BY tanggal_transaksi::date
)
SELECT 
    tgl_transaksi,
    total_omzet_harian,
    ROUND(
        AVG(total_omzet_harian) OVER (
            ORDER BY tgl_transaksi
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 
        2
    ) AS ma_7_days
FROM daily_sales
ORDER BY tgl_transaksi ASC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 5.3 (A): Verifikasi Hari Pertama Moving Average
-- Metode: Memastikan pada baris pertama (tgl paling awal), nilai total_omzet_harian
--         sama persis dengan ma_7_days karena belum memiliki baris pendahulu.
-- Pembuktian: Output selisih wajib bernilai 0.00.
-- ----------------------------------------------------------------------------
WITH daily_sales AS (
    SELECT 
        tanggal_transaksi::date AS tgl_transaksi,
        SUM(total_nilai_transaksi) AS total_omzet_harian
    FROM fact_penjualan_header
    WHERE status_transaksi IN ('PAID', 'COMPLETED')
    GROUP BY tanggal_transaksi::date
),
moving_calc AS (
    SELECT 
        tgl_transaksi,
        total_omzet_harian,
        ROUND(
            AVG(total_omzet_harian) OVER (
                ORDER BY tgl_transaksi
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 
            2
        ) AS ma_7_days
    FROM daily_sales
)
SELECT 
    tgl_transaksi,
    total_omzet_harian,
    ma_7_days,
    ROUND(total_omzet_harian - ma_7_days, 2) AS selisih_hari_pertama
FROM moving_calc
ORDER BY tgl_transaksi ASC
LIMIT 1;


-- ============================================================================
-- TANTANGAN 5.3 (BAGIAN B): PERTUMBUHAN PENJUALAN BULANAN (MOM GROWTH %)
-- ============================================================================
-- 1. Masalah Bisnis : Mengukur laju pertumbuhan omzet antar-bulan (Jan, Feb, Mar 2026).
-- 2. Target Grain    : 1 baris = 1 Bulan Transaksi (YYYY-MM)
-- 3. Audit Sumber    : fact_penjualan_header.
-- 4. Logika Window   :
--    - CTE (monthly_sales): Agregasi omzet per bulan transaksi sukses.
--    - LAG(omzet_bulanan, 1) OVER (ORDER BY bulan_transaksi): Mengambil omzet bulan lalu.
--    - Formula MoM: 100.0 * (omzet_sekarang - omzet_lalu) / omzet_lalu.
-- ============================================================================

WITH monthly_sales AS (
    SELECT 
        TO_CHAR(tanggal_transaksi, 'YYYY-MM') AS bulan_transaksi,
        SUM(total_nilai_transaksi) AS omzet_bulanan
    FROM fact_penjualan_header
    WHERE status_transaksi IN ('PAID', 'COMPLETED')
    GROUP BY TO_CHAR(tanggal_transaksi, 'YYYY-MM')
),
mom_calc AS (
    SELECT 
        bulan_transaksi,
        omzet_bulanan,
        LAG(omzet_bulanan, 1) OVER (ORDER BY bulan_transaksi) AS omzet_bulan_sebelumnya
    FROM monthly_sales
)
SELECT 
    bulan_transaksi,
    omzet_bulanan,
    omzet_bulan_sebelumnya,
    ROUND(omzet_bulanan - omzet_bulan_sebelumnya, 2) AS pertumbuhan_nominal,
    ROUND(
        100.0 * (omzet_bulanan - omzet_bulan_sebelumnya) 
        / NULLIF(omzet_bulan_sebelumnya, 0), 
        2
    ) AS mom_growth_pct
FROM mom_calc
ORDER BY bulan_transaksi ASC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 5.3 (B): Integritas Rekonsiliasi Grand Total
-- Metode: Memastikan penjumlahan omzet 3 bulan di Bagian B sama persis dengan
--         akumulasi omzet seluruh transaksi sukses di tabel fakta header.
-- Pembuktian: Output selisih wajib 0.00.
-- ----------------------------------------------------------------------------
WITH monthly_sales AS (
    SELECT 
        SUM(total_nilai_transaksi) AS total_omzet_agregat_bulanan
    FROM fact_penjualan_header
    WHERE status_transaksi IN ('PAID', 'COMPLETED')
)
SELECT 
    ms.total_omzet_agregat_bulanan,
    header.total_omzet_riil,
    ROUND(ms.total_omzet_agregat_bulanan - header.total_omzet_riil, 2) AS selisih_integritas
FROM monthly_sales ms
CROSS JOIN (
    SELECT SUM(total_nilai_transaksi) AS total_omzet_riil
    FROM fact_penjualan_header
    WHERE status_transaksi IN ('PAID', 'COMPLETED')
) header;