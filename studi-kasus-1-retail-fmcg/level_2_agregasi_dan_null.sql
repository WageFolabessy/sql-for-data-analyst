SELECT * FROM dim_pelanggan;
SELECT * FROM dim_produk;
SELECT * FROM dim_toko;
SELECT * FROM fact_penjualan_header;
SELECT * FROM fact_penjualan_detail;

--Tantangan : 2.1 Direktur Keuangan ingin mengetahui perbandingan omzet kotor, total diskon, dan omzet bersih di setiap cabang toko.
--Target Grain : 1 baris = 1 toko (toko_id)

SELECT
	fph.toko_id,
	SUM(fpd.kuantitas * fpd.harga_jual_aktual) AS total_omzet_kotor,
	SUM(COALESCE(fpd.diskon_nominal, 0)) AS total_diskon,
--	SUM((fpd.kuantitas * fpd.harga_jual_aktual) - fpd.diskon_nominal) AS total_omzet_bersih_tanpa_coalesce,
	SUM(fpd.kuantitas * fpd.harga_jual_aktual) - SUM(COALESCE(fpd.diskon_nominal, 0)) AS total_omzet_bersih
FROM fact_penjualan_header fph
INNER JOIN fact_penjualan_detail fpd
	ON fph.transaksi_id = fpd.transaksi_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY fph.toko_id
ORDER BY toko_id;

-- Sanity Check
SELECT
    COUNT(*) AS total_baris_item,
    COUNT(fpd.diskon_nominal) AS baris_dengan_diskon,
    COUNT(*) - COUNT(fpd.diskon_nominal) AS baris_diskon_null_diselamatkan
FROM fact_penjualan_header fph
INNER JOIN fact_penjualan_detail fpd 
    ON fph.transaksi_id = fpd.transaksi_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED');

--Tantangan : 2.2 Divisi Digital Banking ingin mengevaluasi penetrasi penggunaan QRIS di setiap toko.
--Target Grain : 1 baris = 1 toko (toko_id)

SELECT
	toko_id,
	COUNT(transaksi_id) AS total_transaksi,
	COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') AS total_trx_qris,
	ROUND(100.0 * COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') / COUNT(*), 2) AS pct_qris
FROM fact_penjualan_header
WHERE status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY toko_id;

-- Sanity Check
SELECT
    toko_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE tipe_pembayaran = 'QRIS') / COUNT(*), 2) AS pct_qris
FROM fact_penjualan_header
WHERE status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY toko_id
ORDER BY pct_qris ASC
LIMIT 1;

--Tantangan : 2.3 Temukan cabang toko yang total realisasi penjualan bersihnya di Q1 2026 masih berada di bawah target omzet bulanan cabang tersebut (target_omzet_bulanan).
--Target Grain : 1 baris = 1 toko (toko_id)

SELECT
	dt.toko_id,
	dt.nama_toko,
	SUM(fph.total_nilai_transaksi) AS total_realisasi,
	dt.target_omzet_bulanan
FROM dim_toko dt
INNER JOIN fact_penjualan_header fph
	ON dt.toko_id = fph.toko_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY dt.toko_id, dt.nama_toko, dt.target_omzet_bulanan
HAVING SUM(fph.total_nilai_transaksi) < dt.target_omzet_bulanan;

-- Sanity Check
SELECT
    dt.toko_id,
    SUM(fph.total_nilai_transaksi) AS realisasi,
    dt.target_omzet_bulanan,
    SUM(fph.total_nilai_transaksi) - dt.target_omzet_bulanan AS kelebihan_omzet
FROM dim_toko dt
INNER JOIN fact_penjualan_header fph 
    ON dt.toko_id = fph.toko_id
WHERE fph.status_transaksi IN ('PAID', 'COMPLETED')
GROUP BY dt.toko_id, dt.nama_toko, dt.target_omzet_bulanan
HAVING SUM(fph.total_nilai_transaksi) >= dt.target_omzet_bulanan;
