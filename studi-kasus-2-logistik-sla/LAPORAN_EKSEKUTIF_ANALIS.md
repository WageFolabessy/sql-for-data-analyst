# LAPORAN EKSEKUTIF ANALIS OPERASIONAL & KOMERSIAL
**PT NUSANTARA EKSPRES LOGISTIK (NexLog)**  
*Divisi Corporate Strategy, Network Operations & Commercial Finance*

---

```text
KLASIFIKASI : LAPORAN DIREKSI (EXECUTIVE BRIEFING DELIVERABLE)
NOMOR DOKUMEN: REP/OPS-FIN/2026/Q1/042
TANGGAL      : 26 Maret 2026

KEPADA       : Hendrawan Hartono, M.Sc. (Chief Operating Officer)
TEMBUSAN     : 1. Direktur Utama (CEO)
               2. Vice President of Logistics Network
               3. Head of Commercial Partnerships & Revenue Assurance
DARI         : Endricho (Lead Operations & Commercial Analytics Specialist)
PERIHAL      : Temuan Audit Investigasi Q1 2026 & Rekomendasi Strategis Perbaikan Jaringan NexLog
```

---

## 1. RINGKASAN EKSEKUTIF (BOTTOM LINE UP FRONT - BLUF)

> Audit komprehensif terhadap 5.200 transaksi pengiriman dan 39.395 peristiwa pemindaian barcode pada Q1 2026 mengungkap adanya **krisis operasional sistemik** yang merusak kepatuhan janji layanan (SLA) dan menggerus arus kas perusahaan. Sebanyak **100% lini produk layanan NexLog jebol dari standar industri (95,00%)**, dengan layanan ekspres premium *Same Day* anjlok ke **71,54%** dan *Next Day* ke **74,24%**. Titik kelumpuhan utama berpusat pada dua gerbang transit (*Sortation Gateway Cakung* dan *Gateway Transit Rungkut*) yang mengalami kemacetan kritis (*P95 Dwell Time > 24 jam*). Dari sisi finansial dan integritas, ditemukan **uang tunai COD mengambang sebesar Rp 469.610.900,00** di tangan kurir yang belum disetor ke kasir, **kebocoran pendapatan akibat penipuan berat volumetrik sebesar Rp 80.640.000,00**, serta **liabilitas denda penalti kontrak SLA sebesar Rp 64.193.100,00** yang harus dibayarkan ke mitra pedagang. Total eksposur risiko finansial mencapai **Rp 614.444.000,00**.

* **Krisis Kepatuhan SLA:** Seluruh 4 jenis layanan gagal memenuhi standar kepatuhan minimum ASPERINDO (95,00%). Produk unggulan komersial berbiaya tinggi (*Next Day*) menjadi penyumbang kegagalan terbesar secara volume dengan **525 paket breach** dari 2.038 pengiriman.
* **Titik Kemacetan (Bottleneck Hub):** Sortation Gateway Cakung (P95 Dwell Time 25,89 jam) dan Gateway Transit Rungkut (P95 Dwell Time 23,92 jam) mengalami *Critical Backlog* dengan total 97 paket tertahan di atas 24 jam di dalam gudang, memicu efek domino keterlambatan hingga 26,96 jam pada rute-rute antarpulau Indonesia Timur.
* **Integritas Armada & Risiko COD:** Ditemukan 2 kurir nakal yang terbukti melakukan kecurangan *Fake Attempt* dengan klaim alasan 'Rumah Kosong' di atas 74% (Satria Wibowo di Ambon sebesar 77,08% dan Satria Santoso di Surabaya sebesar 74,19%). Selain itu, 339 paket COD terkirim belum disetorkan uangnya oleh kurir ke kasir hub, menahan dana tunai perusahaan sebesar **Rp 469,61 Juta** (dengan konsentrasi Rp 52 Juta tertahan di hub Pattimura, Ambon).
* **Dampak Finansial (Kebocoran Margin & Penalti):** Terdeteksi kebocoran ongkir sebesar **Rp 80,64 Juta** akibat manipulasi berat volumetrik oleh 20 merchant (dipimpin toko grosir bantal dan boneka sebesar Rp 63,08 Juta), serta kewajiban pembayaran klaim denda penalti keterlambatan sebesar **Rp 64,19 Juta** (di mana 61,7% harus dibayarkan ke merchant tier ENTERPRISE).

---

## 2. MATRIKS RINGKASAN TEMUAN HASIL AUDIT

