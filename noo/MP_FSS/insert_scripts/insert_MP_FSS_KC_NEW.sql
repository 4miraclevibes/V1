-- Truncate table
TRUNCATE TABLE [POWERAPPS].[dbo].[MP_FSS_KC_NEW];

-- Insert data from CSV table
INSERT INTO [POWERAPPS].[dbo].[MP_FSS_KC_NEW]
(
    [market_channel]
    ,[customer_code]
    ,[customer_name]
    ,[kabupaten_kota]
    ,[fss_name]
    ,[fss_code]
    ,[fss_type]
    ,[sales_executive]
    ,[RSM]
    ,[status]
    ,[desc]
    ,[created_at]
    ,[updated_at]
)
SELECT 
    [market_channel]
    ,[customer_code]
    ,[customer_name]
    ,[kabupaten_kota]
    ,[fss_name]
    ,[fss_code]
    ,[fss_type]
    ,[sales_executive]
    ,[RSM]
    ,'active' AS [status]
    ,NULL AS [desc]
    ,GETDATE() AS [created_at]
    ,GETDATE() AS [updated_at]
FROM [POWERAPPS].[dbo].[MP_FSS_KC_NEW_21_11_2025];

