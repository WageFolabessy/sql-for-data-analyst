-- ============================================================================
-- DATABASE SETUP: PT Nusantara Ekspres Logistik (logistics_sla_db)
-- Modul         : SQL for Data Analyst - Studi Kasus 2 (Logistics SLA & Operations)
-- Target RDBMS  : PostgreSQL 16
-- Penulis       : Lead Operations Analytics Team
-- Deskripsi     : DDL skema database Star Schema + Event-Driven Tracking Log
--                 dengan dukungan zona waktu multi-wilayah (TIMESTAMPTZ: WIB, WITA, WIT),
--                 pelacakan multi-hop transit, dan audit uang mengambang COD.
-- ============================================================================

SET search_path TO public;

-- 1. DROP TABEL LAMA JIKA ADA (Urutan terbalik dari relasi)
DROP TABLE IF EXISTS fact_tracking_event CASCADE;
DROP TABLE IF EXISTS fact_pengiriman CASCADE;
DROP TABLE IF EXISTS dim_armada_vendor CASCADE;
DROP TABLE IF EXISTS dim_kurir CASCADE;
DROP TABLE IF EXISTS dim_merchant CASCADE;
DROP TABLE IF EXISTS dim_hub CASCADE;

-- ============================================================================
-- 2. TABEL DIMENSI (DIMENSION TABLES)
-- ============================================================================

-- 2.1. DIM_HUB (Master Fasilitas Gudang & Sortir Logistik)
-- Target Grain: 1 baris = 1 Fasilitas Hub/Gudang (hub_id)
CREATE TABLE dim_hub (
    hub_id                  VARCHAR(50) PRIMARY KEY,
    nama_hub                VARCHAR(255) NOT NULL,
    kota                    VARCHAR(100) NOT NULL,
    provinsi                VARCHAR(100) NOT NULL,
    zona_waktu              VARCHAR(50) NOT NULL, -- Asia/Jakarta (WIB), Asia/Makassar (WITA), Asia/Jayapura (WIT)
    tipe_hub                VARCHAR(50) NOT NULL, -- Gateway Transit, Fulfillment Hub, Last-Mile Delivery DC
    kapasitas_sortir_harian INTEGER NOT NULL CHECK (kapasitas_sortir_harian > 0)
);

-- 2.2. DIM_MERCHANT (Master Klien E-Commerce & Retailers)
-- Target Grain: 1 baris = 1 Merchant Klien (merchant_id)
CREATE TABLE dim_merchant (
    merchant_id             VARCHAR(50) PRIMARY KEY,
    nama_merchant           VARCHAR(255) NOT NULL,
    kategori_bisnis         VARCHAR(100) NOT NULL, -- Fashion, Elektronik, FMCG & Home, Kecantikan, Otomotif
    tier_merchant           VARCHAR(50) NOT NULL,  -- ENTERPRISE, REGULAR
    persentase_kompensasi_denda NUMERIC(5, 2) NOT NULL DEFAULT 50.00 -- 50% atau 100% dari ongkir
);

-- 2.3. DIM_KURIR (Master Personel Kurir Pengantaran Last-Mile)
-- Target Grain: 1 baris = 1 Personel Kurir (kurir_id)
CREATE TABLE dim_kurir (
    kurir_id                VARCHAR(50) PRIMARY KEY,
    nama_kurir              VARCHAR(255) NOT NULL,
    hub_penugasan_id        VARCHAR(50) NOT NULL REFERENCES dim_hub(hub_id),
    jenis_kendaraan         VARCHAR(50) NOT NULL, -- Motor, Mobil Van
    status_kepegawaian      VARCHAR(50) NOT NULL  -- Kemitraan, Tetap
);

-- 2.4. DIM_ARMADA_VENDOR (Master Vendor Line-Haul Antarkota)
-- Target Grain: 1 baris = 1 Vendor Ekspedisi Antarkota (vendor_id)
CREATE TABLE dim_armada_vendor (
    vendor_id               VARCHAR(50) PRIMARY KEY,
    nama_vendor             VARCHAR(255) NOT NULL,
    tipe_armada             VARCHAR(50) NOT NULL, -- Truk Tronton Box, Pesawat Kargo, Kapal Roro
    biaya_kontrak_per_km    NUMERIC(15, 2) NOT NULL CHECK (biaya_kontrak_per_km >= 0)
);

-- ============================================================================
-- 3. TABEL FAKTA (FACT TABLES)
-- ============================================================================

