-- Script untuk insert data btp dan btn dari MP_CUSTOMER_NEW ke MASTER_KEY
-- Mengambil data dari disticn.sql dan insert ke tabel MASTER_KEY

-- Insert data btp dan btn dari MP_CUSTOMER_NEW ke MASTER_KEY
INSERT INTO [POWERAPPS].[dbo].[MASTER_KEY] ([btp], [btn])
SELECT DISTINCT [btp], [btn]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
WHERE [btp] IS NOT NULL 
  AND [btn] IS NOT NULL
  AND [btp] != ''
  AND [btn] != ''
GO

-- Verifikasi hasil insert
SELECT COUNT(*) as 'Total Records Inserted' FROM [POWERAPPS].[dbo].[MASTER_KEY]
SELECT TOP 10 * FROM [POWERAPPS].[dbo].[MASTER_KEY]
GO

PRINT 'Data btp dan btn berhasil diinsert ke tabel MASTER_KEY!'
