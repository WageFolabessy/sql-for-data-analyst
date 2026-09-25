-- ==============================================================================
-- STUDI KASUS 2: PT NUSANTARA EKSPRES LOGISTIK (NexLog)
-- Lembar Kerja Analisis Logistik, Integritas SLA & Revenue Assurance (PostgreSQL 16)
-- Database   : logistics_sla_db
-- Lead Analyst: Endricho (Lead Operations & Commercial Analytics Specialist)
-- ==============================================================================
-- Petunjuk Analis:
-- 1. Gunakan dokumen resmi perusahaan sebagai panduan Single Source of Truth:
--    - docs/MEMO_DIREKSI_OPERASIONAL.md (Mandat penugasan resmi dari COO)
--    - docs/SOP_METRIK_DAN_FORMULA_LOGISTIK.md (Rumus baku OTD, volumetrik, penalti, dwell time)
--    - docs/DATA_DICTIONARY_LOGISTICS.md (Struktur tabel, tipe data, dan zona waktu)
-- 2. Anda memiliki KEBEBASAN PENUH dalam merancang kueri (CTE, Subquery, Window Functions,
--    Self-Join, dsb.). Pilihlah pendekatan yang paling efisien, akurat, dan mudah dipahami!
-- ==============================================================================

SELECT * FROM dim_hub;
SELECT * FROM dim_merchant;
SELECT * FROM dim_kurir;
SELECT * FROM dim_armada_vendor;
SELECT * FROM fact_pengiriman;
SELECT * FROM v_clean_tracking_event;

CREATE OR REPLACE VIEW v_clean_tracking_event AS
WITH deduplikasi AS (
    SELECT 
        *,
        LAG(event_timestamp) OVER (
            PARTITION BY 
                no_resi_awb, 
                event_code, 
                COALESCE(hub_id, ''), 
                COALESCE(kurir_id, '')
            ORDER BY event_timestamp ASC, event_id ASC
        ) AS prev_timestamp
    FROM fact_tracking_event
)
SELECT 
    event_id,
    no_resi_awb, 
    event_code, 
    hub_id, 
    kurir_id, 
    vendor_id, 
    event_timestamp, 
    attempt_ke, 
    alasan_gagal_kirim
FROM deduplikasi
WHERE prev_timestamp IS NULL 
   OR EXTRACT(EPOCH FROM (event_timestamp - prev_timestamp)) > 10;

-- ==============================================================================
-- BAGIAN A: INTEGRITAS DATA PEMINDAIAN & REKONSILIASI MANIFES (DATA HYGIENE)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 0.1: Audit & Pembersihan Jitter Duplicate Barcode Scans
-- ------------------------------------------------------------------------------
-- Masalah Operasional & Pipeline:
-- Sensor conveyor di hub dan PDA kurir di lapangan kerap mengalami network retry
-- sehingga memindai resi yang sama dengan status yang sama dalam selisih <= 10 detik.
-- Jika tidak dibersihkan, kueri LEAD() pada Bagian C akan memasangkan HUB_IN dengan duplikat
-- HUB_IN kedua, sehingga dwell time terhitung 0 jam (rusak total!).
--
-- Tugas Analis:
-- 1. Hitung berapa banyak scan duplikat jitter yang ada di fact_tracking_event per event_code!
-- 2. Tunjukkan logika deduplikasi (mengambil hanya pemindaian pertama per kelompok jitter).
--
-- Referensi SOP:
-- docs/SOP_METRIK_DAN_FORMULA_LOGISTIK.md (Bagian 5.1)
--
-- Kolom yang diharapkan (minimal):
-- event_code | total_scan_kotor | total_jitter_duplicate | total_scan_bersih | pct_jitter_duplikasi
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:
-- ==============================================================================
-- KASUS 0.1: Audit & Pembersihan Jitter Duplicate Barcode Scans
-- ==============================================================================

