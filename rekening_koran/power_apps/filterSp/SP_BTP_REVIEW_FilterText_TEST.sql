-- =====================================================
-- TEST: SP_BTP_REVIEW_FilterText
-- =====================================================
-- Purpose: Test berbagai skenario untuk SP_BTP_REVIEW_FilterText
-- Note: SP ini hanya filter text fields, tidak ada filter Status atau TransactionType
-- =====================================================

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🧪 TESTING: SP_BTP_REVIEW_FilterText';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '⚠️ Note: SP ini hanya filter text fields saja';
PRINT '       Filter Status dan TransactionType dilakukan di Power Apps';
PRINT '';

-- =====================================================
-- TEST 1: Tanpa Parameter (Return Semua Data)
-- =====================================================
PRINT '📋 TEST 1: Tanpa Parameter (Return Semua Data)';
PRINT 'Expected: Return semua data dari BTP_REVIEW';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText];

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 2: Filter CustomerName
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 2: Filter CustomerName';
PRINT 'Expected: Return data dengan CustomerName mengandung "PT"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchCustomer = 'PT';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 3: Filter BatchID
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 3: Filter BatchID';
PRINT 'Expected: Return data dengan BatchID mengandung "BATCH"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchBatch = 'BATCH';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 4: Filter Description
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 4: Filter Description';
PRINT 'Expected: Return data dengan Description mengandung "TRANSFER"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchDescription = 'TRANSFER';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 5: Filter BankType
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 5: Filter BankType';
PRINT 'Expected: Return data dengan BankType mengandung "BCA"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchBankType = 'BCA';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 6: Filter BTP
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 6: Filter BTP';
PRINT 'Expected: Return data dengan BTP mengandung "BTP"';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchBTP = 'BTP';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 7: Filter UploadedAt (Date)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 7: Filter UploadedAt (Date)';
PRINT 'Expected: Return data dengan UploadedAt = tanggal hari ini';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @UploadedAt = CAST(GETDATE() AS DATE);

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 8: Filter TransactionDate (Date)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 8: Filter TransactionDate (Date)';
PRINT 'Expected: Return data dengan TransactionDate = tanggal tertentu';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @TransactionDate = '2025-01-13';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 9: Multiple Filters Combined
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 9: Multiple Filters Combined';
PRINT 'Expected: Return data yang memenuhi semua filter';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchCustomer = 'PT',
    @SearchBatch = 'BATCH',
    @SearchBankType = 'BCA';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 10: Filter dengan Empty String
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 10: Filter dengan Empty String';
PRINT 'Expected: Empty string dianggap sebagai NULL, return semua data';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchCustomer = '';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 11: Empty Result (Filter yang tidak ada)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 11: Empty Result (Filter yang tidak ada)';
PRINT 'Expected: Return 0 rows (tidak ada data yang match)';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchCustomer = 'XYZ123NOTEXIST';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 12: Filter dengan NULL Explicit
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 12: Filter dengan NULL Explicit';
PRINT 'Expected: NULL diabaikan, return semua data';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchCustomer = NULL,
    @SearchBatch = NULL,
    @SearchDescription = NULL,
    @SearchBankType = NULL,
    @SearchBTP = NULL,
    @UploadedAt = NULL,
    @TransactionDate = NULL;

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 13: Filter dengan Partial Match
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 13: Filter dengan Partial Match';
PRINT 'Expected: LIKE menggunakan %value%, jadi partial match harus bekerja';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchCustomer = 'ABC';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT 'Note: Harus return data yang CustomerName mengandung "ABC" di tengah atau akhir';
PRINT '';

-- =====================================================
-- TEST 14: Filter dengan Date Range (UploadedAt)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 14: Filter dengan Date Range (UploadedAt)';
PRINT 'Expected: Return data dengan UploadedAt = tanggal tertentu';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @UploadedAt = '2025-01-01';

PRINT '';
PRINT 'Rows returned: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '';

-- =====================================================
-- TEST 15: Filter dengan Date Range (TransactionDate)
-- =====================================================
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📋 TEST 15: Filter dengan Date Range (TransactionDate)';
PRINT 'Expected: Return data dengan TransactionDate = tanggal tertentu';
PRINT '';

EXEC [dbo].[SP_BTP_REVIEW_FilterText]
    @TransactionDate = '2025-01-01';

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
PRINT 'Total Tests: 15';
PRINT 'Check results above for each test case.';
PRINT '';
PRINT '⚠️ Reminder:';
PRINT '   - SP ini hanya filter text fields';
PRINT '   - Filter Status dan TransactionType dilakukan di Power Apps';
PRINT '   - Sorting default: MatchPercentage ASC, CreatedAt DESC';
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
    COUNT(DISTINCT BankType) AS DistinctBankType,
    COUNT(DISTINCT CustomerName) AS DistinctCustomerName
FROM [dbo].[BTP_REVIEW];

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
