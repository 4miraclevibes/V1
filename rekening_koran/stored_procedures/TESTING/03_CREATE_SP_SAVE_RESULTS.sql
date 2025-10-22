-- ═══════════════════════════════════════════════════════════════════════════
-- SP_MASTER_FindBTP_And_Save
-- ═══════════════════════════════════════════════════════════════════════════
-- Purpose: Execute MASTER SP dan langsung save hasil ke rekening_koran_testing
-- Database: rekening_koran_testing (untuk SP definition)
--           [YourMainDatabase] (untuk execute MASTER SP)
-- ═══════════════════════════════════════════════════════════════════════════

USE rekening_koran_testing;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_MASTER_FindBTP_And_Save]
    @TransactionsJSON NVARCHAR(MAX),
    @SourceDatabase NVARCHAR(128) = 'POWERAPPS'  -- Default database tempat MASTER SP berada
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_And_Save - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'Source Database: ' + @SourceDatabase;
    PRINT '';
    
    -- Temp table untuk menampung hasil dari MASTER SP
    CREATE TABLE #MasterResults (
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
        ProcessedAt DATETIME
    );
    
    -- Build dynamic SQL untuk execute MASTER SP dari database lain
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
        INSERT INTO #MasterResults
        EXEC [' + @SourceDatabase + N'].[dbo].[SP_MASTER_FindBTP_Batch] 
            @TransactionsJSON = @TransactionsJSON;
    ';
    
    PRINT '🔄 Executing MASTER SP from [' + @SourceDatabase + ']...';
    
    BEGIN TRY
        -- Execute MASTER SP
        EXEC sp_executesql 
            @SQL,
            N'@TransactionsJSON NVARCHAR(MAX)',
            @TransactionsJSON = @TransactionsJSON;
        
        -- Count results
        DECLARE @ResultCount INT;
        SELECT @ResultCount = COUNT(*) FROM #MasterResults;
        
        PRINT '✅ MASTER SP executed successfully!';
        PRINT '   Results returned: ' + CAST(@ResultCount AS VARCHAR);
        PRINT '';
        
        -- Save results ke table
        PRINT '💾 Saving results to BTP_MATCHING_RESULTS...';
        
        INSERT INTO dbo.BTP_MATCHING_RESULTS (
            TransactionID, TransactionDate, Description, CustomerName, BTP,
            MatchPercentage, MatchCount, TotalTransactions, LastLineNumber,
            TotalBTPOptions, OptionNumber, BestFlag, LatestFlag, Label,
            Status, Message, BankType, ProcessedAt
        )
        SELECT 
            TransactionID, TransactionDate, Description, CustomerName, BTP,
            MatchPercentage, MatchCount, TotalTransactions, LastLineNumber,
            TotalBTPOptions, OptionNumber, BestFlag, LatestFlag, Label,
            Status, Message, BankType, ProcessedAt
        FROM #MasterResults;
        
        PRINT '✅ Results saved successfully!';
        PRINT '   Rows inserted: ' + CAST(@@ROWCOUNT AS VARCHAR);
        PRINT '';
        
        -- Return results untuk preview
        PRINT '═══════════════════════════════════════════════════════════════════════';
        PRINT 'Returning results for preview...';
        PRINT '═══════════════════════════════════════════════════════════════════════';
        
        SELECT 
            TransactionID,
            TransactionDate,
            Description,
            CustomerName,
            BTP,
            MatchPercentage,
            Status,
            BankType
        FROM #MasterResults
        ORDER BY TransactionID, OptionNumber;
        
        -- Summary statistics
        PRINT '';
        PRINT '═══════════════════════════════════════════════════════════════════════';
        PRINT 'Summary Statistics:';
        PRINT '═══════════════════════════════════════════════════════════════════════';
        
        DECLARE @TotalTransactions INT, @TotalMatched INT, @TotalNoMatch INT, @TotalNoPattern INT;
        
        SELECT @TotalTransactions = COUNT(DISTINCT TransactionID) FROM #MasterResults;
        SELECT @TotalMatched = COUNT(DISTINCT TransactionID) FROM #MasterResults WHERE Status NOT IN ('NO_MATCH', 'NO_PATTERN');
        SELECT @TotalNoMatch = COUNT(DISTINCT TransactionID) FROM #MasterResults WHERE Status = 'NO_MATCH';
        SELECT @TotalNoPattern = COUNT(DISTINCT TransactionID) FROM #MasterResults WHERE Status = 'NO_PATTERN';
        
        PRINT 'Total Transactions: ' + CAST(@TotalTransactions AS VARCHAR);
        PRINT 'Successfully Matched: ' + CAST(@TotalMatched AS VARCHAR);
        PRINT 'No Match Found: ' + CAST(@TotalNoMatch AS VARCHAR);
        PRINT 'No Pattern Extracted: ' + CAST(@TotalNoPattern AS VARCHAR);
        
        IF @TotalTransactions > 0
            PRINT 'Match Rate: ' + CAST(CAST(@TotalMatched * 100.0 / @TotalTransactions AS DECIMAL(5,2)) AS VARCHAR) + '%';
        
        PRINT '';
        PRINT 'Bank Distribution:';
        
        SELECT 
            BankType,
            COUNT(DISTINCT TransactionID) as Transactions,
            SUM(CASE WHEN Status NOT IN ('NO_MATCH', 'NO_PATTERN') THEN 1 ELSE 0 END) as Matched
        FROM #MasterResults
        GROUP BY BankType
        ORDER BY BankType;
        
        PRINT '═══════════════════════════════════════════════════════════════════════';
        
    END TRY
    BEGIN CATCH
        PRINT '❌ ERROR: ' + ERROR_MESSAGE();
        PRINT '   Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
        
        -- Still try to save what we got (if any)
        IF EXISTS (SELECT 1 FROM #MasterResults)
        BEGIN
            PRINT '';
            PRINT '⚠️  Attempting to save partial results...';
            
            INSERT INTO dbo.BTP_MATCHING_RESULTS (
                TransactionID, TransactionDate, Description, CustomerName, BTP,
                MatchPercentage, MatchCount, TotalTransactions, LastLineNumber,
                TotalBTPOptions, OptionNumber, BestFlag, LatestFlag, Label,
                Status, Message, BankType, ProcessedAt
            )
            SELECT 
                TransactionID, TransactionDate, Description, CustomerName, BTP,
                MatchPercentage, MatchCount, TotalTransactions, LastLineNumber,
                TotalBTPOptions, OptionNumber, BestFlag, LatestFlag, Label,
                Status, Message, BankType, ProcessedAt
            FROM #MasterResults;
            
            PRINT '✅ Partial results saved: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
        END
        
        -- Re-raise error
        THROW;
    END CATCH
    
    -- Cleanup
    DROP TABLE #MasterResults;
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '✅ SP_MASTER_FindBTP_And_Save - Completed!';
    PRINT '═══════════════════════════════════════════════════════════════════════';
END;
GO

PRINT '';
PRINT '✅ SP_MASTER_FindBTP_And_Save created successfully!';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Usage Example:';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'DECLARE @JSON NVARCHAR(MAX) = N''[';
PRINT '  {"TransactionID": 1, "TransactionDate": "08/10/2025", "Description": "TRSF E-BANKING..."},';
PRINT '  {"TransactionID": 2, "TransactionDate": "08/10/2025", "Description": "BI-FAST CR..."}';
PRINT ']'';';
PRINT '';
PRINT 'EXEC rekening_koran_testing.dbo.SP_MASTER_FindBTP_And_Save';
PRINT '    @TransactionsJSON = @JSON,';
PRINT '    @SourceDatabase = ''POWERAPPS'';  -- Ganti dengan nama database Anda';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

