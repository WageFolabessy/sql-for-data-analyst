# MEMORANDUM OPERASIONAL DIREKSI
**PT NUSANTARA EKSPRES LOGISTIK (NexLog)**  
*Gedung Graha NexLog Lt. 18, Jl. TB Simatupang Kav. 88, Jakarta Selatan*

---

```text
KLASIFIKASI : SANGAT RAHASIA (STRICTLY CONFIDENTIAL)
NOMOR MEMO  : MEMO/OPS-DIR/2026/Q1/089
KEPADA      : Lead Operations & Commercial Analytics Team
DARI        : Chief Operating Officer (COO) & VP of Logistics Network
TANGGAL     : 24 Maret 2026
PERIHAL     : Audit Komprehensif Kinerja Kuartal I 2026: Kepatuhan SLA, Bottleneck Hub, 
              Krisis Retur COD, Kebocoran Ongkir Volumetrik, dan Liabilitas Penalti
```

---

### 1. LATAR BELAKANG & SITUASI KRISIS BISNIS

Rekan-rekan Tim Analis,

Kuartal pertama 2026 menjadi periode paling menantang dalam sejarah operasional NexLog. Meskipun volume pengiriman dari klien platform *e-commerce* (*Shopee, Tokopedia, TikTok Shop, Lazada*) dan *enterprise brand partners* (*Samsung, Unilever, Erigo*) meningkat pesat hingga menembus ribuan paket per hari, laporan keuangan awal menunjukkan **penurunan margin bersih operasional yang sangat mengkhawatirkan**.

Kemitraan strategis kita dengan platform *e-commerce* berada di ujung tanduk:
1. **Ancaman Pemutusan Kontrak & Pinalti:** Beberapa klien *Enterprise* melayangkan surat peringatan keras (*Notice of Breach*) akibat memburuknya ketepatan waktu pengiriman layanan ekspres (*Same Day* dan *Next Day*). Manajemen telah menerima klaim denda penalti keterlambatan yang nilainya diprediksi mencapai ratusan juta rupiah.
2. **Krisis Arus Kas COD & Retur (*Return to Sender / RTS*):** Layanan *Cash on Delivery* (COD) yang diharapkan menjadi penggerak volume justru memicu tingginya paket retur kembali ke gudang penjual. Selain itu, bagian *Treasury* mencurigai adanya ratusan juta rupiah dana tunai tagihan COD yang belum disetorkan kurir ke kasir hub (*floating cash in transit*).
3. **Kemacetan Alur Transit Antarpulau:** Gudang sortir transit utama kita dilaporkan kewalahan menangani lonjakan paket (*backlog*), menyebabkan paket "tertidur" berhari-hari sebelum diberangkatkan oleh armada truk atau pesawat kargo.
4. **Kecurangan Dimensi Paket (*Volumetric Fraud*):** Divisi armada melaporkan kapasitas kubikasi truk tronton antarkota sering kali penuh sesak sebelum mencapai batas tonase berat fisik. Kami mencurigai banyak *merchant* sengaja mendeklarasikan berat fisik ringan untuk barang-barang berukuran besar agar membayar ongkos kirim murah.

Direksi membutuhkan Anda untuk melakukan **audit investigasi menyeluruh berbasis data** menggunakan database operasional `logistics_sla_db`.

---

### 2. ELEVEN STRATEGIC QUESTIONS (11 MASALAH BISNIS YANG WAJIB DIJAWAB)

Kami menginstruksikan tim Anda untuk memecahkan 11 pertanyaan strategis di bawah ini dan menyajikan angka-angka faktual hasil audit:

#### 📦 TEMA 1: SLA COMPLIANCE & ON-TIME DELIVERY (MACRO PERFORMANCE)
* **Kasus 1.1 (Audit Kepatuhan OTD Makro):**  
  Berapa persentase ketepatan waktu pengiriman (*On-Time Delivery Rate / OTD %*) untuk masing-masing tipe layanan (`Same Day`, `Next Day`, `Reguler`, `Kargo`) selama Q1 2026? Layanan mana saja yang jebol dan gagal memenuhi standar kepatuhan industri (95%)?
* **Kasus 1.2 (10 Rute Antarkota Paling Kronis / Chronic Delay Lanes):**  
  Tunjukkan 10 pasangan rute antarkota (*Origin Hub $\rightarrow$ Destination Hub*) dengan persentase kegagalan SLA tertinggi beserta rata-rata durasi keterlambatannya (dalam satuan jam). Rute mana yang menjadi biang kerok keluhan merchant?

#### 🏭 TEMA 2: SORTING HUB BOTTLENECK & TRANSIT DWELL TIME (MID-MILE AUDIT)
* **Kasus 2.1 (Audit Waktu Mengendap di Gudang Transit / Hub Dwell Time):**  
  Dengan melacak riwayat pemindaian barcode paket, berapa rata-rata waktu yang dihabiskan paket saat singgah di masing-masing fasilitas hub (*dwell time* dari status masuk `HUB_IN` hingga status keluar `HUB_OUT`)?
