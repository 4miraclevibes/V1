-- =====================================================
-- SP_EXPORT_JURNAL
-- =====================================================
-- Purpose: Stored Procedure untuk export data dari MP_JURNAL ke CSV
--          Support filter parameters untuk Power Automate
--          Compatible dengan on-premises gateway
-- =====================================================

USE [POWERAPPS]
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_EXPORT_JURNAL]
    @StartDate NVARCHAR(50) = NULL,
    @EndDate   NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Convert string dates ke DATE (handle NULL dan empty string)
    DECLARE @StartDateOnly DATE = NULL;
    DECLARE @EndDateOnly   DATE = NULL;

    IF @StartDate IS NOT NULL AND LEN(LTRIM(RTRIM(@StartDate))) > 0
    BEGIN
        SET @StartDateOnly = TRY_CAST(LTRIM(RTRIM(@StartDate)) AS DATE);
    END

    IF @EndDate IS NOT NULL AND LEN(LTRIM(RTRIM(@EndDate))) > 0
    BEGIN
        SET @EndDateOnly = TRY_CAST(LTRIM(RTRIM(@EndDate)) AS DATE);
    END

    -- Hanya kolom DOKUMEN DATA sesuai flow.txt (tanpa no_urut, row_line, source_rk_id, created_at)
    SELECT
        [document_date]        AS DocumentDate,
        [document_type]        AS DocumentType,
        [company_code]         AS CompanyCode,
        [posting_date]         AS PostingDate,
        [currency]             AS Currency,
        [country_grouping]     AS CountryGrouping,
        [reference]            AS Reference,
        [material]             AS Material,
        [document_header_text] AS DocumentHeaderText,
        [posting_key]          AS PostingKey,
        [customer]             AS Customer,
        [account]              AS Account,
        [special]              AS Special,
        [amount]               AS Amount,
        [value_date]           AS ValueDate,
        [assignment]           AS Assignment,
        [text]                 AS Text,
        [profit_center]        AS ProfitCenter,
        [cost_center]          AS CostCenter,
        [order_no]             AS [Order],
        [tax_code]             AS TaxCode,
        [customer2]            AS Customer2,
        [sales_organization]   AS SalesOrganization,
        [reason_code]          AS ReasonCode
    FROM [dbo].[MP_JURNAL]
    WHERE
        (@StartDateOnly IS NULL OR [document_date] >= @StartDateOnly)
        AND (@EndDateOnly   IS NULL OR [document_date] <= @EndDateOnly)
    ORDER BY [document_date], [reference], [row_line], [id];

END
GO

PRINT 'SP_EXPORT_JURNAL created successfully.';
PRINT '';
PRINT 'Usage:';
PRINT '  EXEC SP_EXPORT_JURNAL;  -- Export semua data jurnal';
PRINT '  EXEC SP_EXPORT_JURNAL @StartDate = ''2025-01-01'', @EndDate = ''2025-01-31'';';
GO
