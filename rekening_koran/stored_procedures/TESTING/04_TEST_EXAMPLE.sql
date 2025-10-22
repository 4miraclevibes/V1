-- ═══════════════════════════════════════════════════════════════════════════
-- TEST EXAMPLE - Execute MASTER SP dan Save ke rekening_koran_testing
-- ═══════════════════════════════════════════════════════════════════════════
-- Purpose: Contoh cara menggunakan SP_MASTER_FindBTP_And_Save untuk testing
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- TEST 1: Simple Test dengan 5 transactions dari berbagai banks
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 1: Multi-Bank Test (5 transactions)';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @JSON_Test1 NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "TransactionDate": "08/10/2025", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE"},
  {"TransactionID": 5, "TransactionDate": "08/10/2025", "Description": "BI-FAST CR TRANSFER   DR 032 PT Kerry Ingredien"},
  {"TransactionID": 16, "TransactionDate": "08/10/2025", "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI  RDPRLLG081025019"},
  {"TransactionID": 21, "TransactionDate": "08/10/2025", "Description": "KR OTOMATIS LLG-CIMB NIAGA PT.RUANG MAHA KARY  0000002316 11PI000 3899 100325 B H55  0"},
  {"TransactionID": 8, "TransactionDate": "08/10/2025", "Description": "KR OTOMATIS LLG-DBS INDONESIA CITRA HASMORE KULI  KWT/GDI-INDO/2025/ 09/1124128"}
]';

EXEC POWERAPPS.dbo.SP_MASTER_FindBTP_And_Save 
    @TransactionsJSON = @JSON_Test1;

GO

-- ═══════════════════════════════════════════════════════════════════════════
-- TEST 2: View saved results
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 2: View Saved Results';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

USE POWERAPPS;
GO

-- Show all saved results
SELECT 
    ResultID,
    TransactionID,
    TransactionDate,
    LEFT(Description, 50) + '...' AS Description,
    CustomerName,
    BTP,
    MatchPercentage,
    Status,
    BankType,
    InsertedAt
FROM dbo.BTP_MATCHING_RESULTS
ORDER BY ResultID DESC;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Summary by BankType:';
PRINT '═══════════════════════════════════════════════════════════════════════';

SELECT 
    BankType,
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT TransactionID) AS UniqueTransactions,
    SUM(CASE WHEN Status NOT IN ('NO_MATCH', 'NO_PATTERN') THEN 1 ELSE 0 END) AS MatchedRecords,
    AVG(CASE WHEN Status NOT IN ('NO_MATCH', 'NO_PATTERN') THEN MatchPercentage ELSE NULL END) AS AvgMatchPercentage
FROM dbo.BTP_MATCHING_RESULTS
GROUP BY BankType
ORDER BY BankType;

GO

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY QUERIES
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Useful Queries:';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '-- 1. View latest results:';
PRINT 'SELECT TOP 10 * FROM POWERAPPS.dbo.BTP_MATCHING_RESULTS ORDER BY ResultID DESC;';
PRINT '';
PRINT '-- 2. View results by BankType:';
PRINT 'SELECT * FROM POWERAPPS.dbo.BTP_MATCHING_RESULTS WHERE BankType = ''TRSF'';';
PRINT '';
PRINT '-- 3. View only successful matches:';
PRINT 'SELECT * FROM POWERAPPS.dbo.BTP_MATCHING_RESULTS WHERE Status IN (''EXCELLENT'', ''GOOD'', ''FAIR'');';
PRINT '';
PRINT '-- 4. View failed matches:';
PRINT 'SELECT * FROM POWERAPPS.dbo.BTP_MATCHING_RESULTS WHERE Status IN (''NO_MATCH'', ''NO_PATTERN'');';
PRINT '';
PRINT '-- 5. Clear all test data:';
PRINT 'TRUNCATE TABLE POWERAPPS.dbo.BTP_MATCHING_RESULTS;';
PRINT '';
PRINT '-- 6. Count results by date:';
PRINT 'SELECT TransactionDate, COUNT(*) AS Total FROM POWERAPPS.dbo.BTP_MATCHING_RESULTS GROUP BY TransactionDate;';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

