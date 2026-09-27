# DATA DICTIONARY: FINTECH P2P LENDING & CREDIT RISK
**Database**: `fintech_lending_db`  
**RDBMS**: PostgreSQL 16  
**Entitas**: PT Nusantara Modal Pintar (NusaModal)  
**As-Of Evaluation Date**: `2026-09-27`  

---

### 1. Diagram Konseptual Relasi Tabel (Entity Relationship Overview)

```text
[dim_lender] ─────────────┐
                          ▼
[dim_borrower] ──► [fact_loan] ◄──► [fact_escrow_mutation] (via loan_id, nullable)
                          │
                          ▼
             [fact_repayment_schedule]
                          │
                          ▼
             [fact_repayment_payment]
```

---

### 2. Deskripsi Rinci Struktur Tabel

#### A. Tabel Dimensi: `dim_borrower`
Menyimpan profil identitas, demografi, dan skor kelayakan kredit debitur.
*Catatan Data Kotor*: Kolom kota dan telepon mengandung variasi teks operasional nyata.

| Nama Kolom | Tipe Data | Keterangan & Aturan Integritas |
| :--- | :--- | :--- |
| `borrower_id` | `VARCHAR(20)` | **PRIMARY KEY**. Format: `'BRW-10001'`, `'BRW-10002'`, dst. |
| `full_name` | `VARCHAR(100)` | Nama lengkap debitur terdaftar. |
| `phone_number` | `VARCHAR(30)` | Nomor kontak telepon (*inkonsistensi format: `0812...`, `+62812...`, `62812...`*). |
| `city` | `VARCHAR(50)` | Kota domisili (*inkonsistensi casing & penulisan: `'DKI Jakarta'`, `'Jakarta Selatan'`, `'JAKARTA-SELATAN'`, `'Surabaya'`, `'BANDUNG'`*). |
| `employment_type` | `VARCHAR(30)` | Kategori profesi: `'SALARIED'`, `'SME_OWNER'`, `'FREELANCE'`, `'GIG_WORKER'`. |
| `monthly_income` | `NUMERIC(15,2)` | Pendapatan kotor bulanan dalam Rupiah. |
| `credit_score` | `INTEGER` | Skor biro kredit (Pefindo/IdScore) skala 300–850. Bernilai `NULL` untuk peminjam *thin-file* (belum memiliki riwayat kredit). |
| `risk_tier` | `VARCHAR(10)` | Klasifikasi tier risiko underwriting awal: `'TIER_A'` (Score 750+), `'TIER_B'` (650–749), `'TIER_C'` (550–649), `'TIER_D'` (<550 / Thin-file). |
| `registration_date`| `DATE` | Tanggal registrasi akun di platform NusaModal. |

---

#### B. Tabel Dimensi: `dim_lender`
Menyimpan profil pemberi dana (investor/lender) yang mendanai pinjaman di platform.

| Nama Kolom | Tipe Data | Keterangan & Aturan Integritas |
| :--- | :--- | :--- |
| `lender_id` | `VARCHAR(20)` | **PRIMARY KEY**. Format: `'LND-20001'`, `'LND-20002'`, dst. |
| `lender_name` | `VARCHAR(100)` | Nama entitas atau individu pemberi dana. |
| `lender_type` | `VARCHAR(30)` | Klasifikasi: `'INDIVIDUAL_DOMESTIC'`, `'INSTITUTIONAL_DOMESTIC'`, `'INSTITUTIONAL_FOREIGN'`. |
| `has_npwp` | `BOOLEAN` | Kepemilikan NPWP aktif (`TRUE` / `FALSE`). |
| `tax_rate_pct` | `NUMERIC(5,2)` | Tarif withholding tax PMK 69/2022: `15.00` (WPDN ber-NPWP), `30.00` (WPDN tanpa NPWP), `20.00` (WPLN PPh 26). |
| `platform_margin_pct` | `NUMERIC(5,2)` | Persentase bagi hasil platform atas pendapatan bunga (contoh: `15.00`%). |
| `joined_date` | `DATE` | Tanggal pendaftaran lender di platform. |

