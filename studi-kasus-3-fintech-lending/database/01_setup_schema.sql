-- ====================================================================
-- STUDI KASUS 3: FINTECH P2P LENDING & CREDIT RISK ANALYTICS
-- PT NUSANTARA MODAL PINTAR (NusaModal)
-- File    : 01_setup_schema.sql
-- Database: fintech_lending_db
-- RDBMS   : PostgreSQL 16
-- Cutoff  : 2026-09-27
-- ====================================================================

-- 1. Bersihkan skema jika sudah ada tabel sebelumnya
DROP TABLE IF EXISTS fact_escrow_mutation CASCADE;
DROP TABLE IF EXISTS fact_repayment_payment CASCADE;
DROP TABLE IF EXISTS fact_repayment_schedule CASCADE;
DROP TABLE IF EXISTS fact_loan CASCADE;
DROP TABLE IF EXISTS dim_lender CASCADE;
DROP TABLE IF EXISTS dim_borrower CASCADE;

-- 2. Tabel Dimensi: dim_borrower
CREATE TABLE dim_borrower (
    borrower_id         VARCHAR(20) PRIMARY KEY,
    full_name           VARCHAR(100) NOT NULL,
    phone_number        VARCHAR(30),
    city                VARCHAR(50),
    employment_type     VARCHAR(30),
    monthly_income      NUMERIC(15,2) NOT NULL,
    credit_score        INTEGER,
    risk_tier           VARCHAR(10),
    registration_date   DATE NOT NULL
);

-- 3. Tabel Dimensi: dim_lender
CREATE TABLE dim_lender (
    lender_id           VARCHAR(20) PRIMARY KEY,
    lender_name         VARCHAR(100) NOT NULL,
    lender_type         VARCHAR(30) NOT NULL,
    has_npwp            BOOLEAN NOT NULL DEFAULT TRUE,
    tax_rate_pct        NUMERIC(5,2) NOT NULL,
    platform_margin_pct NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    joined_date         DATE NOT NULL
);

-- 4. Tabel Fakta: fact_loan
CREATE TABLE fact_loan (
    loan_id                     VARCHAR(20) PRIMARY KEY,
    borrower_id                 VARCHAR(20) NOT NULL REFERENCES dim_borrower(borrower_id),
    lender_id                   VARCHAR(20) NOT NULL REFERENCES dim_lender(lender_id),
    product_type                VARCHAR(20) NOT NULL, -- 'PAYLATER' atau 'MODAL_KERJA'
    disbursement_date           DATE NOT NULL,
    disbursed_principal         NUMERIC(15,2) NOT NULL,
    tenor_months                INTEGER NOT NULL,
    daily_interest_rate         NUMERIC(8,5) NOT NULL, -- Dikunci pada saat originasi
    daily_penalty_rate          NUMERIC(8,5) NOT NULL, -- Dikunci pada saat originasi
    status                      VARCHAR(20) NOT NULL, -- 'ACTIVE', 'CLOSED', 'DEFAULTED', 'CANCELLED'
    outstanding_principal       NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    is_capped_at_100_pct        BOOLEAN NOT NULL DEFAULT FALSE,
    is_restructured_evergreen   BOOLEAN NOT NULL DEFAULT FALSE
);

-- 5. Tabel Fakta: fact_repayment_schedule
CREATE TABLE fact_repayment_schedule (
    schedule_id         VARCHAR(30) PRIMARY KEY,
    loan_id             VARCHAR(20) NOT NULL REFERENCES fact_loan(loan_id) ON DELETE CASCADE,
    installment_no      INTEGER NOT NULL,
    due_date            DATE NOT NULL,
    principal_due       NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    interest_due        NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    platform_fee_due    NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    late_penalty_due    NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    principal_paid      NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    interest_paid       NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    fee_paid            NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    penalty_paid        NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    status              VARCHAR(20) NOT NULL, -- 'PAID', 'OVERDUE', 'PENDING'
    last_payment_date   DATE
);

-- 6. Tabel Fakta: fact_repayment_payment
CREATE TABLE fact_repayment_payment (
    payment_id          VARCHAR(30) PRIMARY KEY,
    schedule_id         VARCHAR(30) REFERENCES fact_repayment_schedule(schedule_id),
    loan_id             VARCHAR(20) NOT NULL REFERENCES fact_loan(loan_id),
    payment_timestamp   TIMESTAMP NOT NULL,
    amount_paid         NUMERIC(15,2) NOT NULL,
    payment_channel     VARCHAR(50) NOT NULL,
    allocated_penalty   NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    allocated_fee       NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    allocated_interest  NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    allocated_principal NUMERIC(15,2) NOT NULL DEFAULT 0.00
);

-- 7. Tabel Fakta: fact_escrow_mutation
CREATE TABLE fact_escrow_mutation (
    mutation_id         VARCHAR(30) PRIMARY KEY,
    bank_name           VARCHAR(50) NOT NULL,
    mutation_timestamp  TIMESTAMP NOT NULL,
    mutation_type       VARCHAR(10) NOT NULL, -- 'DEBIT' (Kas Keluar) atau 'CREDIT' (Kas Masuk)
    amount              NUMERIC(15,2) NOT NULL,
    balance_after       NUMERIC(15,2) NOT NULL,
    loan_id             VARCHAR(20), -- BISA NULL untuk Unmapped Repayments
    va_number           VARCHAR(30),
    description         TEXT,
    is_reconciled       BOOLEAN NOT NULL DEFAULT FALSE
);

-- 8. Indeks Kinerja untuk Kueri Skala Besar & Agregasi Analitis
CREATE INDEX idx_loan_borrower ON fact_loan(borrower_id);
CREATE INDEX idx_loan_lender ON fact_loan(lender_id);
CREATE INDEX idx_loan_product ON fact_loan(product_type);
CREATE INDEX idx_loan_status ON fact_loan(status);
CREATE INDEX idx_loan_disbursement_date ON fact_loan(disbursement_date);

CREATE INDEX idx_schedule_loan ON fact_repayment_schedule(loan_id);
CREATE INDEX idx_schedule_due_date ON fact_repayment_schedule(due_date);
CREATE INDEX idx_schedule_status ON fact_repayment_schedule(status);

CREATE INDEX idx_payment_schedule ON fact_repayment_payment(schedule_id);
CREATE INDEX idx_payment_loan ON fact_repayment_payment(loan_id);
CREATE INDEX idx_payment_timestamp ON fact_repayment_payment(payment_timestamp);

CREATE INDEX idx_escrow_loan ON fact_escrow_mutation(loan_id);
CREATE INDEX idx_escrow_timestamp ON fact_escrow_mutation(mutation_timestamp);
CREATE INDEX idx_escrow_type ON fact_escrow_mutation(mutation_type);
