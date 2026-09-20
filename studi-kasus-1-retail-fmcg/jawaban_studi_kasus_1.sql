-- ============================================================================
-- LEMBAR KERJA SQL: STUDI KASUS 1 (RETAIL FMCG - NUSANTARA MART)
-- Database     : retail_fmcg_db
-- Target RDBMS : PostgreSQL 16
-- Penulis      : [Nama Anda]
-- Deskripsi    : Lembar jawaban resmi untuk menyelesaikan tantangan Level 1 - 5.
--                Setiap query wajib mematuhi standar 5-Stage Grain-Driven Workflow.
-- ============================================================================

-- Hubungkan koneksi DBeaver Anda ke database 'retail_fmcg_db' sebelum menjalankan query.
SET search_path TO public;


-- ============================================================================
-- LEVEL 1: FONDASI FILTERING, DATA HYGIENE, & EKSPLORASI AWAL
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tantangan 1.1: Transaksi Bernilai Tinggi (> Rp 300.000) pada Januari 2026
-- Target Grain : 1 baris = 1 Transaksi Struk Kasir (transaksi_id)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 1.2: Pembersihan Anomali Teks Katalog Produk Kategori Minuman
-- Target Grain : 1 baris = 1 Produk Unik (produk_id)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 1.3: Analisis Adopsi Pembayaran Non-Tunai (QRIS & DEBIT) Terbesar
-- Target Grain : 1 baris = 1 Transaksi Struk Kasir (transaksi_id)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:




-- ============================================================================
-- LEVEL 2: AGREGASI BISNIS, AUDIT NILAI NULL, & SENSITIVITAS METRIK
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tantangan 2.1: Audit Jebakan Nilai NULL pada Diskon Keranjang Belanja
-- Target Grain : 1 baris = 1 Toko (toko_id)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 2.2: Porsi Penetrasi Transaksi QRIS per Toko (PostgreSQL FILTER Clause)
-- Target Grain : 1 baris = 1 Toko (toko_id)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 2.3: Cabang Berkinerja di Bawah Target Bulanan (HAVING Clause)
-- Target Grain : 1 baris = 1 Toko (toko_id)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:




-- ============================================================================
-- LEVEL 3: PENGGABUNGAN RELASIONAL (JOIN), AUDIT KUNCI, & DETEKSI FAN-OUT
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tantangan 3.1: Perhitungan Gross Profit (Laba Kotor) Multi-Tabel per Kategori
-- Target Grain : 1 baris = 1 Kategori Produk
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 3.2: The Fan-Out Trap Audit (Uji Pembengkakan Baris Akibat JOIN)
-- Target Grain : 1 baris = Audit Perbandingan Jumlah Baris & Total Nilai
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 3.3: Deteksi Barang Siluman (Anti-Join Orphaned Records)
-- Target Grain : 1 baris = 1 Item Transaksi Siluman (detail_id)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:




-- ============================================================================
-- LEVEL 4: MODULAR CTE, REKONSILIASI ZERO DISCREPANCY, & MARGIN BOCOR
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tantangan 4.1: Analisis Diskon Bocor (Cabang di Bawah Margin Rata-Rata Nasional)
-- Target Grain : 1 baris = 1 Toko per Kategori Produk Bermasalah
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 4.2: Rekonsiliasi Zero-Discrepancy (Header Total vs Detail Sum Subtotal)
-- Target Grain : 1 baris = 1 Transaksi Struk (transaksi_id) yang Berselisih
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:




-- ============================================================================
-- LEVEL 5: PUNCAK KEAHLIAN: WINDOW FUNCTIONS, DEDUPLIKASI, & TREN WAKTU
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tantangan 5.1: Deduplikasi Transaksi Akibat POS Double-Click (ROW_NUMBER)
-- Target Grain : 1 baris = 1 Transaksi Struk Kasir Unik (transaksi_id)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 5.2: Top 3 Produk Terlaris per Kategori (DENSE_RANK)
-- Target Grain : 1 baris = 1 Produk dalam Top 3 per Kategori
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:



-- ----------------------------------------------------------------------------
-- Tantangan 5.3: Analisis Pertumbuhan Penjualan MoM (LAG) & 7-Day Moving Average
-- Target Grain : 
--   Bagian A: 1 baris = 1 Tanggal Transaksi (YYYY-MM-DD)
--   Bagian B: 1 baris = 1 Bulan Transaksi (YYYY-MM)
-- ----------------------------------------------------------------------------
-- TULIS QUERY ANDA DI BAWAH INI:

