-- =====================================================
-- SP_EXPORT_JURNAL_CSV_PIPE
-- =====================================================
-- Purpose: Export data MP_JURNAL ke format CSV dengan separator PIPE (|)
--          Return: 1 row, 1 column (CSVContent) = full CSV string
--          Bisa di-copy dari SSMS & paste ke file .csv / .psv
-- =====================================================

USE [POWERAPPS]
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_EXPORT_JURNAL_CSV_PIPE]
    @StartDate NVARCHAR(50) = NULL,
    @EndDate   NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDateOnly DATE = NULL;
    DECLARE @EndDateOnly   DATE = NULL;

    IF @StartDate IS NOT NULL AND LEN(LTRIM(RTRIM(@StartDate))) > 0
        SET @StartDateOnly = TRY_CAST(LTRIM(RTRIM(@StartDate)) AS DATE);
    IF @EndDate IS NOT NULL AND LEN(LTRIM(RTRIM(@EndDate))) > 0
        SET @EndDateOnly = TRY_CAST(LTRIM(RTRIM(@EndDate)) AS DATE);

    -- Build CSV: data rows saja (tanpa header)
    -- Pakai FOR XML PATH (bukan STRING_AGG) agar support NVARCHAR(MAX) - menghindari limit 8000 bytes
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
                ISNULL(CAST(CAST([amount] AS INT) AS NVARCHAR(50)), ''),
                ISNULL(CONVERT(NVARCHAR(10), [value_date], 104), ''),
                REPLACE(ISNULL([assignment], ''), '|', ' '),
                REPLACE(ISNULL([text], ''), '|', ' '),
                UPPER(REPLACE(ISNULL([profit_center], ''), '|', ' '))
                -- REPLACE(ISNULL([cost_center], ''), '|', ' '),
                -- REPLACE(ISNULL([order_no], ''), '|', ' '),
                -- REPLACE(ISNULL([tax_code], ''), '|', ' '),
                -- '',
                -- '',
                -- REPLACE(ISNULL([customer2], ''), '|', ' '),
                -- REPLACE(ISNULL([sales_organization], ''), '|', ' '),
                -- REPLACE(ISNULL([reason_code], ''), '|', ' ')
            ) + CHAR(13) + CHAR(10)
        FROM [dbo].[MP_JURNAL]
        WHERE (@StartDateOnly IS NULL OR [document_date] >= @StartDateOnly)
          AND (@EndDateOnly   IS NULL OR [document_date] <= @EndDateOnly)
        ORDER BY [posting_date] ASC, [no_urut] ASC, [company_code] ASC, [row_line], [id]
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)');

    -- Decode XML entities (FOR XML encodes & < >)
    IF @DataRows IS NOT NULL
        SET @DataRows = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@DataRows, '&amp;', '&'), '&lt;', '<'), '&gt;', '>'), '&quot;', '"'), '&#x0D;', CHAR(13));

    SET @CSVContent = ISNULL(@DataRows, '');

    -- Return 1 row dengan full CSV content (pipe-separated)
    SELECT @CSVContent AS CSVContent;

END
GO

PRINT 'SP_EXPORT_JURNAL_CSV_PIPE created successfully.';
PRINT '';
PRINT 'Usage:';
PRINT '  EXEC SP_EXPORT_JURNAL_CSV_PIPE;  -- Export semua (pipe separator)';
PRINT '  EXEC SP_EXPORT_JURNAL_CSV_PIPE @StartDate = ''2025-01-01'', @EndDate = ''2025-01-31'';';
PRINT '';
PRINT 'Output: 1 column CSVContent = full CSV string. Copy & paste ke file .csv atau .psv';
GO