WITH tracking_lagged AS (
    SELECT 
        event_id,
        no_resi_awb,
        event_code,
        hub_id,
        kurir_id,
        event_timestamp,
        -- Mengambil waktu pemindaian sebelumnya pada paket, event, dan lokasi/kurir yang sama
        LAG(event_timestamp) OVER (
            PARTITION BY 
                no_resi_awb, 
                event_code, 
                COALESCE(hub_id, ''), 
                COALESCE(kurir_id, '')
            ORDER BY event_timestamp ASC, event_id ASC
        ) AS prev_event_timestamp
    FROM fact_tracking_event
),
flagged_jitter AS (
    SELECT 
        event_id,
        no_resi_awb,
        event_code,
        hub_id,
        kurir_id,
        event_timestamp,
        -- Tandai pemindaian duplikat jika selisih waktu <= 10 detik dari pemindaian sebelumnya
        CASE 
            WHEN prev_event_timestamp IS NOT NULL 
                 AND EXTRACT(EPOCH FROM (event_timestamp - prev_event_timestamp)) <= 10 
            THEN 1 
            ELSE 0 
        END AS is_jitter_duplicate
    FROM tracking_lagged
)
SELECT 
    event_code,
    COUNT(*) AS total_scan_kotor,
    COUNT(*) FILTER (WHERE is_jitter_duplicate = 0) AS total_scan_bersih,
    COUNT(*) FILTER (WHERE is_jitter_duplicate = 1) AS total_jitter_duplicate,
    ROUND(
        (100.0 * COUNT(*) FILTER (WHERE is_jitter_duplicate = 1)::NUMERIC / COUNT(*)), 
        2
    ) AS pct_jitter_duplikasi
FROM flagged_jitter
GROUP BY event_code
ORDER BY total_scan_kotor DESC;

-- ------------------------------------------------------------------------------
-- KASUS 0.2: Deteksi Paket Tanpa Manifes (Unmanifested Ghost Parcels)
-- ------------------------------------------------------------------------------
-- Masalah Operasional:
-- Di hub sortir transit antarpulau, kerap ditemukan paket mitra lain atau paket salah
-- sortir yang ter-scan di conveyor tapi nomor resinya tidak terdaftar di fact_pengiriman.
--
-- Tugas Analis:
-- Temukan seluruh nomor resi hantu (unmanifested) yang ter-scan di hub transit beserta
-- di fasilitas hub mana saja paket tersebut sempat terpindai, untuk dilaporkan ke tim
-- Loss Prevention & Investigasi Gudang!
--
-- Referensi SOP:
-- docs/SOP_METRIK_DAN_FORMULA_LOGISTIK.md (Bagian 5.2)
--
-- Kolom yang diharapkan (minimal):
-- no_resi_awb | hub_id | nama_hub | total_scan_di_hub | scan_pertama | scan_terakhir
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:

SELECT
	fte.no_resi_awb,
	dh.hub_id,
	dh.nama_hub,
	COUNT(*) AS total_scan_di_hub,
	MIN(fte.event_timestamp) AS scan_pertama,
	MAX(fte.event_timestamp) AS scan_terakhir
FROM fact_tracking_event fte
INNER JOIN dim_hub dh
	ON fte.hub_id = dh.hub_id
LEFT JOIN fact_pengiriman fp
	ON fte.no_resi_awb = fp.no_resi_awb
WHERE fp.no_resi_awb IS NULL
GROUP BY fte.no_resi_awb, dh.hub_id, dh.nama_hub
ORDER BY total_scan_di_hub DESC, scan_pertama ASC;

