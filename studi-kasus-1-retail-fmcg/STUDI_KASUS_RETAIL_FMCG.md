# ANALISIS RETAIL FMCG (PT NUSANTARA MART RETAILINDO)

---

## 1. MEMO EKSEKUTIF BISNIS

```text
MEMORANDUM INTERNAL
Kepada   : Tim Data Analytics & Business Intelligence
Dari     : Vice President of Retail Operations, PT Nusantara Mart Retailindo
Tanggal  : 19 September 2026
Perihal  : Penyelidikan Integritas Penjualan, Efektivitas Promo, dan Anomali POS Q1 2026
```

> *"Rekan-rekan Analis,*
> 
> *Pada kuartal pertama tahun 2026, jaringan ritel kita mencatatkan lonjakan omzet kotor di 15 gerai yang tersebar di pulau Jawa, Sumatera, Bali, dan Sulawesi. Namun, laporan keuangan pendahuluan menunjukkan indikasi janggal:*
> 1. *Margin laba kotor di beberapa gerai anjlok drastis meskipun volume barang yang keluar sangat tinggi.*
> 2. *Sistem Point-of-Sale (POS) kasir di beberapa gerai dilaporkan mengalami lag jaringan yang memicu double-click submit struk belanja.*
> 3. *Terdapat transaksi penjualan barang yang kodenya tidak dikenal dalam master katalog produk aktif kita.*
> 
> *Kami membutuhkan Anda untuk mengaudit database operasional `retail_fmcg_db`, membersihkan anomali data langsung melalui SQL (in-query cleaning), dan menjawab 5 level pertanyaan analitik dari tingkat operasional hingga tren strategis bulanan.*
> 
> *Gunakan standar **5-Stage Grain-Driven SQL Workflow** agar hasil analisis Anda valid, bebas dari jebakan duplikasi (fan-out trap), dan dapat dipertanggungjawabkan di hadapan direksi."*

---

## 2. ARSITEKTUR SKEMA & KAMUS DATA (`retail_fmcg_db`)

Database dirancang dengan pendekatan **Star Schema Relasional** yang memisahkan tabel dimensi katalog dengan fakta transaksi ber-grain ganda (*Header* vs *Detail*).

```text
┌────────────────────────────────────────────────────────┐
│                      dim_toko                          │
│  (Primary Key: toko_id | Target Grain: 1 Toko)         │
└───────────────────────────┬────────────────────────────┘
                            │
                            │ (1)
                            │
                            ▼ (*)
┌────────────────────────────────────────────────────────┐       ┌────────────────────────────────────────────────────────┐
│                fact_penjualan_header                   │       │                     dim_pelanggan                      │
│ (Primary Key: header_id | Target Grain: 1 Nota Struk)  │◀──────│(Primary Key: customer_id | Target Grain: 1 Pelanggan)  │
└───────────────────────────┬────────────────────────────┘  (1)  └────────────────────────────────────────────────────────┘
                            │
                            │ (1)
                            │
                            ▼ (*)
┌────────────────────────────────────────────────────────┐       ┌────────────────────────────────────────────────────────┐
│                fact_penjualan_detail                   │       │                      dim_produk                        │
│ (Primary Key: detail_id | Target Grain: 1 Item Nota)   │──────▶│ (Primary Key: produk_id | Target Grain: 1 Produk)      │
└────────────────────────────────────────────────────────┘  (*)  └────────────────────────────────────────────────────────┘
                                                            (1)
```

### Kamus Tabel & Deteksi Anomali Lapangan

