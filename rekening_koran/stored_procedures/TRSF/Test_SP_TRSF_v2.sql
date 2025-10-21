-- =====================================================
-- Test Script for SP_TRSF_FindBTP_Batch_v2
-- Testing multiple BTP options display
-- =====================================================

USE [POWERAPPS];  -- Change to your database name
GO

PRINT '╔══════════════════════════════════════════════════════════════════╗';
PRINT '║                                                                  ║';
PRINT '║     TRSF BTP MATCHING v2 - TEST ALL BTP OPTIONS FEATURE        ║';
PRINT '║                                                                  ║';
PRINT '╚══════════════════════════════════════════════════════════════════╝';
PRINT '';

-- =====================================================
-- TEST 1: Multiple BTP Options Display
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 1: Batch with Multiple BTP Options';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Expected: CHRISTIAN should have 2 BTP options';
PRINT '          Result Set 2 will show ALL options with flags';
PRINT '';

DECLARE @JSON1 NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TRX001",
        "description": "TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY"
    },
    {
        "transaction_id": "TRX002",
        "description": "TRSF FROM BCA 123456789 HARDI PUTRA MUHARR"
    },
    {
        "transaction_id": "TRX003",
        "description": "TRSF E-BANKING CR 1304/FTSCY/WS95031 683280.00 K002000013453 EKO BUDI SUDRAJAT"
    },
    {
        "transaction_id": "TRX004",
        "description": "TRSF E-BANKING CR 1304/FTSCY/WS95011 683280.00 fresh milk 36pcs 15/04/2024 CHRISTIAN"
    },
    {
        "transaction_id": "TRX005",
        "description": "TRSF E-BANKING CR 1204/FTSCY/WS95051 455520.00 champaca inv 7402559 PRO PAWON MILLENIA"
    }
]';

EXEC [dbo].[SP_TRSF_FindBTP_Batch_v2] 
    @InputJSON = @JSON1,
    @Debug = 0;

PRINT '';
PRINT '✅ Test 1 Complete';
PRINT '';
PRINT '📊 Check Result Set 1 for main results';
PRINT '📊 Check Result Set 2 for ALL BTP options (TRX004 should show 2 options)';
PRINT '';

-- =====================================================
-- TEST 2: View Options Details
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 2: Detailed View of BTP Options';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Columns in Result Set 2:';
PRINT '  - TransactionID: Reference ke Result Set 1';
PRINT '  - OptionNumber: Rank (1 = BEST)';
PRINT '  - BTP: BTP code';
PRINT '  - MatchPercentage: Match quality';
PRINT '  - MatchCount / TotalTransactions: Usage stats';
PRINT '  - LastLineNumber: Most recent usage indicator';
PRINT '  - BestFlag: ✅ BEST untuk highest match %';
PRINT '  - LatestFlag: 🕒 LATEST untuk most recent usage';
PRINT '  - Label: Combined indicator';
PRINT '  - Quality: EXCELLENT/GOOD/FAIR/LOW';
PRINT '';

-- Same test data
EXEC [dbo].[SP_TRSF_FindBTP_Batch_v2] 
    @InputJSON = @JSON1,
    @Debug = 1;

PRINT '';
PRINT '✅ Test 2 Complete (with debug statistics)';
PRINT '';

-- =====================================================
-- TEST 3: Compare v1 vs v2 Output
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 3: Compare v1 (old) vs v2 (new) Output';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @JSON2 NVARCHAR(MAX) = N'[
    {"transaction_id": "TEST", "description": "TRSF 12345 CHRISTIAN"}
]';

PRINT '--- v1 Output (1 Result Set) ---';
EXEC [dbo].[SP_TRSF_FindBTP_Batch] @InputJSON = @JSON2, @Debug = 0;

PRINT '';
PRINT '--- v2 Output (2 Result Sets) ---';
EXEC [dbo].[SP_TRSF_FindBTP_Batch_v2] @InputJSON = @JSON2, @Debug = 0;

PRINT '';
PRINT '✅ Test 3 Complete';
PRINT '';
PRINT '📝 Difference:';
PRINT '   v1: Returns BEST BTP only (1 result set)';
PRINT '   v2: Returns BEST BTP + ALL OPTIONS (2 result sets)';
PRINT '';