-- ==============================================================================
-- BAGIAN B: KEPATUHAN SERVICE LEVEL AGREEMENT & RUTE KRITIS (MACRO PERFORMANCE)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 1.1: Audit Kepatuhan On-Time Delivery (OTD) Makro
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Direksi ingin mengetahui persentase ketepatan waktu pengiriman (OTD %) untuk setiap
-- jenis layanan ('Same Day', 'Next Day', 'Reguler', 'Kargo') pada Q1 2026.
-- Layanan mana saja yang jebol dan gagal memenuhi standar kepatuhan industri (95,00%)?
--
-- Referensi SOP:
-- docs/SOP_METRIK_DAN_FORMULA_LOGISTIK.md (Bagian 2.1)
-- Paket on-time jika: actual_delivered_timestamp <= promised_sla_timestamp.
-- Paket retur/hilang dihitung sebagai gagal SLA (Breach).
--
-- Kolom yang diharapkan (minimal):
-- layanan | total_paket | total_on_time | total_breach | otd_percentage | status_kepatuhan
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:

WITH agregasi_layanan AS (
	SELECT 
		layanan,
		COUNT(*) AS total_paket,
		COUNT(*) FILTER (WHERE status_akhir = 'DELIVERED' AND actual_delivered_timestamp <= promised_sla_timestamp) AS total_on_time
	FROM fact_pengiriman
	GROUP BY layanan
),
kalkulasi_otd AS (
	SELECT
		layanan,
		total_paket,
		total_on_time,
		(total_paket - total_on_time) AS total_breach,
		ROUND(100.0 * total_on_time / total_paket, 2) AS otd_percentage
	FROM agregasi_layanan
)
SELECT 
	*,
	CASE 
        WHEN otd_percentage >= 95.0
        THEN 'PATUH' 
        ELSE 'JEBOL' 
    END AS status_kepatuhan
FROM kalkulasi_otd
ORDER BY otd_percentage ASC;

-- ------------------------------------------------------------------------------
-- KASUS 1.2: Pemetaan 10 Jalur Pengiriman Paling Kronis (Chronic Delay Lanes)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Temukan 10 pasangan rute antarkota (Origin Hub -> Destination Hub) yang memiliki
-- persentase kegagalan SLA tertinggi beserta rata-rata durasi keterlambatannya (jam).
-- Filter hanya rute dengan volume minimal 30 pengiriman agar tidak bias oleh sampel kecil.
--
-- Kolom yang diharapkan (minimal):
-- rute_pengiriman | hub_asal | hub_tujuan | total_pengiriman | total_terlambat | persentase_gagal_sla | avg_jam_keterlambatan
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:

SELECT
	CONCAT(dha.nama_hub, ' -> ', dht.nama_hub, ' (', dha.kota, ' - ', dht.kota, ')') AS rute_pengiriman,
	dha.nama_hub AS hub_asal,
	dht.nama_hub AS hub_tujuan,
	COUNT(*) AS total_pengiriman,
	COUNT(*) FILTER (WHERE fp.actual_delivered_timestamp > fp.promised_sla_timestamp OR fp.status_akhir <> 'DELIVERED') AS total_terlambat,
	ROUND(100.0 * COUNT(*) FILTER (WHERE fp.actual_delivered_timestamp > fp.promised_sla_timestamp OR fp.status_akhir <> 'DELIVERED') / COUNT(*), 2) AS persentase_gagal_sla,
	ROUND(AVG(EXTRACT(EPOCH FROM (fp.actual_delivered_timestamp - fp.promised_sla_timestamp)) / 3600.0) 
FILTER (WHERE fp.actual_delivered_timestamp > fp.promised_sla_timestamp), 2) AS avg_jam_keterlambatan
FROM fact_pengiriman fp
INNER JOIN dim_hub dha
	ON fp.hub_asal_id = dha.hub_id
INNER JOIN dim_hub dht
	ON fp.hub_tujuan_id = dht.hub_id
GROUP BY fp.hub_asal_id, fp.hub_tujuan_id, dha.hub_id, dht.hub_id, dha.nama_hub, dht.nama_hub
HAVING COUNT(*) >= 30
ORDER BY persentase_gagal_sla DESC, total_terlambat DESC, total_pengiriman DESC
LIMIT 10;

