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

WITH rekap_portofolio AS (
    SELECT
        SUM(outstanding_principal) AS total_baki_debet_aktif,
        SUM(outstanding_principal) FILTER (WHERE status = 'DEFAULTED') AS total_baki_debet_macet
    FROM fact_loan
    WHERE status IN ('ACTIVE', 'DEFAULTED')
)
SELECT
    ROUND(100.0 * total_baki_debet_macet / total_baki_debet_aktif, 2) AS twp90,
    ROUND(100.0 - (100.0 * total_baki_debet_macet / total_baki_debet_aktif), 2) AS tkb90
FROM rekap_portofolio;

WITH pinjaman_dpd AS (
    -- Agregasi per pinjaman untuk mencari DPD terlama dari angsuran yang belum lunas
    SELECT
        fl.loan_id,
        fl.outstanding_principal,
        MAX(CASE WHEN frs.status != 'PAID' THEN ('2026-09-27'::DATE - frs.due_date) ELSE 0 END) AS max_dpd
    FROM fact_loan fl
    INNER JOIN fact_repayment_schedule frs 
        ON fl.loan_id = frs.loan_id
    WHERE fl.status IN ('ACTIVE', 'DEFAULTED')
    GROUP BY fl.loan_id, fl.outstanding_principal
)
SELECT
    ROUND(
        100.0 * SUM(outstanding_principal) FILTER (WHERE max_dpd > 90) / 
        SUM(outstanding_principal), 
        2
    ) AS twp90,
    ROUND(
        100.0 - (100.0 * SUM(outstanding_principal) FILTER (WHERE max_dpd > 90) / SUM(outstanding_principal)), 
        2
    ) AS tkb90
FROM pinjaman_dpd;

-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]

-- Sanity Check 1: Verifikasi bahwa seluruh pinjaman berstatus CLOSED dan WRITTEN_OFF memiliki sisa baki debet nol (0.00)
SELECT 
    status, 
    COUNT(*) AS total_pinjaman, 
    SUM(outstanding_principal) AS sisa_baki_debet_tidak_nol
FROM fact_loan
WHERE status IN ('CLOSED', 'WRITTEN_OFF')
GROUP BY status;

-- Sanity Check 2: Audit konsistensi status pinjaman vs jadwal angsuran faktual (0 anomali batas DPD 90 hari)
WITH pinjaman_max_dpd AS (
    SELECT 
        fl.loan_id,
        fl.status,
        MAX(CASE WHEN frs.status != 'PAID' THEN ('2026-09-27'::DATE - frs.due_date) ELSE 0 END) AS max_dpd
    FROM fact_loan fl
    INNER JOIN fact_repayment_schedule frs ON fl.loan_id = frs.loan_id
    WHERE fl.status IN ('ACTIVE', 'DEFAULTED')
    GROUP BY fl.loan_id, fl.status
)
SELECT 
    COUNT(*) FILTER (WHERE status = 'ACTIVE' AND max_dpd > 90) AS anomali_active_dpd_lewat_90,
    COUNT(*) FILTER (WHERE status = 'DEFAULTED' AND max_dpd <= 90) AS anomali_defaulted_dpd_kurang_91
FROM pinjaman_max_dpd;


-- --------------------------------------------------------------------
-- [KASUS 2.2] Kualitas Portofolio per Segmen: Paylater Konsumtif vs Modal Kerja Produktif
-- --------------------------------------------------------------------

-- TULIS KUERI ANALISIS ANDA DI SINI:

-- Opsi 1: Rekap Dasar Sesuai Standar OJK (Baki Debet Aktif, Macet, TWP90, TKB90)
WITH rekap_portofolio AS (
    SELECT
        product_type AS jenis_produk,
        SUM(outstanding_principal) AS total_baki_debet_aktif,
        SUM(outstanding_principal) FILTER (WHERE status = 'DEFAULTED') AS total_baki_debet_macet
    FROM fact_loan
    WHERE status IN ('ACTIVE', 'DEFAULTED')
    GROUP BY product_type
)
SELECT
    jenis_produk,
    total_baki_debet_aktif,
    total_baki_debet_macet,
    ROUND(100.0 * total_baki_debet_macet / total_baki_debet_aktif, 2) AS twp90,
    ROUND(100.0 - (100.0 * total_baki_debet_macet / total_baki_debet_aktif), 2) AS tkb90
FROM rekap_portofolio;

-- Opsi 2 Dilengkapi Pangsa Portofolio (% Share Exposure & % Share NPL)
WITH rekap_portofolio AS (
    SELECT
        product_type AS jenis_produk,
        SUM(outstanding_principal) AS total_baki_debet_aktif,
        SUM(outstanding_principal) FILTER (WHERE status = 'DEFAULTED') AS total_baki_debet_macet
    FROM fact_loan
    WHERE status IN ('ACTIVE', 'DEFAULTED')
    GROUP BY product_type
)
SELECT
    jenis_produk,
    total_baki_debet_aktif,
    ROUND(100.0 * total_baki_debet_aktif / SUM(total_baki_debet_aktif) OVER(), 2) AS porsi_eksposur_pct,
    total_baki_debet_macet,
    ROUND(100.0 * total_baki_debet_macet / SUM(total_baki_debet_macet) OVER(), 2) AS porsi_npl_nominal_pct,
    ROUND(100.0 * total_baki_debet_macet / total_baki_debet_aktif, 2) AS twp90,
    ROUND(100.0 - (100.0 * total_baki_debet_macet / total_baki_debet_aktif), 2) AS tkb90
FROM rekap_portofolio;


-- [DISIPLIN ANALIS: KUERI SANITY-CHECK KE TABEL MENTAH]

-- Sanity Check 1: Rekonsiliasi matematika portofolio segmen terhadap total portofolio makro Kasus 2.1 (selisih wajib 0.00)
SELECT 
    (SELECT SUM(outstanding_principal) FROM fact_loan WHERE status IN ('ACTIVE', 'DEFAULTED')) 
    - SUM(outstanding_principal) AS selisih_rekonsiliasi_aktif,
    (SELECT SUM(outstanding_principal) FROM fact_loan WHERE status = 'DEFAULTED') 
    - SUM(outstanding_principal) FILTER (WHERE status = 'DEFAULTED') AS selisih_rekonsiliasi_macet
FROM fact_loan
WHERE status IN ('ACTIVE', 'DEFAULTED')
  AND product_type IN ('PAYLATER', 'MODAL_KERJA');

-- Sanity Check 2: Pastikan tidak ada pinjaman aktif tanpa produk (NULL) atau tipe produk asing di luar segmentasi
SELECT 
    COUNT(*) FILTER (WHERE product_type IS NULL) AS pinjaman_tanpa_produk,
    COUNT(*) FILTER (WHERE product_type NOT IN ('PAYLATER', 'MODAL_KERJA')) AS produk_tidak_dikenal
FROM fact_loan
WHERE status IN ('ACTIVE', 'DEFAULTED');

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
