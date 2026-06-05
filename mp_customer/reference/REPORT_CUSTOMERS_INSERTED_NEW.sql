-- =====================================================
-- REPORT_CUSTOMERS_INSERTED_NEW.sql
-- =====================================================
-- Menampilkan customer yang baru di-insert oleh
-- SYNC_INSERT_MP_CUSTOMER_FROM_REFERENCE.sql
--
-- Jalankan SETELAH script sync.
-- Default: run terakhir. Ubah @SyncRunAt jika perlu run tertentu.
-- =====================================================

USE POWERAPPS;
GO

DECLARE @SyncRunAt DATETIME;

SELECT @SyncRunAt = MAX([sync_run_at])
FROM [dbo].[MP_CUSTOMER_REF_SYNC_INSERT_LOG];

IF @SyncRunAt IS NULL
BEGIN
    PRINT 'Belum ada data log insert. Jalankan SYNC_INSERT_MP_CUSTOMER_FROM_REFERENCE.sql terlebih dahulu.';
END
ELSE
BEGIN
    PRINT 'Laporan customer baru di-insert';
    PRINT 'Sync run at: ' + CONVERT(VARCHAR, @SyncRunAt, 120);
    PRINT '';
END

-- Ringkasan
SELECT
    @SyncRunAt AS SyncRunAt,
    COUNT(*) AS TotalInserted
FROM [dbo].[MP_CUSTOMER_REF_SYNC_INSERT_LOG]
WHERE [sync_run_at] = @SyncRunAt;

-- Detail customer yang di-insert
SELECT
    l.[sync_run_at],
    l.[new_customer_id],
    l.[customer_code],
    l.[customer_name],
    l.[distributor_name],
    l.[distributor_id],
    l.[account_name],
    l.[account_id],
    l.[regency_name],
    l.[regency_id],
    c.[status],
    c.[created_at],
    c.[updated_at]
FROM [dbo].[MP_CUSTOMER_REF_SYNC_INSERT_LOG] l
LEFT JOIN [dbo].[MP_CUSTOMER_NEW] c
    ON c.[id] = l.[new_customer_id]
WHERE l.[sync_run_at] = @SyncRunAt
ORDER BY l.[customer_code];
GO
