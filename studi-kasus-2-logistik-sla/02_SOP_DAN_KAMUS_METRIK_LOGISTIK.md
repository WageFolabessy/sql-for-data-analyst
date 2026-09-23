# STANDAR OPERASIONAL PROSEDUR (SOP) & KAMUS METRIK LOGISTIK
**PT Nusantara Ekspres Logistik (NexLog)**  
*Dokumen Resmi: Single Source of Truth (SSOT) - Divisi Operations & Commercial Finance*  
*Versi Dokumen: 2026.1 | Berlaku Efektif: 1 Januari 2026*

---

## 1. PENDAHULUAN & PRINSIP TATA KELOLA DATA

Dokumen ini merupakan panduan baku (*authoritative standard*) bagi seluruh divisi di NexLog—termasuk *Operations*, *Commercial*, *Finance*, dan *Data Analytics*. 

> [!IMPORTANT]
> **Aturan Integritas Metrik:**
> Seluruh kueri analitik dan pelaporan manajerial **WAJIB** merujuk pada formula, konstanta, ambang batas (*threshold*), dan definisi operasional yang tercantum di dalam dokumen ini guna mencegah ketidaksinkronan angka (*metric discrepancy*).

---

## 2. METRIK KINERJA OPERASIONAL & FORMULA BAKU

### 2.1. On-Time Delivery (OTD) Rate
* **Definisi:** Persentase paket yang berhasil diserahkan kepada penerima tepat waktu sesuai janji waktu layanan (*Service Level Agreement*).
* **Standar Industri (Benchmark 2026):** $\ge \mathbf{95,0\%}$.
* **Ketentuan Pengukuran:**
  1. Paket dianggap **Tepat Waktu (*On-Time*)** apabila:
     $$\text{actual\_delivered\_timestamp} \le \text{promised\_sla\_timestamp}$$
  2. Paket yang status akhirnya bukan `DELIVERED` (seperti `LOST_IN_TRANSIT`, `DAMAGED`, atau `RETURN_TO_SENDER`) diperlakukan sebagai **Gagal SLA (*Breach*)**.
* **Formula Perhitungan:**
  $$\text{OTD Rate (\%)} = \frac{\text{Jumlah Paket Terkirim Tepat Waktu}}{\text{Total Seluruh Paket yang Wajib Terkirim}} \times 100\%$$

### 2.2. Hub Dwell Time (Waktu Mengendap di Gudang Transit)
* **Definisi:** Durasi waktu yang dihabiskan oleh sebuah paket di dalam satu fasilitas hub tertentu sejak dipindai masuk (*sorting induction*) hingga dipindai keluar (*manifest dispatch*).
* **Formula Perhitungan:**
  $$\text{Dwell Time (Jam)} = \frac{\text{event\_timestamp(HUB\_OUT)} - \text{event\_timestamp(HUB\_IN)}}{3.600 \text{ detik}}$$
* **Ambang Batas Operasional (*Operational Thresholds*):**
  * **Normal (Healthy):** $< 8 \text{ jam}$ untuk Gateway Transit, $< 4 \text{ jam}$ untuk Delivery DC.
  * **Warning (Buffer Delay):** $8 - 24 \text{ jam}$.
  * **Critical Backlog (Macet):** $> \mathbf{24 \text{ jam}}$ (Wajib diinvestigasi karena mengancam SLA rute line-haul).

### 2.3. First-Attempt Delivery Rate (FADR) & Non-Delivery Report (NDR)
* **Definisi FADR:** Persentase paket yang sukses diserahkan kepada konsumen pada **percobaan pengantaran pertama kurir (*Attempt 1*)**.
* **Formula FADR:**
  $$\text{FADR (\%)} = \frac{\text{Total Paket DEL\_OK pada attempt\_ke = 1}}{\text{Total Paket yang Dilakukan Pengantaran (attempt\_ke = 1)}} \times 100\%$$
* **Non-Delivery Report (NDR):** Paket yang mengalami status `DEL_FAIL`. Setiap kegagalan wajib disertai `alasan_gagal_kirim`.
* **Ambang Batas Integritas Kurir (Fake Attempt Threshold):**  
  Secara historis nasional, alasan *"Rumah Kosong"* mencakup $35\% - 45\%$ dari total kegagalan kirim. Kurir yang mencatatkan proporsi *"Rumah Kosong"* $> \mathbf{65\%}$ dari total kegagalannya diindikasikan melakukan **pemalsuan percobaan kirim (*fake attempt / malas kirim*)**.

---

