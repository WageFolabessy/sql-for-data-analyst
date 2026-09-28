# MEMO INTERNAL DIREKSI: RISK & FINANCE COMMITTEE
**Nomor**: 042/MEMO-CRO/NMP/IX/2026  
**Kepada**: Endricho, Lead Credit Risk & Financial Analytics Specialist  
**Dari**: Bambang Suryodipuro, CFA, FRM — Chief Risk & Operating Officer (CRO)  
**Tembusan**: Dewan Direksi, Head of Compliance, Head of Finance & Treasury  
**Tanggal**: 28 September 2026  
**Perihal**: Mandat Investigasi Kualitas Portofolio Pinjaman, Integritas Rekening Escrow, dan Kepatuhan Regulasi OJK (Cutoff Penutupan Buku EOD 27 September 2026)  

---

### 1. Latar Belakang & Konteks Eksekutif

Rekan Endricho,

Pagi ini saya menerima komunikasi informal dari Pengawas Lembaga Pembiayaan, Modal Ventura, Lembaga Keuangan Mikro, dan Lembaga Jasa Keuangan Lainnya (PVML) OJK terkait pemantauan berkala platform **PT Nusantara Modal Pintar (NusaModal)** menjelang penutupan laporan triwulan III (Q3 2026).

Ada dua isu besar yang berpotensi menjadi temuan audit regulator dan memicu sanksi pengawasan intensif OJK terhadap platform kita:
1. **Lonjakan Rasio TWP90**: Estimasi agregat rasio Tingkat Wanprestasi > 90 hari (TWP90) kita terindikasi merayap naik dan mendekati ambang batas toleransi regulasi **5,00%**. Sesuai **POJK No. 40/2024 dan SEOJK No. 19/SEOJK.06/2023**, apabila TWP90 terbukti melampaui 5,00%, platform ditempatkan dalam status pengawasan intensif OJK, wajib menyerahkan rencana aksi perbaikan (*Supervisory Action Plan*), serta terancam sanksi administratif berupa penerbitan surat pembinaan dari OJK apabila tidak kunjung pulih.
2. **Discrepancy Rekonsiliasi Kas Escrow**: Laporan kilas dari tim Treasury mengindikasikan adanya selisih antara saldo pencatatan di *core ledger* sistem dengan rekening koran penampung (*Escrow/RDL Custodian Bank*). Kita tidak boleh memiliki dana mengendap tanpa pemilik (*unmapped*) maupun kebocoran akibat pencairan ganda.

Komite Risiko dan Direksi menjadwalkan rapat darurat evaluasi portofolio siang ini. Saya menugaskan Anda memimpin audit analitis independen ini secara langsung ke database operasional `fintech_lending_db` per tanggal penutupan buku kemarin (**EOD 27 September 2026**).

---

### 2. Lingkup Mandat Analitis (6 Pilar & 12 Pertanyaan Bisnis)

Saya tidak membutuhkan asumsi atau perkiraan kasar. Saya membutuhkan fakta berbasis kueri data mentah yang dapat dipertanggungjawabkan di hadapan OJK dan Dewan Komisaris.

#### Bagian A: Rekonsiliasi Kas Escrow & Data Hygiene
* **Kasus 1.1 (Deteksi Pencairan Ganda / Double Disbursement)**:
  Terdapat indikasi kegagalan transmisi webhook perbankan saat lonjakan pencairan di awal bulan, yang memicu sistem *auto-retry*. Identifikasi apakah ada pinjaman (`loan_id`) yang mengalami mutasi pencairan debit lebih dari satu kali di rekening koran escrow. Berapa total dana kas escrow yang bocor ke rekening borrower?
* **Kasus 1.2 (Identifikasi Setoran Angsuran Tanpa VA Valid / Unmapped Repayments)**:
  Banyak borrower mengeluh diteror oleh tim *field collection* padahal mereka merasa sudah mentransfer angsuran. Identifikasi setoran angsuran debitur di kas escrow yang tidak berhasil terpetakan (*unmapped*) ke pinjaman dan masih berstatus belum terekonsiliasi (*unreconciled*). Berapa total nominal dana gantung ini, dari bank mana saja alirannya, dan berapa banyak transaksi debitur yang berisiko menjadi korban salah tagih?

#### Bagian B: Kualitas Aset & Kepatuhan Regulasi Batas OJK
* **Kasus 2.1 (Audit Rasio Makro TWP90 & TKB90 vs Ambang 5,00% OJK)**:
  Hitung secara presisi rasio kualitas aset makro portofolio aktif NusaModal per 27 September 2026 sesuai formula resmi SEOJK No. 19/2023:
  $$\text{TWP90} = \frac{\text{Total Baki Debet Pokok Menunggak } > 90 \text{ Hari}}{\text{Total Baki Debet Pokok Seluruh Pinjaman Aktif}} \times 100\%$$
  Berapa angka pasti TWP90 dan TKB90 kita hari ini? Apakah kita sudah melanggar batas legal 5,00%?
* **Kasus 2.2 (Kualitas Portofolio per Segmen: Paylater Konsumtif vs Modal Kerja Produktif)**:
  Bedah baki debet pokok dan rasio macet berdasarkan jenis produk. Apakah pemburukan portofolio ini disumbang oleh ekspansi agresif *Paylater Konsumtif* tanpa agunan, atau ada kegagalan bayar dari *Modal Kerja Produktif* UMKM?