-- 3.1. FACT_PENGIRIMAN (Fakta Header Pengiriman Paket per Resi AWB)
-- Target Grain: 1 baris = 1 Nomor Resi AWB (no_resi_awb)
CREATE TABLE fact_pengiriman (
    no_resi_awb                 VARCHAR(50) PRIMARY KEY,
    merchant_id                 VARCHAR(50) NOT NULL REFERENCES dim_merchant(merchant_id),
    hub_asal_id                 VARCHAR(50) NOT NULL REFERENCES dim_hub(hub_id),
    hub_tujuan_id               VARCHAR(50) NOT NULL REFERENCES dim_hub(hub_id),
    layanan                     VARCHAR(50) NOT NULL, -- Same Day, Next Day, Reguler, Kargo
    berat_aktual_kg             NUMERIC(8, 2) NOT NULL CHECK (berat_aktual_kg > 0),
    panjang_cm                  INTEGER NOT NULL CHECK (panjang_cm > 0),
    lebar_cm                    INTEGER NOT NULL CHECK (lebar_cm > 0),
    tinggi_cm                   INTEGER NOT NULL CHECK (tinggi_cm > 0),
    metode_pembayaran           VARCHAR(50) NOT NULL, -- COD, NON_COD
    nilai_barang                NUMERIC(15, 2) NOT NULL CHECK (nilai_barang >= 0),
    ongkir_tertagih             NUMERIC(15, 2) NOT NULL CHECK (ongkir_tertagih >= 0),
    waktu_booking               TIMESTAMPTZ NOT NULL,
    waktu_pickup                TIMESTAMPTZ NOT NULL,
    promised_sla_timestamp      TIMESTAMPTZ NOT NULL,
    actual_delivered_timestamp  TIMESTAMPTZ, -- NULL jika paket masih jalan, hilang, atau diretur
    waktu_setor_kasir           TIMESTAMPTZ, -- NULL jika uang COD belum disetorkan kurir ke kasir hub
    status_akhir                VARCHAR(50) NOT NULL -- DELIVERED, RETURN_TO_SENDER, LOST_IN_TRANSIT, DAMAGED
);

-- 3.2. FACT_TRACKING_EVENT (Fakta Peristiwa Scan Barcode Riwayat Paket)
-- Target Grain: 1 baris = 1 Peristiwa Pemindaian Barcode pada Resi AWB (event_id)
-- CATATAN DESAIN:
-- 1. Menyimpan stempel waktu berskala global (TIMESTAMPTZ).
-- 2. Memuat pasangan event HUB_IN dan HUB_OUT pada hub_id yang sama untuk kalkulasi Dwell Time via LEAD().
-- 3. Memuat attempt_ke (1, 2, 3) dan alasan_gagal_kirim untuk analisis FADR & NDR kurir.
CREATE TABLE fact_tracking_event (
    event_id                BIGSERIAL PRIMARY KEY,
    no_resi_awb             VARCHAR(50) NOT NULL REFERENCES fact_pengiriman(no_resi_awb),
    event_code              VARCHAR(50) NOT NULL, -- PICKUP, HUB_IN, HUB_OUT, DEL_OUT, DEL_OK, DEL_FAIL, RTS_IN
    hub_id                  VARCHAR(50) REFERENCES dim_hub(hub_id),
    kurir_id                VARCHAR(50) REFERENCES dim_kurir(kurir_id),
    vendor_id               VARCHAR(50) REFERENCES dim_armada_vendor(vendor_id),
    event_timestamp         TIMESTAMPTZ NOT NULL,
    attempt_ke              INTEGER, -- 1, 2, 3 (terisi saat DEL_OUT, DEL_OK, DEL_FAIL)
    alasan_gagal_kirim      VARCHAR(100) -- Rumah Kosong, Alamat Tidak Ditemukan, COD Ditolak Pembeli, Cuaca Ekstrem
);

-- ============================================================================
-- 4. INDEKS OPTIMASI QUERY ANALITIK LOGISTIK
-- ============================================================================
CREATE INDEX idx_pengiriman_hub_asal ON fact_pengiriman(hub_asal_id);
CREATE INDEX idx_pengiriman_hub_tujuan ON fact_pengiriman(hub_tujuan_id);
CREATE INDEX idx_pengiriman_merchant ON fact_pengiriman(merchant_id);
CREATE INDEX idx_pengiriman_pickup ON fact_pengiriman(waktu_pickup);
CREATE INDEX idx_pengiriman_delivered ON fact_pengiriman(actual_delivered_timestamp);
CREATE INDEX idx_pengiriman_status ON fact_pengiriman(status_akhir);

CREATE INDEX idx_tracking_resi ON fact_tracking_event(no_resi_awb);
CREATE INDEX idx_tracking_hub ON fact_tracking_event(hub_id);
CREATE INDEX idx_tracking_timestamp ON fact_tracking_event(event_timestamp);
CREATE INDEX idx_tracking_kurir ON fact_tracking_event(kurir_id);
CREATE INDEX idx_tracking_event_code ON fact_tracking_event(event_code);

COMMENT ON TABLE dim_hub IS 'Master fasilitas logistik, gudang transit, dan delivery DC dengan zona waktu';
COMMENT ON TABLE dim_merchant IS 'Master klien e-commerce dan enterprise sellers';
COMMENT ON TABLE dim_kurir IS 'Master personel kurir lapangan last-mile delivery';
COMMENT ON TABLE dim_armada_vendor IS 'Master vendor pihak ketiga armada line-haul antarkota';
COMMENT ON TABLE fact_pengiriman IS 'Fakta pengiriman tingkat nomor resi (AWB) lengkap dengan SLA dan dimensi paket';
COMMENT ON TABLE fact_tracking_event IS 'Fakta mutasi riwayat scan barcode paket multi-hop dari pickup hingga delivered/retur';
