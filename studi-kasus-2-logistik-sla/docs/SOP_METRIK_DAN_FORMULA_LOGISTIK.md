# STANDAR OPERASIONAL PROSEDUR (SOP) & KAMUS METRIK LOGISTIK
**PT Nusantara Ekspres Logistik (NexLog)**  
*Divisi Corporate Quality Management, Network Operations & Commercial Finance*

---

| PARAMETER DOKUMEN | KETERANGAN RESMI |
| :--- | :--- |
| **Nomor Dokumen** | `SOP/OPS-QMS/2026/014` |
| **Versi Dokumen** | `3.0 (Controlled Document)` |
| **Tanggal Berlaku Efektif** | `1 Januari 2026` |
| **Klasifikasi Akses** | `Internal Terbatas (Corporate Confidential)` |
| **Penyusun** | Tim Standardisasi Proses & Kebijakan Operasional |
| **Disetujui Oleh** | Hendrawan Hartono, M.Sc. (Chief Operating Officer) |
| **Rujukan Regulasi** | Standar Operasional Asosiasi Perusahaan Jasa Pengiriman Ekspres Indonesia (ASPERINDO) |

---

## 1. TUJUAN & RUANG LINGKUP TATA KELOLA

1. Dokumen ini merupakan **Single Source of Truth (SSOT)** resmi yang mengikat seluruh unit kerja di lingkungan PT Nusantara Ekspres Logistik (NexLog), mencakup *Network Operations*, *Hub Sortation*, *Last-Mile Fleet*, *Commercial Partnerships*, *Finance & Accounting*, dan *Data Analytics*.
2. Seluruh definisi operasional, formula matematis, ambang batas toleransi (*operational thresholds*), dan perhitungan penalti yang disajikan dalam laporan manajerial **wajib** merujuk pada ketentuan yang termaktub di dalam dokumen ini.

---

## 2. METRIK KINERJA OPERASIONAL & FORMULA STANDAR

### 2.1. On-Time Delivery (OTD) Rate
* **Definisi:** Rasio ketepatan waktu penyerahan paket kepada pihak penerima akhir (*consignee*) dibandingkan dengan komitmen janji layanan (*Service Level Agreement*).
* **Standar Minimum Industri (Benchmark 2026):** $\ge \mathbf{95,00\%}$.
* **Ketentuan Pengukuran Faktual:**
  1. Paket diklasifikasikan sebagai **Tepat Waktu (*On-Time*)** apabila:
     $$\text{actual\_delivered\_timestamp} \le \text{promised\_sla\_timestamp}$$
  2. Paket yang status akhirnya bukan `DELIVERED` (seperti `LOST_IN_TRANSIT` atau `RETURN_TO_SENDER`) dikategorikan sebagai **Kegagalan SLA (*Breach*)**.
* **Formula Matematis:**
  $$\text{OTD Rate (\%)} = \frac{\sum \text{Paket Terkirim Tepat Waktu}}{\sum \text{Total Populasi Paket Wajib Kirim}} \times 100\%$$

### 2.2. Hub Dwell Time (Waktu Singgah di Fasilitas Gudang Sortir)
* **Definisi:** Durasi waktu yang dihabiskan oleh fisik paket di dalam satu fasilitas hub transit sejak pemindaian masuk (*induction scan / `HUB_IN`*) hingga pemindaian keluar ke armada pengangkut (*dispatch scan / `HUB_OUT`*).
* **Formula Matematis:**
  $$\text{Dwell Time (Jam)} = \frac{\text{event\_timestamp(HUB\_OUT)} - \text{event\_timestamp(HUB\_IN)}}{3.600 \text{ detik}}$$
* **Ambang Batas Toleransi Operasional (*Operational Thresholds*):**
  * **Wajar / Optimal (*Healthy*):** $< 8,0 \text{ jam}$ untuk Gateway Transit, $< 4,0 \text{ jam}$ untuk Delivery DC.
  * **Perhatian / Peringatan (*Warning*):** $8,0 - 24,0 \text{ jam}$.
  * **Kemacetan Kritis (*Critical Backlog*):** $> \mathbf{24,0 \text{ jam}}$ (Wajib diinvestigasi karena berpotensi merusak SLA jaringan *line-haul*).

### 2.3. First-Attempt Delivery Rate (FADR) & Non-Delivery Report (NDR)
* **Definisi FADR:** Persentase paket yang berhasil diserahterimakan kepada konsumen pada **percobaan pengantaran kurir pertama kali (*Attempt 1*)**.
* **Formula Matematis FADR:**
  $$\text{FADR (\%)} = \frac{\text{Total Paket Berstatus DEL\_OK pada attempt\_ke = 1}}{\text{Total Paket yang Diberangkatkan Kurir pada attempt\_ke = 1}} \times 100\%$$
