-- ═══════════════════════════════════════════════════════════════════════════
-- SIMPLE APPROACH: Save SP_MASTER_FindBTP_Batch results to staging table
-- ═══════════════════════════════════════════════════════════════════════════
--
-- HOW TO USE:
--   1. Execute SP_MASTER_FindBTP_Batch
--   2. Copy the results
--   3. Run this script to save to staging
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

-- Step 0: Clean up any existing temp table
IF OBJECT_ID('tempdb..#TempResults') IS NOT NULL
    DROP TABLE #TempResults;

-- Step 1: Declare your JSON
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"TransactionID": 1, "TransactionDate": "01/10/2024", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"},
    {"TransactionID": 2, "TransactionDate": "02/10/2024", "Description": "BI-FAST CR TRANSFER DR 032 PT Kerry Ingredien"},
    {"TransactionID": 3, "TransactionDate": "03/10/2024", "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI RDPRLLG081025019"},
    {"TransactionID": 4, "TransactionDate": "04/10/2024", "Description": "KR OTOMATIS LLG-BNI PT SEJIWA COFFEE RDPRLLG081025067"}
]';

-- Step 2: Create temp table to hold results
CREATE TABLE #TempResults (
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

-- Step 3: Execute Master SP and capture results
PRINT '🔄 Executing SP_MASTER_FindBTP_Batch...';
INSERT INTO #TempResults
EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON;

DECLARE @ResultCount INT = @@ROWCOUNT;
PRINT '✅ Got ' + CAST(@ResultCount AS VARCHAR) + ' results';
PRINT '';

-- Step 4: Generate BatchID
DECLARE @BatchID NVARCHAR(50) = 'BATCH_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + 
                                 REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
DECLARE @UploadedBy NVARCHAR(100) = 'Manual Test';

PRINT '📦 Saving to REKENING_KORAN_STAGING...';
PRINT 'BatchID: ' + @BatchID;
PRINT '';

-- Step 5: Simple INSERT - Just the data we have!
INSERT INTO dbo.REKENING_KORAN_STAGING (
    -- Core transaction data (18 columns from SP)
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
    -- Metadata (4 columns)
    CreatedAt,
    BatchID,
    UploadedBy,
    UploadedAt
)
SELECT
    -- From temp table (18 columns)
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
    -- Metadata values (4 columns)
    GETDATE(),      -- CreatedAt
    @BatchID,       -- BatchID
    @UploadedBy,    -- UploadedBy
    GETDATE()       -- UploadedAt
FROM #TempResults;

DECLARE @SavedCount INT = @@ROWCOUNT;

PRINT '✅ SAVED ' + CAST(@SavedCount AS VARCHAR) + ' rows to REKENING_KORAN_STAGING!';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'SUCCESS!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Show what was saved
SELECT 
    'Saved Data' AS Info,
    @BatchID AS BatchID,
    @SavedCount AS RowsSaved,
    GETDATE() AS SavedAt;

-- Show summary by bank
SELECT 
    BankType,
    COUNT(*) AS [RowCount],
    COUNT(DISTINCT TransactionID) AS UniqueTransactions
FROM dbo.REKENING_KORAN_STAGING
WHERE BatchID = @BatchID
GROUP BY BankType;

-- Cleanup
DROP TABLE #TempResults;

PRINT '';
PRINT '✅ DONE! Check REKENING_KORAN_STAGING table.';
PRINT '';
GO

