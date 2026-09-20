-- ============================================================================
-- MODUL 01: FONDASI FILTERING, DATA HYGIENE, & EKSPLORASI AWAL
-- Database: retail_fmcg_db
-- RDBMS: 	 PostgreSQL 16
-- ============================================================================

SELECT * FROM dim_pelanggan;
SELECT * FROM dim_produk;
SELECT * FROM dim_toko;
SELECT * FROM fact_penjualan_header;
SELECT * FROM fact_penjualan_detail;

-- ============================================================================
-- TANTANGAN 1.1: AUDIT TRANSAKSI BERNILAI TINGGI (HIGH-VALUE BASKET)
-- ============================================================================
-- 1. Masalah Bisnis  : Tim Audit Kasir memverifikasi transaksi sukses dengan nilai
--                      belanja > Rp 300.000 selama Januari 2026 untuk audit limit kasir.
-- 2. Target Grain    : 1 baris = 1 Transaksi Struk Kasir (transaksi_id)
-- 3. Audit Sumber    : Tabel fact_penjualan_header.
-- 4. Logika Filter   :
--    - Hindari casting (::date) pada kolom indeks agar sargable.
--    - Gunakan interval terbuka: >= '2026-01-01 00:00:00' dan < '2026-02-01 00:00:00'.
--    - Filter nominal total_nilai_transaksi > 300000.
--    - Urutkan dari nilai transaksi terbesar ke terkecil.
-- ============================================================================

SELECT 
    transaksi_id, 
    tanggal_transaksi,
    status_transaksi,
    total_nilai_transaksi
FROM fact_penjualan_header
WHERE 
    status_transaksi IN ('PAID', 'COMPLETED')
    AND tanggal_transaksi >= '2026-01-01 00:00:00'
    AND tanggal_transaksi < '2026-02-01 00:00:00'
    AND total_nilai_transaksi > 300000
ORDER BY total_nilai_transaksi DESC;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 1.1:
-- Metode: Distribution Check via SELECT DISTINCT.
-- Pembuktian: Output unik status_transaksi wajib HANYA memuat 'PAID' dan 'COMPLETED'.
-- Jika status 'refund' atau 'CANCELLED' muncul, logika filter bocor.
-- ----------------------------------------------------------------------------
SELECT DISTINCT 
    status_transaksi
FROM fact_penjualan_header
WHERE 
    status_transaksi IN ('PAID', 'COMPLETED')
    AND tanggal_transaksi >= '2026-01-01 00:00:00'
    AND tanggal_transaksi < '2026-02-01 00:00:00'
    AND total_nilai_transaksi > 300000;


-- ============================================================================
-- TANTANGAN 1.2: PEMBERSIHAN ANOMALI TEKS KATALOG PRODUK (DATA HYGIENE)
-- ============================================================================
-- 1. Masalah Bisnis : Divisi Merchandising meminta daftar seluruh produk Minuman aktif.
-- 2. Target Grain    : 1 baris = 1 Produk Unik (produk_id)
-- 3. Audit Sumber    : Tabel dim_produk
-- 4. Logika Filter   :
--    - Standardisasi tampilan kolom output: UPPER(TRIM(kategori)).
--    - Filter kondisi pencarian: TRIM(kategori) ILIKE 'minuman' agar kebal terhadap
--      spasi liar dan perbedaan huruf besar-kecil.
-- ============================================================================

SELECT 
    produk_id,
    nama_produk,
    UPPER(TRIM(kategori)) AS kategori_bersih,
    harga_beli_hpp,
    harga_jual_standar
FROM dim_produk
WHERE TRIM(kategori) ILIKE 'minuman';

-- ----------------------------------------------------------------------------
-- SANITY CHECK 1.2:
-- Metode: Standarisasi Unik & Audit Variasi Mentah yang Tertangkap.
-- Pembuktian:
-- 1. kategori_bersih wajib menghasilkan tepat 1 baris: 'MINUMAN'.
-- 2. kategori_mentah memperlihatkan seluruh bentuk anomali teks yang berhasil dijaring.
-- ----------------------------------------------------------------------------
SELECT DISTINCT 
    UPPER(TRIM(kategori)) AS kategori_terstandarisasi,
    kategori AS variasi_mentah_tertangkap
FROM dim_produk
WHERE TRIM(kategori) ILIKE 'minuman';


-- ============================================================================
-- TANTANGAN 1.3: ANALISIS ADOPSI PEMBAYARAN NON-TUNAI
-- ============================================================================
-- 1. Masalah Bisnis : Manajemen ingin mengevaluasi 25 transaksi pembayaran non-tunai
--                     (QRIS dan DEBIT) bernilai transaksi tertinggi di seluruh cabang.
-- 2. Target Grain    : 1 baris = 1 Transaksi Struk Kasir (transaksi_id)
-- 3. Audit Sumber    : Tabel fact_penjualan_header.
-- 4. Logika Filter   :
--    - Saring tipe_pembayaran IN ('QRIS', 'DEBIT').
--    - Pastikan integritas transaksi sukses via status_transaksi IN ('PAID', 'COMPLETED').
--    - Urutkan ORDER BY total_nilai_transaksi DESC LIMIT 25.
-- ============================================================================

SELECT
    transaksi_id,
    toko_id,
    tipe_pembayaran,
    status_transaksi,
    total_nilai_transaksi
FROM fact_penjualan_header
WHERE 
    tipe_pembayaran IN ('QRIS', 'DEBIT')
    AND status_transaksi IN ('PAID', 'COMPLETED')
ORDER BY total_nilai_transaksi DESC
LIMIT 25;

-- ----------------------------------------------------------------------------
-- SANITY CHECK 1.3:
-- Metode: Combinatorial Check via SELECT DISTINCT.
-- Pembuktian: Output kombinasi unik HANYA boleh berisi variasi pembayaran sah
-- (QRIS / DEBIT) dengan status sah (PAID / COMPLETED). Nilai CASH atau refund
-- tidak boleh ada yang lolos.
-- ----------------------------------------------------------------------------
SELECT DISTINCT
    tipe_pembayaran,
    status_transaksi
FROM fact_penjualan_header
WHERE 
    tipe_pembayaran IN ('QRIS', 'DEBIT')
    AND status_transaksi IN ('PAID', 'COMPLETED');