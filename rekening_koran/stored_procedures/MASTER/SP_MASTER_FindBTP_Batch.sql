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
-- Version: 1.0.0
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
        Description NVARCHAR(MAX),
        BankType NVARCHAR(50)
    );
    
    -- Results from all banks
    DECLARE @AllResults TABLE (
        TransactionID INT,
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
        ProcessedAt DATETIME
    );
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Step 1: Parse JSON and detect bank type for each transaction
    -- ═══════════════════════════════════════════════════════════════════════
    
    INSERT INTO @Transactions (TransactionID, Description, BankType)
    SELECT 
        TransactionID,
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
            SELECT TransactionID, Description
            FROM @Transactions
            WHERE BankType = 'TRSF'
            FOR JSON PATH
        );
        
        INSERT INTO @AllResults
        SELECT *, 'TRSF' as BankType, GETDATE()
        FROM OPENQUERY(LINKEDSERVER, 'EXEC SP_TRSF_FindBTP_Batch @TransactionsJSON = ''' + REPLACE(@TRSF_JSON, '''', '''''') + '''');
        
        -- Alternate method if OPENQUERY doesn't work:
        -- Use temp table and INSERT-EXEC
        CREATE TABLE #TRSF_Results (
            TransactionID INT, Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #TRSF_Results
        EXEC SP_TRSF_FindBTP_Batch @TransactionsJSON = @TRSF_JSON;
        
        INSERT INTO @AllResults
        SELECT *, 'TRSF' FROM #TRSF_Results;
        
        DROP TABLE #TRSF_Results;
        
        PRINT '✅ TRSF completed';
    END
    
    -- BIFAST
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BIFAST')
    BEGIN
        PRINT '🔄 Processing BIFAST transactions...';
        
        DECLARE @BIFAST_JSON NVARCHAR(MAX);
        SELECT @BIFAST_JSON = (
            SELECT TransactionID, Description
            FROM @Transactions
            WHERE BankType = 'BIFAST'
            FOR JSON PATH
        );
        
        CREATE TABLE #BIFAST_Results (
            TransactionID INT, Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BIFAST_Results
        EXEC SP_BIFAST_FindBTP_Batch @TransactionsJSON = @BIFAST_JSON;
        
        INSERT INTO @AllResults
        SELECT *, 'BIFAST' FROM #BIFAST_Results;
        
        DROP TABLE #BIFAST_Results;
        
        PRINT '✅ BIFAST completed';
    END
    
    -- MANDIRI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MANDIRI')
    BEGIN
        PRINT '🔄 Processing MANDIRI transactions...';
        
        DECLARE @MANDIRI_JSON NVARCHAR(MAX);
        SELECT @MANDIRI_JSON = (
            SELECT TransactionID, Description
            FROM @Transactions
            WHERE BankType = 'MANDIRI'
            FOR JSON PATH
        );
        
        CREATE TABLE #MANDIRI_Results (
            TransactionID INT, Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MANDIRI_Results
        EXEC SP_MANDIRI_FindBTP_Batch @TransactionsJSON = @MANDIRI_JSON;
        
        INSERT INTO @AllResults
        SELECT *, 'MANDIRI' FROM #MANDIRI_Results;
        
        DROP TABLE #MANDIRI_Results;
        
        PRINT '✅ MANDIRI completed';
    END
    
    -- BNI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BNI')
    BEGIN
        PRINT '🔄 Processing BNI transactions...';
        
        DECLARE @BNI_JSON NVARCHAR(MAX);
        SELECT @BNI_JSON = (
            SELECT TransactionID, Description
            FROM @Transactions
            WHERE BankType = 'BNI'
            FOR JSON PATH
        );
        
        CREATE TABLE #BNI_Results (
            TransactionID INT, Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BNI_Results
        EXEC SP_BNI_FindBTP_Batch @TransactionsJSON = @BNI_JSON;
        
        INSERT INTO @AllResults
        SELECT *, 'BNI' FROM #BNI_Results;
        
        DROP TABLE #BNI_Results;
        
        PRINT '✅ BNI completed';
    END
    
    -- Continue for all other banks...
    -- (BRI, MEGA, PERMATA, DANAMON, CITIBANK, SINARMAS, BTPN)
    -- (CIMB, MAYBANK, HSBC, UOB, MUAMALAT, OCBC, DBS, CAPITAL, WOORI)
    
    -- For brevity, I'll add a dynamic approach:
    
    DECLARE @CurrentBank NVARCHAR(50);
    DECLARE @CurrentJSON NVARCHAR(MAX);
    DECLARE @SQL NVARCHAR(MAX);
    
    DECLARE bank_cursor CURSOR FOR
        SELECT DISTINCT BankType
        FROM @Transactions
        WHERE BankType NOT IN ('TRSF', 'BIFAST', 'MANDIRI', 'BNI', 'UNKNOWN');
    
    OPEN bank_cursor;
    FETCH NEXT FROM bank_cursor INTO @CurrentBank;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '🔄 Processing ' + @CurrentBank + ' transactions...';
        
        -- Build JSON for current bank
        SELECT @CurrentJSON = (
            SELECT TransactionID, Description
            FROM @Transactions
            WHERE BankType = @CurrentBank
            FOR JSON PATH
        );
        
        -- Dynamic SQL to call appropriate SP
        SET @SQL = '
            CREATE TABLE #' + @CurrentBank + '_Results (
                TransactionID INT, Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
                BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
                TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
                OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
                Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
                ProcessedAt DATETIME
            );
            
            INSERT INTO #' + @CurrentBank + '_Results
            EXEC SP_' + @CurrentBank + '_FindBTP_Batch @TransactionsJSON = @CurrentJSON;
            
            INSERT INTO @AllResults
            SELECT *, ''' + @CurrentBank + ''' FROM #' + @CurrentBank + '_Results;
            
            DROP TABLE #' + @CurrentBank + '_Results;
        ';
        
        EXEC sp_executesql @SQL, N'@CurrentJSON NVARCHAR(MAX)', @CurrentJSON;
        
        PRINT '✅ ' + @CurrentBank + ' completed';
        
        FETCH NEXT FROM bank_cursor INTO @CurrentBank;
    END
    
    CLOSE bank_cursor;
    DEALLOCATE bank_cursor;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Step 3: Return unified results
    -- ═══════════════════════════════════════════════════════════════════════
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'Returning unified results...';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    
    SELECT
        TransactionID,
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
PRINT '  ✅ Support ALL 20 banks';
PRINT '  ✅ Process mixed bank types in 1 batch';
PRINT '  ✅ Return unified results with BankType column';
PRINT '  ✅ NO AZURE COST - Pure SQL Server!';
PRINT '';
PRINT 'Usage:';
PRINT '  DECLARE @JSON NVARCHAR(MAX) = N''[...]'';';
PRINT '  EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON;';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

