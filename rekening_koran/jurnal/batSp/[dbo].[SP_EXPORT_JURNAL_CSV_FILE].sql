-- =====================================================
-- SP_EXPORT_JURNAL_CSV_FILE
-- =====================================================
-- Purpose: Export data MP_JURNAL ke CSV file (pipe separator)
--          Sama format dengan SP_EXPORT_JURNAL_CSV_PIPE & success.csv
--          File disimpan ke C:\REKENINGKORAN\ lalu batch copy ke network
--
-- Cara: Build CSV pakai FOR XML PATH (sama PIPE), tulis ke file via PowerShell
-- =====================================================

USE [POWERAPPS]
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_EXPORT_JURNAL_CSV_FILE]
    @StartDate NVARCHAR(50) = NULL,
    @EndDate   NVARCHAR(50) = NULL,
    @Id        BIGINT       = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDateOnly DATE = NULL;
    DECLARE @EndDateOnly DATE = NULL;
    IF @StartDate IS NOT NULL AND LEN(LTRIM(RTRIM(@StartDate))) > 0
        SET @StartDateOnly = TRY_CAST(LTRIM(RTRIM(@StartDate)) AS DATE);
    IF @EndDate IS NOT NULL AND LEN(LTRIM(RTRIM(@EndDate))) > 0
        SET @EndDateOnly = TRY_CAST(LTRIM(RTRIM(@EndDate)) AS DATE);

    -- Build file name
    DECLARE @shortStamp VARCHAR(20);
    DECLARE @fileName VARCHAR(500);
    SET @shortStamp = RIGHT(CAST(DATEDIFF(SECOND, '1970-01-01', GETUTCDATE()) AS VARCHAR(20)), 10);
    SET @fileName = 'C:\REKENINGKORAN\GDI_MAULANAP_' + @shortStamp + '.csv';

    -- Pastikan folder ada
    EXEC master..xp_cmdshell 'if not exist C:\REKENINGKORAN mkdir C:\REKENINGKORAN';

    -- Build CSV: SAMA PERSIS dengan SP_EXPORT_JURNAL_CSV_PIPE
    DECLARE @CSVContent NVARCHAR(MAX);
    DECLARE @DataRows NVARCHAR(MAX);

    SELECT @DataRows = (
        SELECT CONCAT_WS('|',
                ISNULL(CONVERT(NVARCHAR(10), [document_date], 104), ''),
                REPLACE(ISNULL([document_type], ''), '|', ' '),
                UPPER(REPLACE(ISNULL([company_code], ''), '|', ' ')),
                ISNULL(CONVERT(NVARCHAR(10), [posting_date], 104), ''),
                ISNULL(RIGHT('0' + CAST(MONTH([posting_date]) AS NVARCHAR(2)), 2), ''),
                REPLACE(ISNULL([currency], ''), '|', ' '),
                REPLACE(ISNULL([country_grouping], ''), '|', ' '),
                REPLACE(ISNULL([reference], ''), '|', ' '),
                REPLACE(ISNULL([material], ''), '|', ' '),
                REPLACE(ISNULL([document_header_text], ''), '|', ' '),
                REPLACE(ISNULL([posting_key], ''), '|', ' '),
                REPLACE(ISNULL([customer], ''), '|', ' '),
                REPLACE(ISNULL([account], ''), '|', ' '),
                REPLACE(ISNULL([special], ''), '|', ' '),
                ISNULL(CAST(CAST(ROUND([amount], 0) AS BIGINT) AS NVARCHAR(50)), ''),
                ISNULL(CONVERT(NVARCHAR(10), [value_date], 104), ''),
                REPLACE(ISNULL([assignment], ''), '|', ' '),
                REPLACE(ISNULL([text], ''), '|', ' '),
                UPPER(REPLACE(ISNULL([profit_center], ''), '|', ' '))
            ) + CHAR(13) + CHAR(10)
        FROM [dbo].[MP_JURNAL]
        WHERE (@Id IS NULL OR [source_rk_id] = @Id)
          AND (@StartDateOnly IS NULL OR [document_date] >= @StartDateOnly)
          AND (@EndDateOnly IS NULL OR [document_date] <= @EndDateOnly)
        ORDER BY [posting_date] ASC, [no_urut] ASC, [company_code] ASC, [row_line], [id]
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)');

    -- Decode XML entities
    IF @DataRows IS NOT NULL
        SET @DataRows = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@DataRows, '&amp;', '&'), '&lt;', '<'), '&gt;', '>'), '&quot;', '"'), '&#x0D;', CHAR(13));

    SET @CSVContent = ISNULL(@DataRows, '');

    -- Tulis ke file: gunakan tabel 1 row + BCP (1 row = tidak ada extra newline)
    IF OBJECT_ID('tempdb..##JurnalExportSingle') IS NOT NULL
        DROP TABLE ##JurnalExportSingle;
    CREATE TABLE ##JurnalExportSingle (Content NVARCHAR(MAX));
    INSERT INTO ##JurnalExportSingle (Content) VALUES (@CSVContent);

    DECLARE @cmd VARCHAR(8000);
    SET @cmd = 'bcp "SELECT Content FROM ##JurnalExportSingle" queryout "' + @fileName + '" -c -t"" -S localhost -d POWERAPPS -U sa -P gfiok';
    EXEC master..xp_cmdshell @cmd;

    DROP TABLE ##JurnalExportSingle;

    -- Copy ke network (rekeningkoran dulu, HRIS terakhir - file terbaru dari SQL ada di REKENINGKORAN)
    EXEC master..xp_cmdshell 'C:\REKENINGKORAN\copy-rekeningkoran.bat';
    EXEC master..xp_cmdshell 'C:\REKENINGKORAN\copy-jurnal-terbaru-ke-hris.bat';
    -- Copy ke PRD
    EXEC master..xp_cmdshell 'C:\REKENINGKORAN\copy-rekeningkoran-prd.bat';
    EXEC master..xp_cmdshell 'C:\REKENINGKORAN\copy-jurnal-terbaru-ke-hris-prd.bat';
END
GO

PRINT 'SP_EXPORT_JURNAL_CSV_FILE created.';
PRINT 'Usage: EXEC SP_EXPORT_JURNAL_CSV_FILE @StartDate = ''2025-01-01'', @EndDate = ''2025-01-31'';';
PRINT '       EXEC SP_EXPORT_JURNAL_CSV_FILE @Id = 12345;  -- export per 1 baris RK (source_rk_id)';
PRINT 'Output: C:\REKENINGKORAN\GDI_MAULANAP_{timestamp}.csv';
GO
