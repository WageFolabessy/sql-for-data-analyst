# STANDARD OPERATING PROCEDURE (SOP)
## METRIK RISIKO KREDIT, REKONSILIASI KAS, & AKUNTANSI P2P LENDING
**Dokumen Referensi**: SOP-CR-FIN-2026-004  
**Berlaku Efektif**: 1 Januari 2026 (Diperbarui per 27 September 2026)  
**Payung Regulasi**:
1. **POJK No. 40/2024** tentang Layanan Pendanaan Bersama Berbasis Teknologi Informasi (LPBBTI).
2. **SEOJK No. 19/SEOJK.06/2023** tentang Penyelenggaraan LPBBTI (Khusus Batas Bunga, Denda, dan Kualitas Aset).
3. **PMK No. 69/PMK.03/2022** tentang Perlakuan Perpajakan atas Teknologi Finansial (PPh Pasal 23 & PPh 26 atas Imbal Hasil Bunga).

---

### 1. Batas Maksimum Manfaat Ekonomi & Denda Keterlambatan (SEOJK 19/2023)

Sesuai Bab VII SEOJK No. 19/SEOJK.06/2023, batas maksimum suku bunga (manfaat ekonomi) dan denda keterlambatan ditentukan oleh dua dimensi: **jenis produk pinjaman** dan **tahun originasi/pencairan**:

#### A. Matriks Tarif Harian Maksimum (Produk × Tahun Originasi)

| Kategori Produk | 2024 (Historis) | 2025 (Baseline) | 2026 (Aktif / Berjalan) |
| :--- | :--- | :--- | :--- |
| **Konsumtif (Paylater)** | 0,30% / hari kalender | **0,20% / hari kalender** | **0,10% / hari kalender** |
| **Produktif (Modal Kerja)** | 0,10% / hari kalender | **0,10% / hari kalender** *(tetap)* | **0,067% / hari kalender** |

#### B. Ketentuan Hukum Penetapan Suku Bunga & Denda:
1. **Penguncian Kontrak (*Fixed at Origination*)**:
   - Nilai `daily_interest_rate` dan `daily_penalty_rate` **dikunci secara permanen pada tanggal pencairan pinjaman (`disbursement_date`)** dan mengikat sepanjang masa pinjaman hingga lunas. Suku bunga kontrak tidak boleh berubah mengikuti tanggal kalender berjalan.
2. **Tarif Denda Keterlambatan**:
   - Batas maksimum denda keterlambatan harian (`daily_penalty_rate`) mengikuti batas tarif harian yang persis sama dengan bunga per kategori produk dan tahun originasi.
3. **Dasar Pengenaan Flat atas Nilai Pokok Kontrak**:
   - Sesuai teks resmi regulasi, bunga harian dan denda harian dihitung **secara flat dari pokok pinjaman awal yang tercantum dalam perjanjian pendanaan (`disbursed_principal`)**, bukan dari baki debet / sisa pokok yang menyusut (*declining balance*).
   $$\text{Bunga Harian (Rp)} = \text{disbursed\_principal} \times \text{daily\_interest\_rate}$$
   $$\text{Denda Keterlambatan Harian (Rp)} = \text{disbursed\_principal} \times \text{daily\_penalty\_rate}$$

---

### 2. Aturan Plafon 100% Manfaat Ekonomi & Denda (Hard Cap Rule)

Sesuai ketentuan pasal batas akumulasi biaya pinjaman:
$$\text{Total Akumulasi (Bunga + Biaya Layanan/Fee Platform + Denda Keterlambatan)} \le 100\% \times \text{disbursed\_principal}$$

#### Ketentuan Teknis Penagihan & Sistem:
- Begitu jumlah kumulatif tagihan `bunga + platform_fee + late_penalty` pada sebuah pinjaman menyentuh angka $1,00 \times \text{disbursed\_principal}$, **penambahan bunga dan denda harus dihentikan secara keras (*hard-freeze*)**.
- Sistem dilarang menambahkan beban finansial baru kepada borrower (`is_capped_at_100_pct = TRUE`).
- Segala penagihan yang melampaui 100% dari nilai pokok pinjaman merupakan pelanggaran berat kepatuhan OJK (*regulatory non-compliance*) dan dapat dikenai denda sanksi administratif.

---

### 3. Rumus Resmi Kualitas Pendanaan OJK: TWP90 & TKB90

Kualitas pendanaan diukur berdasarkan tingkat kelancaran pembayaran kembali oleh penerima dana per tanggal evaluasi (*As-Of Date*):