---

#### C. Tabel Fakta: `fact_loan`
Menyimpan kontrak pokok pendanaan yang disalurkan dari Lender kepada Borrower.

| Nama Kolom | Tipe Data | Keterangan & Aturan Integritas |
| :--- | :--- | :--- |
| `loan_id` | `VARCHAR(20)` | **PRIMARY KEY**. Format: `'LN-2025-00001'`, `'LN-2026-00042'`, dst. |
| `borrower_id` | `VARCHAR(20)` | **FOREIGN KEY** merujuk ke `dim_borrower(borrower_id)`. |
| `lender_id` | `VARCHAR(20)` | **FOREIGN KEY** merujuk ke `dim_lender(lender_id)`. |
| `product_type` | `VARCHAR(20)` | Kategori pendanaan OJK: `'PAYLATER'` (Konsumtif) atau `'MODAL_KERJA'` (Produktif). |
| `disbursement_date`| `DATE` | Tanggal pencairan dana ke rekening borrower (rentang: `2025-01-01` s/d `2026-09-27`). |
| `disbursed_principal` | `NUMERIC(15,2)` | Nilai pokok pendanaan awal sesuai kontrak (dasar perhitungan bunga flat). |
| `tenor_months` | `INTEGER` | Durasi kontrak pinjaman (bulan: 1, 3, 6, 12). |
| `daily_interest_rate` | `NUMERIC(8,5)` | **Suku bunga harian kontrak (SEOJK 19/2023)**: Dikunci permanen pada tanggal originasi. |
| `daily_penalty_rate` | `NUMERIC(8,5)` | **Tarif denda keterlambatan harian**: Dikunci permanen pada tanggal originasi (mengikuti batas suku bunga). |
| `status` | `VARCHAR(20)` | Status pinjaman: `'ACTIVE'`, `'CLOSED'`, `'DEFAULTED'`, `'CANCELLED'`. |
| `outstanding_principal`| `NUMERIC(15,2)` | Sisa baki debet pokok pinjaman yang belum dilunasi per 27 September 2026. |
| `is_capped_at_100_pct` | `BOOLEAN` | Flag kepatuhan plafon 100% OJK (`TRUE` jika akumulasi bunga+fee+denda telah menyentuh batas 100% dari `disbursed_principal`). |
| `is_restructured_evergreen` | `BOOLEAN` | Flag audit indikasi *evergreening* (pelunasan semu DPD 89 diikuti pencairan baru). |

---

#### D. Tabel Fakta: `fact_repayment_schedule`
Menyimpan rincian jadwal jatuh tempo angsuran per termin pinjaman.

| Nama Kolom | Tipe Data | Keterangan & Aturan Integritas |
| :--- | :--- | :--- |
| `schedule_id` | `VARCHAR(30)` | **PRIMARY KEY**. Format: `'SCH-LN-2025-00001-01'`. |
| `loan_id` | `VARCHAR(20)` | **FOREIGN KEY** merujuk ke `fact_loan(loan_id)`. |
| `installment_no` | `INTEGER` | Nomor angsuran (termin ke-1, 2, dst). |
| `due_date` | `DATE` | Tanggal jatuh tempo angsuran. |
| `principal_due` | `NUMERIC(15,2)` | Tagihan porsi pokok pinjaman. |
| `interest_due` | `NUMERIC(15,2)` | Tagihan bunga flat (`disbursed_principal * daily_interest_rate * hari`). |
| `platform_fee_due`| `NUMERIC(15,2)` | Tagihan biaya pemeliharaan layanan platform. |
| `late_penalty_due`| `NUMERIC(15,2)` | Tagihan akumulasi denda keterlambatan (tunduk pada hard-cap 100%). |
| `principal_paid`| `NUMERIC(15,2)` | Total porsi pokok yang telah terbayar. |
| `interest_paid` | `NUMERIC(15,2)` | Total porsi bunga yang telah terbayar. |
| `fee_paid` | `NUMERIC(15,2)` | Total porsi fee platform yang telah terbayar. |
| `penalty_paid` | `NUMERIC(15,2)` | Total porsi denda keterlambatan yang telah terbayar. |
| `status` | `VARCHAR(20)` | Status termin: `'PAID'`, `'OVERDUE'`, `'PENDING'`. |
| `last_payment_date`| `DATE` | Tanggal setoran terakhir diterima untuk angsuran ini (bisa `NULL`). |

