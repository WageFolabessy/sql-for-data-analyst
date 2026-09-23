# KAMUS DATA & SKEMA BASIS DATA LOGISTIK
**Database:** `logistics_sla_db` | **Target RDBMS:** PostgreSQL 16 | **Karakter:** Star Schema + Event Log

---

## 1. DIAGRAM RELASI ENTITAS (ERD)

```text
┌────────────────────────────────────────────────────────┐       ┌────────────────────────────────────────────────────────┐
│                       dim_hub                          │       │                      dim_merchant                      │
│ (PK: hub_id | Target Grain: 1 Fasilitas Gudang/Hub)    │       │ (PK: merchant_id | Target Grain: 1 Merchant Klien)     │
└───────────────────────────┬────────────────────────────┘       └───────────────────────────┬────────────────────────────┘
                            │                                                                │
                            │ (hub_asal_id / hub_tujuan_id)                                  │
                            ▼ (*)                                                            ▼ (*)
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                    fact_pengiriman                                                      │
│ (PK: no_resi_awb | Target Grain: 1 Pengiriman Paket / Nomor Resi)                                                       │
│  - Relasi         : merchant_id (FK), hub_asal_id (FK), hub_tujuan_id (FK)                                              │
│  - Dimensi Paket  : berat_aktual_kg, panjang_cm, lebar_cm, tinggi_cm, ongkir_tertagih, metode_pembayaran               │
│  - Waktu Penting  : waktu_booking, waktu_pickup, promised_sla_timestamp, actual_delivered_timestamp, waktu_setor_kasir│
│  - Status Akhir   : status_akhir ('DELIVERED', 'RETURN_TO_SENDER', 'LOST_IN_TRANSIT', 'DAMAGED')                       │
└───────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────┘
                                                            │ (1)
                                                            │
                                                            ▼ (*)
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                 fact_tracking_event                                                     │
│ (PK: event_id | Target Grain: 1 Peristiwa Pemindaian Barcode pada Paket)                                                │
│  - Relasi         : no_resi_awb (FK), hub_id (FK), kurir_id (FK), vendor_id (FK)                                        │
│  - Detail Scan    : event_code ('PICKUP', 'HUB_IN', 'HUB_OUT', 'DEL_OUT', 'DEL_OK', 'DEL_FAIL', 'RTS_IN')              │
│  - Waktu & Kurir  : event_timestamp, attempt_ke (1, 2, 3), alasan_gagal_kirim                                           │
└───────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────┘
                            ▲ (*)                                                            ▲ (*)
                            │                                                                │
┌───────────────────────────┴────────────────────────────┐       ┌───────────────────────────┴────────────────────────────┐
│                      dim_armada_vendor                 │       │                       dim_kurir                        │
│ (PK: vendor_id | Target Grain: 1 Vendor Line-Haul)     │       │ (PK: kurir_id | Target Grain: 1 Personel Kurir)         │
└────────────────────────────────────────────────────────┘       └────────────────────────────────────────────────────────┘
```

---

## 2. KAMUS TABEL & SPESIFIKASI KOLOM

### 2.1. Tabel Dimensi `dim_hub`
* **Target Grain:** `1 baris = 1 Fasilitas Hub/Gudang Logistik Unik`
* **Primary Key:** `hub_id` (VARCHAR)

| Nama Kolom | Tipe Data | Constraint | Keterangan & Contoh Nilai |
| :--- | :--- | :--- | :--- |
| `hub_id` | `VARCHAR(50)` | `PRIMARY KEY` | Kode unik fasilitas (contoh: `'HUB-CGK-01'`, `'HUB-SUB-01'`). |
| `nama_hub` | `VARCHAR(255)` | `NOT NULL` | Nama resmi (contoh: `'Sortation Gateway Cakung'`). |
| `kota` | `VARCHAR(100)` | `NOT NULL` | Kota lokasi hub (contoh: `'Jakarta Timur'`, `'Surabaya'`). |
| `provinsi` | `VARCHAR(100)` | `NOT NULL` | Provinsi (contoh: `'DKI Jakarta'`, `'Jawa Timur'`). |
| `zona_waktu` | `VARCHAR(50)` | `NOT NULL` | IANA Timezone: `'Asia/Jakarta'` (WIB), `'Asia/Makassar'` (WITA), `'Asia/Jayapura'` (WIT). |
| `tipe_hub` | `VARCHAR(50)` | `NOT NULL` | Tipe peran: `'Gateway Transit'`, `'Fulfillment Hub'`, `'Last-Mile Delivery DC'`. |
| `kapasitas_sortir_harian` | `INTEGER` | `NOT NULL` | Kapasitas maksimal mesin sortir (paket/hari). |

---

### 2.2. Tabel Dimensi `dim_merchant`
* **Target Grain:** `1 baris = 1 Klien Penjual / Brand Partner`
* **Primary Key:** `merchant_id` (VARCHAR)