| Nama Tabel | Target Grain Asli | Kunci Utama (PK) | Kolom Kunci Lain | Catatan Anomali Data Mentah |
| :--- | :--- | :--- | :--- | :--- |
| **`dim_produk`** | 1 baris = 1 Produk | `produk_id` | - | Kolom `kategori` tercemar spasi liar (*leading/trailing*) dan huruf kecil/kapital campur aduk. |
| **`dim_toko`** | 1 baris = 1 Gerai | `toko_id` | - | Kolom `kota` tercemar spasi liar. |
| **`dim_pelanggan`** | 1 baris = 1 Member | `customer_id` | - | Kolom `status_member` (`VIP`, `MEMBER`, `NON_MEMBER`). |
| **`fact_penjualan_header`** | 1 baris = 1 Struk Nota | `header_id` (Surrogate) | `transaksi_id` (Business Key) | Terdapat ~75 transaksi terduplikasi akibat *double-click* kasir dengan `transaksi_id` yang sama. |
| **`fact_penjualan_detail`** | 1 baris = 1 Item Struk | `detail_id` (Surrogate) | `transaksi_id`, `produk_id` | 1. Kolom `diskon_nominal` berisi `NULL` (harus di-`COALESCE`).<br>2. Terdapat puluhan *orphaned records* (kode produk fiktif `PRD-SILUMAN-999`, dll). |

---

## 3. PANDUAN KONEKSI DBEAVER KE POSTGRESQL (WSL2 / WINDOWS)

Jika Anda menggunakan DBeaver di Windows 11 yang terhubung ke PostgreSQL 16 di WSL2 Ubuntu:
1. Buka **DBeaver** $\rightarrow$ Klik menu **Database** $\rightarrow$ **New Database Connection**.
2. Pilih driver **PostgreSQL** $\rightarrow$ Klik **Next**.
3. Masukkan parameter koneksi:
   * **Host**: `localhost` atau `127.0.0.1`
   * **Port**: `5432`
   * **Database**: `retail_fmcg_db`
   * **Username**: `postgres`
   * **Password**: `ipangNUGI336`
4. Klik **Test Connection**. Pastikan status bertuliskan *Connected (PostgreSQL 16.x)*.
5. Klik **Finish**. Buat SQL Editor baru (`Ctrl + ]`) untuk mulai menulis query latihan.

---

## 4. MATRIKS 5 LEVEL TANTANGAN ANALISIS SQL

Kerjakan tantangan berikut secara berurutan. Setiap query wajib mematuhi **Clean SQL Style Guide**: huruf kapital untuk kata kunci (`SELECT`, `FROM`, `WHERE`), indentasi 4 spasi, dan wajib mencantumkan blok komentar meta data dengan **`Target Grain`**.

```sql
-- ==========================================================
-- Tantangan   : [Nomor Tantangan] - [Judul Singkat]
-- Target Grain: 1 baris = [Unit Terkecil Baris Hasil Akhir]
-- Author      : [Nama Anda]
-- ==========================================================
```

---

### LEVEL 1: FONDASI FILTERING, DATA HYGIENE, & EKSPLORASI AWAL

#### Tantangan 1.1: Transaksi Bernilai Tinggi (High-Value Basket)
* **Masalah Bisnis (The Objective):** Tim Audit Kasir ingin memeriksa seluruh transaksi sukses pada bulan **Januari 2026** yang memiliki total belanja di atas **Rp 300.000** untuk memverifikasi kesesuaian limit kasir.
* **Target Grain (The Resolution):** `1 baris = 1 Transaksi Struk Kasir (transaksi_id)`
* **Cek Grain Mentah (The Source Audit):** Periksa kolom `fact_penjualan_header.status_transaksi` (status sukses mencakup `'PAID'` dan `'COMPLETED'`). Kolom `tanggal_transaksi` bertipe `TIMESTAMP`.
* **Konstruksi Query:**
  * Gunakan `WHERE status_transaksi IN ('PAID', 'COMPLETED')`
  * Gunakan filter rentang tanggal `tanggal_transaksi >= '2026-01-01' AND tanggal_transaksi < '2026-02-01'` (atau fungsi tanggal PostgreSQL `tanggal_transaksi::date BETWEEN ...`).
  * Filter `total_nilai_transaksi > 300000`.
  * Urutkan dari nilai transaksi terbesar ke terkecil.
* **Sanity Check:** Pastikan tidak ada transaksi berstatus `'refund'` atau `'CANCELLED'` yang lolos ke hasil akhir.

