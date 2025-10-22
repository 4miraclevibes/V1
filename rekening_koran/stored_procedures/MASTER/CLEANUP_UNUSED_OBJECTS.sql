-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP: Drop Unused Objects
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   Drop stored procedures and tables that are NOT needed due to
--   nested INSERT-EXEC limitation
--
-- Objects to DROP:
--   ❌ SP_MASTER_FindBTP_Batch_ToStaging (nested INSERT-EXEC issue)
--   ❌ REKENING_KORAN_STAGING table (not needed for processing)
--
-- Objects to KEEP:
--   ✅ SP_MASTER_FindBTP_Batch (main SP - WORKS!)
--   ✅ All 20 bank-specific SPs (SP_TRSF_FindBTP_Batch, etc.)
--   ✅ MASTER_CUSTOMER_BTP_PATTERN table (pattern data)
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🧹 CLEANUP: Dropping Unused Objects';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- Drop Stored Procedures
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '📦 Dropping Stored Procedures...';
PRINT '';

-- SP_MASTER_FindBTP_Batch_ToStaging
IF OBJECT_ID('dbo.SP_MASTER_FindBTP_Batch_ToStaging', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.SP_MASTER_FindBTP_Batch_ToStaging;
    PRINT '  ✅ Dropped: SP_MASTER_FindBTP_Batch_ToStaging';
END
ELSE
BEGIN
    PRINT '  ⚠️  Not found: SP_MASTER_FindBTP_Batch_ToStaging';
END

-- SP_SAVE_TO_STAGING_DIRECT (if exists)
IF OBJECT_ID('dbo.SP_SAVE_TO_STAGING_DIRECT', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.SP_SAVE_TO_STAGING_DIRECT;
    PRINT '  ✅ Dropped: SP_SAVE_TO_STAGING_DIRECT';
END
ELSE
BEGIN
    PRINT '  ⚠️  Not found: SP_SAVE_TO_STAGING_DIRECT';
END

PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- Drop Tables
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '📊 Dropping Tables...';
PRINT '';

-- REKENING_KORAN_STAGING
IF OBJECT_ID('dbo.REKENING_KORAN_STAGING', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.REKENING_KORAN_STAGING;
    PRINT '  ✅ Dropped: REKENING_KORAN_STAGING';
END
ELSE
BEGIN
    PRINT '  ⚠️  Not found: REKENING_KORAN_STAGING';
END

PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- Verification
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ CLEANUP COMPLETE!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Verifying remaining objects...';
PRINT '';

-- List remaining stored procedures (should show main SP and bank SPs)
PRINT '📦 Stored Procedures (should have 21 total):';
PRINT '   - SP_MASTER_FindBTP_Batch (1)';
PRINT '   - SP_<BANK>_FindBTP_Batch (20)';
PRINT '';

SELECT 
    SCHEMA_NAME(schema_id) + '.' + name AS ProcedureName,
    create_date AS CreatedDate,
    modify_date AS ModifiedDate
FROM sys.procedures
WHERE name LIKE 'SP_%FindBTP%'
ORDER BY name;

PRINT '';
PRINT '📊 Tables (should have MASTER_CUSTOMER_BTP_PATTERN):';
PRINT '';

SELECT 
    SCHEMA_NAME(schema_id) + '.' + name AS TableName,
    create_date AS CreatedDate,
    modify_date AS ModifiedDate
FROM sys.tables
WHERE name LIKE 'MASTER_CUSTOMER%' OR name LIKE 'REKENING_KORAN%'
ORDER BY name;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🎯 EXPECTED OBJECTS:';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Stored Procedures (21 total):';
PRINT '  ✅ SP_MASTER_FindBTP_Batch';
PRINT '  ✅ SP_TRSF_FindBTP_Batch';
PRINT '  ✅ SP_BIFAST_FindBTP_Batch';
PRINT '  ✅ SP_MANDIRI_FindBTP_Batch';
PRINT '  ✅ SP_BNI_FindBTP_Batch';
PRINT '  ✅ SP_BTPN_FindBTP_Batch';
PRINT '  ✅ SP_BRI_FindBTP_Batch';
PRINT '  ✅ SP_MEGA_FindBTP_Batch';
PRINT '  ✅ SP_PERMATA_FindBTP_Batch';
PRINT '  ✅ SP_DANAMON_FindBTP_Batch';
PRINT '  ✅ SP_CITIBANK_FindBTP_Batch';
PRINT '  ✅ SP_SINARMAS_FindBTP_Batch';
PRINT '  ✅ SP_CIMB_FindBTP_Batch';
PRINT '  ✅ SP_MAYBANK_FindBTP_Batch';
PRINT '  ✅ SP_HSBC_FindBTP_Batch';
PRINT '  ✅ SP_UOB_FindBTP_Batch';
PRINT '  ✅ SP_MUAMALAT_FindBTP_Batch';
PRINT '  ✅ SP_OCBC_FindBTP_Batch';
PRINT '  ✅ SP_DBS_FindBTP_Batch';
PRINT '  ✅ SP_CAPITAL_FindBTP_Batch';
PRINT '  ✅ SP_WOORI_FindBTP_Batch';
PRINT '';
PRINT 'Tables (1 total):';
PRINT '  ✅ MASTER_CUSTOMER_BTP_PATTERN';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '🎉 CLEANUP DONE! Database is clean and ready for Power Apps!';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

