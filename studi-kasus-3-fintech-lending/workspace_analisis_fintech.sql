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

SELECT * FROM dim_borrower;
SELECT * FROM dim_lender;
SELECT * FROM fact_loan;
SELECT * FROM fact_repayment_schedule;
SELECT * FROM fact_repayment_payment;
SELECT * FROM fact_escrow_mutation;

-- ====================================================================
-- BAGIAN A: REKONSILIASI KAS ESCROW & DATA HYGIENE
-- ====================================================================

-- --------------------------------------------------------------------
-- [KASUS 1.1] Deteksi Pencairan Ganda (Double Disbursement) pada Kas Escrow
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:

WITH detail_mutasi AS (
    SELECT
        fem.mutation_id,
        fem.loan_id,
        fem.mutation_timestamp,
        fem.mutation_type,
        fem.amount,
        -- Menghitung frekuensi mutasi DEBIT per loan_id
        COUNT(*) OVER (PARTITION BY fem.loan_id) AS jumlah_loan
    FROM fact_escrow_mutation fem
    WHERE fem.mutation_type = 'DEBIT'
),
dana_bocor AS (
    SELECT DISTINCT ON (dl.loan_id)
        dl.mutation_id,
        dl.loan_id,
        fl.borrower_id,
        dl.mutation_timestamp,
        fl.disbursement_date,
        dl.mutation_type,
        dl.amount,
        fl.disbursed_principal
    FROM detail_mutasi dl
    INNER JOIN fact_loan fl
        ON dl.loan_id = fl.loan_id
    WHERE dl.jumlah_loan > 1
    ORDER BY dl.loan_id, dl.mutation_timestamp DESC
)
SELECT
    COUNT(loan_id) AS total_kebocoran,
    SUM(amount)    AS total_dana_yang_bocor
FROM dana_bocor;


-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]

-- Sanity Check 1: Verifikasi mutasi DEBIT yang ditolak/belum terekonsiliasi oleh sistem core
SELECT 
    COUNT(*)    AS total_mutasi_debit_unreconciled, 
    SUM(amount) AS total_nominal_bocor
FROM fact_escrow_mutation
WHERE mutation_type = 'DEBIT' 
  AND is_reconciled = FALSE;

-- Sanity Check 2: Selisih antara total mutasi pencairan kas escrow dengan total pokok kontrak
SELECT 
    (SELECT SUM(amount) FROM fact_escrow_mutation WHERE mutation_type = 'DEBIT' AND description LIKE '%PENCAIRAN%')
    - (SELECT SUM(disbursed_principal) FROM fact_loan) AS selisih_kebocoran_kas;


-- --------------------------------------------------------------------
-- [KASUS 1.2] Identifikasi Setoran Angsuran Tanpa VA Valid (Unmapped Repayments)
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:

SELECT
    COALESCE(bank_name, 'TOTAL_KESELURUHAN') AS bank_penampung,
    COUNT(*)                                 AS total_transaksi_unmapped,
    SUM(amount)                              AS total_dana_gantung
FROM fact_escrow_mutation
WHERE mutation_type = 'CREDIT' 
  AND is_reconciled = FALSE 
  AND loan_id IS NULL
GROUP BY ROLLUP(bank_name);


-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]

-- Sanity Check 1: Buktikan bahwa semua kredit tereconciled cocok 100% dengan total pembayaran payment ledger
SELECT 
    (SELECT SUM(amount) FROM fact_escrow_mutation WHERE mutation_type = 'CREDIT' AND is_reconciled = TRUE AND description LIKE 'SETORAN ANGSURAN%') AS total_escrow_credit_reconciled,
    (SELECT SUM(amount_paid) FROM fact_repayment_payment) AS total_payment_ledger_paid;

-- Sanity Check 2: Pastikan tidak ada satupun mutasi unmapped yang memiliki nomor pinjaman
SELECT COUNT(*) AS anomali_unmapped_ber_loan_id
FROM fact_escrow_mutation
WHERE mutation_type = 'CREDIT' 
  AND is_reconciled = FALSE 
  AND loan_id IS NOT NULL;

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
