-- =====================================================
-- REPORT_CUSTOMERS_LOOKUP_NOT_FOUND.sql
-- =====================================================
-- Menampilkan customer (kandidat insert) yang nama relasinya
-- tidak ditemukan di tabel master:
--   - Distributors (distributor_name)
--   - Accounts (account_name)
--   - Regencies (regency_name)
--
-- Catatan: customer tetap di-insert dengan ID = NULL.
-- Jalankan SETELAH script sync.
-- =====================================================

USE POWERAPPS;
GO

DECLARE @SyncRunAt DATETIME;

SELECT @SyncRunAt = MAX([sync_run_at])
FROM [dbo].[MP_CUSTOMER_REF_SYNC_LOOKUP_MISS_LOG];

IF @SyncRunAt IS NULL
BEGIN
    PRINT 'Belum ada data log lookup miss. Jalankan SYNC_INSERT_MP_CUSTOMER_FROM_REFERENCE.sql terlebih dahulu.';
END
ELSE
BEGIN
    PRINT 'Laporan customer dengan relasi tidak ditemukan';
    PRINT 'Sync run at: ' + CONVERT(VARCHAR, @SyncRunAt, 120);
    PRINT '';
END

-- Ringkasan per jenis miss
SELECT
    @SyncRunAt AS SyncRunAt,
    COUNT(*) AS TotalRowsWithMiss,
    SUM(CASE WHEN [miss_distributor] = 1 THEN 1 ELSE 0 END) AS MissDistributorCount,
    SUM(CASE WHEN [miss_account] = 1 THEN 1 ELSE 0 END) AS MissAccountCount,
    SUM(CASE WHEN [miss_regency] = 1 THEN 1 ELSE 0 END) AS MissRegencyCount
FROM [dbo].[MP_CUSTOMER_REF_SYNC_LOOKUP_MISS_LOG]
WHERE [sync_run_at] = @SyncRunAt;

-- Detail
SELECT
    [sync_run_at],
    [customer_code],
    [customer_name],
    [distributor_name],
    CASE WHEN [miss_distributor] = 1 THEN 'TIDAK DITEMUKAN' ELSE 'OK' END AS distributor_lookup,
    [account_name],
    CASE WHEN [miss_account] = 1 THEN 'TIDAK DITEMUKAN' ELSE 'OK' END AS account_lookup,
    [regency_name],
    CASE WHEN [miss_regency] = 1 THEN 'TIDAK DITEMUKAN' ELSE 'OK' END AS regency_lookup
FROM [dbo].[MP_CUSTOMER_REF_SYNC_LOOKUP_MISS_LOG]
WHERE [sync_run_at] = @SyncRunAt
ORDER BY [customer_code];
GO

-- Preview live (tanpa log): kandidat insert berikutnya yang akan miss lookup
PRINT '';
PRINT '--- Preview kandidat BERIKUTNYA (belum insert, lookup miss) ---';

SELECT
    r.[customer_code],
    r.[customer_name],
    r.[distributor_name],
    CASE
        WHEN ISNULL(LTRIM(RTRIM(r.[distributor_name])), '') = '' THEN 'KOSONG'
        WHEN dist.[distributor_id] IS NULL THEN 'TIDAK DITEMUKAN'
        ELSE 'OK'
    END AS distributor_lookup,
    r.[account_name],
    CASE
        WHEN ISNULL(LTRIM(RTRIM(r.[account_name])), '') = '' THEN 'KOSONG'
        WHEN acc.[account_id] IS NULL THEN 'TIDAK DITEMUKAN'
        ELSE 'OK'
    END AS account_lookup,
    r.[regency_name],
    CASE
        WHEN ISNULL(LTRIM(RTRIM(r.[regency_name])), '') = '' THEN 'KOSONG'
        WHEN reg.[regency_id] IS NULL THEN 'TIDAK DITEMUKAN'
        ELSE 'OK'
    END AS regency_lookup
FROM [dbo].[MP_CUSTOMER_REFERENCE_03_06_2026] r
OUTER APPLY (
    SELECT MIN(d.[Id]) AS [distributor_id]
    FROM [dbo].[Distributors] d
    WHERE ISNULL(LTRIM(RTRIM(r.[distributor_name])), '') <> ''
      AND LTRIM(RTRIM(ISNULL(d.[Distributor], ''))) COLLATE Latin1_General_CI_AI
          = LTRIM(RTRIM(r.[distributor_name])) COLLATE Latin1_General_CI_AI
) dist
OUTER APPLY (
    SELECT MIN(a.[id]) AS [account_id]
    FROM [dbo].[Accounts] a
    WHERE ISNULL(LTRIM(RTRIM(r.[account_name])), '') <> ''
      AND LTRIM(RTRIM(ISNULL(a.[account], ''))) COLLATE Latin1_General_CI_AI
          = LTRIM(RTRIM(r.[account_name])) COLLATE Latin1_General_CI_AI
) acc
OUTER APPLY (
    SELECT MIN(rg.[id]) AS [regency_id]
    FROM [dbo].[Regencies] rg
    WHERE ISNULL(LTRIM(RTRIM(r.[regency_name])), '') <> ''
      AND LTRIM(RTRIM(ISNULL(rg.[kota], ''))) COLLATE Latin1_General_CI_AI
          = LTRIM(RTRIM(r.[regency_name])) COLLATE Latin1_General_CI_AI
) reg
WHERE ISNULL(LTRIM(RTRIM(r.[customer_code])), '') <> ''
  AND NOT EXISTS (
      SELECT 1
      FROM [dbo].[MP_CUSTOMER_NEW] c
      WHERE LTRIM(RTRIM(ISNULL(c.[code], ''))) COLLATE Latin1_General_CI_AI
            = LTRIM(RTRIM(r.[customer_code])) COLLATE Latin1_General_CI_AI
  )
  AND (
        (ISNULL(LTRIM(RTRIM(r.[distributor_name])), '') <> '' AND dist.[distributor_id] IS NULL)
     OR (ISNULL(LTRIM(RTRIM(r.[account_name])), '') <> '' AND acc.[account_id] IS NULL)
     OR (ISNULL(LTRIM(RTRIM(r.[regency_name])), '') <> '' AND reg.[regency_id] IS NULL)
  )
ORDER BY r.[customer_code];
GO