#### Tantangan 1.2: Pembersihan Anomali Teks Katalog Produk (Data Hygiene)
* **Masalah Bisnis (The Objective):** Divisi Merchandising meminta daftar seluruh produk kategori **Minuman** yang aktif. Namun, data mentah pada kolom `kategori` di `dim_produk` tercemar spasi liar di awal/akhir kata serta tidak konsisten huruf kapitalnya (`'Minuman'`, `'  minuman '`, `'MINUMAN'`).
* **Target Grain (The Resolution):** `1 baris = 1 Produk Unik (produk_id)`
* **Cek Grain Mentah (The Source Audit):** `dim_produk` memiliki 120 baris produk.
* **Konstruksi Query:**
  * Bersihkan tampilan kolom dengan `UPPER(TRIM(kategori)) AS kategori_bersih`.
  * Lakukan pencarian tanpa sensitivitas huruf besar-kecil menggunakan `TRIM(kategori) ILIKE 'minuman'`.
  * Tampilkan `produk_id`, `nama_produk`, `kategori_bersih`, `harga_beli_hpp`, dan `harga_jual_standar`.
* **Sanity Check:** Pastikan seluruh produk minuman tertangkap tanpa ada yang terlewat akibat spasi liar atau huruf kecil.

#### Tantangan 1.3: Analisis Adopsi Pembayaran Non-Tunai
* **Masalah Bisnis (The Objective):** Manajemen ingin melihat 25 transaksi non-tunai (`QRIS` dan `DEBIT`) bernilai tertinggi di seluruh cabang.
* **Target Grain (The Resolution):** `1 baris = 1 Transaksi Struk Kasir (transaksi_id)`
* **Konstruksi Query:**
  * Filter `tipe_pembayaran IN ('QRIS', 'DEBIT')` dan `status_transaksi IN ('PAID', 'COMPLETED')`.
  * Urutkan `ORDER BY total_nilai_transaksi DESC LIMIT 25`.
* **Sanity Check:** Pastikan kolom `tipe_pembayaran` pada output hanya bernilai `'QRIS'` atau `'DEBIT'`.

---

### LEVEL 2: AGREGASI BISNIS, AUDIT NILAI NULL, & SENSITIVITAS METRIK

#### Tantangan 2.1: Audit Jebakan Nilai NULL pada Diskon Keranjang Belanja
* **Masalah Bisnis (The Objective):** Direktur Keuangan ingin mengetahui perbandingan omzet kotor, total diskon, dan omzet bersih di setiap cabang toko. Pada data mentah, barang yang tidak mendapatkan promo memiliki nilai `diskon_nominal = NULL`. Jika dijumlahkan langsung dengan operator matematika biasa tanpa `COALESCE`, nilai total akan rusak (*poisoning effect*).
* **Target Grain (The Resolution):** `1 baris = 1 Toko (toko_id)`
* **Cek Grain Mentah (The Source Audit):**
  * `fact_penjualan_detail` berisi 9.298 baris item.
  * 5.599 baris memiliki `diskon_nominal IS NULL`.
* **Konstruksi Query:**
  * Gabungkan `fact_penjualan_detail` dengan `fact_penjualan_header` untuk mendapatkan relasi ke `toko_id`.
  * Hitung:
    * Total Nilai Kotor: `SUM(kuantitas * harga_jual_aktual)`
    * Total Diskon: `SUM(COALESCE(diskon_nominal, 0))`
    * Total Nilai Bersih: `SUM((kuantitas * harga_jual_aktual) - COALESCE(diskon_nominal, 0))`
  * Kelompokkan berdasarkan `toko_id`.
* **Sanity Check:** Buktikan bahwa:
  $$\text{Total Nilai Kotor} - \text{Total Diskon} = \text{Total Nilai Bersih}$$
  Jika Anda lupa menggunakan `COALESCE`, jelaskan apa yang terjadi pada baris yang diskonnya `NULL`.

#### Tantangan 2.2: Porsi Penetrasi QRIS per Toko (PostgreSQL FILTER Clause)
* **Masalah Bisnis (The Objective):** Divisi Digital Banking ingin mengevaluasi penetrasi penggunaan QRIS di setiap toko. Tampilkan total transaksi struk, jumlah transaksi QRIS, dan persentase transaksi QRIS terhadap total transaksi.
* **Target Grain (The Resolution):** `1 baris = 1 Toko (toko_id)`
* **Konstruksi Query:**
  * Gunakan tabel `fact_penjualan_header`.
  * Manfaatkan sintaks elegan PostgreSQL `COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') AS total_trx_qris`.
  * Hitung persentase: `ROUND(100.0 * COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') / COUNT(*), 2) AS pct_qris`.
