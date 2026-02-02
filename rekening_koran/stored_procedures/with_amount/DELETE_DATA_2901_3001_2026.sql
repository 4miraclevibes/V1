-- =====================================================
-- DELETE_DATA_2901_3001_2026.sql
-- =====================================================
-- Purpose: Hapus data di BTP_REVIEW dan MP_REKENING_KORAN
--          where created_at tanggal 29-01-2026 dan 30-01-2026
-- =====================================================

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════
-- 1. DELETE BTP_REVIEW
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '1. Deleting from BTP_REVIEW (CreatedAt = 29-01-2026, 30-01-2026)...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @BTP_Count INT;
SELECT @BTP_Count = COUNT(*)
FROM [dbo].[BTP_REVIEW]
WHERE CAST(CreatedAt AS DATE) IN ('2026-01-29', '2026-01-30');

PRINT '   Rows to delete: ' + CAST(@BTP_Count AS VARCHAR);

DELETE FROM [dbo].[BTP_REVIEW]
WHERE CAST(CreatedAt AS DATE) IN ('2026-01-29', '2026-01-30');

PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows from BTP_REVIEW';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════
-- 2. DELETE MP_REKENING_KORAN
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '2. Deleting from MP_REKENING_KORAN (created_at = 29-01-2026, 30-01-2026)...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @MP_Count INT;
SELECT @MP_Count = COUNT(*)
FROM [dbo].[MP_REKENING_KORAN]
WHERE CAST(created_at AS DATE) IN ('2026-01-29', '2026-01-30');

PRINT '   Rows to delete: ' + CAST(@MP_Count AS VARCHAR);

DELETE FROM [dbo].[MP_REKENING_KORAN]
WHERE CAST(created_at AS DATE) IN ('2026-01-29', '2026-01-30');

PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows from MP_REKENING_KORAN';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════
-- 3. Summary
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ DELETE_DATA_2901_3001_2026.sql completed!';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
