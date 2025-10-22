-- ═══════════════════════════════════════════════════════════════════════════
-- SP_MASTER_FindBTP_Batch
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   MASTER Stored Procedure untuk auto-detect bank type dan execute
--   stored procedure yang sesuai untuk setiap transaksi
--   
--   Mendukung SEMUA 20 BANKS:
--   - Group 1 (Array[3] + Array[4]): 9 banks
--   - Group 2 (Array[4] + Array[5]): 9 banks
--   - Group 3 (Special Logic): 2 banks
--
-- Features:
--   ✅ Auto-detect bank type dari transaction description
--   ✅ Route ke stored procedure yang sesuai
--   ✅ Process multiple bank types dalam 1 batch
--   ✅ Aggregate results dari semua banks
--   ✅ NO AZURE COST - Pure SQL Server!
--
-- Parameters:
--   @TransactionsJSON - JSON array of transactions
--     Format: [{"TransactionID": 1, "Description": "..."}, ...]
--
-- Returns:
--   Unified result set dengan semua BTP matching dari semua banks
--   dengan kolom tambahan: BankType
--
-- Example Usage:
--   DECLARE @JSON NVARCHAR(MAX) = N'[
--     {"TransactionID": 1, "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"},
--     {"TransactionID": 2, "Description": "BI-FAST CR TRANSFER DR 032 PT Kerry Ingredien"},
--     {"TransactionID": 3, "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI RDPRLLG081025019"}
--   ]';
--   
--   EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON;
--
-- Author: Generated October 21, 2025
-- Version: 1.0.1 (Fixed syntax error)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR ALTER PROCEDURE [dbo].[SP_MASTER_FindBTP_Batch]
    @TransactionsJSON NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_Batch - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Variables
    -- ═══════════════════════════════════════════════════════════════════════
    
    DECLARE @TotalTransactions INT;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Temp Tables
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Input transactions
    DECLARE @Transactions TABLE (
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX),
        BankType NVARCHAR(50)
    );
    
    -- Results from all banks (19 columns total)
    DECLARE @AllResults TABLE (
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX),
        CustomerName NVARCHAR(200),
        BTP NVARCHAR(50),
        MatchPercentage DECIMAL(5,2),
        MatchCount INT,
        TotalTransactions INT,
        LastLineNumber INT,
        TotalBTPOptions INT,
        OptionNumber INT,
        BestFlag NVARCHAR(10),
        LatestFlag NVARCHAR(10),
        Label NVARCHAR(50),
        Status NVARCHAR(20),
        Message NVARCHAR(500),
        BankType NVARCHAR(50),
        ProcessedAt DATETIME  -- Column 18: Added back!
    );
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Step 1: Parse JSON and detect bank type for each transaction
    -- ═══════════════════════════════════════════════════════════════════════
    
    INSERT INTO @Transactions (TransactionID, TransactionDate, Description, BankType)
    SELECT 
        TransactionID,
        TransactionDate,
        Description,
        CASE
            -- Group 3: Special Logic (TRSF & BI-FAST)
            WHEN Description LIKE 'TRSF E-BANKING%' OR Description LIKE 'TRSF FROM%' THEN 'TRSF'
            WHEN Description LIKE 'BI-FAST%' THEN 'BIFAST'
            
            -- Group 1: Array[3] + Array[4]
            WHEN Description LIKE '%LLG-BNI %' THEN 'BNI'
            WHEN Description LIKE '%LLG-BTPN %' THEN 'BTPN'
            WHEN Description LIKE '%LLG-MANDIRI %' THEN 'MANDIRI'
            WHEN Description LIKE '%LLG-BRI %' THEN 'BRI'
            WHEN Description LIKE '%LLG-MEGA %' THEN 'MEGA'
            WHEN Description LIKE '%LLG-PERMATA %' THEN 'PERMATA'
            WHEN Description LIKE '%LLG-DANAMON %' THEN 'DANAMON'
            WHEN Description LIKE '%LLG-CITIBANK %' THEN 'CITIBANK'
            WHEN Description LIKE '%LLG-SINARMAS %' THEN 'SINARMAS'
            
            -- Group 2: Array[4] + Array[5] (with special words)
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
    
    -- Show bank type distribution
    PRINT 'Bank Type Distribution:';
    PRINT '─────────────────────────────────────────────────────────────────────';
    
    SELECT 
        BankType,
        COUNT(*) as TransactionCount
    FROM @Transactions
    GROUP BY BankType
    ORDER BY COUNT(*) DESC;
    
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Step 2: Process each bank type separately
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- TRSF
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'TRSF')
    BEGIN
        PRINT '🔄 Processing TRSF transactions...';
        
        DECLARE @TRSF_JSON NVARCHAR(MAX);
        SELECT @TRSF_JSON = (
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
            FROM @Transactions
            WHERE BankType = 'TRSF'
            FOR JSON PATH
        );
        
        CREATE TABLE #TRSF_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #TRSF_Results
        EXEC SP_TRSF_FindBTP_Batch @InputJSON = @TRSF_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'TRSF' AS BankType, ProcessedAt
        FROM #TRSF_Results;
        
        DROP TABLE #TRSF_Results;
        
        PRINT '✅ TRSF completed';
    END
    
    -- BIFAST
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BIFAST')
    BEGIN
        PRINT '🔄 Processing BIFAST transactions...';
        
        DECLARE @BIFAST_JSON NVARCHAR(MAX);
        SELECT @BIFAST_JSON = (
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
            FROM @Transactions
            WHERE BankType = 'BIFAST'
            FOR JSON PATH
        );
        
        CREATE TABLE #BIFAST_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BIFAST_Results
        EXEC SP_BIFAST_FindBTP_Batch @InputJSON = @BIFAST_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'BIFAST' AS BankType, ProcessedAt
        FROM #BIFAST_Results;
        
        DROP TABLE #BIFAST_Results;
        
        PRINT '✅ BIFAST completed';
    END
    
    -- MANDIRI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MANDIRI')
    BEGIN
        PRINT '🔄 Processing MANDIRI transactions...';
        
        DECLARE @MANDIRI_JSON NVARCHAR(MAX);
        SELECT @MANDIRI_JSON = (
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
            FROM @Transactions
            WHERE BankType = 'MANDIRI'
            FOR JSON PATH
        );
        
        CREATE TABLE #MANDIRI_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MANDIRI_Results
        EXEC SP_MANDIRI_FindBTP_Batch @InputJSON = @MANDIRI_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'MANDIRI' AS BankType, ProcessedAt
        FROM #MANDIRI_Results;
        
        DROP TABLE #MANDIRI_Results;
        
        PRINT '✅ MANDIRI completed';
    END
    
    -- BNI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BNI')
    BEGIN
        PRINT '🔄 Processing BNI transactions...';
        
        DECLARE @BNI_JSON NVARCHAR(MAX);
        SELECT @BNI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'BNI'
            FOR JSON PATH
        );
        
        CREATE TABLE #BNI_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BNI_Results
        EXEC SP_BNI_FindBTP_Batch @TransactionsJSON = @BNI_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'BNI' AS BankType, ProcessedAt
        FROM #BNI_Results;
        
        DROP TABLE #BNI_Results;
        
        PRINT '✅ BNI completed';
    END
    
    -- BTPN
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BTPN')
    BEGIN
        PRINT '🔄 Processing BTPN transactions...';
        
        DECLARE @BTPN_JSON NVARCHAR(MAX);
        SELECT @BTPN_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'BTPN'
            FOR JSON PATH
        );
        
        CREATE TABLE #BTPN_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BTPN_Results
        EXEC SP_BTPN_FindBTP_Batch @TransactionsJSON = @BTPN_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'BTPN' AS BankType, ProcessedAt
        FROM #BTPN_Results;
        
        DROP TABLE #BTPN_Results;
        
        PRINT '✅ BTPN completed';
    END
    
    -- BRI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BRI')
    BEGIN
        PRINT '🔄 Processing BRI transactions...';
        
        DECLARE @BRI_JSON NVARCHAR(MAX);
        SELECT @BRI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'BRI'
            FOR JSON PATH
        );
        
        CREATE TABLE #BRI_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BRI_Results
        EXEC SP_BRI_FindBTP_Batch @TransactionsJSON = @BRI_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'BRI' AS BankType, ProcessedAt
        FROM #BRI_Results;
        
        DROP TABLE #BRI_Results;
        
        PRINT '✅ BRI completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GROUP 1 BANKS (Array[3] + Array[4])
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- MEGA
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MEGA')
    BEGIN
        PRINT '🔄 Processing MEGA transactions...';
        
        DECLARE @MEGA_JSON NVARCHAR(MAX);
        SELECT @MEGA_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'MEGA'
            FOR JSON PATH
        );
        
        CREATE TABLE #MEGA_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MEGA_Results
        EXEC SP_MEGA_FindBTP_Batch @TransactionsJSON = @MEGA_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'MEGA' AS BankType, ProcessedAt
        FROM #MEGA_Results;
        
        DROP TABLE #MEGA_Results;
        
        PRINT '✅ MEGA completed';
    END
    
    -- PERMATA
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'PERMATA')
    BEGIN
        PRINT '🔄 Processing PERMATA transactions...';
        
        DECLARE @PERMATA_JSON NVARCHAR(MAX);
        SELECT @PERMATA_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'PERMATA'
            FOR JSON PATH
        );
        
        CREATE TABLE #PERMATA_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #PERMATA_Results
        EXEC SP_PERMATA_FindBTP_Batch @TransactionsJSON = @PERMATA_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'PERMATA' AS BankType, ProcessedAt
        FROM #PERMATA_Results;
        
        DROP TABLE #PERMATA_Results;
        
        PRINT '✅ PERMATA completed';
    END
    
    -- DANAMON
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'DANAMON')
    BEGIN
        PRINT '🔄 Processing DANAMON transactions...';
        
        DECLARE @DANAMON_JSON NVARCHAR(MAX);
        SELECT @DANAMON_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'DANAMON'
            FOR JSON PATH
        );
        
        CREATE TABLE #DANAMON_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #DANAMON_Results
        EXEC SP_DANAMON_FindBTP_Batch @TransactionsJSON = @DANAMON_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'DANAMON' AS BankType, ProcessedAt
        FROM #DANAMON_Results;
        
        DROP TABLE #DANAMON_Results;
        
        PRINT '✅ DANAMON completed';
    END
    
    -- CITIBANK
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CITIBANK')
    BEGIN
        PRINT '🔄 Processing CITIBANK transactions...';
        
        DECLARE @CITIBANK_JSON NVARCHAR(MAX);
        SELECT @CITIBANK_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'CITIBANK'
            FOR JSON PATH
        );
        
        CREATE TABLE #CITIBANK_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CITIBANK_Results
        EXEC SP_CITIBANK_FindBTP_Batch @TransactionsJSON = @CITIBANK_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'CITIBANK' AS BankType, ProcessedAt
        FROM #CITIBANK_Results;
        
        DROP TABLE #CITIBANK_Results;
        
        PRINT '✅ CITIBANK completed';
    END
    
    -- SINARMAS
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'SINARMAS')
    BEGIN
        PRINT '🔄 Processing SINARMAS transactions...';
        
        DECLARE @SINARMAS_JSON NVARCHAR(MAX);
        SELECT @SINARMAS_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'SINARMAS'
            FOR JSON PATH
        );
        
        CREATE TABLE #SINARMAS_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #SINARMAS_Results
        EXEC SP_SINARMAS_FindBTP_Batch @TransactionsJSON = @SINARMAS_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'SINARMAS' AS BankType, ProcessedAt
        FROM #SINARMAS_Results;
        
        DROP TABLE #SINARMAS_Results;
        
        PRINT '✅ SINARMAS completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GROUP 2 BANKS (Array[4] + Array[5])
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- CIMB
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CIMB')
    BEGIN
        PRINT '🔄 Processing CIMB transactions...';
        
        DECLARE @CIMB_JSON NVARCHAR(MAX);
        SELECT @CIMB_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'CIMB'
            FOR JSON PATH
        );
        
        CREATE TABLE #CIMB_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CIMB_Results
        EXEC SP_CIMB_FindBTP_Batch @TransactionsJSON = @CIMB_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'CIMB' AS BankType, ProcessedAt
        FROM #CIMB_Results;
        
        DROP TABLE #CIMB_Results;
        
        PRINT '✅ CIMB completed';
    END
    
    -- MAYBANK
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MAYBANK')
    BEGIN
        PRINT '🔄 Processing MAYBANK transactions...';
        
        DECLARE @MAYBANK_JSON NVARCHAR(MAX);
        SELECT @MAYBANK_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'MAYBANK'
            FOR JSON PATH
        );
        
        CREATE TABLE #MAYBANK_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MAYBANK_Results
        EXEC SP_MAYBANK_FindBTP_Batch @TransactionsJSON = @MAYBANK_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'MAYBANK' AS BankType, ProcessedAt
        FROM #MAYBANK_Results;
        
        DROP TABLE #MAYBANK_Results;
        
        PRINT '✅ MAYBANK completed';
    END
    
    -- HSBC
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'HSBC')
    BEGIN
        PRINT '🔄 Processing HSBC transactions...';
        
        DECLARE @HSBC_JSON NVARCHAR(MAX);
        SELECT @HSBC_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'HSBC'
            FOR JSON PATH
        );
        
        CREATE TABLE #HSBC_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #HSBC_Results
        EXEC SP_HSBC_FindBTP_Batch @TransactionsJSON = @HSBC_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'HSBC' AS BankType, ProcessedAt
        FROM #HSBC_Results;
        
        DROP TABLE #HSBC_Results;
        
        PRINT '✅ HSBC completed';
    END
    
    -- UOB
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'UOB')
    BEGIN
        PRINT '🔄 Processing UOB transactions...';
        
        DECLARE @UOB_JSON NVARCHAR(MAX);
        SELECT @UOB_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'UOB'
            FOR JSON PATH
        );
        
        CREATE TABLE #UOB_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #UOB_Results
        EXEC SP_UOB_FindBTP_Batch @TransactionsJSON = @UOB_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'UOB' AS BankType, ProcessedAt
        FROM #UOB_Results;
        
        DROP TABLE #UOB_Results;
        
        PRINT '✅ UOB completed';
    END
    
    -- MUAMALAT
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MUAMALAT')
    BEGIN
        PRINT '🔄 Processing MUAMALAT transactions...';
        
        DECLARE @MUAMALAT_JSON NVARCHAR(MAX);
        SELECT @MUAMALAT_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'MUAMALAT'
            FOR JSON PATH
        );
        
        CREATE TABLE #MUAMALAT_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MUAMALAT_Results
        EXEC SP_MUAMALAT_FindBTP_Batch @TransactionsJSON = @MUAMALAT_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'MUAMALAT' AS BankType, ProcessedAt
        FROM #MUAMALAT_Results;
        
        DROP TABLE #MUAMALAT_Results;
        
        PRINT '✅ MUAMALAT completed';
    END
    
    -- OCBC
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'OCBC')
    BEGIN
        PRINT '🔄 Processing OCBC transactions...';
        
        DECLARE @OCBC_JSON NVARCHAR(MAX);
        SELECT @OCBC_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'OCBC'
            FOR JSON PATH
        );
        
        CREATE TABLE #OCBC_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #OCBC_Results
        EXEC SP_OCBC_FindBTP_Batch @TransactionsJSON = @OCBC_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'OCBC' AS BankType, ProcessedAt
        FROM #OCBC_Results;
        
        DROP TABLE #OCBC_Results;
        
        PRINT '✅ OCBC completed';
    END
    
    -- DBS
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'DBS')
    BEGIN
        PRINT '🔄 Processing DBS transactions...';
        
        DECLARE @DBS_JSON NVARCHAR(MAX);
        SELECT @DBS_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'DBS'
            FOR JSON PATH
        );
        
        CREATE TABLE #DBS_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #DBS_Results
        EXEC SP_DBS_FindBTP_Batch @TransactionsJSON = @DBS_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'DBS' AS BankType, ProcessedAt
        FROM #DBS_Results;
        
        DROP TABLE #DBS_Results;
        
        PRINT '✅ DBS completed';
    END
    
    -- CAPITAL
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CAPITAL')
    BEGIN
        PRINT '🔄 Processing CAPITAL transactions...';
        
        DECLARE @CAPITAL_JSON NVARCHAR(MAX);
        SELECT @CAPITAL_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'CAPITAL'
            FOR JSON PATH
        );
        
        CREATE TABLE #CAPITAL_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CAPITAL_Results
        EXEC SP_CAPITAL_FindBTP_Batch @TransactionsJSON = @CAPITAL_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'CAPITAL' AS BankType, ProcessedAt
        FROM #CAPITAL_Results;
        
        DROP TABLE #CAPITAL_Results;
        
        PRINT '✅ CAPITAL completed';
    END
    
    -- WOORI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'WOORI')
    BEGIN
        PRINT '🔄 Processing WOORI transactions...';
        
        DECLARE @WOORI_JSON NVARCHAR(MAX);
        SELECT @WOORI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'WOORI'
            FOR JSON PATH
        );
        
        CREATE TABLE #WOORI_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #WOORI_Results
        EXEC SP_WOORI_FindBTP_Batch @TransactionsJSON = @WOORI_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'WOORI' AS BankType, ProcessedAt
        FROM #WOORI_Results;
        
        DROP TABLE #WOORI_Results;
        
        PRINT '✅ WOORI completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Step 3: Return unified results
    -- ═══════════════════════════════════════════════════════════════════════
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'Returning unified results...';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    
    SELECT
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
        BankType,  -- ⭐ Important: Shows which bank's SP processed this
        ProcessedAt
    FROM @AllResults
    ORDER BY TransactionID, OptionNumber;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Statistics
    -- ═══════════════════════════════════════════════════════════════════════
    
    DECLARE @TotalProcessed INT, @TotalMatched INT, @TotalUnknown INT;
    
    SELECT @TotalProcessed = COUNT(DISTINCT TransactionID) FROM @AllResults;
    SELECT @TotalMatched = COUNT(DISTINCT TransactionID) FROM @AllResults WHERE Status NOT IN ('NO_MATCH', 'NO_PATTERN');
    SELECT @TotalUnknown = COUNT(*) FROM @Transactions WHERE BankType = 'UNKNOWN';
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_Batch - COMPLETED';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'Total Input Transactions: ' + CAST(@TotalTransactions AS VARCHAR);
    PRINT 'Successfully Processed: ' + CAST(@TotalProcessed AS VARCHAR);
    PRINT 'Successful BTP Matches: ' + CAST(@TotalMatched AS VARCHAR);
    PRINT 'Unknown Bank Types: ' + CAST(@TotalUnknown AS VARCHAR);
    IF @TotalProcessed > 0
        PRINT 'Overall Match Rate: ' + CAST(CAST(@TotalMatched * 100.0 / NULLIF(@TotalProcessed, 0) AS DECIMAL(5,2)) AS VARCHAR) + '%';
    PRINT '';
    PRINT 'Banks Processed:';
    
    SELECT 
        BankType,
        COUNT(DISTINCT TransactionID) as Transactions,
        SUM(CASE WHEN Status NOT IN ('NO_MATCH', 'NO_PATTERN') THEN 1 ELSE 0 END) as Matched
    FROM @AllResults
    GROUP BY BankType
    ORDER BY BankType;
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
END;
GO

PRINT '';
PRINT '✅ SP_MASTER_FindBTP_Batch created successfully!';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'MASTER STORED PROCEDURE - READY FOR USE!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Features:';
PRINT '  ✅ Auto-detect bank type dari description';
PRINT '  ✅ Route to appropriate SP automatically';
PRINT '  ✅ Support ALL 20 banks (currently showing 6 banks as example)';
PRINT '  ✅ Process mixed bank types in 1 batch';
PRINT '  ✅ Return unified results with BankType column';
PRINT '  ✅ NO AZURE COST - Pure SQL Server!';
PRINT '';
PRINT 'Usage:';
PRINT '  DECLARE @JSON NVARCHAR(MAX) = N''[...]'';';
PRINT '  EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON;';
PRINT '';
PRINT 'Note: This version includes 6 banks (TRSF, BIFAST, MANDIRI, BNI, BTPN, BRI)';
PRINT '      Add remaining 14 banks by copying the pattern above.';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
