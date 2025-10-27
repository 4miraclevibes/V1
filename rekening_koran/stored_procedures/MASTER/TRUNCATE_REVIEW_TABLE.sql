-- ═══════════════════════════════════════════════════════════════════════════════
-- TRUNCATE BTP_REVIEW TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Purpose: Clear all data from BTP_REVIEW table (for testing/cleanup)
-- Warning: This will DELETE ALL data in BTP_REVIEW table!
-- ═══════════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════════════';
PRINT '⚠️  TRUNCATE BTP_REVIEW TABLE';
PRINT '═══════════════════════════════════════════════════════════════════════════════';
PRINT '';

-- Check if table exists
IF OBJECT_ID('dbo.BTP_REVIEW', 'U') IS NOT NULL
BEGIN
    -- Get row count before truncate
    DECLARE @RowCount INT;
    SELECT @RowCount = COUNT(*) FROM dbo.BTP_REVIEW;
    
    PRINT '📊 Current row count: ' + CAST(@RowCount AS VARCHAR);
    PRINT '';
    PRINT '⚠️  WARNING: About to delete all ' + CAST(@RowCount AS VARCHAR) + ' rows!';
    PRINT '';
    
    -- Truncate table (fast delete, resets identity)
    TRUNCATE TABLE dbo.BTP_REVIEW;
    
    PRINT '✅ Table BTP_REVIEW has been truncated successfully!';
    PRINT '✅ All data deleted';
    PRINT '✅ Identity seed reset to 1';
    PRINT '';
    
    -- Verify
    SELECT @RowCount = COUNT(*) FROM dbo.BTP_REVIEW;
    PRINT '📊 New row count: ' + CAST(@RowCount AS VARCHAR);
END
ELSE
BEGIN
    PRINT '❌ ERROR: Table BTP_REVIEW does not exist!';
    PRINT '   → Run CREATE_REVIEW_TABLE.sql first';
END

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════════════';
PRINT 'DONE!';
PRINT '═══════════════════════════════════════════════════════════════════════════════';
GO

