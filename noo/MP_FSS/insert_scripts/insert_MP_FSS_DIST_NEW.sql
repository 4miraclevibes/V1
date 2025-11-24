-- Truncate table
TRUNCATE TABLE [POWERAPPS].[dbo].[MP_FSS_DIST_NEW];

-- Insert data from CSV table
INSERT INTO [POWERAPPS].[dbo].[MP_FSS_DIST_NEW]
(
    [distributor]
    ,[region]
    ,[fresh_dry]
    ,[market_channel]
    ,[fss_name]
    ,[fss_code]
    ,[fss_type]
    ,[rsm]
    ,[status]
    ,[desc]
    ,[created_at]
    ,[updated_at]
)
SELECT 
    [distributor]
    ,[region]
    ,[fresh_dry]
    ,[market_channel]
    ,[fss_name]
    ,[fss_code]
    ,[fss_type]
    ,[rsm]
    ,'active' AS [status]
    ,NULL AS [desc]
    ,GETDATE() AS [created_at]
    ,GETDATE() AS [updated_at]
FROM [POWERAPPS].[dbo].[MP_FSS_DIST_NEW_21_11_2025];

