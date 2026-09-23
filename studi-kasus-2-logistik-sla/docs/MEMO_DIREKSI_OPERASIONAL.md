# MEMORANDUM OPERASIONAL DIREKSI
**PT NUSANTARA EKSPRES LOGISTIK (NexLog)**  
*Gedung Graha NexLog Lantai 18, Jl. TB Simatupang Kav. 88, Jakarta Selatan 12520*

---

```text
KLASIFIKASI : SANGAT RAHASIA (STRICTLY CONFIDENTIAL)
NOMOR DOKUMEN: MEMO/OPS-DIR/2026/Q1/089
TANGGAL     : 24 Maret 2026

KEPADA      : Endricho (Lead Operations & Commercial Analytics Specialist)
DARI        : Hendrawan Hartono, M.Sc. (Chief Operating Officer)
TEMBUSAN    : 1. Direktur Utama (Chief Executive Officer)
              2. Vice President of Logistics Network
              3. Head of Commercial Finance & Revenue Assurance
PERIHAL     : Instruksi Audit Komprehensif Kinerja Kuartal I 2026: 
              Kepatuhan SLA, Kemacetan Hub, Risiko COD, Kebocoran Volumetrik, dan Denda Penalti
```

---

### 1. LATAR BELAKANG & SITUASI KRISIS BISNIS

Saudara Endricho,

Kuartal pertama 2026 mencatatkan ekspansi volume pengiriman yang sangat pesat bagi NexLog. Kemitraan strategis kita dengan platform niaga-el (*Shopee, Tokopedia, TikTok Shop, Lazada*) serta klien korporat (*Samsung, Unilever, Erigo*) telah mendorong kenaikan volume hingga menembus ribuan paket per hari. Namun, penutupan buku operasional awal menunjukkan **penurunan marjin laba bersih operasional yang signifikan dan berada di luar batas toleransi anggaran**.

Secara spesifik, direksi menerima laporan eskalasi kritis dari berbagai lini bisnis:
1. **Risiko Pemutusan Kontrak Korporat:** Beberapa mitra klien kategori *Enterprise* melayangkan Surat Peringatan Keras (*Notice of Breach*) atas kegagalan kepatuhan waktu pengiriman layanan ekspres (*Same Day* dan *Next Day*). Manajemen memperkirakan adanya liabilitas klaim denda penalti keterlambatan dalam jumlah besar.
2. **Krisis Likuiditas Arus Kas COD & Tingginya Retur:** Layanan *Cash on Delivery* (COD) mengalami kegagalan kirim berulang yang berujung pada tingginya rasio pemulangan barang ke penjual (*Return to Sender / RTS*). Lebih lanjut, bagian Keuangan mencurigai adanya ratusan juta rupiah dana tunai penagihan COD yang tertahan di tangan kurir dan belum disetorkan ke kasir hub operasional (*floating cash in transit*).
3. **Kemacetan Alur Sortir Mid-Mile:** Fasilitas hub transit utama antarpulau dilaporkan mengalami penumpukan barang (*critical backlog*), menyebabkan ribuan paket tertahan melebihi batas waktu toleransi standar sebelum dapat dimuat ke armada *line-haul*.
4. **Kebocoran Pendapatan Volumetrik (*Revenue Leakage*):** Divisi armada melaporkan kapasitas kubikasi truk tronton telah penuh sebelum batas tonase tercapai. Terdapat indikasi kuat bahwa sejumlah pedagang (*merchant*) sengaja memanipulasi deklarasi dimensi fisik paket guna menghindari tarif kargo yang seharusnya.

Untuk merespons krisis ini secara terukur dan objektif, Anda ditugaskan memimpin **audit investigasi menyeluruh berbasis data** menggunakan basis data operasional `logistics_sla_db`.

---

### 2. RUANG LINGKUP INVESTIGASI & INSTRUKSI KERJA DIREKSI

Direksi menginstruksikan Anda untuk menjawab 13 pertanyaan bisnis faktual di bawah ini yang terbagi ke dalam 6 area telaah operasional:

