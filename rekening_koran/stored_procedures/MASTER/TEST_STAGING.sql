-- ═══════════════════════════════════════════════════════════════════════════
-- TEST SCRIPT FOR STAGING TABLE WORKFLOW
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST: Upload Rekening Koran & Save to Staging';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Sample JSON dengan multiple banks
DECLARE @JSON NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "TransactionDate": "08/10/2025", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE"},
  {"TransactionID": 2, "TransactionDate": "08/10/2025", "Description": "TRSF E-BANKING CR 0810/FTSCY/WS95051 455520.00  inv tgl 16-09-25 PANNA BERKAT MANDI"},
  {"TransactionID": 5, "TransactionDate": "08/10/2025", "Description": "BI-FAST CR TRANSFER   DR 032 PT Kerry Ingredien"},
  {"TransactionID": 16, "TransactionDate": "08/10/2025", "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI  RDPRLLG081025019"},
  {"TransactionID": 21, "TransactionDate": "08/10/2025", "Description": "KR OTOMATIS LLG-CIMB NIAGA PT.RUANG MAHA KARY  0000002316 11PI000 3899 100325 B H55  0"}
]';

-- Execute dengan save to staging
EXEC SP_MASTER_FindBTP_Batch_ToStaging 
    @TransactionsJSON = @JSON,
    @BatchID = 'TEST_001',
    @UploadedBy = 'test.user@company.com';

PRINT '';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'View Saved Data in Staging Table';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

SELECT 
    ID,
    TransactionID,
    TransactionDate,
    LEFT(Description, 50) + '...' AS Description,
    CustomerName,
    BTP,
    MatchPercentage,
    Label,
    Status,
    BankType,
    BatchID,
    UploadedBy,
    UploadedAt
FROM dbo.REKENING_KORAN_STAGING
WHERE BatchID = 'TEST_001'
ORDER BY TransactionID, OptionNumber;

PRINT '';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Summary Statistics';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

SELECT 
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT BatchID) AS TotalBatches,
    COUNT(DISTINCT BankType) AS UniqueBankTypes
FROM dbo.REKENING_KORAN_STAGING;

SELECT 
    BankType,
    COUNT(*) AS [RowCount]
FROM dbo.REKENING_KORAN_STAGING
GROUP BY BankType
ORDER BY [RowCount] DESC;

PRINT '';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Simulate Submit to Final Table';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Example: Insert ke final table (customize sesuai kebutuhan)
/*
INSERT INTO YourFinalTable (
    TransactionDate,
    Description,
    CustomerName,
    BTP,
    BankType,
    CreatedAt
)
SELECT 
    TransactionDate,
    Description,
    CustomerName,
    BTP,
    BankType,
    GETDATE()
FROM dbo.REKENING_KORAN_STAGING
WHERE BatchID = 'TEST_001'
  AND BTP IS NOT NULL;  -- Only submit matched transactions
*/

PRINT '⚠️  Submit to final table commented out.';
PRINT '    Customize the INSERT statement above for your final table.';

PRINT '';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Clean Up Test Data (Optional)';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Uncomment untuk delete test data
-- DELETE FROM dbo.REKENING_KORAN_STAGING WHERE BatchID = 'TEST_001';
PRINT '⚠️  Clean up commented out. Uncomment to delete test data.';

PRINT '';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ TEST COMPLETED!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Review data di Power Apps (query dbo.REKENING_KORAN_STAGING)';
PRINT '  2. Submit selected data ke final table';
PRINT '  3. Delete/archive dari staging table';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