| Area Telaah Bisnis | Metrik Utama yang Diaudit | Nilai Faktual (Hasil SQL) | Target / Standar SOP | Status & Dampak Bisnis |
| :--- | :--- | :---: | :---: | :--- |
| **Data Hygiene & Manifes** | Jitter Duplicate Scans Dibersihkan | **350 record** | 0 duplikat | Berhasil dieliminasi melalui deduplikasi interval <= 10 detik |
| | Resi Tanpa Manifes Terdeteksi | **15 nomor resi (38 scan)** | 0 paket unmanifested | Diisolasi dari metrik SLA dan diserahkan ke Loss Prevention |
| **Macro SLA Performance** | OTD Same Day Rate (%) | **71,54%** | >= 95,00% | **JEBOL** (35 paket breach dari 123 paket) |
| | OTD Next Day Rate (%) | **74,24%** | >= 95,00% | **JEBOL** (525 paket breach dari 2.038 paket - Volume Terbesar) |
| | OTD Reguler Rate (%) | **87,36%** | >= 95,00% | **JEBOL** (307 paket breach dari 2.428 paket) |
| | OTD Kargo Rate (%) | **93,29%** | >= 95,00% | **JEBOL** (41 paket breach dari 611 paket) |
| **Mid-Mile Hub Dwell Time**| Fasilitas Transit Paling Macet | **Cakung & Rungkut** | < 8,0 jam dwell | **CRITICAL BACKLOG** (Cakung P95: 25,89 jam; Rungkut P95: 23,92 jam) |
| **Last-Mile & Kurir KPI**  | Rata-rata Nasional FADR (%) | **78,87%** | >= 85,00% | **DI BAWAH TARGET** (Pattimura terendah: 71,69%) |
| | Kurir Terindikasi Fake Attempt | **KUR-015 & KUR-032** | < 45,00% Rumah Kosong | **INDIKASI FRAUD TERBUKTI** (KUR-015: 77,08%; KUR-032: 74,19%) |
| **Tata Kelola Arus Kas COD**| Rasio Retur (RTS) COD vs Non-COD | **COD: 14,41% \| Non: 2,68%** | < 8,00% | **DISPARITAS TINGGI (5,4x lipat)**; 336 paket COD retur |
| | Total Floating Cash COD | **Rp 469.610.900,00** | Rp 0 (Disetor H+0) | **RISIKO LIKUIDITAS TINGGI** (339 resi tertahan di kantong kurir) |
| **Revenue Assurance & Penalti**| Kebocoran Volumetrik (Lost Freight)| **Rp 80.640.000,00** | Rp 0 | **KEBOCORAN PENDAPATAN** (8.064 kg selisih bobot tidak tertagih) |
| | Liabilitas Denda Penalti SLA | **Rp 64.193.100,00** | Minimal | **BEBAN UTANG KLAIM** (469 paket; Enterprise menyerap Rp 39,61 Juta) |

---

## 3. ANALISIS MENDALAM PER AREA OPERASIONAL & KOMERSIAL

### 3.1. Integritas Pipeline Data & Resolusi Anomali (Bagian A)
* **Temuan Angka:** Sebanyak **350 peristiwa pemindaian** diidentifikasi sebagai *sensor jitter* (duplikasi pemindaian barcode beruntun dengan selisih waktu <= 10 detik) dan berhasil dibersihkan. Melalui pengujian *Anti-Join*, terdeteksi **15 nomor resi hantu (*unmanifested ghost parcels*)** dengan total **38 kali pemindaian barcode** yang tersebar di 5 hub transit (Gedebage 12 scan, Cakung 9 scan, Maros 11 scan, Tanjung Morawa 5 scan, dan Rungkut 3 scan).
* **Dampak Analitik:** Tanpa deduplikasi jitter, perhitungan durasi *dwell time* dan selisih waktu operasional akan menghasilkan galat matematis ganda. Sementara itu, 15 resi tanpa manifes membuktikan adanya kebocoran fisik di mana paket tertukar atau salah sortir (*cross-dock misroute*) dari ekspedisi lain masuk ke jaringan armada NexLog tanpa kontrak tagihan resmi.

### 3.2. Kinerja Kepatuhan SLA & Jalur Distribusi Kritis (Bagian B)
* **Temuan Angka:** Dari total 5.200 pengiriman pada Q1 2026, sebanyak **908 paket (17,46%) mengalami kegagalan SLA**. Analisis rute antarkota mengungkap 3 koridor pengiriman dengan tingkat kegagalan ekstrem:
  1. *Medan -> Makassar* (Tanjung Morawa -> Maros): **80,95% gagal SLA**, rata-rata keterlambatan **22,14 jam**.
  2. *Jakarta -> Jayapura* (Cakung -> Sentani): **79,07% gagal SLA**, rata-rata keterlambatan **23,50 jam**.
  3. *Surabaya -> Manado* (Rungkut -> Mapanget): **69,39% gagal SLA**, rata-rata keterlambatan **26,96 jam** (> 1 hari kalender).
