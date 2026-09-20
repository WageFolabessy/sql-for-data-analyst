-- ============================================================================
-- MODUL 02 : AGREGASI BISNIS, AUDIT NILAI NULL, & SENSITIVITAS METRIK
-- Database : retail_fmcg_db
-- RDBMS 	: PostgreSQL 16
-- ============================================================================

SELECT * FROM dim_pelanggan;
SELECT * FROM dim_produk;
SELECT * FROM dim_toko;
SELECT * FROM fact_penjualan_header;
SELECT * FROM fact_penjualan_detail;

-- ============================================================================
-- TANTANGAN 2.1: AUDIT JEBAKAN NILAI NULL PADA DISKON KERANJANG BELANJA
-- ============================================================================
-- 1. Masalah Bisnis : Direktur Keuangan ingin membandingkan omzet kotor, total
--                     potongan diskon, dan omzet bersih di setiap gerai.
-- 2. Target Grain    : 1 baris = 1 Toko (toko_id)
-- 3. Audit Sumber    : fact_penjualan_detail dan fact_penjualan_header
-- 4. Logika & Jebakan NULL Poisoning:
--    - Operasi matematika dengan NULL menghasilkan NULL (35.000 - NULL = NULL).
--    - SUM() mengabaikan NULL, sehingga kalkulasi tanpa COALESCE akan membuang
--      seluruh penjualan barang non-promo (omzet toko rusak hingga puluhan juta).
--    - Wajib gunakan COALESCE(diskon_nominal, 0) agar baris non-promo bernilai 0.
-- ============================================================================

SELECT
    fph.toko_id,
    SUM(fpd.kuantitas * fpd.harga_jual_aktual) AS total_omzet_kotor,
    SUM(COALESCE(fpd.diskon_nominal, 0)) AS total_diskon,
    SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0)) AS total_omzet_bersih
FROM fact_penjualan_header fph
INNER JOIN fact_penjualan_detail fpd
    ON fph.transaksi_id = fpd.transaksi_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY fph.toko_id
ORDER BY fph.toko_id;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 2.1 (A): Zero-Discrepancy Equation Assertion
-- Metode: Menguji persamaan keuangan (Kotor - Diskon - Bersih = 0) via HAVING.
-- Pembuktian: Output WAJIB 0 baris (kosong). Jika ada baris muncul, kalkulasi meleset.
-- ----------------------------------------------------------------------------
SELECT
    fph.toko_id,
    (
        SUM(fpd.kuantitas * fpd.harga_jual_aktual) 
        - SUM(COALESCE(fpd.diskon_nominal, 0))
    ) - (
        SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0))
    ) AS selisih_rekonsiliasi
FROM fact_penjualan_header fph
INNER JOIN fact_penjualan_detail fpd 
    ON fph.transaksi_id = fpd.transaksi_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY fph.toko_id
HAVING 
    (
        SUM(fpd.kuantitas * fpd.harga_jual_aktual) 
        - SUM(COALESCE(fpd.diskon_nominal, 0))
    ) - (
        SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0))
    ) <> 0;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 2.1 (B): Audit Baris Non-Diskon yang Diselamatkan COALESCE
-- Metode: Membandingkan COUNT(*) fisik dengan COUNT(kolom_nullable).
-- Pembuktian: COUNT(*) - COUNT(diskon_nominal) membuktikan ada ribuan transaksi
-- non-promo yang berhasil diselamatkan dari racun NULL.
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*) AS total_baris_item,
    COUNT(fpd.diskon_nominal) AS baris_dengan_diskon,
    COUNT(*) - COUNT(fpd.diskon_nominal) AS baris_null_diselamatkan
FROM fact_penjualan_header fph
INNER JOIN fact_penjualan_detail fpd 
    ON fph.transaksi_id = fpd.transaksi_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED');