| Nama Kolom | Tipe Data | Constraint | Keterangan & Contoh Nilai |
| :--- | :--- | :--- | :--- |
| `merchant_id` | `VARCHAR(50)` | `PRIMARY KEY` | Kode unik klien (contoh: `'MCH-001'`). |
| `nama_merchant` | `VARCHAR(255)` | `NOT NULL` | Nama toko/brand (contoh: `'Samsung Official Store'`). |
| `kategori_bisnis` | `VARCHAR(100)` | `NOT NULL` | Sektor usaha (contoh: `'Elektronik'`, `'Fashion'`). |
| `tier_merchant` | `VARCHAR(50)` | `NOT NULL` | Kelas klien: `'ENTERPRISE'` atau `'REGULAR'`. |
| `persentase_kompensasi_denda` | `NUMERIC(5,2)` | `NOT NULL` | Klausul penalti kontrak: `100.00` (Full) atau `50.00`. |

---

### 2.3. Tabel Dimensi `dim_kurir`
* **Target Grain:** `1 baris = 1 Personel Kurir Lapangan`
* **Primary Key:** `kurir_id` (VARCHAR)

| Nama Kolom | Tipe Data | Constraint | Keterangan & Contoh Nilai |
| :--- | :--- | :--- | :--- |
| `kurir_id` | `VARCHAR(50)` | `PRIMARY KEY` | ID pengenal kurir (contoh: `'KUR-001'`). |
| `nama_kurir` | `VARCHAR(255)` | `NOT NULL` | Nama lengkap kurir. |
| `hub_penugasan_id` | `VARCHAR(50)` | `NOT NULL, FK` | Merujuk ke `dim_hub(hub_id)` tempat pangkalan kurir. |
| `jenis_kendaraan` | `VARCHAR(50)` | `NOT NULL` | Armada kurir: `'Motor'` atau `'Mobil Van'`. |
| `status_kepegawaian` | `VARCHAR(50)` | `NOT NULL` | Status kerja: `'Kemitraan'` (Freelance) atau `'Tetap'`. |

---

### 2.4. Tabel Dimensi `dim_armada_vendor`
* **Target Grain:** `1 baris = 1 Perusahaan Rekanan Ekspedisi Antarkota`
* **Primary Key:** `vendor_id` (VARCHAR)

| Nama Kolom | Tipe Data | Constraint | Keterangan & Contoh Nilai |
| :--- | :--- | :--- | :--- |
| `vendor_id` | `VARCHAR(50)` | `PRIMARY KEY` | Kode vendor (contoh: `'VND-001'`). |
| `nama_vendor` | `VARCHAR(255)` | `NOT NULL` | Nama vendor armada *line-haul*. |
| `tipe_armada` | `VARCHAR(50)` | `NOT NULL` | Moda: `'Truk Tronton Box'`, `'Pesawat Kargo'`, `'Kapal Roro'`. |
| `biaya_kontrak_per_km` | `NUMERIC(15,2)` | `NOT NULL` | Biaya sewa operasional per kilometer perjalanan. |

---

### 2.5. Tabel Fakta `fact_pengiriman`
* **Target Grain:** `1 baris = 1 Nomor Resi Pengiriman (no_resi_awb)`
* **Primary Key:** `no_resi_awb` (VARCHAR)

| Nama Kolom | Tipe Data | Constraint | Keterangan & Catatan Analitik |
| :--- | :--- | :--- | :--- |
| `no_resi_awb` | `VARCHAR(50)` | `PRIMARY KEY` | Nomor resi unik (*Air Waybill*), format: `'AWB-2026-000001'`. |
| `merchant_id` | `VARCHAR(50)` | `NOT NULL, FK` | Relasi ke `dim_merchant(merchant_id)`. |
| `hub_asal_id` | `VARCHAR(50)` | `NOT NULL, FK` | Relasi ke `dim_hub(hub_id)` lokasi paket diberangkatkan. |
| `hub_tujuan_id` | `VARCHAR(50)` | `NOT NULL, FK` | Relasi ke `dim_hub(hub_id)` lokasi DC pengantaran akhir. |
| `layanan` | `VARCHAR(50)` | `NOT NULL` | Jenis layanan: `'Same Day'`, `'Next Day'`, `'Reguler'`, `'Kargo'`. |
| `berat_aktual_kg` | `NUMERIC(8,2)` | `NOT NULL` | Berat hasil timbangan fisik timbangan meja (kg). |
| `panjang_cm`, `lebar_cm`, `tinggi_cm` | `INTEGER` | `NOT NULL` | Dimensi terluar kotak kemasan (cm). |
| `metode_pembayaran` | `VARCHAR(50)` | `NOT NULL` | `'COD'` (Bayar di tempat) atau `'NON_COD'`. |
| `nilai_barang` | `NUMERIC(15,2)` | `NOT NULL` | Harga barang yang tertera di faktur e-commerce (Rp). |
| `ongkir_tertagih` | `NUMERIC(15,2)` | `NOT NULL` | Biaya ongkir yang tercetak di resi dan dibayar pengirim (Rp). |
| `waktu_booking` | `TIMESTAMPTZ` | `NOT NULL` | Waktu pesanan dibuat di sistem. |
| `waktu_pickup` | `TIMESTAMPTZ` | `NOT NULL` | Waktu paket fisik diserahterimakan ke kurir first-mile. |
| `promised_sla_timestamp` | `TIMESTAMPTZ` | `NOT NULL` | Batas waktu maksimal paket wajib tiba di tangan penerima. |
| `actual_delivered_timestamp`| `TIMESTAMPTZ` | `NULLABLE` | Waktu nyata penyerahan paket ke konsumen (NULL jika belum/gagal). |
| `waktu_setor_kasir` | `TIMESTAMPTZ` | `NULLABLE` | Waktu kurir menyetorkan uang tunai COD ke kasir hub (NULL = floating). |
| `status_akhir` | `VARCHAR(50)` | `NOT NULL` | `'DELIVERED'`, `'RETURN_TO_SENDER'`, `'LOST_IN_TRANSIT'`, `'DAMAGED'`. |