-- =====================================================
-- TEST 4: Large Batch with Mixed Results
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 4: Large Batch - Some with Multiple Options';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @JSON3 NVARCHAR(MAX) = N'[
    {"transaction_id": "B001", "description": "TRSF 001 RONNY YULIADY"},
    {"transaction_id": "B002", "description": "TRSF 002 CHRISTIAN"},
    {"transaction_id": "B003", "description": "TRSF 003 HARDI PUTRA MUHARR"},
    {"transaction_id": "B004", "description": "TRSF 004 EKO BUDI SUDRAJAT"},
    {"transaction_id": "B005", "description": "TRSF 005 PRO PAWON MILLENIA"},
    {"transaction_id": "B006", "description": "TRSF 006 BROOKLYN BOGA UTAM"},
    {"transaction_id": "B007", "description": "TRSF 007 PANCIOUS TIRTA JAY"},
    {"transaction_id": "B008", "description": "TRSF 008 SUPER NORMAL SISTE"},
    {"transaction_id": "B009", "description": "TRSF 009 CHRISTIAN"},
    {"transaction_id": "B010", "description": "TRSF 010 UNKNOWN CUSTOMER XXX"}
]';

EXEC [dbo].[SP_TRSF_FindBTP_Batch_v2] 
    @InputJSON = @JSON3,
    @Debug = 1;

PRINT '';
PRINT '✅ Test 4 Complete';
PRINT '';
PRINT '📊 Expected:';
PRINT '   - B002 and B009 (CHRISTIAN) should have multiple options';
PRINT '   - B010 should be NO_MATCH';
PRINT '   - Others should have single match';
PRINT '';

-- =====================================================
-- TEST 5: Understanding Flags
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 5: Flag Interpretation Guide';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '🎯 How to Interpret Result Set 2 (All Options):';
PRINT '';
PRINT '  OptionNumber = 1  : Recommended (BEST match)';
PRINT '  BestFlag = ✅ BEST : Highest match percentage';
PRINT '  LatestFlag = 🕒 LATEST : Most recently used BTP';
PRINT '';
PRINT '  Scenarios:';
PRINT '  ──────────────────────────────────────────────────────────────';
PRINT '  1. Label = "BEST + LATEST"';
PRINT '     → Same BTP has highest match % AND most recent';
PRINT '     → Very confident choice! ✅✅';
PRINT '';
PRINT '  2. Label = "BEST" (but not LATEST)';
PRINT '     → Highest match % but older BTP exists';
PRINT '     → Recommended by algorithm (sorted by match %)';
PRINT '';
PRINT '  3. Label = "LATEST" (but not BEST)';
PRINT '     → Most recent but lower match %';
PRINT '     → Consider if recency important';
PRINT '';
PRINT '  4. Label = "" (empty)';
PRINT '     → Alternative option';
PRINT '     → Lower priority';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

-- =====================================================
-- TEST SUMMARY
-- =====================================================

PRINT '';
PRINT '╔══════════════════════════════════════════════════════════════════╗';
PRINT '║                                                                  ║';
PRINT '║                    ✅ ALL TESTS COMPLETE!                        ║';
PRINT '║                                                                  ║';
PRINT '╚══════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT '📊 v2 Features Tested:';
PRINT '  ✅ Multiple BTP options display';
PRINT '  ✅ BEST flag (highest match %)';
PRINT '  ✅ LATEST flag (most recent usage)';
PRINT '  ✅ Combined labels (BEST + LATEST)';
PRINT '  ✅ Quality indicators';
PRINT '  ✅ Two result sets';
PRINT '';
PRINT '📝 Result Set Structure:';
PRINT '  Set 1: Main results (BEST BTP for each transaction)';
PRINT '  Set 2: ALL options (only for multiple matches)';
PRINT '';
PRINT '💡 Usage Recommendation:';
PRINT '  1. Use Result Set 1 for automatic processing';
PRINT '  2. Use Result Set 2 for manual review/override';
PRINT '  3. Check "BEST + LATEST" label for high confidence';
PRINT '  4. Consider LATEST option if business rules prefer recency';
PRINT '';

-- =====================================================
-- Quick Check: Which transactions have multiple options?
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'Quick Check: Transactions with Multiple BTP Options';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

-- Find customers dengan multiple BTPs
SELECT 
    customer_name AS CustomerName,
    COUNT(DISTINCT btp) AS TotalBTPOptions,
    STRING_AGG(btp, ', ') AS BTPs
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN]
WHERE category = 'TRSF'
GROUP BY customer_name
HAVING COUNT(DISTINCT btp) > 1
ORDER BY COUNT(DISTINCT btp) DESC;

PRINT '';
PRINT '💡 Test dengan customer names di atas untuk lihat multiple options!';
PRINT '';