## 3. REGULASI TARIF & AUDIT PENDAPATAN (COMMERCIAL RULES)

### 3.1. Standarisasi Berat Volumetrik (Volumetric Divisor)
Sesuai regulasi Asosiasi Perusahaan Jasa Pengiriman Ekspres Indonesia (ASPERINDO), berat yang ditagihkan (*Chargeable Weight*) adalah nilai tertinggi antara berat fisik timbangan dengan berat volume dimensi kemasan:

$$\text{Chargeable Weight (kg)} = \max(\text{Berat Aktual}, \text{Berat Volumetrik})$$

* **Formula Berat Volumetrik Berdasarkan Moda Layanan:**
  1. **Layanan Ekspres Udara & Darat (`Same Day`, `Next Day`, `Reguler`):**
     $$\text{Berat Volumetrik (kg)} = \frac{\text{Panjang (cm)} \times \text{Lebar (cm)} \times \text{Tinggi (cm)}}{\mathbf{6.000}}$$
  2. **Layanan Truk Berat (`Kargo`):**
     $$\text{Berat Volumetrik (kg)} = \frac{\text{Panjang (cm)} \times \text{Lebar (cm)} \times \text{Tinggi (cm)}}{\mathbf{5.000}}$$
* **Aturan Pembulatan Berat (*Rounding Rule*):**
  * Nilai desimal $\le 0,30 \text{ kg}$ dibulatkan ke bawah ke bilangan bulat terdekat (contoh: $1,28 \text{ kg} \rightarrow 1 \text{ kg}$).
  * Nilai desimal $> 0,30 \text{ kg}$ dibulatkan ke atas ke bilangan bulat berikutnya (contoh: $1,35 \text{ kg} \rightarrow 2 \text{ kg}$).
  * Berat minimum yang ditagihkan adalah $1 \text{ kg}$.
* **Audit Kebocoran Pendapatan (*Weight Fraud Leakage*):**
  $$\text{Lost Revenue} = (\text{Chargeable Weight Seharusnya} - \text{Berat Ditagihkan}) \times \text{Tarif Dasar Ongkir per Kg}$$

### 3.2. Tabel Liabilitas Denda Penalti SLA (*SLA Breach Penalty Tiers*)
Berdasarkan Service Level Agreement (SLA) kontrak logistik B2B NexLog:
Apabila paket mengalami keterlambatan kirim melampaui `promised_sla_timestamp`, NexLog wajib memberikan kompensasi denda pengembalian ongkos kirim (*penalty refund*) kepada merchant pengirim dengan ketentuan:

| Kategori Keterlambatan | Durasi Keterlambatan | Nilai Ganti Rugi Denda Penalti |
| :--- | :--- | :--- |
| **Keterlambatan Ringan** | $1 \text{ jam}$ s/d $\le 12 \text{ jam}$ dari SLA | **50% dari total `ongkir_tertagih`** |
| **Keterlambatan Berat** | $> 12 \text{ jam}$ melampaui SLA | **100% dari total `ongkir_tertagih` (Full Refund)** |
| **Klausul Khusus Merchant `ENTERPRISE`** | Terlambat berapa pun durasinya | **Sesuai kolom `dim_merchant.persentase_kompensasi_denda` (Flat 100%)** |

> *Catatan Finansial:* Paket berstatus `LOST_IN_TRANSIT` atau `DAMAGED` dikenakan denda penggantian 100% ongkir ditambah nilai barang sesuai asuransi.

---

## 4. KETENTUAN KHUSUS CASH ON DELIVERY (COD) & RETUR (RTS)

### 4.1. Alur State Machine Retur (*Return to Sender / RTS*)
1. Paket COD yang gagal diantar pada *Attempt 1* **TIDAK BOLEH** langsung diretur ke penjual.
2. Sistem wajib menjadwalkan *Attempt 2* (dalam kurun waktu 24 jam).
3. Paket baru dinyatakan resmi berstatus `RETURN_TO_SENDER` jika:
   * Mengalami kegagalan pada *Attempt 2* khusus dengan alasan penolakan COD (`alasan_gagal_kirim = 'COD Ditolak Pembeli'`), ATAU
   * Telah gagal sebanyak 3 kali percobaan kirim (*Attempt 3*).

