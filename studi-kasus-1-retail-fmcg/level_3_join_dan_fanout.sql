-- ============================================================================
-- MODUL 03 : PENGGABUNGAN RELASIONAL (JOIN), AUDIT KUNCI, & DETEKSI FAN-OUT
-- Database : retail_fmcg_db
-- RDBMS 	: PostgreSQL 16
-- ============================================================================

SELECT * FROM dim_pelanggan;
SELECT * FROM dim_produk;
SELECT * FROM dim_toko;
SELECT * FROM fact_penjualan_header;
SELECT * FROM fact_penjualan_detail;

-- ============================================================================
-- TANTANGAN 3.1: PERHITUNGAN GROSS PROFIT (LABA KOTOR) MULTI-TABEL
-- ============================================================================
-- 1. Masalah Bisnis  : Manajemen membutuhkan laporan Laba Kotor (Gross Profit)
--                     per Kategori Produk untuk Q1 2026.
-- 2. Target Grain    : 1 baris = 1 Kategori Produk (kategori_bersih)
-- 3. Audit Sumber    : fact_penjualan_detail, dim_produk, dan fact_penjualan_header.
-- 4. Logika & Formula:
--    - Data Hygiene: Kolom kategori dibersihkan menggunakan UPPER(TRIM(dp.kategori))
--      baik di SELECT maupun GROUP BY agar kategori tidak terpecah oleh spasi/huruf.
--    - Total Omzet Kotor : SUM(kuantitas * harga_jual_aktual)
--    - Total Diskon      : SUM(COALESCE(diskon_nominal, 0))
--    - Total Omzet Bersih: Total Omzet Kotor - Total Diskon
--    - Total HPP         : SUM(dp.harga_beli_hpp * fpd.kuantitas) -> HPP per unit
--                          wajib dikalikan kuantitas belanja.
--    - Total Laba Kotor  : Total Omzet Bersih - Total HPP
--    - Filter Transaksi  : status_transaksi IN ('PAID', 'COMPLETED')
-- ============================================================================

SELECT
    UPPER(TRIM(dp.kategori)) AS kategori_bersih,
    SUM(fpd.kuantitas * fpd.harga_jual_aktual) AS total_omzet_kotor,
    SUM(COALESCE(fpd.diskon_nominal, 0)) AS total_diskon,
    SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0)) AS total_omzet_bersih,
    SUM(dp.harga_beli_hpp * fpd.kuantitas) AS total_hpp,
    SUM((fpd.harga_jual_aktual - dp.harga_beli_hpp) * fpd.kuantitas - COALESCE(fpd.diskon_nominal, 0))                                AS total_laba_kotor
FROM dim_produk dp
INNER JOIN fact_penjualan_detail fpd
    ON dp.produk_id = fpd.produk_id
INNER JOIN fact_penjualan_header fph
    ON fpd.transaksi_id = fph.transaksi_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY UPPER(TRIM(dp.kategori))
ORDER BY total_laba_kotor DESC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 3.1: Zero-Discrepancy Assertion (Persamaan Laba Kotor)
-- Metode: Menguji apakah (Total Omzet Bersih - Total HPP) - Total Laba Kotor = 0 via HAVING.
-- Pembuktian: Output WAJIB 0 baris (kosong). Jika muncul baris, berarti
-- terjadi inkonsistensi matematis pada formula laba kotor.
-- ----------------------------------------------------------------------------
SELECT
    UPPER(TRIM(dp.kategori)) AS kategori_bersih,
    (
        (
            SUM(fpd.kuantitas * fpd.harga_jual_aktual) 
            - SUM(COALESCE(fpd.diskon_nominal, 0))
        ) 
        - SUM(dp.harga_beli_hpp * fpd.kuantitas)
    ) 
    - SUM((fpd.harga_jual_aktual - dp.harga_beli_hpp) * fpd.kuantitas 
        - COALESCE(fpd.diskon_nominal, 0)) AS selisih_rekonsiliasi
FROM dim_produk dp
INNER JOIN fact_penjualan_detail fpd
    ON dp.produk_id = fpd.produk_id
