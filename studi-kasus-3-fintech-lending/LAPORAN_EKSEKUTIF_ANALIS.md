# LAPORAN EKSEKUTIF ANALIS: AUDIT PORTOFOLIO KREDIT, REKONSILIASI KAS ESCROW, & KEPATUHAN REGULASI OJK
**Perusahaan**: PT Nusantara Modal Pintar (NusaModal)  
**Kepada**: Bambang Suryodipuro, CFA, FRM — Chief Risk & Operating Officer (CRO)  
**Dari**: Endricho, Lead Credit Risk & Financial Analytics Specialist  
**Tanggal Laporan**: 28 September 2026  
**Status Audit**: In Progress / Draft Evaluasi Komite Risiko  
**Database Acuan**: `fintech_lending_db` (PostgreSQL 16)  

---

### 1. Ringkasan Eksekutif (Bottom Line Up Front — BLUF)

*(Bagian ini menyajikan 3 ringkasan kesimpulan paling krusial bagi Direksi berdasarkan temuan kueri SQL)*

1. **Integritas Kas Escrow**:
   - Ditemukan kebocoran kas akibat sistem *auto-retry webhook* pencairan ganda (*Double Disbursement*) sebesar **Rp [TBD]** pada **[TBD]** pinjaman.
   - Teridentifikasi dana mengendap tanpa pemilik (*Unmapped Repayments*) sebesar **Rp [TBD]** dari **[TBD]** mutasi setoran yang berisiko memicu salah tagih oleh tim collection.
2. **Kepatuhan Batas Regulasi OJK (TWP90 vs Batas 5,00%)**:
   - Rasio TWP90 agregat per penutupan buku 27 September 2026 berada pada posisi **[TBD]%** (TKB90: **[TBD]%**). Posisi ini [MEMATUHI / MELANGGAR] ambang batas pengawasan intensif OJK (5,00%).
   - Pembedahan kualitas aset menunjukkan produk yang menjadi pemicu utama kenaikan rasio adalah **[PAYLATER / MODAL_KERJA]** dengan rasio macet sebesar **[TBD]%**.
3. **Kualitas Seleksi & Kepatuhan Batas 100%**:
   - Analisis kohort vintage membuktikan bahwa kualitas seleksi kredit pada ekspansi pencairan tahun 2026 mengalami **[PENURUNAN / STABIL / PERBAIKAN]** dengan default rate dini sebesar **[TBD]%**.
   - Seluruh tagihan bunga, fee, dan denda telah diaudit terhadap aturan plafon 100% SEOJK 19/2023, di mana sebanyak **[TBD]** pinjaman melanggar dan **[TBD]** pinjaman menunggak lama telah mencapai batas maksimum beban ekonomi (*hard-capped*).

---

### 2. Matriks Indikator Kunci Portofolio (Executive KPI Dashboard)

| Pilar Analisis | Indikator Metrik Kunci | Target / Ambang Acuan | Nilai Temuan Analis | Status Evaluasi |
| :--- | :--- | :--- | :--- | :--- |
| **A. Kas Escrow** | Dana Bocor Double Disbursement | Rp 0,00 *(Toleransi Nol Kustodian)* | Rp [TBD] | [TBD] |
| | Dana Gantung Unmapped Repayments | Rp 0,00 *(Toleransi Nol Kustodian)* | Rp [TBD] | [TBD] |
| **B. Kualitas Aset** | Rasio Makro TWP90 Portofolio | $\le 5,00\%$ *(Batas Maksimum OJK)* | [TBD]% | [TBD] |
| | Rasio Makro TKB90 Portofolio | $\ge 95,00\%$ *(Batas Minimum OJK)* | [TBD]% | [TBD] |
| | Rasio TWP90 Paylater Konsumtif | [Benchmark Internal — Ditetapkan Analis] | [TBD]% | [TBD] |
| | Rasio TWP90 Modal Kerja Produktif | [Benchmark Internal — Ditetapkan Analis] | [TBD]% | [TBD] |
| **C. Segmentasi DPD** | Saldo Pokok di Ambang Default (DPD 61–90) | [Benchmark Internal — Ditetapkan Analis] | Rp [TBD] ([TBD]%) | [TBD] |
| | Roll-Forward Rate ke Default (DPD 61–90 $\rightarrow$ 90+) | [Benchmark Internal — Ditetapkan Analis] | [TBD]% | [TBD] |
| **D. Vintage Curve** | Default Rate Kumulatif Usia Muda (MOB 4–5) | [Benchmark Internal — Ditetapkan Analis] | [TBD]% | [TBD] |
| **E. Akuntansi & Pajak** | Pelanggaran Plafon 100% Pokok (SEOJK 19/2023) | 0 Kontrak *(Batas Absolut Regulasi)* | [TBD] Kontrak | [TBD] |
| | Total Setoran Withholding Tax PPh 23/26 ke Kas Negara | Rekonsiliasi 100% Kas Negara | Rp [TBD] | [TBD] |