#### A. Formula TWP90 (Tingkat Wanprestasi > 90 Hari)
$$\text{TWP90} = \frac{\sum \text{Outstanding Principal Pinjaman Aktif dengan DPD } > 90 \text{ Hari}}{\sum \text{Outstanding Principal Seluruh Pinjaman Aktif}} \times 100\%$$

- **Ambang Batas Pengawasan OJK**: $\text{TWP90} \le 5,00\%$.
- Jika $\text{TWP90} > 5,00\%$, platform masuk dalam pengawasan intensif OJK, wajib menyampaikan rencana aksi perbaikan, dan terancam pembekuan izin penyaluran pinjaman baru.

#### B. Formula TKB90 (Tingkat Keberhasilan Bayar 90 Hari)
$$\text{TKB90} = 100\% - \text{TWP90}$$
- **Ambang Batas Minimum**: $\text{TKB90} \ge 95,00\%$. TKB90 wajib ditampilkan secara mencolok pada laman beranda situs web dan aplikasi platform NusaModal.

*Catatan Definisi Denominator*:
- Denominator mencakup seluruh pinjaman berstatus aktif pada tanggal evaluasi yang memiliki sisa baki debet pokok (`outstanding_principal > 0`). Pinjaman yang sudah lunas (*CLOSED*) atau sudah dihapusbukukan (*WRITTEN_OFF*) tidak masuk dalam denominator baki debet aktif.

---

### 4. Definisi Days Past Due (DPD) & Klasifikasi Aging Buckets

Hari Keterlambatan (*Days Past Due* / DPD) dihitung per tanggal evaluasi (**27 September 2026**):
$$\text{DPD} = \text{DATE '2026-09-27'} - \text{due\_date}$$
*(Hanya dihitung untuk jadwal angsuran yang belum lunas atau memiliki tunggakan).*

Pada level pinjaman (`loan_id`), nilai DPD pinjaman ditentukan oleh **hari keterlambatan terlama** dari jadwal angsuran yang belum dibayar:
$$\text{Loan DPD} = \max(\text{Installment DPD})$$

#### Klasifikasi Bucket Keterlambatan:
1. **Current (Lancar)**: $\text{DPD} = 0$ (tidak ada angsuran tertunggak).
2. **DPD 1–30 (Perhatian Awal / Late Stage 1)**: $1 \le \text{DPD} \le 30$ hari.
3. **DPD 31–60 (Kurang Lancar / Late Stage 2)**: $31 \le \text{DPD} \le 60$ hari.
4. **DPD 61–90 (Diragukan / Pre-Default)**: $61 \le \text{DPD} \le 90$ hari.
5. **DPD 90+ (Macet / TWP90 / Default)**: $\text{DPD} > 90$ hari.

---

### 5. Matriks Transisi Risiko (Roll-Rate Analysis)

Analisis Roll-Rate mengukur probabilitas pergerakan saldo pinjaman antar-bucket dari bulan sebelumnya ($M-1$: Agustus 2026) ke bulan berjalan ($M$: September 2026).

1. **Roll-Forward Rate (Pemburukan)**:
   Persentase saldo dari sebuah bucket yang bergeser ke bucket yang lebih parah di bulan berikutnya:
   $$\text{Roll-Forward Rate}_{(B_i \rightarrow B_{i+1})} = \frac{\text{Saldo yang berpindah dari Bucket } i \text{ ke Bucket } i+1 \text{ di Bulan } M}{\text{Total Saldo Awal di Bucket } i \text{ pada Bulan } M-1} \times 100\%$$
2. **Cure Rate (Penyembuhan / Pelunasan)**:
   Persentase saldo dari bucket tertunggak yang berhasil disembuhkan kembali ke status Current atau lunas (`CLOSED`):
   $$\text{Cure Rate}_{(B_i \rightarrow \text{Current/Closed})} = \frac{\text{Saldo yang kembali ke Current / Lunas di Bulan } M}{\text{Total Saldo Awal di Bucket } i \text{ pada Bulan } M-1} \times 100\%$$

---

### 6. Analisis Kurva Kohort Vintage (Month-on-Book / MOB)

Analisis Vintage mengelompokkan pinjaman berdasarkan bulan pencairan (*origination cohort*) dan melacak pemburukan kredit seiring bertambahnya usia pinjaman (*Month-on-Book* / MOB).

1. **Indeks Usia Pinjaman (MOB Index)**:
   $$\text{MOB} = (\text{Year}_{\text{obs}} \times 12 + \text{Month}_{\text{obs}}) - (\text{Year}_{\text{disburse}} \times 12 + \text{Month}_{\text{disburse}})$$
   - $\text{MOB 0}$: Bulan pencairan pinjaman (usia 0 bulan).
   - $\text{MOB 1}$: 1 bulan kalender setelah pencairan.
   - $\text{MOB } n$: $n$ bulan kalender setelah pencairan.
