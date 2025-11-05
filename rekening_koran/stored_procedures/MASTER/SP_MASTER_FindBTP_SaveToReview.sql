-- ═══════════════════════════════════════════════════════════════════════════
-- SP_MASTER_FindBTP_SaveToReview
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   Process transactions dan LANGSUNG save ke BTP_REVIEW table
--   Solusi untuk nested INSERT-EXEC issue: Insert langsung dari dalam SP
--
-- Parameters:
--   @TransactionsJSON - JSON array of transactions
--   @BatchID - Optional batch identifier (auto-generated if null)
--   @UploadedBy - Optional user identifier
--
-- Returns:
--   Result set dari BTP_REVIEW (yang baru di-insert)
--
-- Example:
--   DECLARE @JSON NVARCHAR(MAX) = N'[
--     {"TransactionID": 1, "TransactionDate": "08/10/2024", "Description": "TRSF E-BANKING..."},
--     {"TransactionID": 2, "TransactionDate": "09/10/2024", "Description": "BI-FAST..."}
--   ]';
--   
--   EXEC SP_MASTER_FindBTP_SaveToReview 
--       @TransactionsJSON = @JSON,
--       @UploadedBy = 'finance@company.com';
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_MASTER_FindBTP_SaveToReview]
    @TransactionsJSON NVARCHAR(MAX),
    @BatchID NVARCHAR(100) = NULL,
    @UploadedBy NVARCHAR(255) = NULL
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
    PRINT 'SP_MASTER_FindBTP_SaveToReview - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'BatchID: ' + @BatchID;
    IF @UploadedBy IS NOT NULL
        PRINT 'Uploaded By: ' + @UploadedBy;
    PRINT '';
    
    -- Variables
    DECLARE @TotalTransactions INT;
    DECLARE @UploadTime DATETIME = GETDATE();
    
    -- Input transactions
    DECLARE @Transactions TABLE (
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX),
        BankType NVARCHAR(50)
    );
    
    -- Parse JSON and detect bank types
    INSERT INTO @Transactions (TransactionID, TransactionDate, Description, BankType)
    SELECT 
        TransactionID,
        TransactionDate,
        Description,
        CASE
            -- Group 3: Special Logic
            WHEN Description LIKE 'TRSF E-BANKING%' OR Description LIKE 'TRSF FROM%' THEN 'TRSF'
            WHEN Description LIKE 'BI-FAST%' THEN 'BIFAST'
            WHEN Description LIKE '% GREENFIEL %' OR Description LIKE '% GREENFIEL,%' OR Description LIKE '% GREENFIEL' THEN 'GREENFIEL'
            -- Group 1
            WHEN Description LIKE '%LLG-BNI %' THEN 'BNI'
            WHEN Description LIKE '%LLG-BTPN %' THEN 'BTPN'
            WHEN Description LIKE '%LLG-MANDIRI %' THEN 'MANDIRI'
            WHEN Description LIKE '%LLG-BRI %' THEN 'BRI'
            WHEN Description LIKE '%LLG-MEGA %' THEN 'MEGA'
            WHEN Description LIKE '%LLG-PERMATA %' THEN 'PERMATA'
            WHEN Description LIKE '%LLG-DANAMON %' THEN 'DANAMON'
            WHEN Description LIKE '%LLG-CITIBANK %' THEN 'CITIBANK'
            WHEN Description LIKE '%LLG-SINARMAS %' THEN 'SINARMAS'
            -- Group 2
            WHEN Description LIKE '%LLG-CIMB NIAGA%' THEN 'CIMB'
            WHEN Description LIKE '%LLG-MAYBANK INDONE%' THEN 'MAYBANK'
            WHEN Description LIKE '%LLG-HSBC INDONESIA%' THEN 'HSBC'
            WHEN Description LIKE '%LLG-UOB INDONESIA%' THEN 'UOB'
            WHEN Description LIKE '%LLG-MUAMALAT INDON%' THEN 'MUAMALAT'
            WHEN Description LIKE '%LLG-OCBC NISP%' THEN 'OCBC'
            WHEN Description LIKE '%LLG-DBS INDONESIA%' THEN 'DBS'
            WHEN Description LIKE '%LLG-CAPITAL INDONE%' THEN 'CAPITAL'
            WHEN Description LIKE '%LLG-WOORI SAUDARA%' THEN 'WOORI'
            ELSE 'UNKNOWN'
        END as BankType
    FROM OPENJSON(@TransactionsJSON)
    WITH (
        TransactionID INT '$.TransactionID',
        TransactionDate NVARCHAR(50) '$.TransactionDate',
        Description NVARCHAR(MAX) '$.Description'
    );
    
    SELECT @TotalTransactions = COUNT(*) FROM @Transactions;
    PRINT 'Total transactions to process: ' + CAST(@TotalTransactions AS VARCHAR);
    PRINT '';
    
    -- Now process each bank type and INSERT directly to BTP_REVIEW
    -- This avoids nested INSERT-EXEC issue!
    
    DECLARE @ProcessedCount INT = 0;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- TRSF
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'TRSF')
    BEGIN
        PRINT '🔄 Processing TRSF...';
        
        DECLARE @TRSF_JSON NVARCHAR(MAX);
        SELECT @TRSF_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'TRSF' FOR JSON PATH
        );
        
        -- Create temp table for TRSF results
        CREATE TABLE #TRSF_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #TRSF_Temp
        EXEC SP_TRSF_FindBTP_Batch @InputJSON = @TRSF_JSON;
        
        -- Insert directly to BTP_REVIEW (with auto-populate Notes)
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, 'TRSF', ProcessedAt,
            0,
            CASE
                WHEN Status = 'NO_PATTERN' THEN 'Customer name tidak ditemukan di description - perlu review format extraction'
                WHEN Status = 'NO_MATCH' THEN 'Customer "' + CustomerName + '" belum ada di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN'
                WHEN Status = 'LOW' THEN 'Match confidence rendah (' + CAST(MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN TotalBTPOptions > 1 THEN 'Ditemukan ' + CAST(TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                ELSE NULL
            END,
            GETDATE()
        FROM #TRSF_Temp;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #TRSF_Temp;
        
        PRINT '✅ TRSF completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- BIFAST
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BIFAST')
    BEGIN
        PRINT '🔄 Processing BIFAST...';
        
        DECLARE @BIFAST_JSON NVARCHAR(MAX);
        SELECT @BIFAST_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'BIFAST' FOR JSON PATH
        );
        
        CREATE TABLE #BIFAST_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BIFAST_Temp
        EXEC SP_BIFAST_FindBTP_Batch @InputJSON = @BIFAST_JSON;
        
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, 'BIFAST', ProcessedAt,
            0,
            CASE
                WHEN Status = 'NO_PATTERN' THEN 'Customer name tidak ditemukan di description - perlu review format extraction'
                WHEN Status = 'NO_MATCH' THEN 'Customer "' + CustomerName + '" belum ada di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN'
                WHEN Status = 'LOW' THEN 'Match confidence rendah (' + CAST(MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN TotalBTPOptions > 1 THEN 'Ditemukan ' + CAST(TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                ELSE NULL
            END,
            GETDATE()
        FROM #BIFAST_Temp;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #BIFAST_Temp;
        
        PRINT '✅ BIFAST completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- MANDIRI
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MANDIRI')
    BEGIN
        PRINT '🔄 Processing MANDIRI...';
        
        DECLARE @MANDIRI_JSON NVARCHAR(MAX);
        SELECT @MANDIRI_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'MANDIRI' FOR JSON PATH
        );
        
        CREATE TABLE #MANDIRI_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MANDIRI_Temp
        EXEC SP_MANDIRI_FindBTP_Batch @InputJSON = @MANDIRI_JSON;
        
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, 'MANDIRI', ProcessedAt,
            0,
            CASE
                WHEN Status = 'NO_PATTERN' THEN 'Customer name tidak ditemukan di description - perlu review format extraction'
                WHEN Status = 'NO_MATCH' THEN 'Customer "' + CustomerName + '" belum ada di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN'
                WHEN Status = 'LOW' THEN 'Match confidence rendah (' + CAST(MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN TotalBTPOptions > 1 THEN 'Ditemukan ' + CAST(TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                ELSE NULL
            END,
            GETDATE()
        FROM #MANDIRI_Temp;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #MANDIRI_Temp;
        
        PRINT '✅ MANDIRI completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GREENFIEL
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'GREENFIEL')
    BEGIN
        PRINT '🔄 Processing GREENFIEL...';
        
        DECLARE @GREENFIEL_JSON NVARCHAR(MAX);
        SELECT @GREENFIEL_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'GREENFIEL' FOR JSON PATH
        );
        
        CREATE TABLE #GREENFIEL_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #GREENFIEL_Temp
        EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON = @GREENFIEL_JSON;
        
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, 'GREENFIEL', ProcessedAt,
            0,
            CASE
                WHEN Status = 'NO_PATTERN' THEN 'Array[4] bukan "GREENFIEL" - transaksi tidak match dengan pattern GREENFIEL'
                WHEN Status = 'NO_BTP' THEN 'BTP tidak ditemukan di description (expected array ending with "23...")'
                WHEN Status = 'NO_MATCH' THEN 'BTP "' + ISNULL(BTP, '') + '" tidak ditemukan di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN'
                WHEN Status = 'LOW' THEN 'Match confidence rendah (' + CAST(MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN TotalBTPOptions > 1 AND Message LIKE '%[Data source: MP_CUSTOMER_NEW]%' THEN 'Ditemukan ' + CAST(TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai [Data source: MP_CUSTOMER_NEW - BTN dari MP_CUSTOMER_NEW]'
                WHEN TotalBTPOptions > 1 THEN 'Ditemukan ' + CAST(TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                WHEN Message LIKE '%[Data source: MP_CUSTOMER_NEW]%' THEN 'CustomerName ditemukan dari MP_CUSTOMER_NEW (BTN) - BTP tidak ada di MASTER_CUSTOMER_BTP_PATTERN'
                ELSE NULL
            END,
            GETDATE()
        FROM #GREENFIEL_Temp;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #GREENFIEL_Temp;
        
        PRINT '✅ GREENFIEL completed';
    END
    
    -- ... Add other banks as needed (BNI, BTPN, BRI, etc.)
    -- For now, just these 4 banks: TRSF, BIFAST, MANDIRI, GREENFIEL
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Handle UNKNOWN bank types (save all with proper notes)
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'UNKNOWN')
    BEGIN
        PRINT '⚠️  Processing UNKNOWN bank types...';
        
        DECLARE @UnknownCount INT;
        SELECT @UnknownCount = COUNT(*) FROM @Transactions WHERE BankType = 'UNKNOWN';
        
        -- Insert UNKNOWN transactions directly with helpful notes
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID,
            @UploadedBy,
            @UploadTime,
            TransactionID,
            TransactionDate,
            Description,
            NULL AS CustomerName,
            NULL AS BTP,
            0.00 AS MatchPercentage,
            0 AS MatchCount,
            0 AS TotalTransactions,
            0 AS LastLineNumber,
            0 AS TotalBTPOptions,
            0 AS OptionNumber,
            '' AS BestFlag,
            '' AS LatestFlag,
            '' AS Label,
            'UNKNOWN_BANK' AS Status,
            'Bank type tidak dikenali - perlu dicek manual atau tambahkan pattern deteksi bank' AS Message,
            'UNKNOWN' AS BankType,
            GETDATE() AS ProcessedAt,
            0 AS IsApproved,
            CASE 
                WHEN Description LIKE 'SETORAN%' THEN 'Transaksi SETORAN - tidak perlu BTP matching'
                WHEN Description LIKE 'DB OTOMATIS%' THEN 'Transaksi DEBIT - tidak perlu BTP matching'
                WHEN Description LIKE 'SWITCHING%' THEN 'Transaksi SWITCHING - cek apakah perlu ditambahkan ke pattern bank'
                WHEN Description LIKE 'FLAZZ%' THEN 'Transaksi FLAZZ - tidak perlu BTP matching'
                WHEN Description LIKE 'KR OTOMATIS%' THEN 'Transaksi KR OTOMATIS tanpa keyword bank spesifik - cek description untuk identifikasi bank'
                ELSE 'Format transaksi tidak dikenali - perlu review manual untuk identifikasi bank atau kategori'
            END AS Notes,
            GETDATE() AS CreatedAt
        FROM @Transactions
        WHERE BankType = 'UNKNOWN';
        
        SET @ProcessedCount = @ProcessedCount + @UnknownCount;
        
        PRINT '⚠️  UNKNOWN bank types saved: ' + CAST(@UnknownCount AS VARCHAR);
        PRINT '   → These require manual review';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Return results from BTP_REVIEW
    -- ═══════════════════════════════════════════════════════════════════════
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '✅ Processing complete!';
    PRINT 'Total rows saved to BTP_REVIEW: ' + CAST(@ProcessedCount AS VARCHAR);
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '';
    
    -- Return the saved data
    SELECT
        ID,
        BatchID,
        UploadedBy,
        UploadedAt,
        TransactionID,
        TransactionDate,
        Description,
        CustomerName,
        BTP,
        MatchPercentage,
        MatchCount,
        TotalTransactions,
        LastLineNumber,
        TotalBTPOptions,
        OptionNumber,
        BestFlag,
        LatestFlag,
        Label,
        Status,
        Message,
        BankType,
        ProcessedAt,
        IsApproved,
        ApprovedBy,
        ApprovedAt,
        Notes,
        CreatedAt
    FROM dbo.BTP_REVIEW
    WHERE BatchID = @BatchID
    ORDER BY TransactionID, OptionNumber;
    
    -- Summary statistics
    SELECT 
        @BatchID AS BatchID,
        @UploadedBy AS UploadedBy,
        @TotalTransactions AS TotalInput,
        @ProcessedCount AS TotalSaved,
        GETDATE() AS CompletedAt,
        'SUCCESS' AS Status;
        
END;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ SP_MASTER_FindBTP_SaveToReview created successfully!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Usage:';
PRINT '  EXEC SP_MASTER_FindBTP_SaveToReview';
PRINT '      @TransactionsJSON = N''[...]'',';
PRINT '      @UploadedBy = ''user@company.com'';';
PRINT '';
PRINT 'Features:';
PRINT '  ✅ Process transactions with SP_MASTER logic';
PRINT '  ✅ Save directly to BTP_REVIEW table';
PRINT '  ✅ NO nested INSERT-EXEC issue!';
PRINT '  ✅ Returns saved data + summary';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