-- ==============================================================================
-- BAGIAN C: EFISIENSI GUDANG SORTIR & WAKTU SINGGAH (MID-MILE DWELL TIME)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 2.1: Audit Waktu Mengendap di Fasilitas Hub (Hub Dwell Time)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Hitung rata-rata waktu (dalam jam) yang dihabiskan paket saat singgah di masing-masing
-- fasilitas hub dari status scan masuk (HUB_IN) hingga keluar (HUB_OUT).
-- Gunakan data tracking event yang sudah dideduplikasi dari jitter scan.
--
-- Tips Analitik:
-- Pada sistem multi-hop, paket singgah di hub yang sama untuk HUB_IN dan HUB_OUT.
-- Pasangkan event HUB_IN dan HUB_OUT berikutnya pada resi dan hub yang bersangkutan.
--
-- Kolom yang diharapkan (minimal):
-- hub_id | nama_hub | tipe_hub | kota | total_kunjungan_paket | avg_dwell_time_jam | p95_dwell_time_jam
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:

WITH hub_visits AS (
-- Pasangkan HUB_IN dengan HUB_OUT berikutnya per resi dan per hub
    SELECT 
        no_resi_awb,
        hub_id,
        event_code,
        event_timestamp AS in_timestamp,
        LEAD(event_timestamp) OVER (
            PARTITION BY no_resi_awb, hub_id 
            ORDER BY event_timestamp ASC
        ) AS out_timestamp,
        LEAD(event_code) OVER (
            PARTITION BY no_resi_awb, hub_id 
            ORDER BY event_timestamp ASC
        ) AS next_event_code
    FROM v_clean_tracking_event
    WHERE event_code IN ('HUB_IN', 'HUB_OUT')
),
dwell_per_package AS (
-- Ambil pasangan yang valid dan hitung durasi jamnya
    SELECT 
        hub_id,
        no_resi_awb,
        EXTRACT(EPOCH FROM (out_timestamp - in_timestamp)) / 3600.0 AS dwell_time_jam
    FROM hub_visits
    WHERE event_code = 'HUB_IN' 
      AND next_event_code = 'HUB_OUT'
)
SELECT 
    d.hub_id,
    dh.nama_hub,
    dh.tipe_hub,
    dh.kota,
    COUNT(*) AS total_kunjungan_paket,
    ROUND(AVG(d.dwell_time_jam)::NUMERIC, 2) AS avg_dwell_time_jam,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d.dwell_time_jam)::NUMERIC, 2) AS p95_dwell_time_jam
FROM dwell_per_package d
INNER JOIN dim_hub dh 
    ON d.hub_id = dh.hub_id
GROUP BY 
    d.hub_id, 
    dh.nama_hub, 
    dh.tipe_hub, 
    dh.kota
ORDER BY avg_dwell_time_jam DESC;

-- ------------------------------------------------------------------------------
-- KASUS 2.2: Identifikasi Fasilitas Hub dengan Backlog Kritis (> 24 Jam)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Fasilitas hub mana yang mengalami penumpukan paket paling parah dengan volume
-- dan persentase paket tertahan > 24 jam (Critical Backlog) tertinggi?
--
-- Kolom yang diharapkan (minimal):
-- hub_id | nama_hub | total_transit | paket_tertahan_gt_24jam | pct_critical_backlog | status_kemacetan
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:

