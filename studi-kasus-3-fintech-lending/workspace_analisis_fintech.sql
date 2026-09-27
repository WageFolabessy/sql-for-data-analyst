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
-- Mandat Bisnis: Identifikasi anomali mutasi kas debit ganda akibat auto-retry webhook,
--                hitung total dana escrow yang bocor, dan identifikasi loan_id terkait.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 1.2] Identifikasi Setoran Angsuran Tanpa VA Valid (Unmapped Repayments)
-- Mandat Bisnis: Temukan mutasi kas kredit yang masuk ke rekening escrow tanpa relasi pinjaman
--                (loan_id IS NULL), hitung total dana gantung, dan kelompokkan per bank.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN B: KUALITAS ASET & KEPATUHAN REGULASI BATAS OJK
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 2.1] Audit Rasio Makro TWP90 & TKB90 vs Ambang Batas 5,00% OJK
-- Mandat Bisnis: Hitung rasio agregat TWP90 dan TKB90 seluruh portofolio aktif as-of 27 Sep 2026
--                sesuai formula SEOJK 19/2023, serta tentukan status kepatuhan hukum platform.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 2.2] Kualitas Portofolio per Segmen: Paylater Konsumtif vs Modal Kerja Produktif
-- Mandat Bisnis: Bedah perbandingan baki debet aktif, nominal macet (>90 DPD), dan rasio TWP90
--                antara segmen PAYLATER dan MODAL_KERJA untuk menemukan pemicu utama kenaikan risiko.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN C: SEGMENTASI KETERLAMBATAN DPD & MATRIKS TRANSISI RISIKO
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 3.1] Klasifikasi Aging Buckets DPD (Current, 1–30, 31–60, 61–90, 90+)
-- Mandat Bisnis: Petakan baki debet pokok pinjaman aktif ke dalam 5 keranjang DPD as-of 27 Sep 2026,
--                hitung porsi eksposur dan identifikasi saldo berisiko tinggi (DPD 61–90).
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 3.2] Matriks Transisi Risiko: Roll-Forward Rate vs Cure Rate
-- Mandat Bisnis: Analisis pergerakan saldo antar-bucket dari status bulan lalu ke bulan berjalan,
--                hitung probabilitas pemburukan (Roll-Forward) dan keberhasilan penagihan (Cure Rate).
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN D: ANALISIS KOHORT VINTAGE RISIKO KREDIT (VINTAGE CURVE / MOB)
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 4.1] Matriks Kinerja Bulanan Pinjaman (Month-on-Book / MOB 1 s/d MOB 6)
-- Mandat Bisnis: Bangun kurva vintage kumulatif NPL per bulan pencairan (cohort disbursement month)
--                dari MOB 1 hingga MOB 6 dengan denominator Original Disbursed Principal di MOB 0.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 4.2] Deteksi Pemburukan Seleksi (Adverse Selection) pada Vintage 2026
-- Mandat Bisnis: Bandingkan akselerasi gagal bayar dini (MOB 1–3) antara vintage 2025 dengan
--                vintage Q2 2026 (Apr–Jun 2026) untuk membuktikan adanya degradasi kualitas underwriting.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN E: AKUNTANSI PEMBAYARAN WATERFALL, PLAFON 100%, & PAJAK LENDER
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 5.1] Audit Alokasi Pembayaran Berjenjang (Waterfall) & Kepatuhan Plafon 100% OJK
-- Mandat Bisnis: Verifikasi kepatuhan urutan pelunasan (Denda -> Fee -> Bunga -> Pokok) pada setoran,
--                serta audit apakah ada pinjaman yang melanggar batas 100% pokok pinjaman.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]



-- --------------------------------------------------------------------
-- [KASUS 5.2] Imbal Hasil Bersih Lender & Pemotongan Pajak Bunga PPh 23 (PMK 69/2022)
-- Mandat Bisnis: Hitung penerimaan bunga bersih per tipe lender setelah bagi hasil platform dan
--                potongan PPh 23 (15%/30%) atau PPh 26 (20%), serta total setoran withholding tax ke kas negara.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]




-- ====================================================================
-- BAGIAN F: LAPORAN EKSEKUTIF BLUF & REKOMENDASI MANAJEMEN
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 6.1] Sintesis Eksekutif & Kueri Rekomendasi Terukur untuk Komite Risiko
-- Mandat Bisnis: Kueri pendukung untuk perumusan kebijakan pengetatan credit score cut-off,
--                pembekuan segmen berisiko, dan rencana aksi penyelamatan sebelum audit OJK.
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:



-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]

-- ====================================================================
-- AKHIR DARI LEMBAR KERJA
-- ====================================================================