* **Sanity Check:** Nilai `pct_qris` harus berada di antara 0% hingga 100%.

#### Tantangan 2.3: Cabang Berkinerja di Bawah Target (HAVING Clause)
* **Masalah Bisnis (The Objective):** Temukan cabang toko yang total realisasi penjualan bersihnya di Q1 2026 masih berada di bawah target omzet bulanan cabang tersebut (`target_omzet_bulanan`).
* **Target Grain (The Resolution):** `1 baris = 1 Toko (toko_id)`
* **Konstruksi Query:**
  * Gabungkan `fact_penjualan_header` dengan `dim_toko`.
  * Filter hanya transaksi berstatus `'PAID'` atau `'COMPLETED'`.
  * Gunakan `GROUP BY dim_toko.toko_id, dim_toko.nama_toko, dim_toko.target_omzet_bulanan`.
  * Saring menggunakan klausa `HAVING SUM(fact_penjualan_header.total_nilai_transaksi) < dim_toko.target_omzet_bulanan`.
* **Sanity Check:** Pastikan kolom agregasi tidak diletakkan di klausa `WHERE`.

---

### LEVEL 3: PENGGABUNGAN RELASIONAL (JOIN), AUDIT KUNCI, & DETEKSI FAN-OUT

#### Tantangan 3.1: Perhitungan Gross Profit (Laba Kotor) Multi-Tabel
* **Masalah Bisnis (The Objective):** Manajemen membutuhkan laporan Laba Kotor (*Gross Profit*) per Kategori Produk untuk Q1 2026.
* **Target Grain (The Resolution):** `1 baris = 1 Kategori Produk`
* **Formula Bisnis:**
  $$\text{Gross Profit} = \sum \Big( (\text{harga\_jual\_aktual} - \text{harga\_beli\_hpp}) \times \text{kuantitas} - \text{COALESCE}(\text{diskon\_nominal}, 0) \Big)$$
* **Konstruksi Query:**
  * Lakukan `INNER JOIN` antara `fact_penjualan_detail` dengan `dim_produk` berdasarkan `produk_id`.
  * Gabungkan ke `fact_penjualan_header` untuk memfilter status transaksi sukses (`'PAID'`, `'COMPLETED'`).
  * Bersihkan kategori menggunakan `UPPER(TRIM(dim_produk.kategori))`.
  * Hitung total omzet kotor, total HPP, total diskon, dan total laba kotor.
* **Sanity Check:** Laba kotor harus sama dengan: $\text{Total Omzet Bersih} - \text{Total HPP}$.

#### Tantangan 3.2: The Fan-Out Trap Audit (Uji Pelipatan Baris)
* **Masalah Bisnis (The Objective):** Sebelum menyajikan laporan gabungan header dan detail ke pimpinan, analis wajib membuktikan bahwa penggabungan tabel tidak melipatgandakan nilai transaksi (*Fan-Out Trap*).
* **Target Grain (The Resolution):** `1 baris = Audit Perbandingan Jumlah Baris & Total Nilai`
* **Konstruksi Query:**
  * Hitung `COUNT(*)` dan `SUM(total_nilai_transaksi)` langsung dari `fact_penjualan_header`.
  * Kemudian, lakukan `JOIN fact_penjualan_detail ON ...` dan hitung kembali `COUNT(*)` serta `SUM(header.total_nilai_transaksi)`.
* **Pertanyaan Analisis:** Berapa kali lipat total nilai transaksi membengkak saat header di-join ke detail tanpa pra-agregasi? Mengapa hal tersebut terjadi?

#### Tantangan 3.3: Deteksi Barang Siluman (Anti-Join Orphaned Records)
* **Masalah Bisnis (The Objective):** Temukan transaksi pada `fact_penjualan_detail` yang menjual `produk_id` yang **TIDAK TERDAFTAR** di master katalog `dim_produk` (barang selundupan / kasir salah input barcode).
* **Target Grain (The Resolution):** `1 baris = 1 Item Transaksi Siluman (detail_id)`
* **Konstruksi Query:**
  * Gunakan teknik **Anti-Join**:
    ```sql
    FROM fact_penjualan_detail d
    LEFT JOIN dim_produk p ON d.produk_id = p.produk_id
    WHERE p.produk_id IS NULL;
    ```
  * Tampilkan `detail_id`, `transaksi_id`, `produk_id`, `kuantitas`, dan `subtotal`.
