-- ═══════════════════════════════════════════════════════════════════════════
-- UPDATE: Set all records to 'MT' in MASTER_CUSTOMER_BTP_PATTERN
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Database: POWERAPPS
-- Table: [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
--
-- Purpose:
--   Update semua record existing di tabel MASTER_CUSTOMER_BTP_PATTERN
--   Set kolom 'type' = 'MT' untuk semua data yang sudah ada
--
-- ═══════════════════════════════════════════════════════════════════════════

USE [POWERAPPS];
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Updating all records to type = ''MT''...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Check if column exists
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'dbo' 
    AND TABLE_NAME = 'MASTER_CUSTOMER_BTP_PATTERN' 
    AND COLUMN_NAME = 'type'
)
BEGIN
    PRINT '❌ Column ''type'' does not exist!';
    PRINT '   Please run add_type_column.sql first.';
    PRINT '';
    RETURN;
END

-- Get total record count before update
DECLARE @TotalRecords INT;
SELECT @TotalRecords = COUNT(*) 
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN];

PRINT 'Total records in table: ' + CAST(@TotalRecords AS VARCHAR);
PRINT '';

-- Get count of records that will be updated (NULL or different value)
DECLARE @RecordsToUpdate INT;
SELECT @RecordsToUpdate = COUNT(*) 
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
WHERE [type] IS NULL OR [type] <> 'MT';

PRINT 'Records to update: ' + CAST(@RecordsToUpdate AS VARCHAR);
PRINT '';

-- Update all records to 'MT'
BEGIN TRY
    BEGIN TRANSACTION;
    
    UPDATE [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
    SET [type] = 'MT'
    WHERE [type] IS NULL OR [type] <> 'MT';
    
    DECLARE @RowsUpdated INT = @@ROWCOUNT;
    
    COMMIT TRANSACTION;
    
    PRINT '✅ Update completed successfully!';
    PRINT '   Rows updated: ' + CAST(@RowsUpdated AS VARCHAR);
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

SELECT 
    [type],
    COUNT(*) AS RecordCount
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
GROUP BY [type]
ORDER BY [type];
GO

PRINT '';
PRINT '✅ Script completed!';
PRINT '';