2. **Tingkat Gagal Bayar Kumulatif (Cumulative Default Rate / Vintage Curve)**:
   $$\text{Cum NPL Rate}_{\text{Cohort}, \text{MOB } n} = \frac{\sum \text{Pokok Pinjaman Default Kumulatif pada MOB } n}{\text{Original Disbursed Principal pada MOB 0}} \times 100\%$$

*Peringatan Metodologis*:
- **Denominator Wajib Tetap**: Pembagi kumulatif NPL adalah **Original Disbursed Principal di MOB 0** (nilai pokok awal saat dicairkan). Denominator tidak boleh menggunakan sisa saldo baki debet yang menyusut, karena akan memicu distorsi *survivorship bias*.
- **Perlakuan Pinjaman WRITTEN_OFF**: Pinjaman yang telah dihapusbukukan (*WRITTEN_OFF*) **wajib tetap diperhitungkan sebagai gagal bayar kumulatif** sejak bulan terjadinya default. Penghapusbukuan adalah aksi akuntansi neraca, bukan pembatalan fakta gagal bayar historis.

---

### 7. Urutan Prioritas Pembayaran Waterfall (Payment Waterfall Hierarchy)

Ketika debitur menyetorkan dana pembayaran angsuran, sistem akuntansi NusaModal **wajib** mengalokasikan dana tersebut secara berjenjang (*waterfall priority*) dengan urutan kaku:

1. **Prioritas 1: Denda Keterlambatan (*Late Penalty*)** — Menutupi seluruh akumulasi denda yang timbul akibat keterlambatan.
2. **Prioritas 2: Biaya Layanan / Fee Platform (*Platform Service Fee*)** — Menutupi pendapatan fee NusaModal atas fasilitas penagihan dan pemeliharaan teknologi.
3. **Prioritas 3: Bunga Pinjaman (*Loan Interest*)** — Menutupi pendapatan hak bunga pemberi dana (*Lender*).
4. **Prioritas 4: Pokok Pinjaman (*Principal Balance*)** — Menutupi pelunasan baki debet pokok pinjaman.

*Aturan Sisa Setoran*:
- Jika nominal pembayaran kurang dari total tagihan (*partial payment*), sisa pembayaran dialokasikan bertahap sesuai urutan prioritas di atas.
- Jika pembayaran melebihi seluruh tagihan berjalan, kelebihan dana (*overpayment*) ditahan pada saldo deposit escrow debitur untuk dipotongkan pada angsuran berikutnya atau dikembalikan.

---

### 8. Perpajakan Finansial P2P Lending (PMK No. 69/PMK.03/2022)

Sesuai PMK No. 69/PMK.03/2022 Pasal 7 ayat (2), NusaModal ditunjuk sebagai pemotong pajak penghasilan atas imbal hasil (bunga) yang diterima atau diperoleh Pemberi Dana (*Lender*):

1. **Dasar Pengenaan Pajak (DPP) Bunga Bruto**:
   - Pemotongan PPh Pasal 23 dan PPh Pasal 26 dilakukan secara langsung **dari jumlah bruto bunga (*Gross Interest*)** yang dibayarkan oleh penerima pinjaman, tanpa dikurangi biaya operasional maupun bagi hasil platform.
2. **Tarif Pemotongan Pajak Withholding**:
   - **Wajib Pajak Dalam Negeri (WPDN) ber-NPWP**: Dikenakan PPh Pasal 23 sebesar **15%** dari bruto bunga.
   - **WPDN tanpa NPWP**: Dikenakan tarif **30%** (asumsi studi kasus merujuk klausul Pasal 23 ayat (1a) UU PPh perihal sanksi kenaikan tarif 100% bagi wajib pajak yang tidak memiliki/mencantumkan NPWP).
   - **Wajib Pajak Luar Negeri (WPLN / Institutional Foreign)**: Dikenakan PPh Pasal 26 sebesar **20%** dari bruto bunga (kecuali terdapat Tax Treaty / P3B khusus).
3. **Formula Net Cash Yield Lender**:
   $$\text{Gross Interest Earned} = \text{Tagihan Bunga Terbayar (Allocated Interest)}$$
   $$\text{Withholding Tax (PPh 23/26)} = \text{Gross Interest Earned} \times \left(\frac{\text{tax\_rate\_pct}}{100}\right)$$
   $$\text{Platform Margin Cut} = \text{Gross Interest Earned} \times \left(\frac{\text{platform\_margin\_pct}}{100}\right)$$
   $$\text{Net Cash Yield to Lender} = \text{Gross Interest Earned} - \text{Withholding Tax} - \text{Platform Margin Cut}$$
