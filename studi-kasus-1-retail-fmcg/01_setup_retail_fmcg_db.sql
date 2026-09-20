-- ============================================================================
-- DATABASE SETUP: PT Nusantara Mart Retailindo (retail_fmcg_db)
-- Modul         : SQL for Data Analyst - Studi Kasus 1 (Retail FMCG)
-- Target RDBMS  : PostgreSQL 16
-- Penulis       : Data Analytics Team
-- Deskripsi     : DDL skema database Star Schema dengan Dual-Grain Fact Tables
--                 (Header vs Detail) dan kolom toleran anomali data riil POS.
-- ============================================================================

-- Pastikan kita bekerja pada skema public
SET search_path TO public;

-- 1. DROP TABEL JIKA SUDAH ADA (URUTAN TERBALIK DARI RELASI)
DROP TABLE IF EXISTS fact_penjualan_detail CASCADE;
DROP TABLE IF EXISTS fact_penjualan_header CASCADE;
DROP TABLE IF EXISTS dim_pelanggan CASCADE;
DROP TABLE IF EXISTS dim_toko CASCADE;
DROP TABLE IF EXISTS dim_produk CASCADE;

-- ============================================================================
-- 2. TABEL DIMENSI (DIMENSION TABLES)
-- ============================================================================

-- 2.1. DIM_PRODUK (Master Katalog Produk)
-- Target Grain: 1 baris = 1 Produk Unik (produk_id)
CREATE TABLE dim_produk (
    produk_id           VARCHAR(50) PRIMARY KEY,
    nama_produk         VARCHAR(255) NOT NULL,
    kategori            VARCHAR(100) NOT NULL, -- Mengandung anomali whitespace & mixed casing
    sub_kategori        VARCHAR(100),
    harga_beli_hpp      NUMERIC(15, 2) NOT NULL CHECK (harga_beli_hpp >= 0),
    harga_jual_standar  NUMERIC(15, 2) NOT NULL CHECK (harga_jual_standar >= 0)
);

-- 2.2. DIM_TOKO (Master Cabang Toko Ritel)
-- Target Grain: 1 baris = 1 Cabang Toko (toko_id)
CREATE TABLE dim_toko (
    toko_id             VARCHAR(50) PRIMARY KEY,
    nama_toko           VARCHAR(255) NOT NULL,
    kota                VARCHAR(100) NOT NULL, -- Mengandung anomali whitespace
    provinsi            VARCHAR(100) NOT NULL,
    tipe_toko           VARCHAR(50) NOT NULL,  -- Hypermarket, Supermarket, Minimarket
    target_omzet_bulanan NUMERIC(15, 2) NOT NULL CHECK (target_omzet_bulanan >= 0)
);

-- 2.3. DIM_PELANGGAN (Master Member Pelanggan)
-- Target Grain: 1 baris = 1 Pelanggan Terdaftar (customer_id)
CREATE TABLE dim_pelanggan (
    customer_id         VARCHAR(50) PRIMARY KEY,
    nama_pelanggan      VARCHAR(255) NOT NULL,
    status_member       VARCHAR(50) NOT NULL, -- VIP, MEMBER, NON_MEMBER
    tanggal_registrasi  DATE NOT NULL
);

-- ============================================================================
-- 3. TABEL FAKTA (FACT TABLES DUAL-GRAIN)
-- ============================================================================

-- 3.1. FACT_PENJUALAN_HEADER (Fakta Struk/Nota Kasir POS)
-- Target Grain: 1 baris = 1 Transaksi Struk Kasir
-- CATATAN DESAIN:
-- 1. Menggunakan surrogate key `header_id BIGSERIAL PRIMARY KEY`.
-- 2. `transaksi_id` tidak diberi constraint UNIQUE agar menampung anomali 'double-click submit'
--    dari mesin POS untuk tantangan deduplikasi Window Function ROW_NUMBER() di Level 5.
-- 3. `total_nilai_transaksi` menyimpan total struk untuk query Level 1 dan rekonsiliasi Level 4.
CREATE TABLE fact_penjualan_header (
    header_id               BIGSERIAL PRIMARY KEY,
    transaksi_id            VARCHAR(50) NOT NULL,
    tanggal_transaksi       TIMESTAMP NOT NULL,
    customer_id             VARCHAR(50), -- Dapat berupa NULL untuk pembeli umum (walk-in non-member)
    toko_id                 VARCHAR(50) NOT NULL REFERENCES dim_toko(toko_id),
    total_nilai_transaksi   NUMERIC(15, 2) NOT NULL,
    tipe_pembayaran         VARCHAR(50) NOT NULL, -- CASH, QRIS, DEBIT, KREDIT
    status_transaksi        VARCHAR(50) NOT NULL  -- PAID, COMPLETED, refund, CANCELLED
);

-- 3.2. FACT_PENJUALAN_DETAIL (Fakta Rincian Keranjang Belanja per Item)
-- Target Grain: 1 baris = 1 Item Produk dalam 1 Transaksi
-- CATATAN DESAIN:
-- 1. `produk_id` SENGAJA TIDAK DIBERI CONSTRAINT FOREIGN KEY ke dim_produk.
--    Hal ini merefleksikan arsitektur Data Warehouse/Data Lakehouse riil di mana
--    data transaksi mentah POS tetap ditampung apa adanya, sehingga analis dapat
--    menemukan 'orphaned records' (produk siluman) via LEFT JOIN ... WHERE dim_produk.produk_id IS NULL (Level 3.3).
-- 2. `diskon_nominal` dapat bernilai NULL (transaksi tanpa diskon) untuk melatih COALESCE (Level 2.1).
CREATE TABLE fact_penjualan_detail (
    detail_id           BIGSERIAL PRIMARY KEY,
    transaksi_id        VARCHAR(50) NOT NULL,
    produk_id           VARCHAR(50), -- Boleh berisi produk tak terdaftar (orphaned)
    kuantitas           INTEGER NOT NULL,
    harga_jual_aktual   NUMERIC(15, 2) NOT NULL,
    diskon_nominal      NUMERIC(15, 2), -- Mengandung NULL untuk melatih COALESCE
    subtotal            NUMERIC(15, 2) NOT NULL
);

-- ============================================================================
-- 4. INDEKS UNTUK OPTIMASI PERFORMA QUERY ANALITIK
-- ============================================================================
CREATE INDEX idx_fact_header_transaksi_id ON fact_penjualan_header(transaksi_id);
CREATE INDEX idx_fact_header_tgl ON fact_penjualan_header(tanggal_transaksi);
CREATE INDEX idx_fact_header_toko ON fact_penjualan_header(toko_id);
CREATE INDEX idx_fact_header_cust ON fact_penjualan_header(customer_id);

CREATE INDEX idx_fact_detail_transaksi_id ON fact_penjualan_detail(transaksi_id);
CREATE INDEX idx_fact_detail_produk_id ON fact_penjualan_detail(produk_id);

COMMENT ON TABLE dim_produk IS 'Master katalog produk ritel FMCG Nusantara Mart';
COMMENT ON TABLE dim_toko IS 'Master data toko/gerai Nusantara Mart di berbagai kota';
COMMENT ON TABLE dim_pelanggan IS 'Master data pelanggan dan loyalty membership';
COMMENT ON TABLE fact_penjualan_header IS 'Fakta penjualan tingkat nota/struk kasir POS';
COMMENT ON TABLE fact_penjualan_detail IS 'Fakta penjualan tingkat baris keranjang belanja per produk';