---

### 3. Pembahasan Rinci Hasil Analisis per Pilar Bisnis

#### A. Rekonsiliasi Kas Escrow & Data Hygiene
* **Kasus 1.1 — Deteksi Double Disbursement**:
  *(Tabel temuan kueri: daftar loan_id, nominal pencairan ganda, bank penampung, dan estimasi recovery)*
* **Kasus 1.2 — Identifikasi Unmapped Repayments**:
  *(Tabel temuan kueri: breakdown dana mengendap per bank kustodian dan rekomendasi freeze penagihan)*

#### B. Kualitas Aset & Kepatuhan Batas OJK
* **Kasus 2.1 — Rasio Makro TWP90 & TKB90**:
  *(Rincian matematis formula SEOJK 19/2023, pembuktian denominator baki debet aktif)*
* **Kasus 2.2 — Komparasi Segmen Produk**:
  *(Tabel komparasi eksposur baki debet, porsi kredit macet, dan kontribusi risiko Paylater vs Modal Kerja)*

#### C. Segmentasi Keterlambatan DPD & Matriks Transisi
* **Kasus 3.1 — Distribusi 5 Aging Buckets DPD**:
  *(Tabel distribusi saldo pokok: Current, 1–30, 31–60, 61–90, 90+ beserta bobot risikonya)*
* **Kasus 3.2 — Matriks Transisi Roll-Rate**:
  *(Tabel matriks pergerakan status pinjaman Agustus 2026 vs September 2026, evaluasi efektivitas Desk Collection)*

#### D. Analisis Kohort Vintage Risiko Kredit (MOB)
* **Kasus 4.1 — Matriks Kurva Vintage MOB 1 s/d MOB 6**:
  *(Tabel perkembangan persentase NPL kumulatif per kohort bulan originasi)*
* **Kasus 4.2 — Pembuktian Adverse Selection Vintage 2026**:
  *(Analisis komparatif kecepatan pemburukan kualitas kredit antara kohort 2025 vs Q2 2026)*

#### E. Akuntansi Pembayaran Waterfall, Plafon 100%, & Pajak Lender
* **Kasus 5.1 — Audit Alokasi Waterfall & Kepatuhan Plafon 100%**:
  *(Pembuktian prioritas pemotongan: Denda $\rightarrow$ Fee $\rightarrow$ Bunga $\rightarrow$ Pokok, serta kepatuhan hard-cap)*
* **Kasus 5.2 — Imbal Hasil Bersih Lender & Pemotongan PPh 23 / PPh 26**:
  *(Breakdown penerimaan bunga bruto, platform cut, potongan pajak WPDN/WPLN, dan net yield)*

---

### 4. Rekomendasi Kebijakan & Rencana Aksi Direksi (Action Plan)

*(Diisi pada Bagian F berdasarkan sintesis temuan komprehensif)*

1. **Bidang Underwriting & Credit Risk**:
   - Usulan penyesuaian *cut-off credit score* minimum untuk persetujuan pinjaman baru.
   - Moratorium atau pengetatan limit pada segmen produk berisiko tinggi.
2. **Bidang Operasional & Rekonsiliasi Escrow**:
   - Perbaikan arsitektur integrasi API perbankan dan idempotency key untuk mencegah *auto-retry* ganda.
   - Prosedur penanganan dana mengendap (*unmapped repayment clearing*) untuk pembersihan riwayat debitur.
3. **Bidang Kepatuhan Regulasi (OJK Action Plan)**:
   - Rencana aksi resmi (*Supervisory Action Plan*) yang akan diserahkan kepada pengawas PVML OJK untuk menjaga status izin operasional platform NusaModal.

---

*Laporan ini disusun secara independen berdasarkan data mentah terverifikasi pada database `fintech_lending_db`.*