* **Akar Masalah (Root Cause):** Seluruh rute dengan kegagalan di atas 60% merupakan jalur pengiriman jarak jauh antarpulau (*long-haul air & sea freight*) menuju wilayah Indonesia Timur. Masalah utama dipicu oleh ketergantungan jadwal keberangkatan kargo udara komersial dan proses *ground handling* di hub penghubung.

### 3.3. Bottleneck Gudang Sortir & Waktu Mengendap (Bagian C)
* **Temuan Angka:** Dari 12 fasilitas hub, **Sortation Gateway Cakung (HUB-CGK-01)** mencatatkan *P95 Dwell Time* terpanjang sebesar **25,89 jam** (dengan 53 paket tertahan > 24 jam / 6,02%), disusul oleh **Gateway Transit Rungkut (HUB-SUB-01)** dengan *P95 Dwell Time* sebesar **23,92 jam** (44 paket tertahan > 24 jam / 5,09%). Sebanyak 10 hub lainnya beroperasi sehat dengan rata-rata singgah 4,8 - 5,4 jam dan P95 < 13 jam.
* **Dampak Operasional:** Cakung dan Rungkut adalah gerbang utama arus barang nasional. Ketika paket mengendap lebih dari 24 jam di meja sortir Cakung, janji layanan produk *Next Day* (SLA 24 jam) otomatis hancur sebelum paket sempat dimuat ke dalam armada *line-haul*.

### 3.4. Efisiensi Pengantaran Pertama & Integritas Kurir (Bagian D)
* **Temuan Angka:** Rata-rata nasional keberhasilan antar pertama (*FADR*) berada di angka **78,87%** (target >= 85,00%), dengan titik terendah berada di **Delivery DC Pattimura, Ambon (71,69%)**. Investigasi anomali menemukan 2 kurir dengan rasio alasan *'Rumah Kosong'* yang melampaui batas kewajaran nasional (35% - 45%):
  1. **KUR-015 (Satria Wibowo)** di Delivery DC Pattimura: 96 kali gagal antar, di mana **74 paket (77,08%)** diklaim sebagai 'Rumah Kosong'.
  2. **KUR-032 (Satria Santoso)** di Gateway Transit Rungkut: 62 kali gagal antar, di mana **46 paket (74,19%)** diklaim sebagai 'Rumah Kosong'.
* **Indikasi Pelanggaran SOP:** Kedua kurir tersebut terbukti melakukan *Fake Delivery Attempt*, yaitu menandai paket gagal di aplikasi kurir tanpa mendatangi alamat penerima guna menghindari batas waktu kerja harian. Tindakan ini secara langsung menghancurkan FADR di Ambon dan memicu ketidakpuasan konsumen.

### 3.5. Arus Kas COD & Risiko Retur ke Penjual (Bagian E)
* **Temuan Angka:** Tingkat retur pesanan **COD mencapai 14,41% (336 paket RTS)**, berbanding jauh dengan pesanan Non-COD yang hanya **2,68% (77 paket RTS)**. Retur COD tertinggi terkonsentrasi di kawasan perkotaan: Jakarta Timur (18,32%), Bandung (17,78%), dan Ambon (17,50%). Pada saat yang sama, terdapat **339 resi COD bernilai Rp 469.610.900,00** yang status barangnya sudah *DELIVERED*, namun uang pembayarannya belum disetorkan kurir ke kasir hub (*Floating Cash*).
* **Risiko Likuiditas:** Uang mengambang terbesar dikuasai oleh dua kurir di **Delivery DC Pattimura (Ambon)**, yaitu **Eko Hidayat (KUR-002) sebesar Rp 27.959.100,00** dan **Satria Wibowo (KUR-015) sebesar Rp 24.062.900,00**. Total dana kas perusahaan yang tertahan di saku kurir Ambon mencapai **Rp 52.022.000,00**. Hal ini menandakan adanya kelalaian supervisi kasir dan risiko tinggi penggelapan uang perusahaan (*embezzlement*).

### 3.6. Kebocoran Pendapatan Volumetrik & Estimasi Denda Kontrak (Bagian F)
* **Temuan Angka:** 
  1. *Manipulasi Dimensi:* Seluruh 20 merchant terbukti mendeklarasikan berat fisik lebih rendah dari berat volumetrik kemasan, dengan akumulasi selisih bobot mencapai **8.064 kg**. Praktik ini didominasi oleh **Grosir Bantal Silikon Bandung (MCH-012)** dengan kebocoran **3.411 kg (Rp 34,11 Juta)** dan **Toko Boneka Fluffy Jumbo (MCH-011)** dengan kebocoran **2.897 kg (Rp 28,97 Juta)**. Total kehilangan potensi pendapatan ongkir (*Lost Revenue*) mencapai **Rp 80.640.000,00**.
  2. *Liabilitas Penalti SLA:* Sebanyak 469 paket terlambat menimbulkan estimasi liabilitas denda kompensasi kontrak sebesar **Rp 64.193.100,00**. Merchant tier **ENTERPRISE menyerap Rp 39.607.800,00 (61,7%)** karena klausul kontrak garansi *100% Full Refund* tanpa toleransi keterlambatan.
