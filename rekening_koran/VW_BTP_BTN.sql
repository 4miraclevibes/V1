-- View untuk menampilkan data BTP dan BTN yang unik dari MP_CUSTOMER_NEW
CREATE VIEW [dbo].[VW_BTP_BTN] AS
SELECT DISTINCT [btp]
      ,[btn]
  FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
  WHERE [btp] IS NOT NULL 
    AND [btn] IS NOT NULL
GO

-- Verifikasi view berhasil dibuat
SELECT COUNT(*) as 'Total Unique BTP_BTN' FROM [POWERAPPS].[dbo].[VW_BTP_BTN]
SELECT TOP 10 * FROM [POWERAPPS].[dbo].[VW_BTP_BTN]
GO

PRINT 'View VW_BTP_BTN berhasil dibuat!'
