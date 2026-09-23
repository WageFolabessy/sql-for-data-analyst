-- ==============================================================================
-- STUDI KASUS 2: PT NUSANTARA EKSPRES LOGISTIK (NexLog)
-- Lembar Kerja Analisis Logistik & SLA Integritas (PostgreSQL 16)
-- Database: logistics_sla_db
-- ==============================================================================
-- Petunjuk Analis:
-- 1. Gunakan dokumen resmi perusahaan sebagai panduan Single Source of Truth:
--    - 01_MEMO_DIREKSI_OPERASIONAL.md (Masalah bisnis & ekspektasi manajemen)
--    - 02_SOP_DAN_KAMUS_METRIK_LOGISTIK.md (Rumus baku OTD, volumetrik, penalti, dwell time)
--    - 03_KAMUS_DATA_DAN_SKEMA_LOGISTIK.md (Struktur tabel, tipe data, dan zona waktu)
-- 2. Anda memiliki KEBEBASAN PENUH dalam merancang kueri (CTE, Subquery, Window Functions,
--    Self-Join, dsb.). Pilihlah pendekatan yang paling efisien, akurat, dan mudah dibaca!
-- ==============================================================================


-- ==============================================================================
-- TEMA 0: DATA HYGIENE & PIPELINE INTEGRITY (PRE-ANALYTICS GATEWAY)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 0.1: Audit & Pembersihan Jitter Duplicate Barcode Scans
-- ------------------------------------------------------------------------------
-- Masalah Bisnis & Pipeline:
-- Sensor conveyor di hub dan PDA kurir di lapangan kerap mengalami network retry
-- sehingga memindai resi yang sama dengan status yang sama dalam selisih <= 10 detik.
-- Jika tidak dibersihkan, kueri LEAD() di Tema 2 akan memasangkan HUB_IN dengan duplikat
-- HUB_IN kedua, sehingga dwell time terhitung 0 jam (rusak total!).
--
-- Tugas Anda:
-- 1. Hitung berapa banyak scan duplikat jitter yang ada di fact_tracking_event per event_code!
-- 2. Tunjukkan logika deduplikasi (mengambil hanya pemindaian pertama per kelompok jitter).
--
-- Referensi SOP:
-- 02_SOP_DAN_KAMUS_METRIK_LOGISTIK.md (Bagian 6.1)
--
-- Kolom yang diharapkan (minimal):
-- event_code | total_scan_kotor | total_jitter_duplicate | total_scan_bersih | pct_jitter_duplikasi
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ------------------------------------------------------------------------------
-- KASUS 0.2: Deteksi Paket Nyasar / Unmanifested Ghost Parcels
-- ------------------------------------------------------------------------------
-- Masalah Bisnis & Operasional:
-- Di hub sortir transit antarpulau, kerap ditemukan paket mitra lain atau paket salah
-- kirim yang ter-scan di conveyor tapi nomor resinya tidak terdaftar di fact_pengiriman.
--
-- Tugas Anda:
-- Temukan seluruh nomor resi hantu (unmanifested) yang ter-scan di hub transit beserta
-- di fasilitas hub mana saja paket tersebut sempat terpindai, untuk dilaporkan ke tim
-- Loss Prevention & Investigasi Gudang!
--
-- Referensi SOP:
-- 02_SOP_DAN_KAMUS_METRIK_LOGISTIK.md (Bagian 6.2)
--
-- Kolom yang diharapkan (minimal):
-- no_resi_awb | hub_id | nama_hub | total_scan_di_hub | scan_pertama | scan_terakhir
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ==============================================================================
-- TEMA 1: SLA COMPLIANCE & ON-TIME DELIVERY (MACRO PERFORMANCE)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 1.1: Audit Kepatuhan On-Time Delivery (OTD) Makro
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Direksi ingin mengetahui persentase ketepatan waktu pengiriman (OTD %) untuk setiap
-- jenis layanan ('Same Day', 'Next Day', 'Reguler', 'Kargo') pada Q1 2026.
-- Layanan mana saja yang jebol dan gagal memenuhi standar kepatuhan industri (95%)?
--
-- Referensi SOP:
-- Paket on-time jika: actual_delivered_timestamp <= promised_sla_timestamp.
-- Paket retur/hilang/rusak dihitung sebagai gagal SLA (Breach).
--
-- Kolom yang diharapkan (minimal):
-- layanan | total_paket | total_on_time | total_breach | otd_percentage | status_kepatuhan
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ------------------------------------------------------------------------------
-- KASUS 1.2: 10 Rute Antarkota Paling Kronis (Chronic Delay Lanes)
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




