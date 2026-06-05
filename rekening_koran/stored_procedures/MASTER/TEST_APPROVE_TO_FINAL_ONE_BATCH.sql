-- ═══════════════════════════════════════════════════════════════════════════
-- TEST: SP_MASTER_ApproveToFinal (Single Batch Validation)
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Purpose:
--   Validasi eksekusi approval dengan fokus 1 batch tertentu.
--   Script ini tetap memanggil SP tanpa parameter batch (sesuai SP saat ini),
--   tapi hasil verifikasi akan menunjukkan:
--     1) perubahan pada batch target
--     2) apakah ada batch lain ikut ter-update
--
-- Batch target:
--   BATCH_20260528_032302
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

DECLARE @BatchID NVARCHAR(100) = 'BATCH_20260528_032302';
DECLARE @TestStartedAt DATETIME = GETDATE();
DECLARE @ApprovedBy NVARCHAR(255) = 'TEST_SINGLE_BATCH_20260528@company.com';

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🧪 SINGLE BATCH TEST - SP_MASTER_ApproveToFinal';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Target BatchID : ' + @BatchID;
PRINT 'Test ApprovedBy: ' + @ApprovedBy;
PRINT 'Started At     : ' + CONVERT(VARCHAR, @TestStartedAt, 120);
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 1: PRE-CHECK (Batch target)
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '📊 PRE-CHECK TARGET BATCH';
PRINT '';

SELECT
    COUNT(*) AS Target_TotalRows,
    SUM(CASE WHEN IsApproved = 0 THEN 1 ELSE 0 END) AS Target_NotApproved,
    SUM(CASE WHEN IsApproved = 1 THEN 1 ELSE 0 END) AS Target_AlreadyApproved,
    SUM(CASE WHEN Status IN ('FAIR','GOOD','EXCELLENT') THEN 1 ELSE 0 END) AS Target_StatusEligible,
    SUM(
        CASE
            WHEN Status IN ('FAIR','GOOD','EXCELLENT')
                 AND IsApproved = 0
                 AND ISNULL(TransactionType, 'CR') = 'CR'
                 AND ISNULL(LTRIM(RTRIM(BTP)), '') <> ''
            THEN 1 ELSE 0
        END
    ) AS Target_ReadyToProcess
FROM [dbo].[BTP_REVIEW]
WHERE BatchID = @BatchID;

PRINT '';
PRINT 'Detail status di target batch:';
SELECT
    Status,
    COUNT(*) AS Cnt,
    SUM(CASE WHEN IsApproved = 0 THEN 1 ELSE 0 END) AS NotApproved,
    SUM(CASE WHEN IsApproved = 1 THEN 1 ELSE 0 END) AS Approved
FROM [dbo].[BTP_REVIEW]
WHERE BatchID = @BatchID
GROUP BY Status
ORDER BY Status;

PRINT '';
PRINT '📌 PRE-CHECK NON-TARGET (eligible rows di batch lain)';
SELECT COUNT(*) AS NonTarget_ReadyToProcess
FROM [dbo].[BTP_REVIEW]
WHERE BatchID <> @BatchID
    AND Status IN ('FAIR','GOOD','EXCELLENT')
    AND IsApproved = 0
    AND ISNULL(TransactionType, 'CR') = 'CR'
    AND ISNULL(LTRIM(RTRIM(BTP)), '') <> '';

-- Snapshot before untuk target batch
IF OBJECT_ID('tempdb..#BeforeTarget') IS NOT NULL DROP TABLE #BeforeTarget;
SELECT
    ID,
    BatchID,
    Status,
    TransactionType,
    BTP,
    IsApproved,
    ApprovedBy,
    ApprovedAt
INTO #BeforeTarget
FROM [dbo].[BTP_REVIEW]
WHERE BatchID = @BatchID;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🚀 EXEC SP_MASTER_ApproveToFinal';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

EXEC [dbo].[SP_MASTER_ApproveToFinal]
    @ApprovedBy = @ApprovedBy;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📊 POST-CHECK';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

PRINT '1) Perubahan pada TARGET batch';
SELECT
    COUNT(*) AS Target_ChangedToApproved_ByThisRun
FROM [dbo].[BTP_REVIEW] r
INNER JOIN #BeforeTarget b ON b.ID = r.ID
WHERE b.IsApproved = 0
    AND r.IsApproved = 1
    AND r.ApprovedBy = @ApprovedBy
    AND r.ApprovedAt >= @TestStartedAt;

SELECT
    r.ID,
    r.BatchID,
    r.Status,
    r.TransactionType,
    r.BTP,
    b.IsApproved AS Before_IsApproved,
    r.IsApproved AS After_IsApproved,
    r.ApprovedBy,
    r.ApprovedAt
FROM [dbo].[BTP_REVIEW] r
INNER JOIN #BeforeTarget b ON b.ID = r.ID
WHERE b.IsApproved = 0
    AND r.IsApproved = 1
    AND r.ApprovedBy = @ApprovedBy
    AND r.ApprovedAt >= @TestStartedAt
ORDER BY r.ApprovedAt DESC, r.ID DESC;

PRINT '';
PRINT '2) Apakah ada NON-TARGET batch yang ikut ke-update pada run ini?';
SELECT
    COUNT(*) AS NonTarget_ChangedToApproved_ByThisRun
FROM [dbo].[BTP_REVIEW]
WHERE BatchID <> @BatchID
    AND IsApproved = 1
    AND ApprovedBy = @ApprovedBy
    AND ApprovedAt >= @TestStartedAt;

SELECT TOP 50
    ID,
    BatchID,
    Status,
    TransactionType,
    BTP,
    IsApproved,
    ApprovedBy,
    ApprovedAt
FROM [dbo].[BTP_REVIEW]
WHERE BatchID <> @BatchID
    AND IsApproved = 1
    AND ApprovedBy = @ApprovedBy
    AND ApprovedAt >= @TestStartedAt
ORDER BY ApprovedAt DESC, ID DESC;

PRINT '';
PRINT '3) Data MP_REKENING_KORAN yang ter-insert untuk batch target pada run ini';
SELECT
    COUNT(*) AS Target_Inserted_To_MP
FROM [dbo].[MP_REKENING_KORAN]
WHERE BatchID = @BatchID
    AND approved_by = @ApprovedBy
    AND created_at >= @TestStartedAt;

SELECT TOP 50
    id,
    BatchID,
    btp,
    [desc],
    Amount,
    TransactionType,
    approved_by,
    created_at
FROM [dbo].[MP_REKENING_KORAN]
WHERE BatchID = @BatchID
    AND approved_by = @ApprovedBy
    AND created_at >= @TestStartedAt
ORDER BY created_at DESC, id DESC;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ SINGLE BATCH TEST COMPLETED';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
GO