#### BAGIAN A: INTEGRITAS DATA PEMINDAIAN & REKONSILIASI MANIFES (DATA HYGIENE)
* **Kasus 0.1 (Audit & Pembersihan Jitter Duplicate Scans):**  
  Perangkat pemindai barcode kurir di lapangan dan sensor otomatis di gudang sering mengalami pengulangan pengiriman data jaringan (*network retry*) atau pemindaian ganda dalam rentang waktu sangat singkat ($\le 10\text{ detik}$). Identifikasi total pemindaian duplikat ini per jenis peristiwa pemindaian, dan bangun logika deduplikasi agar tidak mendistorsi perhitungan durasi singgah gudang (*Dwell Time*)!
* **Kasus 0.2 (Deteksi Paket Tanpa Manifes / Unmanifested Ghost Parcels):**  
  Identifikasi seluruh nomor resi yang tercatat melakukan aktivitas pemindaian di fasilitas hub transit namun **tidak terdaftar** dalam sistem manifes order resmi (`fact_pengiriman`). Tentukan fasilitas hub mana saja yang menampung paket-paket tanpa surat jalan ini agar tim *Loss Prevention* dapat segera melakukan pengamanan fisik!

#### BAGIAN B: KEPATUHAN SERVICE LEVEL AGREEMENT & RUTE KRITIS (MACRO PERFORMANCE)
* **Kasus 1.1 (Audit Kepatuhan On-Time Delivery Makro):**  
  Hitung persentase ketepatan waktu pengiriman (*On-Time Delivery Rate / OTD %*) untuk setiap jenis layanan (`Same Day`, `Next Day`, `Reguler`, `Kargo`) selama Q1 2026. Identifikasi layanan mana saja yang gagal memenuhi standar kepatuhan minimum industri (95,0%)!
* **Kasus 1.2 (Pemetaan 10 Jalur Pengiriman Paling Kronis / Chronic Delay Lanes):**  
  Tentukan 10 pasangan rute antarkota (*Origin Hub $\rightarrow$ Destination Hub*) dengan tingkat kegagalan SLA tertinggi (filter volume $\ge 30$ pengiriman) beserta rata-rata jam keterlambatannya. Jalur mana yang menjadi kontributor utama keluhan pelanggan?

#### BAGIAN C: EFISIENSI GUDANG SORTIR & WAKTU SINGGAH (MID-MILE DWELL TIME)
* **Kasus 2.1 (Audit Waktu Mengendap di Gudang Transit / Hub Dwell Time):**  
  Dengan memanfaatkan data pemindaian barcode yang telah dibersihkan dari duplikasi, hitung rata-rata waktu singgah (*average dwell time*) paket pada masing-masing fasilitas hub (dari status `HUB_IN` hingga `HUB_OUT`) beserta persentil ke-95 (*P95 Dwell Time*)!
* **Kasus 2.2 (Identifikasi Fasilitas Gudang Paling Macet / Congested Hub):**  
  Fasilitas hub mana yang mencatatkan volume dan persentase paket tertahan di atas 24 jam (*critical backlog*) tertinggi, yang mengindikasikan kegagalan kapasitas penyortiran atau keterbatasan jadwal keberangkatan armada *line-haul*?

#### BAGIAN D: PRODUKTIVITAS & AUDIT KEPATUHAN KURIR PENGANTARAN (LAST-MILE)
* **Kasus 3.1 (Efisiensi Pengantaran Pertama / First-Attempt Delivery Rate - FADR):**  
  Berapa rasio keberhasilan pengantaran paket pada percobaan pertama (*Attempt 1*) di masing-masing Hub Pengantaran (*Delivery DC*), dan berapa proporsi paket yang memerlukan percobaan kirim ulang (2 hingga 3 kali)?
* **Kasus 3.2 (Investigasi Integritas Kurir & Deteksi Fake Delivery Attempt):**  
  Audit sebaran alasan kegagalan pengantaran (*Non-Delivery Report / NDR*). Temukan personel kurir dengan volume kegagalan minimal 15 paket yang mencatatkan proporsi alasan *"Rumah Kosong"* melampaui batas kewajaran operasional ($> 65\%$), yang terindikasi melakukan pemalsuan status pengantaran tanpa mendatangi alamat penerima!