* **Non-Delivery Report (NDR):** Seluruh insiden kegagalan pengantaran fisik paket (`DEL_FAIL`). Setiap insiden NDR wajib disertai alasan operasional yang valid (`alasan_gagal_kirim`).
* **Batas Toleransi Integritas Kurir (*Fake Attempt Threshold*):**  
  Secara agregat nasional, alasan kegagalan *"Rumah Kosong"* berkisar antara $35\% - 45\%$. Personel kurir yang mencatatkan proporsi alasan *"Rumah Kosong"* melampaui **$65,00\%$** dari total kegagalannya ditetapkan berada di bawah status **Investigasi Khusus (*Indikasi Fake Attempt*)** karena terindikasi menandai paket gagal tanpa mendatangi alamat tujuan.

---

## 3. AUDIT PENDAPATAN & STANDARISASI TARIF VOLUMETRIK

### 3.1. Penentuan Berat Tagihan (*Chargeable Weight*)
Berdasarkan regulasi ASPERINDO, berat yang wajib dijadikan dasar pengenaan tarif ongkos kirim (*Chargeable Weight*) adalah nilai tertinggi antara berat fisik riil timbangan dengan berat hasil konversi volume kemasan:

$$\text{Chargeable Weight (kg)} = \max(\text{Berat Aktual}, \text{Berat Volumetrik})$$

* **Formula Berat Volumetrik Berdasarkan Moda Layanan:**
  1. **Layanan Ekspres Udara & Darat (`Same Day`, `Next Day`, `Reguler`):**
     $$\text{Berat Volumetrik (kg)} = \frac{\text{Panjang (cm)} \times \text{Lebar (cm)} \times \text{Tinggi (cm)}}{\mathbf{6.000}}$$
  2. **Layanan Muatan Berat Darat / Truk (`Kargo`):**
     $$\text{Berat Volumetrik (kg)} = \frac{\text{Panjang (cm)} \times \text{Lebar (cm)} \times \text{Tinggi (cm)}}{\mathbf{5.000}}$$
* **Aturan Pembulatan Fraksi Desimal Berat (*Rounding Protocol*):**
  * Fraksi desimal $\le 0,30 \text{ kg}$ dibulatkan ke bawah ke bilangan bulat terdekat (contoh: $2,25 \text{ kg} \rightarrow 2 \text{ kg}$).
  * Fraksi desimal $> 0,30 \text{ kg}$ dibulatkan ke atas ke bilangan bulat berikutnya (contoh: $2,35 \text{ kg} \rightarrow 3 \text{ kg}$).
  * Batas minimum berat tagihan adalah $1 \text{ kg}$.
* **Kalkulasi Kebocoran Pendapatan (*Lost Freight Revenue*):**
  $$\text{Lost Revenue (Rp)} = (\text{Chargeable Weight Seharusnya} - \text{Berat Dideklarasikan}) \times \text{Tarif Dasar Ongkir per Kg}$$

### 3.2. Matriks Kompensasi Denda Penalti Keterlambatan SLA
Sesuai klausul perjanjian kerjasama operasional logistik B2B antara NexLog dan mitra pedagang:

| Kategori Keterlambatan | Parameter Durasi Keterlambatan | Nilai Ganti Rugi / Kompensasi Penalti |
| :--- | :--- | :--- |
| **Keterlambatan Ringan** | $1 \text{ jam} < \text{keterlambatan} \le 12 \text{ jam}$ dari janji SLA | **$50\%$ dari nilai `ongkir_tertagih`** |
| **Keterlambatan Berat** | $> 12 \text{ jam}$ melampaui janji SLA | **$100\%$ dari nilai `ongkir_tertagih` (Full Refund)** |
| **Klausul Khusus Merchant `ENTERPRISE`** | Terlambat dengan durasi berapa pun | **Flat $100\%$ dari nilai `ongkir_tertagih`** (mengacu kolom `persentase_kompensasi_denda`) |

---

## 4. TATA KELOLA TRANSAKSI CASH ON DELIVERY (COD) & RETUR

### 4.1. Alur Prosedur Retur ke Penjual (*Return to Sender / RTS*)
1. Paket dengan metode COD yang mengalami kegagalan pada percobaan pertama (*Attempt 1*) dilarang keras langsung dinyatakan sebagai retur.
2. Petugas pengantaran wajib menjadwalkan percobaan ulang (*Attempt 2*) dalam rentang waktu $1 \times 24 \text{ jam}$.
3. Status paket secara resmi dialihkan menjadi `RETURN_TO_SENDER` hanya apabila:
   * Terjadi penolakan eksplisit dari pihak pembeli pada *Attempt 2* (`alasan_gagal_kirim = 'COD Ditolak Pembeli'`), ATAU
   * Telah melampaui batas maksimum 3 kali percobaan pengantaran (*Attempt 3*).

