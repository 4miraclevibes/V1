-- ═══════════════════════════════════════════════════════════════════════════
-- TEST: 200 Real Transactions from statement_for_sp.json
-- ═══════════════════════════════════════════════════════════════════════════
--
-- INSTRUCTIONS:
-- 1. Open test_200_rows.json in text editor
-- 2. Copy ALL content (select all, copy)
-- 3. Paste into @JSON variable below (replace the N'[...]' part)
-- 4. Execute this script
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🧪 TEST: 200 Real Transactions - BTP Review Workflow';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Data source: test_200_rows.json';
PRINT 'Bank types: TRSF (91), Other LLG (83), BIFAST (16), UNKNOWN (10)';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- OPTION 1: PASTE JSON HERE (Recommended for testing)
-- ═══════════════════════════════════════════════════════════════════════════

-- Uncomment and paste your JSON here:
/*
DECLARE @JSON NVARCHAR(MAX) = N'
[
  {
    "TransactionID": 1,
    "TransactionDate": "01/10/2025",
    "Description": "TRSF E-BANKING CR 3009/FTSCY/WS95051 455520.00 pemb. 2 cartoon WORCAS NUSANTARA A"
  },
  ... (paste all 200 rows here)
]
';
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- OPTION 2: Use OPENROWSET to read from file (if file is accessible)
-- ═══════════════════════════════════════════════════════════════════════════

-- Note: This requires the file path to be accessible by SQL Server
-- Uncomment if you want to use this method:

/*
DECLARE @JSON NVARCHAR(MAX);

SELECT @JSON = BulkColumn
FROM OPENROWSET(
    BULK '/Users/balian/Documents/GitHub/V1/rekening_koran/html_to_json_converter/examples/test_200_rows.json',
    SINGLE_CLOB
) AS j;
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- FOR NOW: Use small sample (uncomment one of the options above for full test)
-- ═══════════════════════════════════════════════════════════════════════════

DECLARE @JSON NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "TransactionDate": "01/10/2025", "Description": "TRSF E-BANKING CR 3009/FTSCY/WS95051 455520.00 pemb. 2 cartoon WORCAS NUSANTARA A"},
  {"TransactionID": 2, "TransactionDate": "01/10/2025", "Description": "BI-FAST CR TANGGAL :30/09 TRANSFER DR 002 ROY GUSERNI"},
  {"TransactionID": 3, "TransactionDate": "01/10/2025", "Description": "TRSF E-BANKING CR 3009/FTSCY/WS95051 1366560.00 STJ BKS, 23 SEP 25 INV K9243391 STUJA MANAJEMEN IN"},
  {"TransactionID": 4, "TransactionDate": "01/10/2025", "Description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744"},
  {"TransactionID": 5, "TransactionDate": "01/10/2025", "Description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 18 SEP 25 INV K9226314 2300017744"},
  {"TransactionID": 10, "TransactionDate": "01/10/2025", "Description": "TRSF E-BANKING CR 3009/FTSCY/WS95051 455520.00 STJ IC, 04 MAR 25 INV N8482864 STUJA MANAJEMEN IN"},
  {"TransactionID": 14, "TransactionDate": "01/10/2025", "Description": "TRSF E-BANKING CR 3009/FTSCY/WS95011 1366560.00 matchabae pik 26 29 sep CAITLIN RUSLI"},
  {"TransactionID": 19, "TransactionDate": "01/10/2025", "Description": "BI-FAST CR TANGGAL :30/09 TRANSFER DR 008 MAUDREY ALESIA"},
  {"TransactionID": 52, "TransactionDate": "01/10/2025", "Description": "KR OTOMATIS LLG-BRI KARYAWAN ISS SUKSE Pembeian Susu Gree nfield 3Crt KISSCa fe - 250924"},
  {"TransactionID": 59, "TransactionDate": "01/10/2025", "Description": "KR OTOMATIS LLG-CIMB NIAGA PT.SUMMARECON AGUN PEMBAYARAN DARI KK G"}
]';

PRINT '⚠️  Using sample of 10 transactions for quick test';
PRINT '   (Uncomment OPTION 1 or 2 above for full 200 rows)';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- Execute SP_MASTER_FindBTP_SaveToReview
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '🔄 Processing transactions...';
PRINT '';

DECLARE @StartTime DATETIME = GETDATE();

EXEC SP_MASTER_FindBTP_SaveToReview
    @TransactionsJSON = @JSON,
    @UploadedBy = 'test_user@company.com';

DECLARE @EndTime DATETIME = GETDATE();
DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

PRINT '';
PRINT '─────────────────────────────────────────────────────────────────────';
PRINT '⏱️  Processing time: ' + CAST(@Duration AS VARCHAR) + ' ms';
PRINT '─────────────────────────────────────────────────────────────────────';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- View saved data summary
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '📊 Viewing saved data summary...';
PRINT '';

SELECT 
    BankType,
    COUNT(*) AS [RowCount],
    COUNT(DISTINCT TransactionID) AS UniqueTransactions,
    SUM(CASE WHEN Status IN ('EXCELLENT', 'GOOD') THEN 1 ELSE 0 END) AS HighConfidence,
    SUM(CASE WHEN Status = 'FAIR' THEN 1 ELSE 0 END) AS MediumConfidence,
    SUM(CASE WHEN Status = 'LOW' THEN 1 ELSE 0 END) AS LowConfidence,
    SUM(CASE WHEN Status = 'NO_MATCH' THEN 1 ELSE 0 END) AS NoMatch,
    SUM(CASE WHEN Status = 'NO_PATTERN' THEN 1 ELSE 0 END) AS NoPattern,
    AVG(MatchPercentage) AS AvgMatchPct
FROM dbo.BTP_REVIEW
WHERE IsApproved = 0
  AND UploadedBy = 'test_user@company.com'
GROUP BY BankType
ORDER BY [RowCount] DESC;

PRINT '';
PRINT '─────────────────────────────────────────────────────────────────────';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- Show sample matches
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '✅ Sample matches (top 20):';
PRINT '';

SELECT TOP 20
    TransactionID,
    BankType,
    LEFT(Description, 60) AS DescriptionPreview,
    CustomerName,
    BTP,
    MatchPercentage,
    Status
FROM dbo.BTP_REVIEW
WHERE IsApproved = 0
  AND UploadedBy = 'test_user@company.com'
  AND Status IN ('EXCELLENT', 'GOOD', 'FAIR')
ORDER BY MatchPercentage DESC, TransactionID;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ TEST COMPLETE!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Next steps:';
PRINT '  1. Review data in BTP_REVIEW table';
PRINT '  2. Test with full 200 rows (uncomment OPTION 1 or 2)';
PRINT '  3. Check Power Apps integration';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

