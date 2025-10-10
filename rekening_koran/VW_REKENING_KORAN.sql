-- View untuk menampilkan data Rekening Koran
USE [POWERAPPS]
GO

CREATE VIEW [dbo].[VW_REKENING_KORAN] AS
SELECT [id]
      ,[trx_date]
      ,[created_at]
      ,[updated_at]
      ,[credit]
      ,[btp]
      ,[desc]
  FROM [POWERAPPS].[dbo].[MP_REKENING_KORAN]
GO

-- Verifikasi view berhasil dibuat
SELECT COUNT(*) as 'Total Records' FROM [POWERAPPS].[dbo].[VW_REKENING_KORAN]
SELECT TOP 10 * FROM [POWERAPPS].[dbo].[VW_REKENING_KORAN] ORDER BY [id] DESC
GO

PRINT 'View VW_REKENING_KORAN berhasil dibuat!'

