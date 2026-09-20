# PANDUAN LENGKAP & KURIKULUM SQL FOR DATA ANALYST
*Kurikulum Mandiri: PostgreSQL 16, DBeaver, Set-Based Thinking, Audit Query AI, CTEs, Window Functions, & Validasi Logika*

---

> *"Di era LLM dan Text-to-SQL, AI bisa menulis klausa `SELECT`, `WHERE`, dan `JOIN` dalam 5 detik.  
> Nilai seorang Analis Data profesional tidak lagi diukur dari kecepatan mengetik sintaks, melainkan dari **kemampuan merancang arsitektur logika, mengaudit query AI yang 'confidently wrong', dan membuktikan kebenaran angka sebelum diserahkan ke Direksi**."*

---

## DAFTAR ISI

1. [Mentalitas Analis Data di Era AI](#1-mentalitas-analis-data-di-era-ai)
   - [1.1 Pergeseran Peran: Dari Query Writer Menjadi Logic Auditor](#11-pergeseran-peran-dari-query-writer-menjadi-logic-auditor)
   - [1.2 Jembatan Konsep: Excel vs SQL (Cell-Based vs Set-Based)](#12-jembatan-konsep-excel-vs-sql-cell-based-vs-set-based)
2. [Metodologi 5 Tahap Analisis SQL Berbasis Grain (The Grain-Driven Workflow)](#2-metodologi-5-tahap-analisis-sql-berbasis-grain-the-grain-driven-workflow)
   - [2.1 Pemahaman Fundamental: The Grain of Data](#21-pemahaman-fundamental-the-grain-of-data)
   - [2.2 Framework 5 Tahap Analisis](#22-framework-5-tahap-analisis)
   - [2.3 Studi Kasus & Contoh Nyata End-to-End](#23-studi-kasus--contoh-nyata-end-to-end)
3. [Protokol 5 Langkah Audit Query AI (The 5-Step AI Query Audit Protocol)](#3-protokol-5-langkah-audit-query-ai-the-5-step-ai-query-audit-protocol)
4. [Arsitektur Lingkungan Belajar: 1 Kasus = 1 Database](#4-arsitektur-lingkungan-belajar-1-kasus--1-database)
5. [Kurikulum 5 Level: Roadmap Teknis SQL & Data Validation](#5-kurikulum-5-level-roadmap-teknis-sql--data-validation)
   - [Level 1: Fondasi Filtering & Seleksi Data Dasar](#level-1-fondasi-filtering--seleksi-data-dasar)
   - [Level 2: Agregasi Bisnis & Audit Perilaku Nilai NULL](#level-2-agregasi-bisnis--audit-perilaku-nilai-null)
   - [Level 3: Penggabungan Data Relasional, Audit Join, & Deteksi Fan-Out Trap](#level-3-penggabungan-data-relasional-audit-join--deteksi-fan-out-trap)
   - [Level 4: Modular CTE, Rekonsiliasi Data, & Audit Logika AI](#level-4-modular-cte-rekonsiliasi-data--audit-logika-ai)
   - [Level 5: Puncak Keahlian: Window Functions, Kohort, & Analisis Retensi](#level-5-puncak-keahlian-window-functions-kohort--analisis-retensi)
6. [Standar Penulisan Query Profesional (Clean SQL Style Guide)](#6-standar-penulisan-query-profesional-clean-sql-style-guide)
7. [Matriks Batas Cukup Belajar SQL untuk Data Analyst](#7-matriks-batas-cukup-belajar-sql-untuk-data-analyst)

---

## 1. MENTALITAS ANALIS DATA DI ERA AI

### 1.1 Pergeseran Peran: Dari Query Writer Menjadi Logic Auditor
* Di era kecerdasan buatan (LLM, Copilot, Text-to-SQL), menulis sintaks dasar SQL bukan lagi pembeda utama keahlian analis data.
* AI saat ini sangat piawai menghasilkan query SQL yang sintaksnya 100% valid dan berjalan mulus tanpa error.
* Namun, AI memiliki kelemahan fatal: **buta konteks bisnis dan struktur data spesifik**. AI sering kali menghasilkan query yang *"confidently wrong"*—tabelnya keluar dan angkanya tampak masuk akal, tetapi logikanya cacat secara fundamental.
* **Tanggung Jawab Analis:** Anda bertindak sebagai *Logic Designer*, *Query Auditor*, dan *Data Validator*. Anda memegang tanggung jawab mutlak atas setiap angka yang disajikan ke pengambil keputusan.

> [!CAUTION]
> **BAHAYA "CONFIDENTLY WRONG" PADA QUERY AI**  
> Jangan pernah mengutip atau menyajikan angka hasil kueri AI tanpa audit independen. Periksa kembali asumsi logika filter, relasi tabel, dan kardinalitasnya. Di hadapan Direksi, alasan *"karena AI yang menulis kuerinya"* adalah bentuk kelalaian profesional.

---

### 1.2 Jembatan Konsep: Excel vs SQL (Cell-Based vs Set-Based)
Sebelum menulis query, ubah cara kerja otak Anda dari lingkungan Excel ke lingkungan SQL:
* **Di Excel (Cell-Based):** Anda berpikir sel per sel, menulis rumus di satu sel lalu menggesernya (*drag & drop*) ke bawah.
* **Di SQL (Set-Based):** Anda berpikir per himpunan (*set*), memproses seluruh baris tabel secara serentak dalam satu kesatuan operasi matematis.

Semua keahlian modern yang telah Anda kuasai di Excel memiliki padanan langsung di SQL:

| Konsep di Excel (Yang Sudah Anda Kuasai) | Padanan di PostgreSQL (SQL) | Catatan Analis |
| :--- | :--- | :--- |
| **Filter Data (AutoFilter / Slicer)** | `WHERE` / `HAVING` | Menyaring baris data berdasarkan kriteria tertentu |
| **Pivot Table (Baris & Agregasi Nilai)** | `GROUP BY` + `SUM()`, `COUNT()` | Mengelompokkan transaksi dan meringkas metrik bisnis |
| **Merge Queries (Power Query)** | `LEFT JOIN`, `INNER JOIN` | Menggabungkan dua tabel berbasis kolom kunci (*Key*) |
| **Append Queries (Power Query)** | `UNION ALL` | Menumpuk dua tabel berstruktur sama ke bawah |
| **Calculated Column (Power Pivot)** | `SELECT Kolom1 * Kolom2 AS Total` | Membuat kolom kalkulasi baru secara virtual |
| **DAX Measure `CALCULATE(..., FILTER)`** | `FILTER (WHERE ...)` atau `CASE WHEN` | Agregasi bersyarat langsung di dalam query |
| **Star Schema (1 : \*)** | `Primary Key` $\leftrightarrow$ `Foreign Key` | Menghubungkan tabel dimensi master ke tabel fakta |

---

## 2. METODOLOGI 5 TAHAP ANALISIS SQL BERBASIS GRAIN (THE GRAIN-DRIVEN WORKFLOW)

### 2.1 Pemahaman Fundamental: The Grain of Data

Sebelum mengetik klausa `SELECT` apa pun, pertanyaan pertama yang wajib dijawab adalah:

> [!IMPORTANT]
> **"SATU BARIS DI TABEL INI MEREPRESENTASIKAN APA?" (*WHAT IS THE GRAIN?*)**  
> Mengabaikan *grain* adalah sumber dari 90% kesalahan fatal kalkulasi data di tempat kerja.
>
> * Contoh Tingkatan Grain:
>   * **Order Level:** 1 baris = 1 nota transaksi kasir.
>   * **Order Item Level:** 1 baris = 1 barang belanjaan di dalam keranjang nota.
>   * **Customer Monthly Level:** 1 baris = 1 pelanggan per bulan transaksi.
>
> Jika tabel ber-grain *Order Item Level* langsung di-`JOIN` dengan tabel pembayaran tanpa penyesuaian, nilai total omzet Anda akan berlipat ganda (*inflated*) secara palsu!

---

### 2.2 Framework 5 Tahap Analisis

Agar proses analisis terarah dan kebal dari kesalahan logika, terapkan 5 tahap sistematis berikut:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│              METODOLOGI 5 TAHAP ANALISIS SQL BERBASIS GRAIN                 │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. Masalah Bisnis   (The Objective)    : Keputusan apa yang ingin diambil?  │
│ 2. Target Grain     (The Resolution)   : 1 baris output mewakili unit apa?  │
│ 3. Cek Grain Mentah (The Source Audit) : Apa grain tabel sumber & gap-nya?  │
│ 4. Konstruksi Query (Transformation)   : Jembatani gap via JOIN/GROUP BY/CTE│
│ 5. Validasi Hasil   (Sanity Check)     : Uji keunikan baris & rekonsiliasi! │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Masalah Bisnis (The Objective):**  
   Merumuskan pertanyaan spesifik atau keputusan bisnis apa yang ingin diambil oleh manajemen.
2. **Target Grain (The Resolution):**  
   Menetapkan unit terkecil yang harus direpresentasikan oleh satu baris hasil akhir agar pertanyaan bisnis tersebut terjawab tanpa distorsi.
3. **Cek Grain Tabel Mentah (The Source Audit):**  
   Memeriksa grain dari tabel-tabel sumber yang ada di database untuk mengetahui jarak (*gap*) antara data mentah dengan output yang diinginkan.
4. **Konstruksi Query (The Transformation):**  
   Menulis perintah SQL (`JOIN`, `WHERE`, `GROUP BY`, atau `CTE`) yang secara spesifik berfungsi menjembatani grain tabel mentah menuju target grain.
5. **Validasi Hasil (The Sanity Check):**  
   Memverifikasi apakah output query benar-benar unik pada target grain tersebut dan memastikan tidak ada pembengkakan baris (*fan-out*) akibat relasi tabel.

---

### 2.3 Studi Kasus & Contoh Nyata End-to-End

#### 1. Masalah Bisnis (The Objective):
* **Latar Belakang:** VP of Commercial di perusahaan ritel ingin memberikan *loyalty rewards* khusus kepada pelanggan terbaik.
* **Pertanyaan Bisnis:**  
  *"Siapa 10 pelanggan teratas (Top 10 VIP Customers) yang menghasilkan belanja bersih terbesar di Kuartal 1 2026 (Januari – Maret), berapa total belanja mereka, berapa kali frekuensi pesanan mereka, dan kapan terakhir kali mereka bertransaksi?"*

#### 2. Target Grain (The Resolution):
* **Target Output:** **1 baris = 1 Pelanggan Unik (`customer_id`)**.
* Kolom yang wajib ada di hasil akhir:
  * `customer_id` (ID unik pelanggan)
  * `nama_pelanggan` (Nama lengkap)
  * `total_belanja_bersih` (Nominal rupiah setelah diskon)
  * `frekuensi_order` (Jumlah transaksi pesanan)
  * `transaksi_terakhir` (Tanggal terakhir belanja)

#### 3. Cek Grain Tabel Mentah (The Source Audit):
Analis memeriksa skema database dan menemukan 3 tabel:
1. `master_pelanggan`:
   * *Grain:* **1 baris = 1 Pelanggan**. (*Primary Key:* `customer_id`).
2. `pesanan_header`:
   * *Grain:* **1 baris = 1 Nota Pesanan**. (*Primary Key:* `order_id`, *Foreign Key:* `customer_id`).
   * *Kolom:* `tanggal_order`, `status_pesanan` (`'PAID'`, `'CANCELLED'`).
3. `pesanan_detail`:
   * *Grain:* **1 baris = 1 Item Barang di Keranjang**. (*Primary Key:* `order_detail_id`, *Foreign Key:* `order_id`).
   * *Kolom:* `kuantitas`, `harga_satuan`, `diskon_nominal`.

> [!NOTE]
> **GAP GRAIN ANALYSIS:**  
> Nilai rupiah ada di tabel `pesanan_detail` (*Order Item Level*), status pesanan ada di `pesanan_header` (*Order Level*), dan nama pelanggan ada di `master_pelanggan` (*Customer Level*).  
> **Tantangan:** Jika kita langsung me-`JOIN` ketiga tabel ini tanpa agregasi bertahap, 1 pelanggan dengan 5 pesanan yang masing-masing berisi 3 barang akan berlipat ganda menjadi 15 baris! Kita wajib mereduksi (*roll-up*) grain dari **Order Item Level $\rightarrow$ Order Level $\rightarrow$ Customer Level**.

#### 4. Konstruksi Query (The Transformation):
Kita gunakan pendekatan **Modular CTE** agar alur transformasi grain terlihat sangat jernih:

```sql
-- =========================================================================
-- Deskripsi   : Analisis Top 10 Pelanggan Bernilai Tinggi Q1 2026
-- Target Grain: 1 baris = 1 Pelanggan (customer_id)
-- Author      : Lead Data Analyst
-- =========================================================================

WITH item_level_bersih AS (
    -- Tahap A: Reduksi dari Order Item Level -> Order Level
    -- Menghitung total belanja bersih per nomor order
    SELECT 
        order_id,
        SUM((kuantitas * harga_satuan) - diskon_nominal) AS subtotal_bersih
    FROM pesanan_detail
    GROUP BY order_id
),
order_level_valid AS (
    -- Tahap B: Sambungkan ke header untuk filter periode Q1 dan status PAID
    -- Grain saat ini: 1 baris = 1 Pesanan Sah
    SELECT 
        h.order_id,
        h.customer_id,
        h.tanggal_order,
        d.subtotal_bersih
    FROM pesanan_header AS h
    INNER JOIN item_level_bersih AS d 
        ON h.order_id = d.order_id
    WHERE h.status_pesanan = 'PAID'
      AND h.tanggal_order BETWEEN '2026-01-01' AND '2026-03-31'
),
customer_level_aggregated AS (
    -- Tahap C: Roll-up menuju Target Grain (1 baris = 1 Pelanggan)
    SELECT 
        customer_id,
        SUM(subtotal_bersih) AS total_belanja_bersih,
        COUNT(order_id) AS frekuensi_order,
        MAX(tanggal_order) AS transaksi_terakhir
    FROM order_level_valid
    GROUP BY customer_id
)
-- Tahap D: Final Output - Tambahkan atribut profil pelanggan
SELECT 
    c.customer_id,
    c.nama_pelanggan,
    agg.total_belanja_bersih,
    agg.frekuensi_order,
    agg.transaksi_terakhir
FROM customer_level_aggregated AS agg
INNER JOIN master_pelanggan AS c 
    ON agg.customer_id = c.customer_id
ORDER BY agg.total_belanja_bersih DESC
LIMIT 10;
```

#### 5. Validasi Hasil (The Sanity Check):
Sebagai analis profesional, jangan langsung menyajikan hasil ke manajemen. Jalankan 2 query pembuktian:

* **Uji 1: Verifikasi Keunikan Target Grain pada Output (Bebas Duplikasi):**
  ```sql
  -- Memastikan customer_id pada tabel output benar-benar unik:
  SELECT customer_id, COUNT(*)
  FROM (
      -- Masukkan query di atas sebagai subquery
      SELECT c.customer_id
      FROM customer_level_aggregated AS agg
      INNER JOIN master_pelanggan AS c ON agg.customer_id = c.customer_id
      LIMIT 10
  ) AS audit_output
  GROUP BY customer_id
  HAVING COUNT(*) > 1;
  -- HASIL WAJIB: 0 baris (Tidak boleh ada ID yang muncul lebih dari 1 kali!)
  ```

* **Uji 2: Rekonsiliasi Total Nilai Belanja (Zero Discrepancy Reconciliation):**
  ```sql
  -- Bandingkan total omzet di tabel mentah pesanan_detail dengan total belanja di query:
  SELECT 
      SUM((d.kuantitas * d.harga_satuan) - d.diskon_nominal) AS total_omzet_mentah_q1
  FROM pesanan_detail AS d
  INNER JOIN pesanan_header AS h ON d.order_id = h.order_id
  WHERE h.status_pesanan = 'PAID'
    AND h.tanggal_order BETWEEN '2026-01-01' AND '2026-03-31';
  -- Angka ini harus cocok 100% dengan total akumulasi belanja seluruh pelanggan di Q1!
  ```

---

## 3. PROTOKOL 5 LANGKAH AUDIT QUERY AI (THE 5-STEP AI QUERY AUDIT PROTOCOL)

Ketika Anda menggunakan AI (ChatGPT, Claude, Copilot) untuk membantu menulis query SQL di tempat kerja, **lakukan 5 langkah verifikasi ini sebelum mempercayai hasilnya**:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 PROTOKOL 5 LANGKAH AUDIT QUERY AI OLEH ANALIS                │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. Clarify Grain       : Apakah AI memahami definisi 1 baris tabel ini?     │
│ 2. Check Cardinality   : Apakah JOIN AI berpotensi memicu Fan-Out Trap?     │
│ 3. NULL Sensitivity    : Apakah fungsi COUNT/AVG aman dari distorsi NULL?   │
│ 4. Metric Alignment    : Apakah definisi metrik (filter status) sudah pas?  │
│ 5. Pre-Post Sanity     : Bandingkan total baris & nilai sebelum vs sesudah! │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Clarify Grain:** Apakah AI memahami level unit data tabel sumber dan target output? (Waspadai AI yang menggabungkan tabel tanpa agregasi).
2. **Check Cardinality:** Apakah relasi `JOIN` yang dibuat AI bersifat *Many-to-Many* yang menggandakan baris secara diam-diam?
3. **NULL Sensitivity:** Apakah fungsi agregasi (`COUNT`, `AVG`) terdistorsi oleh baris kosong?
4. **Metric Alignment:** Apakah AI menggunakan status transaksi yang tepat? (Misal: hanya menghitung status `'SUCCESS'` / `'PAID'`, bukan semua baris).
5. **Pre-Post Sanity:** Bandingkan jumlah baris dan total nominal sebelum vs sesudah query dijalankan.

---

## 4. ARSITEKTUR LINGKUNGAN BELAJAR: 1 KASUS = 1 DATABASE

Setiap studi kasus akan memiliki **database independen tersendiri** di PostgreSQL untuk memastikan isolasi domain bisnis dan mencegah tabrakan nama tabel:

```text
[PostgreSQL Server 16.15 - WSL2]
   │
   ├── 📂 retail_fmcg_db       <── KASUS 1: Fondasi Query, Grouping, & Profitabilitas Toko
   ├── 📂 logistics_sla_db      <── KASUS 2: Relasi Multi-Tabel, Durasi Waktu, & SLA Rute
   └── 📂 fintech_lending_db   <── KASUS 3: Rekonsiliasi Kas, Credit Risk, Kohort & Window Functions
```

Melalui 1 sambungan koneksi di DBeaver (`localhost:5432`), Anda dapat berpindah dan mengelola ketiga database ini secara visual dengan sangat mudah.

---

## 5. KURIKULUM 5 LEVEL: ROADMAP TEKNIS SQL & DATA VALIDATION

```text
[LEVEL 1: FONDASI FILTERING & SELEKSI DATA]
                   │
                   ▼
[LEVEL 2: AGREGASI BISNIS & AUDIT NILAI NULL]
                   │
                   ▼
[LEVEL 3: PENGGABUNGAN DATA RELASIONAL & DETEKSI FAN-OUT TRAP]
                   │
                   ▼
[LEVEL 4: MODULAR CTE, AUDIT QUERY AI, & REKONSILIASI DATA]
                   │
                   ▼
[LEVEL 5: PUNCAK KEAHLIAN: WINDOW FUNCTIONS, KOHORT, & RETENSI]
```

---

### LEVEL 1: Fondasi Filtering & Seleksi Data Dasar
*Tujuan: Mampu mengekstrak data mentah secara spesifik, terstruktur, dan efisien.*

* **Sintaks Inti:** `SELECT`, `FROM`, `WHERE`, `ORDER BY`, `LIMIT`, `OFFSET`.
* **Operator Logika:** `=`, `<>`, `>`, `<`, `>=`, `<=`, `AND`, `OR`, `NOT`.
* **Penyaringan Fleksibel:**
  * `IN ('A', 'B', 'C')` $\rightarrow$ Alternatif praktis pengganti banyak kondisi `OR`.
  * `BETWEEN x AND y` $\rightarrow$ Menyaring rentang nilai atau tanggal inklusif.
  * `LIKE` & `ILIKE` (PostgreSQL) $\rightarrow$ Pencarian teks dengan *wildcard* (`%` dan `_`). `ILIKE` bersifat kebal huruf besar/kecil (*case-insensitive*).
  * `IS NULL` & `IS NOT NULL` $\rightarrow$ Mendeteksi nilai yang hilang (*missing values*).
* **Ekspresi Aritmatika & Alias:**
  * Memberi nama alias kolom yang deskriptif (`AS omzet_bersih`).
  * Menggunakan `DISTINCT` untuk melihat variasi nilai unik tanpa duplikasi.

```sql
-- Contoh Sintaks Level 1:
SELECT 
    transaksi_id,
    tanggal_transaksi,
    tipe_pelanggan,
    total_belanja
FROM transaksi
WHERE status = 'SUCCESS'
  AND tipe_pelanggan IN ('MEMBER', 'VIP')
  AND total_belanja BETWEEN 100000 AND 1000000
ORDER BY total_belanja DESC
LIMIT 10;
```

---

### LEVEL 2: Agregasi Bisnis & Audit Perilaku Nilai NULL
*Tujuan: Mengubah ribuan baris transaksi mentah menjadi metrik performa bisnis serta memahami jebakan agregasi.*

* **Fungsi Agregasi Esensial:** `COUNT(*)`, `COUNT(kolom)`, `COUNT(DISTINCT kolom)`, `SUM()`, `AVG()`, `MIN()`, `MAX()`.
* **Klausul Pengelompokan:**
  * `GROUP BY` $\rightarrow$ Membagi data per kategori (Cabang, Kategori Produk, Bulan).
  * `HAVING` $\rightarrow$ Memfilter hasil setelah diagregasi (berbeda dari `WHERE` yang memfilter baris sebelum agregasi).

> [!WARNING]
> **JEBAKAN KRITIS NILAI `NULL` PADA AGREGASI**  
> * `COUNT(*)` menghitung **seluruh baris fisik**, termasuk baris yang bernilai `NULL`.
> * `COUNT(kolom)` hanya menghitung baris yang memiliki **nilai tidak NULL**.
> * `AVG(kolom)` otomatis mengabaikan nilai `NULL` dari pembagi (*denominator*). Jika sel kosong seharusnya bernilai 0 (misal: diskon Rp 0), gunakan `COALESCE(kolom, 0)` agar hasil rata-rata tidak melambung palsu!

> [!TIP]
> **FITUR ELEGAN POSTGRESQL: `FILTER (WHERE ...)`**  
> Di PostgreSQL, Anda bisa melakukan agregasi bersyarat secara bersih tanpa memerlukan `CASE WHEN` yang panjang:
> ```sql
> SELECT 
>     kategori_produk,
>     COUNT(*) AS total_transaksi,
>     SUM(total_belanja) AS total_omzet,
>     SUM(total_belanja) FILTER (WHERE tipe_pembayaran = 'QRIS') AS omzet_qris
> FROM transaksi
> GROUP BY kategori_produk;
> ```

---

### LEVEL 3: Penggabungan Data Relasional, Audit Join, & Deteksi Fan-Out Trap
*Tujuan: Menyatukan tabel-tabel terpisah dengan validasi integritas data dan mencegah duplikasi baris.*

* **Jenis-Jenis JOIN:**
  * `INNER JOIN` $\rightarrow$ Hanya menampilkan baris yang cocok di kedua tabel.
  * `LEFT JOIN` (Standar Industri) $\rightarrow$ Mempertahankan seluruh baris tabel utama (kiri), dan mencocokkan data pelengkap (kanan).
  * `RIGHT JOIN` & `FULL OUTER JOIN` $\rightarrow$ Mengambil irisan data kanan atau seluruh data kedua tabel.
  * `CROSS JOIN` $\rightarrow$ Perkalian baris (*Cartesian Product*) untuk membuat matriks kombinasi.
* **Deteksi Transaksi Bodong / Anomali (Anti-Join):**
  * `LEFT JOIN ... WHERE tabel_kanan.id IS NULL` $\rightarrow$ Menemukan transaksi tanpa master data produk atau pelanggan siluman.

> [!CAUTION]
> **BAHAYA *THE FAN-OUT TRAP* PADA OPERASI `JOIN`**  
> * **Penyebab:** Jika Anda melakukan `LEFT JOIN` ke tabel dimensi yang ternyata memiliki baris duplikat pada kolom kuncinya (*unintended one-to-many relationship*), baris tabel utama Anda akan berlipat ganda!
> * **Dampak:** Fungsi `SUM(omzet)` akan menggelembung (*inflated*) jauh melampaui omzet riil perusahaan!
> * **Protokol Audit:**
>   1. Jalankan *Pre-Join Sanity Check* untuk memastikan keunikan kunci di tabel master:
>      ```sql
>      SELECT id, COUNT(*) FROM master_produk GROUP BY id HAVING COUNT(*) > 1;
>      ```
>   2. Selalu bandingkan `COUNT(*)` tabel sebelum vs sesudah `JOIN`. Jika jumlah baris bertambah padahal menggunakan `LEFT JOIN` ke tabel master, berarti terjadi kebocoran *fan-out*!

---

### LEVEL 4: Modular CTE, Rekonsiliasi Data, & Audit Logika AI
*Tujuan: Menulis query bertingkat yang bersih, merekonsiliasi angka sebelum/sesudah kalkulasi, dan mengaudit query AI.*

* **CTE (Common Table Expression - `WITH` Clause):**
  * Standar industri modern untuk menghindari *nested subquery* yang mirip sarang burung (*spaghetti code*).
  * Memecah masalah analitik besar menjadi tahapan pipa data (*pipeline*) yang terstruktur.
* **CTE untuk Rekonsiliasi Data (*Sanity Check CTE*):**
  * Membuat blok CTE khusus untuk memastikan total nilai sebelum dan sesudah agregasi cocok 100% (*zero discrepancy*).
* **Pola Pikir Audit Query AI (*Spot the Flaw*):**
  * Latihan mengevaluasi query yang dihasilkan AI dengan mengajukan 3 pertanyaan kritis:
    1. *Apakah AI mengasumsikan kolom ini unik padahal ada duplikat?*
    2. *Apakah AI salah memperlakukan filter status transaksi?*
    3. *Apakah rumus yang dibuat AI menghasilkan fan-out pada nilai `SUM()`?*

---

### LEVEL 5: Puncak Keahlian: Window Functions, Kohort, & Analisis Retensi
*Tujuan: Menganalisis ranking, tren waktu, perbandingan periode, dan retensi pelanggan tanpa mengubah grain baris data.*

* **Anatomi Window Function:**  
  `FUNGSI() OVER (PARTITION BY kategori ORDER BY urutan ROWS/RANGE frame)`
* **Fungsi Ranking:**
  * `ROW_NUMBER()` $\rightarrow$ Memberi nomor urut baris unik 1, 2, 3...
  * `RANK()` $\rightarrow$ Memberi peringkat dengan nilai sama melompat (1, 2, 2, 4...).
  * `DENSE_RANK()` $\rightarrow$ Memberi peringkat tanpa melompat (1, 2, 2, 3...).
  * `NTILE(4)` $\rightarrow$ Membagi data ke dalam 4 kuartil / kelompok persentil.
* **Fungsi Navigasi Periode (Time-Lags):**
  * `LAG(kolom, 1)` $\rightarrow$ Mengambil nilai baris sebelumnya (menghitung pertumbuhan MoM / YoY).
  * `LEAD(kolom, 1)` $\rightarrow$ Mengambil nilai baris berikutnya.
* **Running Total & Moving Average:**
  * `SUM(omzet) OVER (ORDER BY tanggal ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` (Akumulasi berjalan).
  * `AVG(omzet) OVER (ORDER BY tanggal ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` (Rata-rata bergerak 7 hari).
* **Analisis Kohort & Retensi Pengguna:**
  * Menggunakan `generate_series()` untuk membuat kalender waktu referensi.
  * Menghitung *User Retention Rate* (berapa persen pengguna yang kembali bertransaksi di bulan ke-1, ke-2, ke-3 setelah registrasi).

---

## 6. STANDAR PENULISAN QUERY PROFESIONAL (CLEAN SQL STYLE GUIDE)

1. **Kata Kunci SQL Huruf Kapital:**  
   Gunakan huruf besar untuk kata kunci: `SELECT`, `FROM`, `WHERE`, `JOIN`, `ON`, `GROUP BY`, `ORDER BY`.
2. **Nama Tabel & Kolom Huruf Kecil (*snake_case*):**  
   Gunakan huruf kecil dipisah garis bawah: `transaksi_penjualan`, `total_harga`, `customer_id`.
3. **Satu Baris Satu Kolom pada `SELECT`:**  
   Beri jeda baris dan indentasi agar mudah dibaca manusia maupun di-debug bersama AI.
4. **Wajib Menyertakan *Inline Comments* (`--`) untuk Definisi Metrik Bisnis:**  
   Contoh:
   ```sql
   -- Omzet bersih = nilai transaksi status SUCCESS dikurangi diskon & voucher
   SUM(nominal_transaksi - diskon) AS omzet_bersih
   ```
5. **Indikator Target Grain di Header Query:**  
   Biasakan menuliskan deskripsi singkat dan target resolusi akhir di awal skrip:
   ```sql
   -- ==========================================================
   -- Deskripsi   : Analisis Kinerja Penjualan Toko Bulanan
   -- Target Grain: 1 baris = 1 Toko per Bulan Transaksi
   -- Author      : Endricho (Lead Data Analyst)
   -- ==========================================================
   ```

---

## 7. MATRIKS BATAS CUKUP BELAJAR SQL UNTUK DATA ANALYST

| Kategori | Wajib Dikuasai (Must-Have) | Cukup Tahu Konsepnya (Good-to-Know) | Abaikan / Bukan Porsi Analis (Skip) |
| :--- | :--- | :--- | :--- |
| **Pengambilan Data** | `SELECT`, `WHERE`, `JOIN`, `GROUP BY`, `ORDER BY` | Operasi Set: `INTERSECT`, `EXCEPT` | Perintah DDL mendalam: `ALTER TABLESPACE`, `VACUUM` |
| **Kalkulasi** | Agregasi, `CASE WHEN`, Window Functions (`RANK`, `LAG`) | Regular Expression SQL (`REGEXP_MATCHES`) | Menulis *Stored Procedures* & *Triggers* kompleks |
| **Validasi & Audit** | Deteksi *Fan-out*, cek kunci unik, rekonsiliasi baris | Execution Plan dasar (`EXPLAIN`) | Tuning parameter memori buffer / WAL PostgreSQL |
| **Arsitektur** | CTE (`WITH`), Views, Indeks dasar | Materialized Views, Partisi Tabel | Manajemen replikasi server, kluster multi-node |

---
