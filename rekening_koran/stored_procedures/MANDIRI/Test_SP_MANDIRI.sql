-- =====================================================
-- Test Script for MANDIRI Stored Procedures
-- =====================================================

USE [YourDatabase];  -- Change to your database name
GO

PRINT '╔══════════════════════════════════════════════════════════════════╗';
PRINT '║                                                                  ║';
PRINT '║          MANDIRI BTP PATTERN MATCHING - TEST SUITE                 ║';
PRINT '║                                                                  ║';
PRINT '╚══════════════════════════════════════════════════════════════════╝';
PRINT '';

-- =====================================================
-- TEST 1: SP_MANDIRI_FindBTP_Single - Basic Test
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 1: Single Search - Basic';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'MANDIRI E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY',
    @Debug = 0;

PRINT '';
PRINT '✅ Test 1 Complete';
PRINT '';

-- =====================================================
-- TEST 2: SP_MANDIRI_FindBTP_Single - With Debug
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 2: Single Search - With Debug Mode';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'MANDIRI FROM BCA 123456789 100000 HARDI PUTRA MUHARR',
    @Debug = 1;

PRINT '';
PRINT '✅ Test 2 Complete';
PRINT '';

-- =====================================================
-- TEST 3: SP_MANDIRI_FindBTP_Single - No Pattern
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 3: Single Search - No Customer Name Pattern';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'MANDIRI E-BANKING 12345',  -- No customer name
    @Debug = 0;

PRINT '';
PRINT '✅ Test 3 Complete';
PRINT '';

-- =====================================================
-- TEST 4: SP_MANDIRI_FindBTP_Single - Not in Master
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 4: Single Search - Customer Not in Master Data';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'MANDIRI 12345 100000 NONEXISTENT CUSTOMER ZZZZZ',
    @Debug = 0;

PRINT '';
PRINT '✅ Test 4 Complete';
PRINT '';

-- =====================================================
-- TEST 5: SP_MANDIRI_FindBTP_Batch - Small Batch
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 5: Batch Search - 3 Descriptions';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @JSON1 NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TRX001",
        "description": "MANDIRI E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY"
    },
    {
        "transaction_id": "TRX002",
        "description": "MANDIRI FROM BCA 123456789 HARDI PUTRA MUHARR"
    },
    {
        "transaction_id": "TRX003",
        "description": "MANDIRI ONLINE PAYMENT 555.00 BROOKLYN BOGA UTAM"
    }
]';

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] 
    @InputJSON = @JSON1,
    @Debug = 0;

PRINT '';
PRINT '✅ Test 5 Complete';
PRINT '';

-- =====================================================
-- TEST 6: SP_MANDIRI_FindBTP_Batch - With Debug
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 6: Batch Search - With Debug + Statistics';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @JSON2 NVARCHAR(MAX) = N'[
    {"transaction_id": "T1", "description": "MANDIRI 12345 RONNY YULIADY"},
    {"transaction_id": "T2", "description": "MANDIRI 67890 HARDI PUTRA MUHARR"},
    {"transaction_id": "T3", "description": "MANDIRI 11111 BROOKLYN BOGA UTAM"},
    {"transaction_id": "T4", "description": "MANDIRI 22222 PANCIOUS TIRTA JAY"},
    {"transaction_id": "T5", "description": "MANDIRI 33333 SUPER NORMAL SISTE"}
]';

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] 
    @InputJSON = @JSON2,
    @Debug = 1;

PRINT '';
PRINT '✅ Test 6 Complete';
PRINT '';

-- =====================================================
-- TEST 7: SP_MANDIRI_FindBTP_Batch - Without Transaction ID
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 7: Batch Search - Auto-generated Transaction IDs';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @JSON3 NVARCHAR(MAX) = N'[
    {"description": "MANDIRI E-BANKING CR 0201 455520.00 RONNY YULIADY"},
    {"description": "MANDIRI FROM BCA 123456789 HARDI PUTRA MUHARR"},
    {"description": "MANDIRI ONLINE 100000 BROOKLYN BOGA UTAM"}
]';

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] 
    @InputJSON = @JSON3,
    @Debug = 0;

PRINT '';
PRINT '✅ Test 7 Complete';
PRINT '';

-- =====================================================
-- TEST 8: SP_MANDIRI_FindBTP_Batch - Mixed Results
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 8: Batch Search - Mixed (Found + Not Found)';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @JSON4 NVARCHAR(MAX) = N'[
    {"transaction_id": "VALID1", "description": "MANDIRI 12345 RONNY YULIADY"},
    {"transaction_id": "INVALID1", "description": "MANDIRI 67890 UNKNOWN CUSTOMER XXXXX"},
    {"transaction_id": "VALID2", "description": "MANDIRI 11111 HARDI PUTRA MUHARR"},
    {"transaction_id": "INVALID2", "description": "MANDIRI 22222"},
    {"transaction_id": "VALID3", "description": "MANDIRI 33333 BROOKLYN BOGA UTAM"}
]';

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] 
    @InputJSON = @JSON4,
    @Debug = 1;

