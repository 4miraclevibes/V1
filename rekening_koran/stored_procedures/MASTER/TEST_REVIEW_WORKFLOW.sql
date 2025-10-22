-- ═══════════════════════════════════════════════════════════════════════════
-- TEST: Complete Review Workflow
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🧪 TEST: BTP Review Workflow';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Step 1: Test data
DECLARE @TestJSON NVARCHAR(MAX) = N'[
    {"TransactionID": 1, "TransactionDate": "08/10/2024", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"},
    {"TransactionID": 2, "TransactionDate": "09/10/2024", "Description": "BI-FAST CR TRANSFER DR 032 PT Kerry Ingredien"},
    {"TransactionID": 3, "TransactionDate": "10/10/2024", "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI RDPRLLG081025019"}
]';

PRINT '📋 Test Data: 3 transactions (TRSF, BIFAST, MANDIRI)';
PRINT '';

-- Step 2: Execute SP to save to review table
PRINT '🔄 Step 1: Processing and saving to BTP_REVIEW...';
PRINT '';

EXEC SP_MASTER_FindBTP_SaveToReview
    @TransactionsJSON = @TestJSON,
    @UploadedBy = 'test_user@company.com';

PRINT '';
PRINT '─────────────────────────────────────────────────────────────────────';
PRINT '';

-- Step 3: View saved data
PRINT '📊 Step 2: Viewing saved data in BTP_REVIEW...';
PRINT '';

SELECT 
    ID,
    BatchID,
    TransactionID,
    Description,
    CustomerName,
    BTP,
    MatchPercentage,
    Status,
    BankType,
    IsApproved
FROM dbo.BTP_REVIEW
WHERE BatchID LIKE 'BATCH_%'
ORDER BY ID DESC;

PRINT '';
PRINT '─────────────────────────────────────────────────────────────────────';
PRINT '';

-- Step 4: Show pending approval
PRINT '⏳ Step 3: Pending Approval (IsApproved = 0):';
PRINT '';

SELECT 
    COUNT(*) AS PendingCount,
    BankType,
    STRING_AGG(CAST(TransactionID AS VARCHAR), ', ') AS TransactionIDs
FROM dbo.BTP_REVIEW
WHERE IsApproved = 0
GROUP BY BankType;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ TEST COMPLETE!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Next steps for finance:';
PRINT '  1. Review data in BTP_REVIEW table';
PRINT '  2. Edit BTP if needed';
PRINT '  3. Update IsApproved = 1 when confirmed';
PRINT '  4. Move approved data to final table';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