---

#### E. Tabel Fakta: `fact_repayment_payment`
Menyimpan riwayat setoran uang nyata yang masuk dari debitur beserta alokasi waterfall-nya.

| Nama Kolom | Tipe Data | Keterangan & Aturan Integritas |
| :--- | :--- | :--- |
| `payment_id` | `VARCHAR(30)` | **PRIMARY KEY**. Format: `'PAY-20260901-0001'`. |
| `schedule_id` | `VARCHAR(30)` | **FOREIGN KEY** merujuk ke `fact_repayment_schedule(schedule_id)`. |
| `loan_id` | `VARCHAR(20)` | **FOREIGN KEY** merujuk ke `fact_loan(loan_id)`. |
| `payment_timestamp` | `TIMESTAMP` | Waktu persis transaksi pembayaran tercatat. |
| `amount_paid` | `NUMERIC(15,2)` | Total nominal uang yang disetorkan debitur. |
| `payment_channel` | `VARCHAR(50)` | Kanal pembayaran: `'BCA_VA'`, `'MANDIRI_VA'`, `'BNI_VA'`, `'INDOMARET'`, `'ALFAMART'`. |
| `allocated_penalty`| `NUMERIC(15,2)` | Porsi dana yang terserap untuk pelunasan denda (Prioritas 1). |
| `allocated_fee` | `NUMERIC(15,2)` | Porsi dana yang terserap untuk fee platform (Prioritas 2). |
| `allocated_interest`| `NUMERIC(15,2)` | Porsi dana yang terserap untuk bunga lender (Prioritas 3). |
| `allocated_principal`| `NUMERIC(15,2)`| Porsi dana yang terserap untuk pelunasan pokok (Prioritas 4). |

---

#### F. Tabel Fakta: `fact_escrow_mutation`
Menyimpan rekening koran mutasi kas escrow/RDL pada bank penampung (*Bank Custodian*).

| Nama Kolom | Tipe Data | Keterangan & Aturan Integritas |
| :--- | :--- | :--- |
| `mutation_id` | `VARCHAR(30)` | **PRIMARY KEY**. Format: `'MUT-2026-000001'`. |
| `bank_name` | `VARCHAR(50)` | Nama rekening bank kustodian: `'BANK_BCA_ESCROW'` atau `'BANK_MANDIRI_ESCROW'`. |
| `mutation_timestamp` | `TIMESTAMP` | Waktu pencatatan mutasi di rekening koran bank. |
| `mutation_type` | `VARCHAR(10)` | `'DEBIT'` (Kas Keluar / Pencairan pinjaman ke borrower) atau `'CREDIT'` (Kas Masuk / Pembayaran borrower atau top-up lender). |
| `amount` | `NUMERIC(15,2)` | Nominal transaksi kas mutasi. |
| `balance_after` | `NUMERIC(15,2)` | Saldo akhir rekening bank setelah mutasi. |
| `loan_id` | `VARCHAR(20)` | ID pinjaman terkait. **BISA BERSIFAT NULL** jika terjadi *Unmapped Repayments* (salah transfer VA). |
| `va_number` | `VARCHAR(30)` | Nomor Virtual Account tujuan transaksi. |
| `description` | `TEXT` | Berita acara mutasi dari bank. |
| `is_reconciled` | `BOOLEAN` | Status rekonsiliasi dengan core ledger sistem NusaModal. |