* **Sanity Check:** Buktikan berapa total kerugian/omzet dari barang siluman yang tidak memiliki master produk ini.

---

### LEVEL 4: MODULAR CTE, REKONSILIASI ZERO DISCREPANCY, & MARGIN BOCOR

#### Tantangan 4.1: Analisis Diskon Bocor (Cabang di Bawah Margin Nasional)
* **Masalah Bisnis (The Objective):** Divisi Commercial mencurigai ada beberapa cabang toko yang memberikan diskon berlebihan pada kategori tertentu, sehingga persentase margin labanya jatuh jauh di bawah rata-rata nasional untuk kategori tersebut.
* **Target Grain (The Resolution):** `1 baris = 1 Toko per Kategori Produk Bermasalah`
* **Konstruksi Query Menggunakan Modular CTE (WITH):**
  * **CTE 1 (`store_category_margin`):** Hitung omzet bersih, total laba kotor, dan `% Margin` per `(toko_id, nama_toko, kategori_bersih)`.
  * **CTE 2 (`national_category_margin`):** Hitung rata-rata `% Margin Nasional` per `kategori_bersih`.
  * **Final Query:** Gabungkan CTE 1 dan CTE 2, lalu tampilkan toko dan kategori yang memiliki `% Margin Toko < % Margin Nasional - 5%` (selisih lebih dari 5 poin persentase).
* **Sanity Check:** Pastikan pembagian persentase dikalikan `100.0` untuk mencegah *integer division truncation* di SQL.

#### Tantangan 4.2: Rekonsiliasi Zero-Discrepancy (Header vs Detail Audit)
* **Masalah Bisnis (The Objective):** Lakukan rekonsiliasi keuangan antara nilai total yang tercatat di tabel struk (`fact_penjualan_header.total_nilai_transaksi`) dengan penjumlahan subtotal di tabel keranjang (`fact_penjualan_detail.subtotal`). Identifikasi transaksi yang memiliki selisih (*discrepancy*).
* **Target Grain (The Resolution):** `1 baris = 1 Transaksi Struk (transaksi_id) yang Berselisih`
* **Konstruksi Query:**
  * **CTE (`detail_aggregated`):**
    ```sql
    SELECT transaksi_id, SUM(subtotal) AS sum_detail_subtotal
    FROM fact_penjualan_detail
    GROUP BY transaksi_id
    ```
  * Gabungkan CTE ke `fact_penjualan_header`.
  * Hitung `selisih = header.total_nilai_transaksi - detail.sum_detail_subtotal`.
  * Filter `WHERE ABS(header.total_nilai_transaksi - detail.sum_detail_subtotal) > 0.01`.
* **Sanity Check:** Tampilkan jumlah transaksi berselisih beserta total nominal selisihnya.

---

### LEVEL 5: PUNCAK KEAHLIAN: WINDOW FUNCTIONS, DEDUPLIKASI, & TREN WAKTU

#### Tantangan 5.1: Deduplikasi Transaksi Akibat POS Double-Click
* **Masalah Bisnis (The Objective):** Mesin kasir POS di beberapa cabang mengalami masalah *double-click submit*, di mana kasir menekan tombol pembayaran dua kali dalam rentang beberapa detik sehingga tercipta dua baris nota dengan `transaksi_id` yang sama di `fact_penjualan_header`. Bersihkan data ini dalam query analitik tanpa menghapus data fisik database!
* **Target Grain (The Resolution):** `1 baris = 1 Transaksi Struk Kasir Unik (transaksi_id)`
* **Konstruksi Query:**
  * Gunakan Window Function `ROW_NUMBER()`:
    ```sql
    WITH ranked_transactions AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY transaksi_id 
                ORDER BY tanggal_transaksi DESC, header_id DESC
            ) AS row_num
        FROM fact_penjualan_header
    )
    SELECT * 
    FROM ranked_transactions
    WHERE row_num = 1;
    ```
