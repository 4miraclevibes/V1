-- Truncate table
TRUNCATE TABLE [POWERAPPS].[dbo].[MP_FSS_OD_NEW];

-- Insert data from CSV table
INSERT INTO [POWERAPPS].[dbo].[MP_FSS_OD_NEW]
(
    [distributor]
    ,[market_channel]
    ,[customer_code]
    ,[customer_name]
    ,[kabupaten_kota]
    ,[fss_name]
    ,[fss_code]
    ,[fss_type]
    ,[sales_executive]
    ,[rsm]
    ,[status]
    ,[desc]
    ,[created_at]
    ,[updated_at]
)
SELECT 
    [distributor]
    ,[market_channel]
    ,[customer_code]
    ,[customer_name]
    ,[kabupaten_kota]
    ,[fss_name]
    ,[fss_code]
    ,[fss_type]
    ,[sales_executive]
    ,[rsm]
    ,'active' AS [status]
    ,NULL AS [desc]
    ,GETDATE() AS [created_at]
    ,GETDATE() AS [updated_at]
FROM [POWERAPPS].[dbo].[MP_FSS_OD_NEW_21_11_2025];

