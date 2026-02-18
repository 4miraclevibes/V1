-- =====================================================
-- UTILITY_DeleteNullApprovedBy_ResetBTP.sql
-- =====================================================
-- Purpose: 
--   1. Delete data di MP_REKENING_KORAN where btn IS NULL
--   2. Update BTP_REVIEW: Set IsApproved = 0 (reset) untuk BatchID yang sama
--      supaya bisa di-reapprove lewat Power Apps (dengan btn dari CustomerName)
--
-- Jalankan script ini sesering diperlukan untuk cleanup data lama yang btn NULL
-- =====================================================

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════
-- 1. Simpan BatchID yang akan di-delete (btn NULL)
-- ═══════════════════════════════════════════════════════════════════════

DECLARE @BatchIDsToReset TABLE (BatchID NVARCHAR(100));

INSERT INTO @BatchIDsToReset (BatchID)
SELECT DISTINCT BatchID
FROM [dbo].[MP_REKENING_KORAN]
WHERE btn IS NULL
  AND BatchID IS NOT NULL
  AND LTRIM(RTRIM(ISNULL(BatchID, ''))) <> '';

DECLARE @BatchCount INT = (SELECT COUNT(*) FROM @BatchIDsToReset);

-- ═══════════════════════════════════════════════════════════════════════
-- 2. DELETE MP_REKENING_KORAN (btn IS NULL)
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '1. Deleting from MP_REKENING_KORAN (btn IS NULL)...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @MP_Count INT;
SELECT @MP_Count = COUNT(*)
FROM [dbo].[MP_REKENING_KORAN]
WHERE btn IS NULL;

PRINT '   Rows to delete: ' + CAST(@MP_Count AS VARCHAR);

DELETE FROM [dbo].[MP_REKENING_KORAN]
WHERE btn IS NULL;

PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows from MP_REKENING_KORAN';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════
-- 3. UPDATE BTP_REVIEW: IsApproved = 0 untuk BatchID yang sama
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '2. Resetting BTP_REVIEW (IsApproved = 0) for BatchIDs: ' + CAST(@BatchCount AS VARCHAR);
PRINT '═══════════════════════════════════════════════════════════════════════';

UPDATE [dbo].[BTP_REVIEW]
SET 
    [IsApproved] = 0,
    [ApprovedBy] = NULL,
    [ApprovedAt] = NULL,
    [ModifiedAt] = GETDATE()
WHERE BatchID IN (SELECT BatchID FROM @BatchIDsToReset);

PRINT '✅ Updated ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows in BTP_REVIEW (IsApproved = 0)';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════
-- 4. Summary
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ UTILITY_DeleteNullApprovedBy_ResetBTP.sql completed!';
PRINT '   - MP_REKENING_KORAN: ' + CAST(@MP_Count AS VARCHAR) + ' rows deleted (btn NULL)';
PRINT '   - BTP_REVIEW: ' + CAST(@BatchCount AS VARCHAR) + ' BatchIDs reset (IsApproved = 0)';
PRINT '   → Data siap di-reapprove lewat Power Apps';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
