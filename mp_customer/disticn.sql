SELECT DISTINCT [btp]
      ,[btn]
  FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
  WHERE [btp] IS NOT NULL AND [btn] IS NOT NULL

-- Cek jumlah data unik berdasarkan btp
SELECT COUNT(DISTINCT [btp]) as 'Total Unique BTP' 
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
WHERE [btp] IS NOT NULL AND [btn] IS NOT NULL
