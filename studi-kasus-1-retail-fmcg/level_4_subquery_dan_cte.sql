-- ============================================================================
-- MODUL 04 : SUBQUERY, COMMON TABLE EXPRESSIONS (CTE), & AUDIT REKONSILIASI
-- Database : retail_fmcg_db
-- RDBMS 	: PostgreSQL 16
-- ============================================================================

SELECT * FROM dim_pelanggan;
SELECT * FROM dim_produk;
SELECT * FROM dim_toko;
SELECT * FROM fact_penjualan_header;
SELECT * FROM fact_penjualan_detail;

-- ============================================================================
-- TANTANGAN 4.1: DETEKSI DISKON BOCOR (DEVIASI MARGIN CABANG VS NASIONAL)
-- ============================================================================
-- 1. Masalah Bisnis  : Mengidentifikasi gerai yang mengalami kebocoran margin laba
--                     pada kategori produk tertentu dibanding acuan nasional.
-- 2. Target Grain    : 1 baris = 1 Toko per Kategori Produk Anomali
-- 3. Audit Sumber    :
--    - CTE 1 (store_category_margin): Grain 1 baris = 1 Toko per Kategori.
--    - CTE 2 (national_category_margin): Grain 1 baris = 1 Kategori (Acuan Nasional).
-- 4. Temuan Empiris  : Ambang batas 5% menghasilkan 0 baris karena deviasi terburuk
--                     di data riil adalah -2,88%. Ambang batas disesuaikan menjadi
--                     2,0% untuk menangkap cabang paling berisiko.
-- ============================================================================

WITH store_category_margin AS (
    SELECT
        dt.toko_id,
        dt.nama_toko,
        UPPER(TRIM(dp.kategori)) AS kategori_bersih,
        SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0)) AS total_omzet_bersih,
        SUM((fpd.harga_jual_aktual - dp.harga_beli_hpp) * fpd.kuantitas - COALESCE(fpd.diskon_nominal, 0)) AS total_laba_kotor,
        ROUND(
            100.0 * SUM((fpd.harga_jual_aktual - dp.harga_beli_hpp) * fpd.kuantitas - COALESCE(fpd.diskon_nominal, 0))
            / NULLIF(SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0)), 0),
            2
        ) AS persentase_margin_toko
    FROM fact_penjualan_detail fpd
    INNER JOIN fact_penjualan_header fph
        ON fpd.transaksi_id = fph.transaksi_id
    INNER JOIN dim_toko dt
        ON fph.toko_id = dt.toko_id
    INNER JOIN dim_produk dp
        ON fpd.produk_id = dp.produk_id
    WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
    GROUP BY dt.toko_id, dt.nama_toko, UPPER(TRIM(dp.kategori))
),
national_category_margin AS (
    SELECT
        kategori_bersih,
        ROUND(
            100.0 * SUM(total_laba_kotor)
            / NULLIF(SUM(total_omzet_bersih), 0),
            2
        ) AS persentase_margin_nasional
    FROM store_category_margin
    GROUP BY kategori_bersih
)
SELECT
    scm.toko_id, 
    scm.nama_toko,
    scm.kategori_bersih,
    scm.persentase_margin_toko,
    ncm.persentase_margin_nasional,
    ROUND(scm.persentase_margin_toko - ncm.persentase_margin_nasional, 2) AS selisih_margin
FROM store_category_margin scm
INNER JOIN national_category_margin ncm
    ON scm.kategori_bersih = ncm.kategori_bersih