### 4.2. Rekonsiliasi Dana Tunai Mengambang (*Floating Cash in Transit*)
* **Definisi:** Akumulasi dana tunai pembayaran paket COD yang secara fisik telah diserahkan konsumen kepada kurir (terkonfirmasi status `DELIVERED`), namun uangnya belum disetorkan kurir ke petugas kasir hub operasional.
* **Kriteria Pengujian Sistem:**
  $$\text{metode\_pembayaran} = \text{'COD'} \quad \text{AND} \quad \text{status\_akhir} = \text{'DELIVERED'} \quad \text{AND} \quad \text{waktu\_setor\_kasir IS NULL}$$
* **Nominal Dana Tunai per Resi COD:**
  $$\text{Nilai Tagihan COD} = \text{nilai\_barang} + \text{ongkir\_tertagih}$$

---

## 5. PENGENDALIAN KUALITAS DATA PEMINDAIAN (DATA HYGIENE)

### 5.1. Protokol Deduplikasi Jitter Scan Barcode
* **Definisi Anomali:** Duplikasi rekaman peristiwa pemindaian barcode yang timbul akibat latensi jaringan (*network retry*) atau tombol pemindai fisik tertekan ganda secara berurutan.
* **Kriteria Teknis Jitter:**
  Dua rekaman atau lebih pada `fact_tracking_event` yang memiliki:
  1. `no_resi_awb` identik,
  2. `event_code` identik,
  3. `hub_id` identik (atau `kurir_id` identik), dan
  4. Selisih stempel waktu dengan rekaman sebelumnya $\le \mathbf{10\text{ detik}}$.
* **Resolusi Baku:**
  * Pertahankan rekaman pemindaian pertama (`MIN(event_timestamp)` atau baris pertama dengan `ROW_NUMBER() = 1`).
  * Rekaman duplikat berikutnya wajib diabaikan dalam seluruh kueri kalkulasi durasi operasional.

### 5.2. Protokol Paket Tanpa Manifes (*Unmanifested Ghost Parcels*)
* **Definisi Anomali:** Paket fisik yang ter-scan di fasilitas hub transit namun tidak memiliki entitas pemesanan resmi pada tabel induk `fact_pengiriman`. Kasus ini umumnya terjadi akibat paket salah sortir antarperusahaan ekspedisi (*cross-dock misroute*).
* **Resolusi Baku:**
  * Wajib dideteksi menggunakan pengujian *Anti-Join* (`fact_tracking_event LEFT JOIN fact_pengiriman ... WHERE fact_pengiriman.no_resi_awb IS NULL`).
  * Seluruh rekaman unmanifested wajib diisolasi ke dalam *Laporan Paket Anomali* untuk ditindaklanjuti oleh divisi *Loss Prevention & Security*, dan dilarang disertakan dalam evaluasi metrik kepatuhan SLA komersial.

---

## 6. KODE SISTEM & ENUMERASI OPERASIONAL

### 6.1. Kode Peristiwa Pemindaian (*Event Codes*)
| Kode Event | Deskripsi Peristiwa | Lokasi Pemindaian | Aktor Penanggung Jawab |
| :--- | :--- | :--- | :--- |
| **`PICKUP`** | Penjemputan paket dari lokasi pedagang | Merchant Warehouse | Kurir First-Mile |
| **`HUB_IN`** | Penerimaan paket di pintu masuk hub transit | Inbound Sorting Dock | Petugas Inbound Hub |
| **`HUB_OUT`** | Keberangkatan paket menuju rute antarkota | Outbound Dispatch Dock | Petugas Outbound Hub |
| **`DEL_OUT`** | Paket dibawa kurir untuk diantar ke konsumen | Delivery DC Hub | Kurir Last-Mile |
| **`DEL_OK`** | Paket sukses diserahkan ke pihak penerima | Alamat Konsumen | Kurir Last-Mile |
| **`DEL_FAIL`** | Percobaan penyerahan paket mengalami kegagalan | Alamat Konsumen | Kurir Last-Mile |
| **`RTS_IN`** | Paket masuk ke jalur pemulangan retur | Return Processing Desk | Petugas Retur Hub |

### 6.2. Kode Standar Alasan Kegagalan Pengantaran (*NDR Reasons*)
* `'Rumah Kosong'` : Penerima tidak berada di tempat saat kurir tiba di alamat.
* `'Alamat Tidak Ditemukan'` : Alamat tidak lengkap, nomor rumah tidak ada, atau akses jalan terputus.
* `'COD Ditolak Pembeli'` : Pembeli menolak melakukan pembayaran atau membatalkan pesanan di tempat.
* `'Cuaca Ekstrem'` : Hambatan bencana alam, banjir, atau tanah longsor yang menutup akses transportasi.
