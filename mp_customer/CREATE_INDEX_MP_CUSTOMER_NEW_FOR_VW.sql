-- Index pendukung performa VW_MP_CUSTOMER
-- Jalankan sekali di SQL Server (bukan bagian view)

USE [POWERAPPS];
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_MP_CUSTOMER_NEW_distributor_id'
      AND object_id = OBJECT_ID('dbo.MP_CUSTOMER_NEW')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_MP_CUSTOMER_NEW_distributor_id]
        ON [dbo].[MP_CUSTOMER_NEW] ([distributor_id])
        INCLUDE ([code], [updated_at], [id]);
    PRINT 'Index IX_MP_CUSTOMER_NEW_distributor_id dibuat';
END
ELSE
    PRINT 'Index IX_MP_CUSTOMER_NEW_distributor_id sudah ada';
GO

-- code kemungkinan NVARCHAR(MAX) -> tidak bisa dijadikan key index.
-- Jika code sudah diubah ke NVARCHAR(100) atau lebih kecil, aktifkan blok di bawah:

/*
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_MP_CUSTOMER_NEW_code_updated'
      AND object_id = OBJECT_ID('dbo.MP_CUSTOMER_NEW')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_MP_CUSTOMER_NEW_code_updated]
        ON [dbo].[MP_CUSTOMER_NEW] ([code], [updated_at] DESC, [id] DESC)
        INCLUDE ([distributor_id]);
    PRINT 'Index IX_MP_CUSTOMER_NEW_code_updated dibuat';
END
*/
GO