WHERE scm.persentase_margin_toko < (ncm.persentase_margin_nasional - 2.0)
ORDER BY selisih_margin ASC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 4.1: Pembuktian Hipotesis Ambang Batas 5%
-- Metode: Memastikan bahwa pada ambang batas 5%, output benar-benar 0 baris.
-- Pembuktian: Output WAJIB 0 baris (kosong).
-- ----------------------------------------------------------------------------
WITH store_category_margin AS (
    SELECT
        dt.toko_id,
        dt.nama_toko,
        UPPER(TRIM(dp.kategori)) AS kategori_bersih,
        SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0)) AS total_omzet_bersih,
        SUM((fpd.harga_jual_aktual - dp.harga_beli_hpp) * fpd.kuantitas - COALESCE(fpd.diskon_nominal, 0)) AS total_laba_kotor,
        ROUND(
            100.0 * SUM((fpd.harga_jual_aktual - dp.harga_beli_hpp) * fpd.kuantitas - COALESCE(fpd.diskon_nominal, 0))
            / NULLIF(SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0)), 0),
            2
        ) AS persentase_margin_toko
    FROM fact_penjualan_detail fpd
    INNER JOIN fact_penjualan_header fph
        ON fpd.transaksi_id = fph.transaksi_id
    INNER JOIN dim_toko dt
        ON fph.toko_id = dt.toko_id
    INNER JOIN dim_produk dp
        ON fpd.produk_id = dp.produk_id
    WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
    GROUP BY dt.toko_id, dt.nama_toko, UPPER(TRIM(dp.kategori))
),
national_category_margin AS (
    SELECT
        kategori_bersih,
        ROUND(
            100.0 * SUM(total_laba_kotor)
            / NULLIF(SUM(total_omzet_bersih), 0),
            2
        ) AS persentase_margin_nasional
    FROM store_category_margin
    GROUP BY kategori_bersih
)
SELECT
    scm.toko_id,
    scm.kategori_bersih,
    ROUND(scm.persentase_margin_toko - ncm.persentase_margin_nasional, 2) AS selisih_margin
FROM store_category_margin scm
INNER JOIN national_category_margin ncm
    ON scm.kategori_bersih = ncm.kategori_bersih
WHERE scm.persentase_margin_toko < (ncm.persentase_margin_nasional - 5.0);

-- ============================================================================
-- TANTANGAN 4.2: REKONSILIASI ZERO-DISCREPANCY (HEADER VS DETAIL AUDIT)
-- ============================================================================
-- 1. Masalah Bisnis  : Rekonsiliasi integritas data antara total nilai struk di
--                     header dengan akumulasi subtotal keranjang belanja di detail.
-- 2. Target Grain    : 1 baris = 1 Transaksi Struk Bermasalah (transaksi_id)
-- 3. Audit Sumber    : fact_penjualan_header dan fact_penjualan_detail.
-- 4. Logika Rekonsiliasi:
--    - Meringkas detail ke tingkat transaksi via CTE (Grain: 1 baris = 1 transaksi).
--    - Menggabungkan ke header dengan relasi 1-to-1 (tanpa GROUP BY di luar).
--    - Menghitung deviasi: ABS(header - detail) > 0.01 guna menghindari
--      pembacaan selisih akibat pembulatan desimal floating-point.
-- ============================================================================
WITH detail_aggregated AS (
	SELECT 
		transaksi_id, 
		SUM(subtotal) AS total_nilai_detail
	FROM fact_penjualan_detail
	GROUP BY transaksi_id
)
SELECT
	fph.transaksi_id,
	fph.total_nilai_transaksi AS total_nilai_header,
	detail.total_nilai_detail AS total_nilai_detail,
	ROUND(fph.total_nilai_transaksi - detail.total_nilai_detail, 2) AS nominal_selisih
FROM fact_penjualan_header fph
INNER JOIN detail_aggregated detail
	ON fph.transaksi_id = detail.transaksi_id
WHERE status_transaksi IN ('PAID', 'COMPLETED')
	AND ABS(fph.total_nilai_transaksi - detail.total_nilai_detail) > 0.01
ORDER BY nominal_selisih;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 4.2: Grand Summary Rekonsiliasi Zero-Discrepancy
-- Metode: Menghitung total volume transaksi janggal dan total eksposur selisih uang.
-- Pembuktian: Jika data sehat, output wajib menghasilkan count = 0 dan sum = NULL/0.
-- ----------------------------------------------------------------------------
WITH detail_aggregated AS (
	SELECT 
		transaksi_id, 
		SUM(subtotal) AS total_nilai_detail
	FROM fact_penjualan_detail
	GROUP BY transaksi_id
)
SELECT
	COUNT(*) AS total_transaksi_berselisih,
	COALESCE(SUM(fph.total_nilai_transaksi - detail.total_nilai_detail), 0)  AS total_selisih
FROM fact_penjualan_header fph
INNER JOIN detail_aggregated detail
	ON fph.transaksi_id = detail.transaksi_id
WHERE status_transaksi IN ('PAID', 'COMPLETED')
	AND ABS(fph.total_nilai_transaksi - detail.total_nilai_detail) > 0.01;