PRINT '';
PRINT '✅ Test 8 Complete';
PRINT '';

-- =====================================================
-- TEST 9: Performance Test - Large Batch
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'TEST 9: Performance Test - 20 Descriptions';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @JSON5 NVARCHAR(MAX) = N'[
    {"transaction_id": "PERF01", "description": "MANDIRI 001 RONNY YULIADY"},
    {"transaction_id": "PERF02", "description": "MANDIRI 002 HARDI PUTRA MUHARR"},
    {"transaction_id": "PERF03", "description": "MANDIRI 003 BROOKLYN BOGA UTAM"},
    {"transaction_id": "PERF04", "description": "MANDIRI 004 PANCIOUS TIRTA JAY"},
    {"transaction_id": "PERF05", "description": "MANDIRI 005 SUPER NORMAL SISTE"},
    {"transaction_id": "PERF06", "description": "MANDIRI 006 RONNY YULIADY"},
    {"transaction_id": "PERF07", "description": "MANDIRI 007 HARDI PUTRA MUHARR"},
    {"transaction_id": "PERF08", "description": "MANDIRI 008 BROOKLYN BOGA UTAM"},
    {"transaction_id": "PERF09", "description": "MANDIRI 009 PANCIOUS TIRTA JAY"},
    {"transaction_id": "PERF10", "description": "MANDIRI 010 SUPER NORMAL SISTE"},
    {"transaction_id": "PERF11", "description": "MANDIRI 011 RONNY YULIADY"},
    {"transaction_id": "PERF12", "description": "MANDIRI 012 HARDI PUTRA MUHARR"},
    {"transaction_id": "PERF13", "description": "MANDIRI 013 BROOKLYN BOGA UTAM"},
    {"transaction_id": "PERF14", "description": "MANDIRI 014 PANCIOUS TIRTA JAY"},
    {"transaction_id": "PERF15", "description": "MANDIRI 015 SUPER NORMAL SISTE"},
    {"transaction_id": "PERF16", "description": "MANDIRI 016 RONNY YULIADY"},
    {"transaction_id": "PERF17", "description": "MANDIRI 017 HARDI PUTRA MUHARR"},
    {"transaction_id": "PERF18", "description": "MANDIRI 018 BROOKLYN BOGA UTAM"},
    {"transaction_id": "PERF19", "description": "MANDIRI 019 PANCIOUS TIRTA JAY"},
    {"transaction_id": "PERF20", "description": "MANDIRI 020 SUPER NORMAL SISTE"}
]';

-- Enable timing
SET STATISTICS TIME ON;

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] 
    @InputJSON = @JSON5,
    @Debug = 0;

SET STATISTICS TIME OFF;

PRINT '';
PRINT '✅ Test 9 Complete (Check execution time above)';
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
PRINT 'Tests Run:';
PRINT '  1. ✅ Single search - basic';
PRINT '  2. ✅ Single search - with debug';
PRINT '  3. ✅ Single search - no pattern';
PRINT '  4. ✅ Single search - not in master';
PRINT '  5. ✅ Batch search - 3 items';
PRINT '  6. ✅ Batch search - with debug';
PRINT '  7. ✅ Batch search - auto transaction IDs';
PRINT '  8. ✅ Batch search - mixed results';
PRINT '  9. ✅ Performance test - 20 items';
PRINT '';
PRINT '📊 Expected Results:';
PRINT '  • Tests 1, 2: Should find BTP';
PRINT '  • Test 3: Should return NO_PATTERN';
PRINT '  • Test 4: Should return NO_MATCH';
PRINT '  • Tests 5-9: Should process all items';
PRINT '';
PRINT '⚠️  Note: Results depend on your master data content.';
PRINT '    Update test customer names to match your actual data.';
PRINT '';

-- =====================================================
-- QUICK VERIFICATION QUERIES
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════════════';
PRINT 'Quick Verification - Master Data Status';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

-- Check if master data exists
IF EXISTS (SELECT 1 FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] WHERE category = 'MANDIRI')
BEGIN
    SELECT 
        COUNT(*) AS TotalPatterns,
        COUNT(DISTINCT btp) AS UniqueBTPs,
        COUNT(DISTINCT customer_name) AS UniqueCustomers,
        AVG(match_percentage) AS AvgMatchPercentage,
        MIN(match_percentage) AS MinMatchPercentage,
        MAX(match_percentage) AS MaxMatchPercentage
    FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN]
    WHERE category = 'MANDIRI';
    
    PRINT '';
    PRINT '✅ Master data exists and loaded';
    PRINT '';
    
    -- Show sample patterns
    PRINT 'Sample Patterns (Top 10):';
    SELECT TOP 10 
        customer_name, 
        btp, 
        match_percentage,
        match_count,
        total_transactions
    FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN]
    WHERE category = 'MANDIRI'
    ORDER BY match_percentage DESC, total_transactions DESC;
END
ELSE
BEGIN
    PRINT '❌ ERROR: No MANDIRI master data found!';
    PRINT '   Please import master_customer_btp_pattern_MANDIRI.sql first.';
END

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════';
PRINT '';