* **Dampak Margin Perusahaan:** Gabungan antara kebocoran ongkir volumetrik dan beban denda keterlambatan menimbulkan erosi laba kotor sebesar **Rp 144.833.100,00** pada Q1 2026.

---

## 4. TIGA REKOMENDASI STRATEGIS BERBASIS DATA (ACTION PLAN)

Berdasarkan bukti-bukti faktual di atas, kami merekomendasikan 3 langkah intervensi terstruktur bagi jajaran Direksi:

### Rekomendasi 1 (Immediate / Tindakan Darurat - Minggu Ini):
* **Fokus:** Penertiban Kas COD Mengambang, Audit Kasir Hub, dan Penindakan Disiplin Kurir Fraud.
* **Tindakan Konkret:**
  1. **Pembekuan dan Penarikan Kas Ambon:** Bekukan sementara penugasan kurir KUR-015 (Satria Wibowo) dan KUR-002 (Eko Hidayat) di Delivery DC Pattimura. Perintahkan tim *Internal Audit & Loss Prevention* untuk menarik fisik dana tunai COD mengambang sebesar Rp 52.022.000,00 dalam waktu 1x24 jam.
  2. **Audit Investigasi Kurir Fraud:** Berikan Surat Peringatan Keras (SP-3) / Pemutusan Kemitraan terhadap kurir KUR-015 dan KUR-032 atas pembuktian manipulasi data pengantaran (*Fake Attempt* > 74%).
  3. **Penetapan Cut-Off Setoran H+0:** Wajibkan seluruh kasir hub menutup rekonsiliasi kas harian (*Daily Cash Reconciliation*) maksimal pukul 20:00 waktu lokal. Sistem kurir otomatis terblokir untuk mengambil paket esok hari jika uang tagihan COD hari sebelumnya belum tervalidasi masuk rekening kasir (*Settlement Lock*).

### Rekomendasi 2 (Mid-Term / Perbaikan Proses - Bulan Depan):
* **Fokus:** Otomasi Pengukuran Dimensi (*DWS System*) dan Penguraian *Backlog* Gudang Sortir.
* **Tindakan Konkret:**
  1. **Pengadaan Mesin DWS (Dimensioning, Weighing, Scanning):** Pasang mesin pemindai dimensi volumetrik otomatis di pintu masuk barang (*induction area*) Fulfillment Hub Gedebage dan Cakung. Tagihan ongkir otomatis disesuaikan secara *real-time* berbasis bobot volumetrik sebelum paket dimuat ke armada, menghentikan kebocoran Rp 63 Juta dari pedagang produk bantal dan boneka.
  2. **Restrukturisasi Shift Kerja di Cakung dan Rungkut:** Tambah kapasitas tenaga kerja sortir pada Shift Malam (pukul 22:00 - 06:00) di Gateway Cakung dan Rungkut guna memecah penumpukan paket transit. Tetapkan KPI maksimal *Dwell Time* hub transit sebesar 8 jam untuk mencegah paket terperangkap > 24 jam.

### Rekomendasi 3 (Long-Term / Penataan Komersial & Jaringan - Kuartal II):
* **Fokus:** Restrukturisasi Perjanjian Kerja Sama (PKS) SLA Enterprise dan Evaluasi Vendor *Line-Haul* Antarpulau.
* **Tindakan Konkret:**
  1. **Revisi Klausul SLA Rute Indonesia Timur:** Rute-rute antarpulau yang kronis (*Medan-Makassar, Jakarta-Jayapura, Surabaya-Manado*) harus disesuaikan komitmen janji layanannya pada kontrak komersial klien Enterprise (dari semula *Next Day* menjadi minimal *Layanan 2-3 Hari*), mengingat keterbatasan frekuensi penerbangan kargo terjadwal.
  2. **Pemberlakuan Denda Balasan Manipulasi Dimensi (*Back-charging & Penalty Surcharge*):** Sisipkan klausul denda penalti sebesar 200% dari kekurangan ongkir bagi merchant reguler maupun enterprise yang terbukti memanipulasi dimensi barang lebih dari 3 kali dalam satu bulan. Kebijakan ini akan menutup risiko klaim penalti SLA Rp 64 Juta melalui pendapatan tambahan denda manipulasi volume.

---

*Disusun secara independen oleh:*  
**Endricho**  
Lead Operations & Commercial Analytics Specialist  
*Divisi Data & Analytics - PT Nusantara Ekspres Logistik (NexLog)*