#### Bagian C: Segmentasi Keterlambatan DPD & Matriks Transisi Risiko
* **Kasus 3.1 (Klasifikasi Aging Buckets DPD: Current, 1–30, 31–60, 61–90, 90+)**:
  Petakan seluruh eksposur baki debet pokok pinjaman aktif ke dalam 5 keranjang keterlambatan (*aging buckets*) berdasarkan *Days Past Due* (DPD) per 27 September 2026. Berapa persentase dan nominal modal lender yang berada di ambang bahaya (DPD 61–90) yang berisiko menyeberang menjadi TWP90 bulan depan?
* **Kasus 3.2 (Matriks Transisi Risiko: Roll-Forward Rate vs Cure Rate)**:
  Analisis pergerakan debitur antar-bulan (Agustus 2026 vs September 2026). Berapa persen pinjaman yang memburuk ke bucket lebih dalam (*Roll-Forward Rate*), dan berapa persen yang berhasil disembuhkan/dilunasi oleh tim *Desk Collection* (*Cure Rate*)? Di bucket mana collection kita mengalami kebuntuan total?

#### Bagian D: Analisis Kohort Vintage Risiko Kredit (Vintage Curve / MOB)
* **Kasus 4.1 (Matriks Kinerja Bulanan Pinjaman: Month-on-Book / MOB 1 s/d MOB 6)**:
  Susun matriks kurva vintage kumulatif NPL (persentase pokok macet kumulatif terhadap nilai pencairan awal / *original disbursed principal*) per bulan pencairan (*cohort disbursement month*). Lacak perkembangannya dari MOB 1 hingga MOB 6 untuk memetakan kurva akumulasi risiko kredit.
* **Kasus 4.2 (Deteksi Pemburukan Seleksi / Adverse Selection pada Vintage 2026)**:
  Bandingkan kurva akselerasi gagal bayar pinjaman usia muda antar-vintage (vintage 2025 vs vintage semester I 2026). Apakah data membuktikan terjadinya fenomena *Adverse Selection* (penurunan kualitas underwriting) pada ekspansi penyaluran pinjaman baru tahun 2026? Evaluasi pula bagaimana faktor kedewasaan kohort (*cohort maturity*) mempengaruhi profil risiko tersebut.

#### Bagian E: Akuntansi Pembayaran Waterfall, Plafon 100%, & Pajak Lender
* **Kasus 5.1 (Audit Urutan Pelunasan Waterfall & Kepatuhan Plafon 100%)**:
  Audit apakah alokasi setoran borrower mematuhi hukum urutan prioritas: *Denda Keterlambatan $\rightarrow$ Biaya Layanan/Fee Platform $\rightarrow$ Bunga $\rightarrow$ Pokok Pinjaman*. Selain itu, buktikan apakah ada pinjaman macet di portofolio kita yang total akumulasi bunga + fee + dendanya melebihi **100% dari nilai pokok pinjaman** (pelanggaran plafon batas manfaat ekonomi OJK).
* **Kasus 5.2 (Imbal Hasil Bersih Lender & Pemotongan Pajak PPh 23 / PMK 69/2022)**:
  Hitung distribusi pendapatan bunga bersih kepada *Lender* setelah dipotong bagi hasil platform (*Platform Margin Share*) dan pemotongan kewajiban pajak penghasilan bunga sesuai PMK No. 69/PMK.03/2022 (PPh Pasal 23 sebesar 15% untuk WPDN ber-NPWP, 30% untuk WPDN non-NPWP, serta PPh Pasal 26 sebesar 20% untuk WPLN). Berapa total kewajiban setor pajak withholding yang harus disetorkan Finance ke kas negara bulan ini?

#### Bagian F: Laporan Eksekutif & Rencana Aksi Penyelamatan
* **Kasus 6.1 (Executive Summary BLUF untuk Komite Risiko & OJK)**:
  Susun ringkasan eksekutif satu halaman (*Bottom Line Up Front*) yang menyajikan angka-angka tervalidasi dari seluruh kueri Anda, identifikasi akar masalah (underwriting, fraud, atau collection), serta proposal kebijakan mitigasi terukur (pengetatan *credit score cutoff*, moratorium penyaluran segmen berisiko tinggi, dan pembekuan penagihan salah sasaran).

---

### 3. Standar Akurasi, Tata Kelola, & Kerahasiaan

1. **Integritas Rekonsiliasi & Jejak Audit (*Audit Trail*)**:
   Mengingat angka-angka dalam laporan ini akan dipaparkan di hadapan Komite Manajemen, Dewan Komisaris, dan berpotensi diaudit oleh Pengawas OJK maupun KAP eksternal, saya menuntut **toleransi selisih nol (*zero-tolerance reconciliation*)**. Setiap angka agregat atau rasio yang Anda sajikan wajib memiliki pembuktian yang dapat ditelusuri (*reconcilable*) hingga ke tingkat data transaksi mentah (*raw transactional ledger*).
2. **Kemandirian Analisis (*Decision-Oriented Delivery*)**:
   Sebagai *Lead Specialist*, susun output temuan secara terstruktur dan fokus pada besaran eksposur finansial serta implikasi risiko strategis. Sajikan metrik komparatif yang tajam agar Komite Risiko dapat langsung mengeksekusi keputusan mitigasi tanpa perlu meminta interpretasi tambahan.
3. **Kerahasiaan & Batas Waktu Penyelesaian (*Strictly Confidential*)**:
   Informasi dalam audit ini berkategori rahasia dan berdampak langsung pada status izin operasional perusahaan. Seluruh analisis dan dokumen laporan wajib diselesaikan sebelum **Rapat Darurat Komite Risiko pukul 15.00 WIB hari ini**.

Selamat bertugas. Keberlangsungan izin operasional NusaModal bergantung pada ketajaman dan integritas analisis Anda.

**Bambang Suryodipuro, CFA, FRM**  
*Chief Risk & Operating Officer — PT Nusantara Modal Pintar*