INNER JOIN fact_penjualan_header fph
    ON fpd.transaksi_id = fph.transaksi_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY UPPER(TRIM(dp.kategori))
HAVING 
    (
        (
            SUM(fpd.kuantitas * fpd.harga_jual_aktual) 
            - SUM(COALESCE(fpd.diskon_nominal, 0))
        ) 
        - SUM(dp.harga_beli_hpp * fpd.kuantitas)
    ) 
    - SUM((fpd.harga_jual_aktual - dp.harga_beli_hpp) * fpd.kuantitas 
        - COALESCE(fpd.diskon_nominal, 0)) <> 0;

-- ============================================================================
-- TANTANGAN 3.2: THE FAN-OUT TRAP AUDIT (UJI PELIPATAN BARIS)
-- ============================================================================
-- 1. Masalah Bisnis  : Membuktikan secara empiris bahaya penggabungan tabel
--                     Header (1) ke Detail (*) tanpa pra-agregasi.
-- 2. Target Grain    : 1 baris = Audit Nilai Pra-Join vs Pasca-Join
-- 3. Temuan Audit    :
--    - Nilai Pra-Join  : 3.460 baris struk | Omzet: Rp 641.951.500,00
--    - Nilai Pasca-Join: 8.931 baris item  | Omzet: Rp 2.059.376.700,00
--    - Kesimpulan      : Omzet membengkak 3,21x lipat akibat nilai nota yang sama
--                        dijumlahkan berulang kali sebanyak item keranjang belanja.
-- ============================================================================

-- Langkah 1: Hitung baseline valid langsung dari tabel Header
SELECT 
    COUNT(*) AS total_baris_pra_join,
    SUM(total_nilai_transaksi) AS total_omzet_pra_join
FROM fact_penjualan_header
WHERE status_transaksi IN ('PAID', 'COMPLETED');

-- Langkah 2: Buktikan terjadinya pelipatan baris dan nilai setelah di-JOIN ke Detail
SELECT 
    COUNT(*) AS total_baris_pasca_join,
    SUM(fph.total_nilai_transaksi) AS total_omzet_pasca_join
FROM fact_penjualan_header fph
INNER JOIN fact_penjualan_detail fpd 
    ON fph.transaksi_id = fpd.transaksi_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED');


-- ============================================================================
-- TANTANGAN 3.3: DETEKSI BARANG SILUMAN (ANTI-JOIN ORPHANED RECORDS)
-- ============================================================================
-- 1. Masalah Bisnis  : Mengidentifikasi transaksi kasir yang memuat kode produk
--                     yang tidak terdaftar di master katalog dim_produk.
-- 2. Target Grain    : 1 baris = 1 Item Transaksi Siluman (detail_id)
-- 3. Audit Sumber    : fact_penjualan_detail dan dim_produk.
-- 4. Logika Anti-Join:
--    - Gunakan LEFT JOIN dari tabel transaksi (fpd) ke tabel master (dp).
--    - Pasang filter WHERE dp.produk_id IS NULL untuk menangkap transaksi
--      yang kuncinya tidak memiliki pasangan di tabel dimensi.
-- ============================================================================

SELECT
    fpd.detail_id,
    fpd.transaksi_id,
    fpd.produk_id,
    fpd.kuantitas,
    fpd.subtotal
FROM fact_penjualan_detail fpd
LEFT JOIN dim_produk dp
    ON fpd.produk_id = dp.produk_id
WHERE dp.produk_id IS NULL
ORDER BY fpd.detail_id ASC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 3.3: Audit Nilai Transaksi Produk Tidak Terpetakan
-- Metode: Menghitung volume baris, sebaran nota, dan total nilai transaksi anomali.
-- Pembuktian: Memberikan angka riil total eksposur data unmapped ke tim operasional.
-- ----------------------------------------------------------------------------
SELECT 
    COUNT(*)                         AS total_baris_anomali,
    COUNT(DISTINCT fpd.transaksi_id) AS total_struk_terdampak,
    SUM(fpd.subtotal)                AS total_nilai_unmapped
FROM fact_penjualan_detail fpd
LEFT JOIN dim_produk dp 
    ON fpd.produk_id = dp.produk_id
WHERE dp.produk_id IS NULL;