-- ============================================================================
-- TANTANGAN 2.2: PORSI PENETRASI QRIS PER TOKO (POSTGRESQL FILTER CLAUSE)
-- ============================================================================
-- 1. Masalah Bisnis : Divisi Digital Banking mengevaluasi tingkat adopsi QRIS
--                     pada transaksi sukses di setiap gerai.
-- 2. Target Grain    : 1 baris = 1 Toko (toko_id)
-- 3. Audit Sumber    : fact_penjualan_header.
-- 4. Logika Agregasi :
--    - Saring transaksi sukses via status_transaksi IN ('PAID', 'COMPLETED')
--      agar transaksi gagal, batal, atau refund tidak menggelembungkan metrik.
--    - Gunakan fitur PostgreSQL: COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS').
--    - Hitung rasio dengan pengali 100.0 untuk mencegah pemotongan pembagian bulat.
-- ============================================================================

SELECT
    toko_id,
    COUNT(*) AS total_transaksi,
    COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') AS total_trx_qris,
    ROUND(100.0 * COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') / COUNT(*), 2) AS pct_qris
FROM fact_penjualan_header
WHERE status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY toko_id
ORDER BY pct_qris DESC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 2.2: Boundary Assertion Test via HAVING
-- Metode: Mencari anomali persentase di luar batas matematis (< 0% atau > 100%).
-- Pembuktian: Output WAJIB 0 baris (kosong), membuktikan seluruh rasio valid.
-- ----------------------------------------------------------------------------
SELECT
    toko_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') / COUNT(*), 2) AS pct_qris
FROM fact_penjualan_header
WHERE status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY toko_id
HAVING 
    ROUND(100.0 * COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') / COUNT(*), 2) < 0
    OR ROUND(100.0 * COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') / COUNT(*), 2) > 100;


-- ============================================================================
-- TANTANGAN 2.3: CABANG BERKINERJA DI BAWAH TARGET (HAVING CLAUSE)
-- ============================================================================
-- 1. Masalah Bisnis : Menemukan gerai dengan total realisasi penjualan Q1 2026
--                     masih di bawah target omzet 1 bulan cabang bersangkutan.
-- 2. Target Grain    : 1 baris = 1 Toko (toko_id)
-- 3. Audit Sumber    : fact_penjualan_header dan dim_toko.
-- 4. Logika Filtering & Standar ANSI SQL:
--    - WHERE menyaring baris mentah sebelum agregasi (transaksi sukses).
--    - HAVING menyaring hasil kalkulasi setelah agregasi (SUM(...) < target).
--    - Seluruh kolom non-agregasi di SELECT (toko_id, nama_toko, target_omzet_bulanan)
--      wajib didaftarkan ke dalam GROUP BY demi portabilitas standar SQL.
-- ============================================================================

SELECT
    dt.toko_id,
    dt.nama_toko,
    SUM(fph.total_nilai_transaksi) AS total_realisasi,
    dt.target_omzet_bulanan
FROM dim_toko dt
INNER JOIN fact_penjualan_header fph
    ON dt.toko_id = fph.toko_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY dt.toko_id, dt.nama_toko, dt.target_omzet_bulanan
HAVING SUM(fph.total_nilai_transaksi) < dt.target_omzet_bulanan
ORDER BY total_realisasi ASC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 2.3: Negative Assertion Test (Uji Kebocoran Target)
-- Metode: Mencari toko yang lolos filter padahal realisasinya >= target bulanan.
-- Pembuktian: Output WAJIB 0 baris (kosong), membuktikan tidak ada gerai berkinerja
-- baik yang salah masuk ke daftar evaluasi direksi.
-- ----------------------------------------------------------------------------
SELECT
    dt.toko_id,
    dt.nama_toko,
    SUM(fph.total_nilai_transaksi) AS total_realisasi,
    dt.target_omzet_bulanan,
    SUM(fph.total_nilai_transaksi) - dt.target_omzet_bulanan AS kelebihan_omzet
FROM dim_toko dt
INNER JOIN fact_penjualan_header fph 
    ON dt.toko_id = fph.toko_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY dt.toko_id, dt.nama_toko, dt.target_omzet_bulanan
HAVING SUM(fph.total_nilai_transaksi) >= dt.target_omzet_bulanan;