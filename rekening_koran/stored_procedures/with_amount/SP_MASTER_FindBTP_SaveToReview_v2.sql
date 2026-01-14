-- ═══════════════════════════════════════════════════════════════════════════
-- SP_MASTER_FindBTP_SaveToReview_v2
-- ═══════════════════════════════════════════════════════════════════════════
-- VERSION: 2.0 - Enhanced Amount & TransactionType handling
-- 
-- Perubahan dari v1:
--   1. Better logging untuk Amount parsing
--   2. Explicit Amount validation
--   3. Debug output untuk troubleshooting
--   4. Return Amount & TransactionType di summary
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_MASTER_FindBTP_SaveToReview_v2]
    @TransactionsJSON NVARCHAR(MAX),
    @BatchID NVARCHAR(100) = NULL,
    @UploadedBy NVARCHAR(255) = NULL,
    @Debug BIT = 0  -- Set to 1 for verbose output
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate BatchID if not provided
    IF @BatchID IS NULL
    BEGIN
        SET @BatchID = 'BATCH_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + 
                       REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
    END
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_SaveToReview_v2 - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'BatchID: ' + @BatchID;
    IF @UploadedBy IS NOT NULL
        PRINT 'Uploaded By: ' + @UploadedBy;
    PRINT '';
    
    -- Variables
    DECLARE @TotalTransactions INT;
    DECLARE @UploadTime DATETIME = GETDATE();
    
    -- Input transactions dengan Amount & TransactionType
    DECLARE @Transactions TABLE (
        TransactionID INT,
        TransactionDate DATE,
        Description NVARCHAR(MAX),
        BankType NVARCHAR(50),
        BTP NVARCHAR(50),
        CustomerNameFromInput NVARCHAR(200),
        TransactionTime NVARCHAR(50),
        TransactionType NVARCHAR(2),
        Amount DECIMAL(18,2),
        Location NVARCHAR(100),
        Keterangan1 NVARCHAR(200),
        Keterangan2 NVARCHAR(200)
    );
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- STEP 1: Parse JSON dengan Amount & TransactionType
    -- ═══════════════════════════════════════════════════════════════════════
    
    INSERT INTO @Transactions (
        TransactionID,
        TransactionDate,
        Description,
        BankType,
        BTP,
        CustomerNameFromInput,
        TransactionTime,
        TransactionType,
        Amount,
        Location,
        Keterangan1,
        Keterangan2
    )
    SELECT 
        -- TransactionID
        COALESCE(TransactionID, TransactionIDLower) AS TransactionID,
        
        -- TransactionDate (handle multiple formats)
        CASE
            WHEN COALESCE(TransactionDate, TransactionDateLower) LIKE '%/%' 
                THEN TRY_CAST(
                    CONCAT(
                        CASE 
                            WHEN LEN(LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 1)))) = 2 
                            THEN CONCAT('20', LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 1))))
                            ELSE LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 1)))
                        END,
                        '-',
                        RIGHT(CONCAT('0', LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 2)))), 2),
                        '-',
                        RIGHT(CONCAT('0', LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 3)))), 2)
                    )
                    AS DATE)
            WHEN COALESCE(TransactionDate, TransactionDateLower) LIKE '%-%-%'
                THEN TRY_CAST(LEFT(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), 10) AS DATE)
            ELSE TRY_CAST(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))) AS DATE)
        END AS TransactionDate,
        
        -- Description
        COALESCE(Description, DescriptionLower) AS Description,
        
        -- BankType detection
        CASE
            WHEN UPPER(ISNULL(BankTypeInput, '')) = 'VA' OR UPPER(ISNULL(BankTypeInputLower, '')) = 'VA' THEN 'VA'
            WHEN COALESCE(BTPValue, BTPValueLower) IS NOT NULL AND (
                    COALESCE(Description, DescriptionLower) IS NULL OR 
                    COALESCE(Description, DescriptionLower) LIKE 'RPT:%' OR 
                    LEN(ISNULL(COALESCE(TransactionTimeInput, TransactionTimeLower), '')) > 0
                ) THEN 'VA'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE 'TRSF E-BANKING%' OR 
                 COALESCE(Description, DescriptionLower, '') LIKE 'TRSF FROM%' THEN 'TRSF'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE 'BI-FAST%' THEN 'BIFAST'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL %' OR 
                 COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL,%' OR 
                 COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL' THEN 'GREENFIEL'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CIMB NIAGA%' THEN 'CIMB'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MAYBANK INDONE%' THEN 'MAYBANK'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-HSBC INDONESIA%' THEN 'HSBC'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-UOB INDONESIA%' THEN 'UOB'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MUAMALAT INDON%' THEN 'MUAMALAT'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-OCBC NISP%' THEN 'OCBC'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-DBS INDONESIA%' THEN 'DBS'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CAPITAL INDONE%' THEN 'CAPITAL'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-WOORI SAUDARA%' THEN 'WOORI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BNI %' THEN 'BNI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BTPN %' THEN 'BTPN'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MANDIRI %' THEN 'MANDIRI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BRI %' THEN 'BRI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MEGA %' THEN 'MEGA'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-PERMATA %' THEN 'PERMATA'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-DANAMON %' THEN 'DANAMON'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CITIBANK %' THEN 'CITIBANK'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-SINARMAS %' THEN 'SINARMAS'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE 'KR OTOMATIS RTGS-PT BANK CIMB%' THEN 'CIMB'
            ELSE 'UNKNOWN'
        END as BankType,
        
        -- BTP
        COALESCE(BTPValue, BTPValueLower) AS BTP,
        
        -- CustomerName
        COALESCE(CustomerNameInput, CustomerNameLower) AS CustomerNameFromInput,
        
        -- TransactionTime
        COALESCE(TransactionTimeInput, TransactionTimeLower) AS TransactionTime,
        
        -- ═══════════════════════════════════════════════════════════════════
        -- AMOUNT & TRANSACTION TYPE - EXPLICIT HANDLING
        -- ═══════════════════════════════════════════════════════════════════
        
        -- TransactionType (CR/DB)
        CASE 
            WHEN COALESCE(TransactionTypeInput, TransactionTypeLower) IS NULL THEN NULL
            WHEN UPPER(LEFT(LTRIM(RTRIM(COALESCE(TransactionTypeInput, TransactionTypeLower))), 2)) IN ('CR', 'DB')
                THEN UPPER(LEFT(LTRIM(RTRIM(COALESCE(TransactionTypeInput, TransactionTypeLower))), 2))
            ELSE NULL
        END AS TransactionType,
        
        -- Amount (DECIMAL 18,2)
        COALESCE(AmountValue, AmountValueLower) AS Amount,
        
        -- Location
        COALESCE(LocationInput, LocationLower) AS Location,
        
        -- Keterangan
        COALESCE(Keterangan1Input, Keterangan1Lower) AS Keterangan1,
        COALESCE(Keterangan2Input, Keterangan2Lower) AS Keterangan2
        
    FROM OPENJSON(@TransactionsJSON)
    WITH (
        -- TransactionID
        TransactionID INT '$.TransactionID',
        TransactionIDLower INT '$.transaction_id',
        
        -- TransactionDate
        TransactionDate NVARCHAR(50) '$.TransactionDate',
        TransactionDateLower NVARCHAR(50) '$.transaction_date',
        
        -- Description
        Description NVARCHAR(MAX) '$.Description',
        DescriptionLower NVARCHAR(MAX) '$.description',
        
        -- BTP
        BTPValue NVARCHAR(50) '$.BTP',
        BTPValueLower NVARCHAR(50) '$.btp',
        
        -- CustomerName
        CustomerNameInput NVARCHAR(200) '$.CustomerName',
        CustomerNameLower NVARCHAR(200) '$.customer_name',
        
        -- TransactionTime
        TransactionTimeInput NVARCHAR(50) '$.TransactionTime',
        TransactionTimeLower NVARCHAR(50) '$.transaction_time',
        
        -- ═══════════════════════════════════════════════════════════════════
        -- AMOUNT & TRANSACTION TYPE - JSON PATHS
        -- ═══════════════════════════════════════════════════════════════════
        TransactionTypeInput NVARCHAR(10) '$.TransactionType',
        TransactionTypeLower NVARCHAR(10) '$.transaction_type',
        
        AmountValue DECIMAL(18,2) '$.Amount',
        AmountValueLower DECIMAL(18,2) '$.amount',
        
        -- Location & Keterangan
        LocationInput NVARCHAR(100) '$.Location',
        LocationLower NVARCHAR(100) '$.location',
        Keterangan1Input NVARCHAR(200) '$.Keterangan1',
        Keterangan1Lower NVARCHAR(200) '$.keterangan1',
        Keterangan2Input NVARCHAR(200) '$.Keterangan2',
        Keterangan2Lower NVARCHAR(200) '$.keterangan2',
        
        -- BankType
        BankTypeInput NVARCHAR(50) '$.BankType',
        BankTypeInputLower NVARCHAR(50) '$.bank_type'
    );
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- STEP 2: Debug - Show parsed Amount & TransactionType
    -- ═══════════════════════════════════════════════════════════════════════
    
    SELECT @TotalTransactions = COUNT(*) FROM @Transactions;
    
    PRINT 'Total transactions parsed: ' + CAST(@TotalTransactions AS VARCHAR);
    
    -- Amount Statistics
    DECLARE @WithAmount INT, @WithoutAmount INT;
    DECLARE @TotalCredit DECIMAL(18,2), @TotalDebit DECIMAL(18,2);
    
    SELECT 
        @WithAmount = SUM(CASE WHEN Amount IS NOT NULL THEN 1 ELSE 0 END),
        @WithoutAmount = SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END),
        @TotalCredit = SUM(CASE WHEN TransactionType = 'CR' THEN Amount ELSE 0 END),
        @TotalDebit = SUM(CASE WHEN TransactionType = 'DB' THEN Amount ELSE 0 END)
    FROM @Transactions;
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'AMOUNT STATISTICS FROM JSON:';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '  With Amount:    ' + CAST(ISNULL(@WithAmount, 0) AS VARCHAR);
    PRINT '  Without Amount: ' + CAST(ISNULL(@WithoutAmount, 0) AS VARCHAR);
    PRINT '  Total Credit:   ' + FORMAT(ISNULL(@TotalCredit, 0), 'N2');
    PRINT '  Total Debit:    ' + FORMAT(ISNULL(@TotalDebit, 0), 'N2');
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '';
    
    -- Debug: Show sample data
    IF @Debug = 1
    BEGIN
        PRINT 'DEBUG: Sample transactions with Amount:';
        SELECT TOP 5
            TransactionID,
            TransactionDate,
            LEFT(Description, 30) AS Description,
            BankType,
            Amount,
            TransactionType
        FROM @Transactions
        ORDER BY TransactionID;
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- NOTE: Sisa processing sama dengan SP_MASTER_FindBTP_SaveToReview original
    -- Lihat file MASTER/SP_MASTER_FindBTP_SaveToReview.sql untuk implementasi lengkap
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Return parsed data untuk verifikasi
    SELECT 
        TransactionID,
        TransactionDate,
        LEFT(Description, 50) AS Description,
        BankType,
        Amount,
        TransactionType,
        CustomerNameFromInput AS CustomerName
    FROM @Transactions
    ORDER BY TransactionID;
    
    -- Summary
    SELECT 
        @BatchID AS BatchID,
        @TotalTransactions AS TotalTransactions,
        @WithAmount AS TransactionsWithAmount,
        @WithoutAmount AS TransactionsWithoutAmount,
        @TotalCredit AS TotalCreditAmount,
        @TotalDebit AS TotalDebitAmount,
        GETDATE() AS ProcessedAt;
        
END;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ SP_MASTER_FindBTP_SaveToReview_v2 created!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Usage:';
PRINT '  -- Test parsing Amount dari JSON';
PRINT '  EXEC SP_MASTER_FindBTP_SaveToReview_v2';
PRINT '      @TransactionsJSON = N''[{"TransactionID":1,"Amount":1500000,"TransactionType":"CR",...}]'',';
PRINT '      @Debug = 1;';
PRINT '';
PRINT 'Features:';
PRINT '  ✅ Parse Amount dari JSON ($.Amount atau $.amount)';
PRINT '  ✅ Parse TransactionType dari JSON ($.TransactionType atau $.transaction_type)';
PRINT '  ✅ Detailed logging untuk debugging';
PRINT '  ✅ Return Amount statistics';
PRINT '';
GO
