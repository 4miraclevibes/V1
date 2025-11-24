-- Truncate table
TRUNCATE TABLE [POWERAPPS].[dbo].[MP_FSS_DIRECT_NEW];

-- Insert data from CSV table
INSERT INTO [POWERAPPS].[dbo].[MP_FSS_DIRECT_NEW]
(
    [distributor]
    ,[customer_code]
    ,[customer_name]
    ,[fss_code]
    ,[fss_name]
    ,[fss_type]
    ,[sales_executive]
    ,[fresh_dry]
    ,[rsm]
    ,[status]
    ,[desc]
    ,[created_at]
    ,[updated_at]
)
SELECT 
    [distributor]
    ,[customer_code]
    ,[customer_name]
    ,[fss_code]
    ,[fss_name]
    ,[fss_type]
    ,[sales_executive]
    ,[fresh_dry]
    ,[rsm]
    ,'active' AS [status]
    ,NULL AS [desc]
    ,GETDATE() AS [created_at]
    ,GETDATE() AS [updated_at]
FROM [POWERAPPS].[dbo].[MP_FSS_DIRECT_NEW_21_11_2025];

