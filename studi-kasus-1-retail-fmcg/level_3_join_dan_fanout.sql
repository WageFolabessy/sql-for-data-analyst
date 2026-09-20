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