WITH hub_visits AS (
    -- Pasangkan HUB_IN dengan HUB_OUT berikutnya per resi dan per hub
    SELECT 
        no_resi_awb,
        hub_id,
        event_code,
        event_timestamp AS in_timestamp,
        LEAD(event_timestamp) OVER (
            PARTITION BY no_resi_awb, hub_id 
            ORDER BY event_timestamp ASC, event_id ASC
        ) AS out_timestamp,
        LEAD(event_code) OVER (
            PARTITION BY no_resi_awb, hub_id 
            ORDER BY event_timestamp ASC, event_id ASC
        ) AS next_event_code
    FROM v_clean_tracking_event
    WHERE event_code IN ('HUB_IN', 'HUB_OUT')
),
dwell_per_package AS (
    -- Ambil pasangan yang sah dan hitung durasi dwell time dalam jam
    SELECT 
        hub_id,
        no_resi_awb,
        EXTRACT(EPOCH FROM (out_timestamp - in_timestamp)) / 3600.0 AS dwell_time_jam
    FROM hub_visits
    WHERE event_code = 'HUB_IN' 
      AND next_event_code = 'HUB_OUT'
)
-- Agregasi total transit, volume backlog > 24 jam, dan persentasenya
SELECT 
    vte.hub_id,
    dh.nama_hub,
    COUNT(*) AS total_transit,
    COUNT(*) FILTER (WHERE vte.dwell_time_jam > 24.0) AS paket_tertahan_gt_24jam,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE vte.dwell_time_jam > 24.0) / COUNT(*), 
        2
    ) AS pct_critical_backlog,
    CASE 
        WHEN COUNT(*) FILTER (WHERE vte.dwell_time_jam > 24.0) > 0 
        THEN 'CRITICAL BACKLOG' 
        ELSE 'LANCAR / HEALTHY' 
    END AS status_kemacetan
FROM dwell_per_package vte
INNER JOIN dim_hub dh 
    ON vte.hub_id = dh.hub_id
GROUP BY 
    vte.hub_id, 
    dh.nama_hub
ORDER BY 
    pct_critical_backlog DESC, 
    paket_tertahan_gt_24jam DESC;

-- ==============================================================================
-- BAGIAN D: PRODUKTIVITAS & AUDIT KEPATUHAN KURIR PENGANTARAN (LAST-MILE)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 3.1: Efisiensi Pengantaran Pertama (First-Attempt Delivery Rate - FADR)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Evaluasi kinerja armada pengantaran di masing-masing Last-Mile Delivery DC:
-- Berapa rasio paket yang langsung sukses diantar pada percobaan pertama (Attempt 1),
-- dan berapa porsi paket yang membutuhkan percobaan kirim ulang (Attempt 2 atau 3)?
--
-- Kolom yang diharapkan (minimal):
-- hub_pengantaran | total_tugas_antar | sukses_attempt_1 | butuh_attempt_2_plus | fadr_pct
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:

SELECT
    dh.hub_id,
    dh.nama_hub AS hub_pengantaran,
    dh.tipe_hub,
    COUNT(*) FILTER (WHERE vte.event_code = 'DEL_OUT' AND vte.attempt_ke = 1) AS total_tugas_antar,
    COUNT(*) FILTER (WHERE vte.event_code = 'DEL_OK' AND vte.attempt_ke = 1) AS sukses_attempt_1,
    (
        COUNT(*) FILTER (WHERE vte.event_code = 'DEL_OUT' AND vte.attempt_ke = 1) - 
        COUNT(*) FILTER (WHERE vte.event_code = 'DEL_OK' AND vte.attempt_ke = 1)
    ) AS butuh_attempt_2_plus,
    ROUND(
        (100.0 * COUNT(*) FILTER (WHERE vte.event_code = 'DEL_OK' AND vte.attempt_ke = 1) / 
        NULLIF(COUNT(*) FILTER (WHERE vte.event_code = 'DEL_OUT' AND vte.attempt_ke = 1), 0))::NUMERIC, 
        2
    ) AS fadr_pct
FROM v_clean_tracking_event vte
INNER JOIN dim_hub dh 
    ON vte.hub_id = dh.hub_id
GROUP BY 
    dh.hub_id, 
    dh.nama_hub, 
    dh.tipe_hub