-- ==============================================================================
-- TEMA 2: SORTING HUB BOTTLENECK & TRANSIT DWELL TIME (MID-MILE AUDIT)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 2.1: Audit Waktu Mengendap di Gudang Transit (Hub Dwell Time)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Hitung rata-rata waktu (dalam jam) yang dihabiskan paket saat singgah di masing-masing
-- fasilitas hub dari status scan masuk (HUB_IN) hingga keluar (HUB_OUT).
-- Gunakan data riwayat pemindaian barcode pada tabel fact_tracking_event.
--
-- Tips Analitik:
-- Pada sistem multi-hop, paket singgah di hub yang sama untuk HUB_IN dan HUB_OUT.
-- Pasangkan event HUB_IN dan HUB_OUT berikutnya pada resi dan hub yang bersangkutan.
--
-- Kolom yang diharapkan (minimal):
-- hub_id | nama_hub | tipe_hub | kota | total_kunjungan_paket | avg_dwell_time_jam | p95_dwell_time_jam
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ------------------------------------------------------------------------------
-- KASUS 2.2: Identifikasi Gudang Transit Paling Macet (Congested Hub Backlog)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Fasilitas hub mana yang mengalami penumpukan paket paling parah dengan volume
-- dan persentase paket tertahan > 24 jam (Critical Backlog) tertinggi?
--
-- Kolom yang diharapkan (minimal):
-- hub_id | nama_hub | total_transit | paket_tertahan_gt_24jam | pct_critical_backlog | status_kemacetan
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ==============================================================================
-- TEMA 3: LAST-MILE FLEET & FIRST-ATTEMPT DELIVERY RATE (COURIER KPI)
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




-- ------------------------------------------------------------------------------
-- KASUS 3.2: Audit Integritas Kurir & Deteksi Fake Delivery Attempt
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Manajemen mencurigai adanya kurir nakal yang malas mengantar paket dan langsung
-- menandai paket sebagai 'Rumah Kosong' (fake attempt).
-- Temukan personel kurir yang memiliki total kegagalan kirim minimal 15 paket
-- dan mencatatkan proporsi alasan 'Rumah Kosong' > 65% dari total kegagalannya.
--
-- Kolom yang diharapkan (minimal):
-- kurir_id | nama_kurir | hub_penugasan | total_gagal_kirim | gagal_rumah_kosong | pct_rumah_kosong | indikasi_fraud
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ==============================================================================
-- TEMA 4: E-COMMERCE CASH FLOW: COD & RETURN TO SENDER (RTS) RISK
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 4.1: Analisis Tingkat Retur (RTS) Pesanan COD vs Non-COD
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Bandingkan performa pengiriman antara metode pembayaran COD dengan Non-COD:
-- Berapa tingkat paket yang berujung retur (RETURN_TO_SENDER) pada masing-masing metode?
-- Wilayah pulau/kota tujuan mana yang mencatatkan tingkat retur COD tertinggi?
--
-- Kolom yang diharapkan (minimal):
-- metode_pembayaran | total_pengiriman | total_delivered | total_rts | rts_rate_pct
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ------------------------------------------------------------------------------
-- KASUS 4.2: Audit Uang Tunai COD Mengambang (Floating Cash in Transit)
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
-- TEMA 5: REVENUE LEAKAGE, PENALTY EXPOSURE, & EXECUTIVE STRATEGY
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- KASUS 5.1: Audit Kebocoran Pendapatan Berat Volumetrik (Weight Fraud)
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Bandingkan berat fisik aktual yang dideklarasikan dengan berat volumetrik seharusnya
-- (Divisor 6.000 untuk Same Day, Next Day, Reguler; Divisor 5.000 untuk Kargo).
-- Hitung total selisih kilogram under-declared dan estimasi potensi pendapatan ongkir
-- yang bocor (asumsi tarif dasar Rp 10.000 per kg tambahan).
-- Merchant mana yang paling banyak melakukan under-declaration dimensi?
--
-- Kolom yang diharapkan (minimal):
-- merchant_id | nama_merchant | tier_merchant | total_paket | total_under_declared_kg | estimasi_lost_revenue_rp
-- ------------------------------------------------------------------------------

-- TULIS KUERI ANDA DI SINI:




-- ------------------------------------------------------------------------------
-- KASUS 5.2: Perhitungan Eksposur Liabilitas Denda Penalti SLA
-- ------------------------------------------------------------------------------
-- Masalah Bisnis:
-- Berdasarkan klausul kontrak penalti SLA di 02_SOP_DAN_KAMUS_METRIK_LOGISTIK.md:
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
-- KASUS 5.3: Rekomendasi Keputusan Eksekutif (Executive BLUF Memo)
-- ------------------------------------------------------------------------------
-- Silakan tuangkan analisis komprehensif dan 3 rekomendasi strategis Anda
-- ke dalam berkas deliverable: 05_LAPORAN_EKSEKUTIF_ANALIS.md!
-- ==============================================================================
