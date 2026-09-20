SELECT * FROM dim_pelanggan;
SELECT * FROM dim_produk;
SELECT * FROM dim_toko;
SELECT * FROM fact_penjualan_header;
SELECT * FROM fact_penjualan_detail;

--Tantangan : 1.1 Audit kasir ingin melihat transaksi sukses di bulan Januari 2026 dengan total belanja > Rp 300.000.
--Target Grain : 1 baris = 1 transaksi struk kasir (transaksi_id)

SELECT 
	transaksi_id, 
	tanggal_transaksi,
	status_transaksi,
	total_nilai_transaksi
FROM fact_penjualan_header
WHERE 
	status_transaksi IN ('PAID', 'COMPLETED') AND
	tanggal_transaksi >= '2026-01-01 00:00:00' AND tanggal_transaksi < '2026-02-01 00:00:00' AND 
	total_nilai_transaksi > 300000
ORDER BY total_nilai_transaksi DESC;

--Sanity Check
SELECT DISTINCT status_transaksi
FROM fact_penjualan_header
WHERE 
    status_transaksi IN ('PAID', 'COMPLETED') 
    AND tanggal_transaksi >= '2026-01-01 00:00:00' 
    AND tanggal_transaksi < '2026-02-01 00:00:00' 
    AND total_nilai_transaksi > 300000;

--Tantangan : 1.2 Divisi Merchandising meminta daftar seluruh produk kategori Minuman yang aktif.
--Target Grain : 1 baris = 1 produk unik (produk_id)

SELECT 
	produk_id,
	nama_produk,
	UPPER(TRIM(kategori)) AS kategori_bersih,
	harga_beli_hpp,
	harga_jual_standar
FROM dim_produk
WHERE TRIM(kategori) ILIKE 'minuman';

-- Sanity Check
SELECT DISTINCT UPPER(TRIM(kategori)) AS kategori_bersih
FROM dim_produk
WHERE TRIM(kategori) ILIKE 'minuman';

--Tantangan : 1.3 Manajemen ingin melihat 25 transaksi non-tunai (QRIS dan DEBIT) bernilai tertinggi di seluruh cabang.
--Target Grain : 1 baris = 1 struk transaksi kasir (transaksi_id)

SELECT
	transaksi_id,
	toko_id,
	total_nilai_transaksi,
	tipe_pembayaran,
	status_transaksi
FROM fact_penjualan_header
WHERE tipe_pembayaran IN ('QRIS', 'DEBIT') AND 
	status_transaksi IN ('PAID', 'COMPLETED')
ORDER BY total_nilai_transaksi DESC LIMIT 25;

-- Sanity Check
SELECT DISTINCT
	tipe_pembayaran,
	status_transaksi
FROM fact_penjualan_header
WHERE tipe_pembayaran IN ('QRIS', 'DEBIT') AND 
	status_transaksi IN ('PAID', 'COMPLETED');