HAVING 
    COUNT(*) FILTER (WHERE vte.event_code = 'DEL_OUT' AND vte.attempt_ke = 1) > 0
ORDER BY 
    fadr_pct ASC;

-- ------------------------------------------------------------------------------
-- KASUS 3.2: Investigasi Anomali Gagal Kirim & Indikasi Fake Delivery Attempt
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Manajemen mencurigai adanya kurir nakal yang malas mengantar paket dan langsung
-- menandai paket sebagai 'Rumah Kosong' (fake attempt) tanpa mendatangi lokasi.
-- Temukan personel kurir yang memiliki total kegagalan kirim minimal 15 paket
-- dan mencatatkan proporsi alasan 'Rumah Kosong' > 65% dari total kegagalannya.
--
-- Kolom yang diharapkan (minimal):
-- kurir_id | nama_kurir | hub_penugasan | total_gagal_kirim | gagal_rumah_kosong | pct_rumah_kosong | indikasi_fraud
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:

SELECT
	vte.kurir_id,
	dk.nama_kurir,
	dh.nama_hub AS hub_penugasan,
	COUNT(*) AS total_gagal_kirim,
	COUNT(*) FILTER (WHERE vte.alasan_gagal_kirim = 'Rumah Kosong') AS gagal_rumah_kosong,
	ROUND(100.0 * COUNT(*) FILTER (WHERE vte.alasan_gagal_kirim = 'Rumah Kosong') / COUNT(*)::NUMERIC, 2) AS pct_rumah_kosong,
	CASE 
		WHEN ROUND(100.0 * COUNT(*) FILTER (WHERE vte.alasan_gagal_kirim = 'Rumah Kosong') / COUNT(*)::NUMERIC, 2) > 65.0
		THEN 'INDIKASI FAKE ATTEMPT'
		ELSE 'NORMAL'
	END AS indikasi_fraud
FROM v_clean_tracking_event vte
INNER JOIN dim_kurir dk
	ON vte.kurir_id = dk.kurir_id
INNER JOIN dim_hub dh 
    ON dk.hub_penugasan_id = dh.hub_id
WHERE vte.event_code = 'DEL_FAIL'
GROUP BY vte.kurir_id, dk.nama_kurir, dh.nama_hub
HAVING COUNT(*) >= 15
ORDER BY pct_rumah_kosong DESC;

-- ==============================================================================
-- BAGIAN E: PENGENDALIAN RISIKO PEMBAYARAN TUNAI (COD & SETTLEMENT)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 4.1: Evaluasi Risiko Retur Pesanan COD (Return to Sender Rate)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Bandingkan performa pengiriman antara metode pembayaran COD dengan Non-COD:
-- Berapa persentase paket yang berujung retur (RETURN_TO_SENDER) pada masing-masing metode?
-- Wilayah pulau/kota tujuan mana yang mencatatkan tingkat retur COD tertinggi?
--
-- Kolom yang diharapkan (minimal):
-- metode_pembayaran | total_pengiriman | total_delivered | total_rts | rts_rate_pct
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:

SELECT
	fp.metode_pembayaran,
	COUNT(*) AS total_pengiriman,
	COUNT(*) FILTER (WHERE fp.status_akhir = 'DELIVERED') AS total_delivered,
	COUNT(*) FILTER (WHERE fp.status_akhir = 'RETURN_TO_SENDER') AS total_rts,
	ROUND(100.0 * COUNT(*) FILTER (WHERE fp.status_akhir = 'RETURN_TO_SENDER') / COUNT(*), 2) AS rts_rate_pct
FROM fact_pengiriman fp 
GROUP BY fp.metode_pembayaran
ORDER BY rts_rate_pct DESC;

