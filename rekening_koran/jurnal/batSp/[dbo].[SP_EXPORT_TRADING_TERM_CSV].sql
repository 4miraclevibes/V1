USE [POWERAPPS]
GO
/****** Object:  StoredProcedure [dbo].[SP_EXPORT_TRADING_TERM_CSV]    Script Date: 26/02/2026 13:30:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_EXPORT_TRADING_TERM_CSV]
    @TradingTermNumber NVARCHAR(MAX) = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @Year INT = NULL,
    @Customer NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Build the file name for the CSV export
    -- Use a short filename (under 20 characters): prefix 'tt' + last 10 digits of unix timestamp + '.csv'
    DECLARE @fileName NVARCHAR(4000)
    DECLARE @unixTimestamp BIGINT
    DECLARE @shortStamp NVARCHAR(20)
    SET @unixTimestamp = DATEDIFF(SECOND, '1970-01-01', GETUTCDATE())
    SET @shortStamp = RIGHT(CAST(@unixTimestamp AS NVARCHAR(20)), 10)
    SET @fileName = 'C:\SPECIALPRICE\tt' + @shortStamp + '.csv'

    -- Build the dynamic SQL for filtering
    DECLARE @sql NVARCHAR(MAX)
    SET @sql = 'SELECT ''A914~'' + [Condition type] AS [Table], [Sales Office], [Customer group], Customer, Material, CAST([Currency amount in BAPI in] AS INT) AS [Currency amount in BAPI in], [Condition currency], [Pricing unit], [Unit of measure], [Valid From], [Valid To], '''' AS [Condition record no.] FROM [POWERAPPS].[dbo].[VW_LSMW_ACCOUNT_EXPANDED] WHERE 1=1'

    IF @TradingTermNumber IS NOT NULL AND LEN(@TradingTermNumber) > 0
        SET @sql = @sql + ' AND [Trading Term Number] IN (SELECT TRIM(value) FROM STRING_SPLIT(''' + @TradingTermNumber + ''', '',''))'
    IF @Year IS NOT NULL
        SET @sql = @sql + ' AND [Valid From] LIKE ''%' + CAST(@Year AS NVARCHAR(10)) + '%'''
    IF @StartDate IS NOT NULL
        SET @sql = @sql + ' AND CONVERT(date, [Valid From], 104) >= ''' + CONVERT(NVARCHAR(10), @StartDate, 120) + ''''
    IF @EndDate IS NOT NULL
        SET @sql = @sql + ' AND CONVERT(date, [Valid From], 104) <= ''' + CONVERT(NVARCHAR(10), @EndDate, 120) + ''''
    IF @Customer IS NOT NULL AND LEN(@Customer) > 0
    BEGIN
        -- If @Customer contains commas, treat as a list of tokens; match exact Customer codes or partial Customer Name
        IF CHARINDEX(',', @Customer) > 0
            SET @sql = @sql + ' AND EXISTS (SELECT 1 FROM STRING_SPLIT(''' + REPLACE(@Customer, '''', '''''') + ''', '','') s WHERE [Customer] = TRIM(s.value) OR [Customer Name] LIKE ''%'' + TRIM(s.value) + ''%'')'
        ELSE
            SET @sql = @sql + ' AND ( [Customer] = ''' + REPLACE(@Customer, '''', '''''') + ''' OR [Customer Name] LIKE ''%'+ REPLACE(@Customer, '''', '''''') + '%'' )'
    END

    -- SET @sql = @sql + ' AND CONVERT(date, GETDATE()) BETWEEN CONVERT(date, [Valid From], 104) AND CONVERT(date, [Valid To], 104)'

    -- Generate the CSV file using sqlcmd and xp_cmdshell
    DECLARE @cmd NVARCHAR(4000)
    SET @cmd = 'sqlcmd -h-1 -U sa -P gfiok -Q "SET NOCOUNT ON; ' + REPLACE(@sql, '"', '""') + '" -o "' + @fileName + '" -s "|" -W'
    EXEC master..xp_cmdshell @cmd

    -- Call a batch file to move/upload the file
    EXEC master..xp_cmdshell 'C:\SPECIALPRICE\copy-file.bat'
END