* **Kasus 2.2 (Identifikasi Gudang Transit Paling Macet / Congested Hub):**  
  Fasilitas gudang transit mana yang mengalami penumpukan paket paling parah dengan volume paket menginap lebih dari 24 jam (*backlog critical*) tertinggi?

#### 🛵 TEMA 3: LAST-MILE FLEET & FIRST-ATTEMPT DELIVERY RATE (COURIER KPI)
* **Kasus 3.1 (Efisiensi Pengantaran Pertama / First-Attempt Delivery Rate - FADR):**  
  Berapa rasio keberhasilan pengantaran paket pada percobaan pertama (*1st Attempt*) di masing-masing Hub Pengantaran (*Delivery DC*), dan berapa porsi paket yang harus diantar berulang kali (2 hingga 3 kali) oleh kurir?
* **Kasus 3.2 (Audit Integritas Kurir & Deteksi Fake Delivery Attempt):**  
  Bongkar sebaran alasan gagal kirim (*Non-Delivery Report / NDR*). Temukan personel kurir yang memiliki frekuensi alasan *"Rumah Kosong"* di atas batas kewajaran operasional yang terindikasi melakukan pemalsuan percobaan kirim (*fake attempt* tanpa mendatangi alamat).

#### 💵 TEMA 4: E-COMMERCE CASH FLOW: COD & RETURN TO SENDER (RTS) RISK
* **Kasus 4.1 (Tingkat Kegagalan & Retur Pesanan COD):**  
  Berapa tingkat kegagalan kirim yang berujung retur ke penjual (*Return to Sender / RTS*) pada pesanan dengan metode pembayaran COD dibandingkan pesanan Non-COD? Wilayah tujuan mana yang paling berisiko tinggi untuk pesanan COD?
* **Kasus 4.2 (Audit Uang Tunai COD Mengambang / Floating Cash in Transit):**  
  Berapa total lembar resi dan akumulasi nominal rupiah uang hasil tagihan COD yang status barangnya sudah berhasil diserahkan ke pembeli (`DELIVERED`), namun uangnya belum disetorkan kurir ke kasir hub (*unsettled floating cash*)? Siapa saja kurir pemegang dana terbesar?

#### ⚖️ TEMA 5: REVENUE LEAKAGE, PENALTY EXPOSURE, & EXECUTIVE STRATEGY
* **Kasus 5.1 (Audit Kebocoran Pendapatan Berat Volumetrik / Weight Fraud):**  
  Berapa total selisih kilogram antara berat aktual yang dideklarasikan *merchant* dengan berat volumetrik yang seharusnya ditagihkan, dan berapa estimasi total potensi pendapatan ongkir yang hilang (*Lost Freight Revenue*) akibat kelalaian timbangan di pos asal?
* **Kasus 5.2 (Perhitungan Eksposur Liabilitas Denda Penalti SLA):**  
  Berdasarkan klausul kontrak kerjasama dengan para *Enterprise Merchants*, hitung total kewajiban denda kompensasi penalti keterlambatan yang harus dibayarkan NexLog pada kuartal ini! Klien *merchant* mana yang menuntut ganti rugi terbesar?
* **Kasus 5.3 (Rekomendasi Keputusan Eksekutif / Executive Decision BLUF):**  
  Tuliskan memo balasan ringkas (maksimal 1 halaman) yang berisi rangkuman temuan angka paling kritis dan berikan **3 rekomendasi aksi bisnis konkret** untuk rapat pimpinan direksi hari Senin depan.

---

### 3. PEDOMAN KERJA & BATASAN OPERASIONAL

1. **Rujukan Aturan & Rumus Perusahaan:**  
   Dalam menyusun kueri analitik, Anda dilarang berasumsi sendiri mengenai formula perhitungan. Gunakan dokumen resmi perusahaan yang tersimpan di:  
   👉 **`02_SOP_DAN_KAMUS_METRIK_LOGISTIK.md`**  
   *(Dokumen tersebut memuat formula baku OTD, divisor volumetrik, tabel tier penalti, dan kode operasional).*
2. **Kamus Data & Struktur Skema:**  
   Struktur tabel, relasi, tipe data, dan petunjuk penanganan zona waktu lokal dapat dipelajari pada:  
   👉 **`03_KAMUS_DATA_DAN_SKEMA_LOGISTIK.md`**
3. **Format Pengumpulan:**  
   * Seluruh kueri SQL mandiri Anda dikumpulkan pada berkas **`04_jawaban_studi_kasus_2.sql`**.
   * Laporan kesimpulan dan rekomendasi eksekutif disusun pada template **`05_LAPORAN_EKSEKUTIF_ANALIS.md`**.

Kami menantikan laporan audit faktual Anda. Kredibilitas dan efisiensi operasional NexLog berada di tangan analisis data Anda.

*Selamat bertugas,*

**Hendrawan Hartono, M.Sc.**  
*Chief Operating Officer (COO)*  
PT Nusantara Ekspres Logistik (NexLog)
