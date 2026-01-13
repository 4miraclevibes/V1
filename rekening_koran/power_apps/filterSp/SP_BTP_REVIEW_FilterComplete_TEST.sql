-- =====================================================
-- TEST: SP_BTP_REVIEW_FilterComplete
-- =====================================================
-- Purpose: Test berbagai skenario untuk SP_BTP_REVIEW_FilterComplete
-- =====================================================

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🧪 TESTING: SP_BTP_REVIEW_FilterComplete';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- =====================================================
-- TEST 1: Tanpa Parameter (Default - Show Review)
-- =====================================================
PRINT '📋 TEST 1: Tanpa Parameter (Default - Show Review)';
PRINT 'Expected: Return semua data dengan Status review (NO_MATCH, NO_PATTERN, dll) dan IsApproved = 0';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete];

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 2: Show Approved (ShowReview = 0)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 2: Show Approved (ShowReview = 0)';
PRINT 'Expected: Return semua data dengan Status approved (FAIR, GOOD, LOW, EXCELLENT) dan IsApproved = 0';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @ShowReview = 0;

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 3: Filter CustomerName
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 3: Filter CustomerName';
PRINT 'Expected: Return data dengan CustomerName mengandung "PT"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @SearchCustomer = 'PT';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 4: Filter BatchID
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 4: Filter BatchID';
PRINT 'Expected: Return data dengan BatchID mengandung "BATCH"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @SearchBatch = 'BATCH';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 5: Filter Description
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 5: Filter Description';
PRINT 'Expected: Return data dengan Description mengandung "TRANSFER"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @SearchDescription = 'TRANSFER';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 6: Filter BankType
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 6: Filter BankType';
PRINT 'Expected: Return data dengan BankType = "BCA"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @SearchBankType = 'BCA';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 7: Filter BTP
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 7: Filter BTP';
PRINT 'Expected: Return data dengan BTP mengandung "BTP"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @SearchBTP = 'BTP';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 8: Filter UploadedAt (Date)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 8: Filter UploadedAt (Date)';
PRINT 'Expected: Return data dengan UploadedAt = tanggal hari ini';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @UploadedAt = CAST(GETDATE() AS DATE);

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 9: Filter TransactionDate (Date)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 9: Filter TransactionDate (Date)';
PRINT 'Expected: Return data dengan TransactionDate = tanggal tertentu';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @TransactionDate = '2025-01-13';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 10: Filter TransactionType (ShowDebit = 1)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 10: Filter TransactionType - Debit Only (ShowDebit = 1)';
PRINT 'Expected: Return data dengan TransactionType = "DB"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @ShowDebit = 1;

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 11: Filter TransactionType (ShowDebit = 0)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 11: Filter TransactionType - Credit Only (ShowDebit = 0)';
PRINT 'Expected: Return data dengan TransactionType = "CR"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @ShowDebit = 0;

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 12: Multiple Filters Combined
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 12: Multiple Filters Combined';
PRINT 'Expected: Return data yang memenuhi semua filter';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @ShowReview = 1,
    @SearchCustomer = 'PT',
    @SearchBatch = 'BATCH',
    @SearchBankType = 'BCA',
    @ShowDebit = 1,
    @SortBy = 'MatchPercentage',
    @SortOrder = 'DESC';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 13: Filter Status - IncludeNoMatch Only
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 13: Filter Status - IncludeNoMatch Only';
PRINT 'Expected: Return data dengan Status = "NO_MATCH" saja';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @ShowReview = 1,
    @IncludeNoMatch = 1,
    @IncludeUnknownBank = 0,
    @IncludeMissing = 0,
    @IncludeNoPattern = 0;

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 14: Filter Status - IncludeExcellent Only
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 14: Filter Status - IncludeExcellent Only';
PRINT 'Expected: Return data dengan Status = "EXCELLENT" saja';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @ShowReview = 0,
    @IncludeFair = 0,
    @IncludeGood = 0,
    @IncludeLow = 0,
    @IncludeExcellent = 1;

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 15: Sorting - CreatedAt DESC
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 15: Sorting - CreatedAt DESC';
PRINT 'Expected: Return data diurutkan berdasarkan CreatedAt DESC';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @SortBy = 'CreatedAt',
    @SortOrder = 'DESC';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 16: Sorting - TransactionDate ASC
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 16: Sorting - TransactionDate ASC';
PRINT 'Expected: Return data diurutkan berdasarkan TransactionDate ASC';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @SortBy = 'TransactionDate',
    @SortOrder = 'ASC';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 17: Empty Result (Filter yang tidak ada)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 17: Empty Result (Filter yang tidak ada)';
PRINT 'Expected: Return 0 rows (tidak ada data yang match)';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @SearchCustomer = 'XYZ123NOTEXIST';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 18: IsApproved = 1
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 18: IsApproved = 1';
PRINT 'Expected: Return data dengan IsApproved = 1';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 1;

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST SUMMARY
-- =====================================================
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ TESTING COMPLETED';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Total Tests: 18';
PRINT 'Check results above for each test case.';
PRINT '';

-- =====================================================
-- QUICK CHECK: Count Total Rows in Table
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📊 QUICK CHECK: Total Rows in BTP_REVIEW Table';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN IsApproved = 0 THEN 1 ELSE 0 END) AS NotApproved,
    SUM(CASE WHEN IsApproved = 1 THEN 1 ELSE 0 END) AS Approved,
    COUNT(DISTINCT Status) AS DistinctStatus,
    COUNT(DISTINCT BankType) AS DistinctBankType
FROM [dbo].[BTP_REVIEW];

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
