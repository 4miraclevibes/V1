-- =====================================================
-- DELETE_DATA_DIGICARE_2026.sql
-- =====================================================
-- Purpose: Hapus data di BTP_REVIEW (UploadedBy) dan MP_REKENING_KORAN (approved_by)
--          where UploadedBy/approved_by = 'digicare@greenfieldsdairy.com'
-- =====================================================

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════
-- 1. DELETE BTP_REVIEW (UploadedBy = digicare@greenfieldsdairy.com)
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '1. Deleting from BTP_REVIEW (UploadedBy = digicare@greenfieldsdairy.com)...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @BTP_Count INT;
SELECT @BTP_Count = COUNT(*)
FROM [dbo].[BTP_REVIEW]
WHERE UploadedBy = 'digicare@greenfieldsdairy.com';

PRINT '   Rows to delete: ' + CAST(@BTP_Count AS VARCHAR);

DELETE FROM [dbo].[BTP_REVIEW]
WHERE UploadedBy = 'digicare@greenfieldsdairy.com';

PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows from BTP_REVIEW';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════
-- 2. DELETE MP_REKENING_KORAN (approved_by = digicare@greenfieldsdairy.com)
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '2. Deleting from MP_REKENING_KORAN (approved_by = digicare@greenfieldsdairy.com)...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @MP_Count INT;
SELECT @MP_Count = COUNT(*)
FROM [dbo].[MP_REKENING_KORAN]
WHERE approved_by = 'digicare@greenfieldsdairy.com';

PRINT '   Rows to delete: ' + CAST(@MP_Count AS VARCHAR);

DELETE FROM [dbo].[MP_REKENING_KORAN]
WHERE approved_by = 'digicare@greenfieldsdairy.com';

PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows from MP_REKENING_KORAN';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════
-- 3. Summary
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ DELETE_DATA_DIGICARE_2026.sql completed!';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