-- Sebaran Risiko Retur COD per Hub/Kota Tujuan
SELECT
    dht.hub_id AS hub_tujuan_id,
    dht.nama_hub AS hub_tujuan,
    dht.kota,
    dht.provinsi,
    COUNT(*) AS total_paket_cod,
    COUNT(*) FILTER (WHERE fp.status_akhir = 'DELIVERED') AS cod_delivered,
    COUNT(*) FILTER (WHERE fp.status_akhir = 'RETURN_TO_SENDER') AS cod_rts,
    ROUND(
        (100.0 * COUNT(*) FILTER (WHERE fp.status_akhir = 'RETURN_TO_SENDER') / COUNT(*))::NUMERIC, 
        2
    ) AS rts_cod_pct
FROM fact_pengiriman fp
INNER JOIN dim_hub dht 
    ON fp.hub_tujuan_id = dht.hub_id
WHERE fp.metode_pembayaran = 'COD'
GROUP BY 
    dht.hub_id, 
    dht.nama_hub, 
    dht.kota, 
    dht.provinsi
HAVING COUNT(*) >= 20
ORDER BY rts_cod_pct DESC;

-- ------------------------------------------------------------------------------
-- KASUS 4.2: Rekonsiliasi Dana Tunai Mengambang (Floating Cash in Transit)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Temukan paket COD yang status barangnya sudah berhasil diserahkan ke pembeli (DELIVERED),
-- namun uang pembayarannya belum disetorkan kurir ke kasir hub (waktu_setor_kasir IS NULL).
-- Hitung total lembar resi, total uang mengambang nasional, dan sebaran kurir pemegang dana terbesar!
-- (Ingat SOP: Nominal COD per resi = nilai_barang + ongkir_tertagih).
--
-- Kolom yang diharapkan (minimal):
-- Ringkasan Nasional & Top 5 Kurir Pemegang Floating Cash
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ==============================================================================
-- BAGIAN F: AUDIT KEBOCORAN FINANSIAL & LIABILITAS KOMERSIAL (REVENUE ASSURANCE)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 5.1: Audit Manipulasi Berat Volumetrik (Chargeable Weight Fraud)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Bandingkan berat fisik aktual yang dideklarasikan pedagang dengan berat volumetrik seharusnya
-- (Divisor 6.000 untuk Same Day, Next Day, Reguler; Divisor 5.000 untuk Kargo).
-- Hitung total selisih kilogram under-declared dan estimasi potensi pendapatan ongkir
-- yang bocor (asumsi tarif dasar Rp 10.000 per kg tambahan).
-- Pedagang mana yang paling banyak melakukan manipulasi dimensi?
--
-- Kolom yang diharapkan (minimal):
-- merchant_id | nama_merchant | tier_merchant | total_paket | total_under_declared_kg | estimasi_lost_revenue_rp
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ------------------------------------------------------------------------------
-- KASUS 5.2: Perhitungan Eksposur Liabilitas Denda Penalti Kontrak SLA
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Berdasarkan klausul kontrak penalti SLA di docs/SOP_METRIK_DAN_FORMULA_LOGISTIK.md:
-- - Terlambat 1 s/d <= 12 jam: denda 50% ongkir.
-- - Terlambat > 12 jam: denda 100% ongkir (Full Refund).
-- - Merchant ENTERPRISE: denda flat 100% ongkir jika terlambat.
-- Hitung total estimasi kewajiban denda yang harus dibayar NexLog pada Q1 2026,
-- dan sebarannya per tier merchant!
--
-- Kolom yang diharapkan (minimal):
-- tier_merchant | total_paket_terlambat | total_ongkir_terlambat | total_klaim_penalti_rp | avg_penalti_per_paket
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ------------------------------------------------------------------------------
-- KASUS 5.3: Penyusunan Rekomendasi Keputusan Eksekutif (BLUF Briefing)
-- ------------------------------------------------------------------------------
-- Silakan tuangkan analisis komprehensif dan 3 rekomendasi strategis Anda
-- ke dalam berkas deliverable: LAPORAN_EKSEKUTIF_ANALIS.md!
-- ==============================================================================