### 4.2. Audit Uang Mengambang (*Floating Cash in Transit*)
* **Definisi:** Dana tunai pembayaran paket COD yang secara fisik telah diserahkan oleh pembeli kepada kurir (ditandai dengan `fact_pengiriman.status_akhir = 'DELIVERED'`), namun kurir belum menyetorkannya ke kasir hub (*cashier settlement*).
* **Kriteria SQL:**
  $$\text{metode\_pembayaran} = \text{'COD'} \quad \text{AND} \quad \text{status\_akhir} = \text{'DELIVERED'} \quad \text{AND} \quad \text{waktu\_setor\_kasir IS NULL}$$
* **Nominal Uang Mengambang per Resi:**
  $$\text{Floating Cash Amount} = \text{nilai\_barang} + \text{ongkir\_tertagih}$$
  *(Pada paket COD, kurir menagih total harga barang ditambah biaya ongkos kirim).*

---

## 5. STANDAR KODE SISTEM & ENUMERASI

### 5.1. Kode Peristiwa Tracking (*Event Codes*)
| Kode Event | Nama Peristiwa | Deskripsi Operasional |
| :--- | :--- | :--- |
| **`PICKUP`** | Paket Diambil | Kurir *first-mile* memindai paket di lokasi *merchant*. |
| **`HUB_IN`** | Masuk Fasilitas Hub | Paket dipindai di pintu *inbound* gudang sortir / transit. |
| **`HUB_OUT`** | Keluar Fasilitas Hub | Paket dipindai di pintu *outbound* dan dimuat ke armada *line-haul*. |
| **`DEL_OUT`** | Dibawa Kurir Pengantar | Paket diserahkan ke kurir *last-mile* untuk diantar ke alamat. |
| **`DEL_OK`** | Berhasil Terkirim | Paket telah diterima oleh konsumen / penerima yang sah. |
| **`DEL_FAIL`** | Gagal Diantar | Percobaan kirim gagal (membutuhkan alasan kegagalan). |
| **`RTS_IN`** | Proses Retur | Paket masuk ke jalur pemulangan kembali ke gudang penjual. |

### 5.2. Kode Alasan Gagal Kirim (*NDR Reason Codes*)
* `'Rumah Kosong'` (Penerima tidak berada di tempat saat kurir tiba).
* `'Alamat Tidak Ditemukan'` (Alamat tidak lengkap, nomor rumah tidak ada, jalan buntu).
* `'COD Ditolak Pembeli'` (Pembeli merasa tidak memesan, tidak punya uang, atau menolak membayar).
* `'Cuaca Ekstrem'` (Banjir, pohon tumbang, akses jalan terputus).

---

## 6. STANDAR PEMBERSIHAN DATA & PIPELINE CLEANSING (DATA HYGIENE SOP)

### 6.1. Protokol Deduplikasi Jitter Scan Barcode
* **Definisi:** Pemindaian ganda yang tidak disengaja akibat pengulangan jaringan (*network retry*) atau tombol PDA kurir/sensor conveyor tertekan berkali-kali.
* **Kriteria Anomali Jitter:**
  Dua baris data atau lebih pada `fact_tracking_event` yang memiliki:
  1. `no_resi_awb` yang sama,
  2. `event_code` yang sama,
  3. `hub_id` yang sama (atau `kurir_id` yang sama), dan
  4. Selisih waktu dengan scan sebelumnya: $\le \mathbf{10\text{ detik}}$.
* **Aturan Resolusi (SOP):**
  * Selalu pertahankan **rekaman scan pertama** (`MIN(event_timestamp)` atau baris pertama dengan `ROW_NUMBER() = 1`).
  * Seluruh rekaman duplikat berikutnya **WAJIB DIABAIKAN** dalam kueri penghitungan Dwell Time dan timeline pengiriman agar tidak merusak kalkulasi `LEAD()`.

### 6.2. Protokol Paket Nyasar / Tanpa Manifes (Unmanifested Ghost Parcels)
* **Definisi:** Paket fisik yang ter-scan di hub transit oleh tim sortir, namun nomor resinya tidak terdaftar di sistem pemesanan resmi (`fact_pengiriman`). Kasus ini lazim terjadi akibat salah kirim antarmitra ekspedisi (*cross-dock misroute*).
* **Aturan Resolusi (SOP):**
  * Wajib dideteksi menggunakan *Anti-Join* (`fact_tracking_event LEFT JOIN fact_pengiriman ON ... WHERE fact_pengiriman.no_resi_awb IS NULL`).
  * Resi-resi ini **DILARANG** dimasukkan ke dalam pelaporan kepatuhan SLA/OTD resmi, melainkan wajib dialihkan ke *Laporan Harian Paket Nyasar (Over & Astray Report)* untuk diinvestigasi oleh tim *Loss Prevention*.

