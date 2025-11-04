-- ═══════════════════════════════════════════════════════════════════════════
-- FIX: Add Category Fallback untuk SP_TRSF_FindBTP_Batch
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Problem:
--   Data master dengan category = 'NEW' tidak ditemukan karena SP hanya
--   mencari di category = 'TRSF'
--
-- Solution:
--   Tambahkan fallback ke category = 'NEW' dengan prioritas lebih rendah
--   (category = 'TRSF' tetap prioritas utama)
--
-- Usage:
--   Jalankan script ini untuk update SP_TRSF_FindBTP_Batch
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Fixing SP_TRSF_FindBTP_Batch: Adding category fallback to ''NEW''';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Drop existing SP
IF OBJECT_ID('dbo.SP_TRSF_FindBTP_Batch', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.SP_TRSF_FindBTP_Batch;
    PRINT '✅ Dropped existing SP_TRSF_FindBTP_Batch';
END
GO

-- Create updated SP with category fallback
-- NOTE: This is a partial script - you need to copy the full SP_TRSF_FindBTP_Batch.sql
-- and modify the WHERE clauses as shown below
PRINT '';
PRINT '⚠️  IMPORTANT: This is a reference script only!';
PRINT '';
PRINT 'To fix SP_TRSF_FindBTP_Batch, you need to:';
PRINT '1. Open: rekening_koran/stored_procedures/TRSF/SP_TRSF_FindBTP_Batch.sql';
PRINT '2. Find all WHERE clauses with: WHERE m.category = ''TRSF''';
PRINT '3. Replace with: WHERE (m.category = ''TRSF'' OR m.category = ''NEW'')';
PRINT '4. Add ORDER BY with priority for TRSF category';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'CHANGES TO MAKE:';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Show the exact changes needed
PRINT 'Change 1: COUNT query (around line ~165)';
PRINT '────────────────────────────────────────────────────────────────────';
PRINT 'BEFORE:';
PRINT '  SELECT @TotalOptions = COUNT(DISTINCT btp)';
PRINT '  FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m';
PRINT '  WHERE m.category = ''TRSF''';
PRINT '      AND UPPER(m.customer_name) = UPPER(@CustomerName);';
PRINT '';
PRINT 'AFTER:';
PRINT '  SELECT @TotalOptions = COUNT(DISTINCT btp)';
PRINT '  FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m';
PRINT '  WHERE (m.category = ''TRSF'' OR m.category = ''NEW'')';
PRINT '      AND UPPER(m.customer_name) = UPPER(@CustomerName);';
PRINT '';

PRINT 'Change 2: INSERT into @TempOptions (around line ~185)';
PRINT '────────────────────────────────────────────────────────────────────';
PRINT 'BEFORE:';
PRINT '  FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m';
PRINT '  WHERE m.category = ''TRSF''';
PRINT '      AND UPPER(m.customer_name) = UPPER(@CustomerName);';
PRINT '';
PRINT 'AFTER:';
PRINT '  FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m';
PRINT '  WHERE (m.category = ''TRSF'' OR m.category = ''NEW'')';
PRINT '      AND UPPER(m.customer_name) = UPPER(@CustomerName)';
PRINT '  ORDER BY';
PRINT '      CASE WHEN m.category = ''TRSF'' THEN 1 ELSE 2 END,  -- TRSF priority first';
PRINT '      m.match_percentage DESC,';
PRINT '      m.total_transactions DESC,';
PRINT '      m.last_line_number DESC;';
PRINT '';

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'After making changes:';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '1. Save the modified SP_TRSF_FindBTP_Batch.sql file';
PRINT '2. Run the modified file to recreate the SP';
PRINT '3. Test with data that has category = ''NEW''';
PRINT '';
PRINT 'Test query:';
PRINT '────────────────────────────────────────────────────────────────────';
PRINT 'DECLARE @JSON NVARCHAR(MAX) = N''[';
PRINT '  {"transaction_id": 1, "description": "TRSF ... [CUSTOMER_NAME_FROM_NEW_CATEGORY]"}';
PRINT ']'';';
PRINT '';
PRINT 'EXEC SP_TRSF_FindBTP_Batch @InputJSON = @JSON;';
PRINT '';
PRINT 'Expected: Should find BTP even if customer is in category = ''NEW''';
PRINT '';

GO
