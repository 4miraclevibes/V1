-- Query untuk mengambil data distinct channel dan KAM dari VW_ACCOUNT
SELECT DISTINCT 
    [ChanelId],
    [ChanelName],
    [Kam]
FROM [POWERAPPS].[dbo].[VW_ACCOUNT]
WHERE [ChanelId] IS NOT NULL 
    AND [ChanelName] IS NOT NULL 
    AND [Kam] IS NOT NULL
    AND [status] = 'active'
    AND [Kam] NOT IN ('VACANT', 'belum ada')
    AND [Kam] NOT LIKE '%no'
ORDER BY [ChanelName], [Kam]
GO
