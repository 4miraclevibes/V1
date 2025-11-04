-- ═══════════════════════════════════════════════════════════════════════════
-- ALTER TABLE: Add 'type' Column to MASTER_CUSTOMER_BTP_PATTERN
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Database: POWERAPPS
-- Table: [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
--
-- Purpose:
--   Menambahkan kolom 'type' ke tabel MASTER_CUSTOMER_BTP_PATTERN
--   Kolom ini nullable dengan default NULL
--
-- ═══════════════════════════════════════════════════════════════════════════

USE [POWERAPPS];
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Adding column ''type'' to MASTER_CUSTOMER_BTP_PATTERN...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Check if column already exists
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'dbo' 
    AND TABLE_NAME = 'MASTER_CUSTOMER_BTP_PATTERN' 
    AND COLUMN_NAME = 'type'
)
BEGIN
    PRINT '⚠️  Column ''type'' already exists. Skipping...';
    PRINT '';
END
ELSE
BEGIN
    -- Add column 'type' (nullable, default NULL)
    ALTER TABLE [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
    ADD [type] NVARCHAR(50) NULL;
    
    PRINT '✅ Column ''type'' added successfully!';
    PRINT '';
    PRINT 'Column details:';
    PRINT '  - Name: type';
    PRINT '  - Type: NVARCHAR(50)';
    PRINT '  - Nullable: YES';
    PRINT '  - Default: NULL';
    PRINT '';
END
GO

-- Verify column was added
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Verifying column structure...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' 
    AND TABLE_NAME = 'MASTER_CUSTOMER_BTP_PATTERN' 
    AND COLUMN_NAME = 'type';
GO

PRINT '';
PRINT '✅ Script completed!';
PRINT '';
