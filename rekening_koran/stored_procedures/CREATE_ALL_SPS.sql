-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE ALL BANK STORED PROCEDURES
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- This script creates stored procedures for ALL 20 banks:
-- - Group 1 (Array[3] + Array[4]): 9 banks
-- - Group 2 (Array[4] + Array[5]): 9 banks  
-- - Group 3 (Special Logic): 2 banks
--
-- Plus 1 MASTER stored procedure for auto-routing
--
-- Total: 21 stored procedures (20 banks + 1 master)
--
-- Author: Generated October 21, 2025
-- Version: 1.0.0
-- ═══════════════════════════════════════════════════════════════════════════

USE [YourDatabase];
GO

-- Note: Execute each section separately in sequence
-- Section order:
--   1. Group 1 Banks (BNI, BTPN, BRI, MEGA, PERMATA, DANAMON, CITIBANK, SINARMAS)
--   2. Group 2 Banks (CIMB, MAYBANK, HSBC, UOB, MUAMALAT, OCBC, DBS, CAPITAL, WOORI)
--   3. Group 3 Banks (TRSF, BIFAST) - Already exist, skip if already created
--   4. MASTER SP (Auto-routing)

PRINT 'Starting creation of all bank stored procedures...';
PRINT 'Total procedures to create: 21 (20 banks + 1 master)';
PRINT '';
PRINT 'Execution order:';
PRINT '  1. Group 1: Array[3] + Array[4] - 9 banks';
PRINT '  2. Group 2: Array[4] + Array[5] - 9 banks';
PRINT '  3. Group 3: Special Logic - 2 banks';
PRINT '  4. Master SP: Auto-routing';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Execute each file in the following order:';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '-- Group 1 (Array[3] + Array[4])';
PRINT ':r GROUP1/SP_BNI_FindBTP_Batch.sql';
PRINT ':r GROUP1/SP_BTPN_FindBTP_Batch.sql';
PRINT ':r GROUP1/SP_BRI_FindBTP_Batch.sql';
PRINT ':r GROUP1/SP_MEGA_FindBTP_Batch.sql';
PRINT ':r GROUP1/SP_PERMATA_FindBTP_Batch.sql';
PRINT ':r GROUP1/SP_DANAMON_FindBTP_Batch.sql';
PRINT ':r GROUP1/SP_CITIBANK_FindBTP_Batch.sql';
PRINT ':r GROUP1/SP_SINARMAS_FindBTP_Batch.sql';
PRINT ':r GROUP1/SP_MANDIRI_FindBTP_Batch.sql';  -- Already exists
PRINT '';
PRINT '-- Group 2 (Array[4] + Array[5])';
PRINT ':r GROUP2/SP_CIMB_FindBTP_Batch.sql';
PRINT ':r GROUP2/SP_MAYBANK_FindBTP_Batch.sql';
PRINT ':r GROUP2/SP_HSBC_FindBTP_Batch.sql';
PRINT ':r GROUP2/SP_UOB_FindBTP_Batch.sql';
PRINT ':r GROUP2/SP_MUAMALAT_FindBTP_Batch.sql';
PRINT ':r GROUP2/SP_OCBC_FindBTP_Batch.sql';
PRINT ':r GROUP2/SP_DBS_FindBTP_Batch.sql';
PRINT ':r GROUP2/SP_CAPITAL_FindBTP_Batch.sql';
PRINT ':r GROUP2/SP_WOORI_FindBTP_Batch.sql';
PRINT '';
PRINT '-- Group 3 (Special Logic)';
PRINT ':r TRSF/SP_TRSF_FindBTP_Batch.sql';      -- Already exists
PRINT ':r BIFAST/SP_BIFAST_FindBTP_Batch.sql';  -- Already exists
PRINT '';
PRINT '-- Master SP (Auto-routing)';
PRINT ':r MASTER/SP_MASTER_FindBTP_Batch.sql';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

