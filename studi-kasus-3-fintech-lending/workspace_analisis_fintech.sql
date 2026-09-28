-- ====================================================================
-- STUDI KASUS 3: FINTECH P2P LENDING & CREDIT RISK ANALYTICS
-- PT NUSANTARA MODAL PINTAR (NusaModal)
-- Lembar Kerja Analisis SQL
-- Database : fintech_lending_db
-- RDBMS    : PostgreSQL 16
-- Analis   : Endricho (Lead Credit Risk & Financial Analytics Specialist)
-- Cutoff   : 2026-09-27
-- Dokumen  : docs/MEMO_DIREKSI_RISK_FINANCE.md
--            docs/SOP_METRIK_DAN_FORMULA_CREDIT_RISK.md
--            docs/DATA_DICTIONARY_FINTECH.md
-- ====================================================================


-- ====================================================================
-- BAGIAN A: REKONSILIASI KAS ESCROW & DATA HYGIENE
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 1.1] Deteksi Pencairan Ganda (Double Disbursement) pada Kas Escrow
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 1.2] Identifikasi Setoran Angsuran Tanpa VA Valid (Unmapped Repayments)
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN B: KUALITAS ASET & KEPATUHAN REGULASI BATAS OJK
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 2.1] Audit Rasio Makro TWP90 & TKB90 vs Ambang Batas 5,00% OJK
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 2.2] Kualitas Portofolio per Segmen: Paylater Konsumtif vs Modal Kerja Produktif
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN C: SEGMENTASI KETERLAMBATAN DPD & MATRIKS TRANSISI RISIKO
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 3.1] Klasifikasi Aging Buckets DPD (Current, 1–30, 31–60, 61–90, 90+)
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 3.2] Matriks Transisi Risiko: Roll-Forward Rate vs Cure Rate
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN D: ANALISIS KOHORT VINTAGE RISIKO KREDIT (VINTAGE CURVE / MOB)
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 4.1] Matriks Kinerja Bulanan Pinjaman (Month-on-Book / MOB 1 s/d MOB 6)
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 4.2] Deteksi Pemburukan Seleksi (Adverse Selection) pada Vintage 2026
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN E: AKUNTANSI PEMBAYARAN WATERFALL, PLAFON 100%, & PAJAK LENDER
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 5.1] Audit Alokasi Pembayaran Berjenjang (Waterfall) & Kepatuhan Plafon 100% OJK
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 5.2] Imbal Hasil Bersih Lender & Pemotongan Pajak Bunga PPh 23 (PMK 69/2022)
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN F: LAPORAN EKSEKUTIF BLUF & REKOMENDASI MANAJEMEN
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 6.1] Sintesis Eksekutif & Kueri Rekomendasi Terukur untuk Komite Risiko
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]

-- ====================================================================
-- AKHIR DARI LEMBAR KERJA
-- ====================================================================
