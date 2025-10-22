-- Debug script to check exact column count

-- Check @AllResults table definition
PRINT '=== @AllResults Table Structure ===';
-- TransactionID INT,
-- TransactionDate NVARCHAR(50),
-- Description NVARCHAR(MAX),
-- CustomerName NVARCHAR(200),
-- BTP NVARCHAR(50),
-- MatchPercentage DECIMAL(5,2),
-- MatchCount INT,
-- TotalTransactions INT,
-- LastLineNumber INT,
-- TotalBTPOptions INT,
-- OptionNumber INT,
-- BestFlag NVARCHAR(10),
-- LatestFlag NVARCHAR(10),
-- Label NVARCHAR(50),
-- Status NVARCHAR(20),
-- Message NVARCHAR(500),
-- BankType NVARCHAR(50),
-- ProcessedAt DATETIME
PRINT 'Expected: 18 columns';
PRINT '';

-- Check what CIMB SP returns
PRINT '=== Testing SP_CIMB_FindBTP_Batch Output ===';

DECLARE @TestJSON NVARCHAR(MAX) = N'[
  {"TransactionID": 21, "TransactionDate": "08/10/2025", "Description": "KR OTOMATIS LLG-CIMB NIAGA PT.RUANG MAHA KARY  0000002316 11PI000 3899 100325 B H55  0"}
]';

-- Create temp table matching CIMB output
CREATE TABLE #TestCIMB (
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
    ProcessedAt DATETIME
);

PRINT 'Executing SP_CIMB_FindBTP_Batch...';

BEGIN TRY
    INSERT INTO #TestCIMB
    EXEC SP_CIMB_FindBTP_Batch @TransactionsJSON = @TestJSON;
    
    PRINT '✅ SP_CIMB_FindBTP_Batch executed successfully!';
    PRINT '';
    PRINT 'Columns returned:';
    SELECT * FROM #TestCIMB;
    
    PRINT '';
    PRINT 'Column count: ' + CAST(@@ROWCOUNT AS VARCHAR);
    
END TRY
BEGIN CATCH
    PRINT '❌ Error executing SP_CIMB_FindBTP_Batch:';
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Message: ' + ERROR_MESSAGE();
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
END CATCH

DROP TABLE #TestCIMB;