---

### 2.6. Tabel Fakta Riwayat Peristiwa `fact_tracking_event`
* **Target Grain:** `1 baris = 1 Peristiwa Pemindaian Barcode pada Resi AWB (event_id)`
* **Primary Key:** `event_id` (BIGSERIAL)

| Nama Kolom | Tipe Data | Constraint | Keterangan & Catatan Analitik |
| :--- | :--- | :--- | :--- |
| `event_id` | `BIGSERIAL` | `PRIMARY KEY` | Kunci urut unik fisik per peristiwa scan barcode. |
| `no_resi_awb` | `VARCHAR(50)` | `NOT NULL` | Nomor resi paket. *Catatan Arsitektur: Pada event stream data lake (Kafka), kolom ini tidak dibebani hard FK agar ingestion lancar saat menerima scan paket nyasar (unmanifested scans).* |
| `event_code` | `VARCHAR(50)` | `NOT NULL` | Kode peristiwa: `'PICKUP'`, `'HUB_IN'`, `'HUB_OUT'`, `'DEL_OUT'`, `'DEL_OK'`, `'DEL_FAIL'`, `'RTS_IN'`. |
| `hub_id` | `VARCHAR(50)` | `NULLABLE, FK` | Fasilitas hub tempat peristiwa terjadi (digunakan untuk *Dwell Time*). |
| `kurir_id` | `VARCHAR(50)` | `NULLABLE, FK` | Kurir penanggung jawab (terisi pada peristiwa delivery). |
| `vendor_id` | `VARCHAR(50)` | `NULLABLE, FK` | Vendor pengangkut (terisi pada perpindahan antarkota). |
| `event_timestamp` | `TIMESTAMPTZ` | `NOT NULL` | Waktu peristiwa pemindaian barcode tercatat di server. |
| `attempt_ke` | `INTEGER` | `NULLABLE` | Urutan percobaan pengantaran kurir (`1`, `2`, atau `3`). |
| `alasan_gagal_kirim` | `VARCHAR(100)` | `NULLABLE` | Alasan saat `DEL_FAIL`: `'Rumah Kosong'`, `'Alamat Tidak Ditemukan'`, `'COD Ditolak Pembeli'`, `'Cuaca Ekstrem'`. |

---

## 3. PANDUAN PENANGANAN ZONA WAKTU & KALKULASI DURASI DI POSTGRESQL

### A. Konversi Waktu Global ke Waktu Lokal Hub
Seluruh kolom waktu disimpan dalam format `TIMESTAMPTZ` (standar UTC di server). Ketika Anda ingin mengetahui jam kerja lokal di Makassar atau Jayapura:
```sql
SELECT 
    fpe.event_timestamp,
    fpe.event_timestamp AT TIME ZONE dh.zona_waktu AS waktu_lokal_hub
FROM fact_tracking_event fpe
JOIN dim_hub dh ON fpe.hub_id = dh.hub_id;
```

### B. Kalkulasi Selisih Waktu dalam Satuan Jam (*Decimal Hours*)
Untuk menghitung durasi keterlambatan SLA atau *Dwell Time* gudang dalam desimal jam:
```sql
-- Selisih dalam satuan jam desimal
EXTRACT(EPOCH FROM (actual_delivered_timestamp - promised_sla_timestamp)) / 3600.0 AS selisih_jam
```
* Jika `selisih_jam <= 0` $\rightarrow$ Pengiriman **Tepat Waktu (*On-Time*)**.
* Jika `selisih_jam > 0` $\rightarrow$ Pengiriman **Terlambat (*Breach SLA*)** sebesar nilai jam tersebut.