* **Sanity Check:** Bandingkan `COUNT(*)` tabel sebelum dideduplikasi vs sesudah dideduplikasi. Selisihnya harus persis sama dengan jumlah transaksi yang terduplikasi.

#### Tantangan 5.2: Top 3 Produk Terlaris per Kategori (DENSE_RANK)
* **Masalah Bisnis (The Objective):** Divisi Supply Chain ingin mengetahui **3 Produk Terlaris** (berdasarkan total kuantitas terjual) untuk setiap kategori produk pada transaksi berstatus sukses Q1 2026.
* **Target Grain (The Resolution):** `1 baris = 1 Produk dalam Top 3 per Kategori`
* **Konstruksi Query:**
  * **CTE 1 (`product_sales`):** Hitung `SUM(kuantitas)` per `(kategori_bersih, produk_id, nama_produk)`.
  * **CTE 2 (`ranked_products`):** Berikan peringkat penjualan per kategori menggunakan:
    ```sql
    DENSE_RANK() OVER (
        PARTITION BY kategori_bersih 
        ORDER BY total_kuantitas DESC
    ) AS rank_penjualan
    ```
  * **Final Query:** Ambil `WHERE rank_penjualan <= 3`.
* **Sanity Check:** Pastikan tidak ada kategori yang memiliki produk berperingkat $> 3$. Jika ada produk dengan kuantitas penjualan sama persis, `DENSE_RANK` akan memberikan nomor peringkat yang sama tanpa melompati urutan berikutnya.

#### Tantangan 5.3: Analisis Pertumbuhan Penjualan Bulanan (MoM) & Rata-Rata Bergerak 7 Hari
* **Masalah Bisnis (The Objective):** 
  1. Hitung total penjualan harian seluruh gerai, lalu hitung **7-Day Moving Average** untuk memperhalus fluktuasi harian (*smoothing trend*).
  2. Hitung total omzet bulanan (Januari, Februari, Maret 2026), lalu hitung **Month-over-Month (MoM) Growth %** menggunakan fungsi `LAG()`.
* **Target Grain (The Resolution):** 
  * Bagian A: `1 baris = 1 Tanggal Transaksi (YYYY-MM-DD)`
  * Bagian B: `1 baris = 1 Bulan Transaksi (YYYY-MM)`
* **Konstruksi Query Bagian A (7-Day Moving Average):**
  * Gunakan Window Frame:
    ```sql
    AVG(total_omzet_harian) OVER (
        ORDER BY tgl_transaksi
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ma_7_days
    ```
* **Konstruksi Query Bagian B (MoM Growth):**
  * Ambil omzet bulan sebelumnya dengan `LAG(omzet_bulanan, 1) OVER (ORDER BY bulan_transaksi)`.
  * Hitung pertumbuhan: `ROUND(100.0 * (omzet_bulanan - lag_omzet) / lag_omzet, 2) AS mom_growth_pct`.
* **Sanity Check:** Pada hari ke-1 sampai ke-6, moving average akan menghitung rata-rata dari hari yang tersedia hingga genap 7 hari pada hari ke-7. Pada bulan pertama (Januari), nilai `LAG()` bernilai `NULL`.

---

## 5. CARA MENGERJAKAN & MENGUMPULKAN JAWABAN

1. Buka berkas lembar kerja di folder proyek Anda:  
   📂 `sql/studi-kasus-1-retail-fmcg/jawaban_studi_kasus_1.sql`
2. Tuliskan jawaban SQL Anda untuk masing-masing tantangan (1.1 s/d 5.3).
3. Selalu awali setiap query dengan blok header:
   ```sql
   -- ==========================================================
   -- Tantangan   : [Nomor Tantangan] - [Nama Tantangan]
   -- Target Grain: [Definisi 1 baris hasil akhir]
   -- Author      : [Nama Anda]
   -- ==========================================================
   ```
4. Jalankan dan uji query Anda langsung di **DBeaver** terhadap database `retail_fmcg_db`.
5. Laporkan ke asisten coding ini jika Anda ingin memeriksa kebenaran hasil query atau jika menemui kendala eksekusi!
