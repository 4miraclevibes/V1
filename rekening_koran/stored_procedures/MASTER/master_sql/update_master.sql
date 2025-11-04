-- ═══════════════════════════════════════════════════════════════════════════
-- UPDATE: Update category 'UNKNOWN' to 'NEW' and total_transactions to 100
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Database: POWERAPPS
-- Table: [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
--
-- Purpose:
--   Update semua record yang category = 'UNKNOWN' menjadi:
--   - category = 'NEW'
--   - total_transactions = 100
--
-- ═══════════════════════════════════════════════════════════════════════════

USE [POWERAPPS];
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Updating records with category = ''UNKNOWN''...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Get count of records to be updated
DECLARE @RecordsToUpdate INT;
SELECT @RecordsToUpdate = COUNT(*) 
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
WHERE [category] = 'UNKNOWN';

PRINT 'Total records with category = ''UNKNOWN'': ' + CAST(@RecordsToUpdate AS VARCHAR);
PRINT '';

IF @RecordsToUpdate = 0
BEGIN
    PRINT '⚠️  No records found with category = ''UNKNOWN''. Nothing to update.';
    PRINT '';
    RETURN;
END

-- Update records
BEGIN TRY
    BEGIN TRANSACTION;
    
    UPDATE [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
    SET 
        [category] = 'NEW',
        [total_transactions] = 100
    WHERE [category] = 'UNKNOWN';
    
    DECLARE @RowsUpdated INT = @@ROWCOUNT;
    
    COMMIT TRANSACTION;
    
    PRINT '✅ Update completed successfully!';
    PRINT '   Records updated: ' + CAST(@RowsUpdated AS VARCHAR);
    PRINT '';
    PRINT 'Changes applied:';
    PRINT '   - category: ''UNKNOWN'' → ''NEW''';
    PRINT '   - total_transactions: → 100';
    PRINT '';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT '❌ Error occurred during update:';
    PRINT '   Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT '   Error Message: ' + ERROR_MESSAGE();
    PRINT '';
    RETURN;
END CATCH
GO

-- Verify update results
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Verifying update results...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Check category distribution
PRINT 'Category distribution:';
SELECT 
    [category],
    COUNT(*) AS RecordCount
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
GROUP BY [category]
ORDER BY [category];
GO

PRINT '';
PRINT 'Records with category = ''NEW'' and total_transactions = 100:';
SELECT 
    COUNT(*) AS RecordCount
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
WHERE [category] = 'NEW' AND [total_transactions] = 100;
GO

PRINT '';
PRINT '✅ Script completed!';
PRINT '';