#### BAGIAN E: PENGENDALIAN RISIKO PEMBAYARAN TUNAI (COD & SETTLEMENT)
* **Kasus 4.1 (Evaluasi Risiko Retur Pesanan COD / Return to Sender Rate):**  
  Bandingkan persentase kegagalan kirim yang berujung retur ke penjual (`RETURN_TO_SENDER`) antara pesanan metode pembayaran COD dengan Non-COD. Wilayah tujuan mana yang memiliki tingkat risiko penolakan COD paling kritis?
* **Kasus 4.2 (Rekonsiliasi Dana Tunai Mengambang / Floating Cash in Transit):**  
  Hitung total lembar resi dan akumulasi nilai rupiah uang hasil tagihan COD yang status fisiknya telah berhasil diterima konsumen (`DELIVERED`), namun belum disetorkan kurir ke kasir hub operasional (`waktu_setor_kasir IS NULL`). Laporkan daftar 5 kurir dengan nominal dana mengambang terbesar!

#### BAGIAN F: AUDIT KEBOCORAN FINANSIAL & LIABILITAS KOMERSIAL (REVENUE ASSURANCE)
* **Kasus 5.1 (Audit Manipulasi Berat Volumetrik / Weight Fraud):**  
  Hitung total selisih kilogram antara berat aktual yang dideklarasikan pedagang dengan berat volumetrik yang seharusnya ditagihkan (sesuai standar divisor 6.000 untuk ekspres dan 5.000 untuk kargo). Berapa estimasi potensi pendapatan ongkos kirim yang hilang (*Lost Freight Revenue*)? Pedagang (*merchant*) mana yang melakukan pelanggaran terberat?
* **Kasus 5.2 (Perhitungan Eksposur Liabilitas Denda Penalti Kontrak SLA):**  
  Berdasarkan klausul kontrak komersial penalti keterlambatan, hitung total kewajiban denda kompensasi yang wajib dibayarkan NexLog kepada para mitra *Enterprise* pada Q1 2026, serta uraikan sebarannya per tingkatan (*tier*) merchant!
* **Kasus 5.3 (Penyusunan Rekomendasi Keputusan Eksekutif / Executive Decision Briefing):**  
  Tuangkan sintesis analitik Anda ke dalam dokumen ringkas eksekutif berformat BLUF (*Bottom Line Up Front*) dengan menyertakan **3 rekomendasi aksi bisnis strategis** untuk dipresentasikan dalam Rapat Pimpinan Direksi.

---

### 3. STANDAR TATA KELOLA & PENGIRIMAN LAPORAN

1. **Rujukan Prosedur & Formula:**  
   Seluruh kueri analitik wajib mematuhi definisi matematis, toleransi ambang batas, dan acuan tarif resmi yang tertuang dalam dokumen pedoman operasional:  
   *Berkas:* `docs/SOP_METRIK_DAN_FORMULA_LOGISTIK.md`
2. **Kamus Arsitektur Data:**  
   Relasi entitas, kamus kolom, serta tata cara penanganan zona waktu (`TIMESTAMPTZ` WIB, WITA, WIT) dapat dipelajari pada dokumentasi tata kelola data:  
   *Berkas:* `docs/DATA_DICTIONARY_LOGISTICS.md`
3. **Format Pengumpulan:**  
   * Seluruh kueri SQL mandiri disusun rapi pada berkas kerja: `workspace_analisis_sla.sql`.
   * Laporan eksekutif beserta rekomendasi strategis dikumpulkan pada berkas deliverable: `LAPORAN_EKSEKUTIF_ANALIS.md`.

Integritas data dan ketajaman analisis Anda akan menjadi dasar bagi Direksi dalam mengambil tindakan disipliner operasional, penataan ulang kontrak komersial, dan penyelamatan arus kas perusahaan.

Selamat menjalankan tugas penugasan ini.

---

**Hendrawan Hartono, M.Sc.**  
Chief Operating Officer (COO)  
*PT Nusantara Ekspres Logistik (NexLog)*
