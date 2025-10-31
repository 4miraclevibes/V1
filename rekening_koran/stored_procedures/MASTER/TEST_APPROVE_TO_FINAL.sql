-- ═══════════════════════════════════════════════════════════════════════════
-- TEST: SP_MASTER_ApproveToFinal
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   Test script untuk verify SP_MASTER_ApproveToFinal bekerja dengan benar
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 1: Check data sebelum approval
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📊 BEFORE APPROVAL - CHECKING DATA';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Count by status (belum approved)
SELECT 
    Status,
    COUNT(*) AS Count,
    COUNT(CASE WHEN IsApproved = 0 THEN 1 END) AS NotApproved,
    COUNT(CASE WHEN IsApproved = 1 THEN 1 END) AS Approved
FROM [POWERAPPS].[dbo].[BTP_REVIEW]
WHERE Status IN ('FAIR', 'GOOD', 'EXCELLENT')
GROUP BY Status
ORDER BY Status;

PRINT '';
PRINT 'Total rows ready for approval:';
SELECT COUNT(*) AS ReadyForApproval
FROM [POWERAPPS].[dbo].[BTP_REVIEW]
WHERE Status IN ('FAIR', 'GOOD', 'EXCELLENT')
    AND IsApproved = 0;

PRINT '';
PRINT 'Current MP_REKENING_KORAN count:';
SELECT COUNT(*) AS CurrentCount
FROM [POWERAPPS].[dbo].[MP_REKENING_KORAN];

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 2: Execute SP
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🚀 EXECUTING SP_MASTER_ApproveToFinal';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

EXEC [dbo].[SP_MASTER_ApproveToFinal] 
    @ApprovedBy = 'TEST_USER@company.com';

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 3: Check data setelah approval
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '📊 AFTER APPROVAL - VERIFICATION';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Count by status (setelah approval)
SELECT 
    Status,
    COUNT(*) AS TotalCount,
    COUNT(CASE WHEN IsApproved = 0 THEN 1 END) AS NotApproved,
    COUNT(CASE WHEN IsApproved = 1 THEN 1 END) AS Approved
FROM [POWERAPPS].[dbo].[BTP_REVIEW]
WHERE Status IN ('FAIR', 'GOOD', 'EXCELLENT')
GROUP BY Status
ORDER BY Status;

PRINT '';
PRINT 'Total rows still not approved:';
SELECT COUNT(*) AS StillNotApproved
FROM [POWERAPPS].[dbo].[BTP_REVIEW]
WHERE Status IN ('FAIR', 'GOOD', 'EXCELLENT')
    AND IsApproved = 0;

PRINT '';
PRINT 'New MP_REKENING_KORAN count:';
SELECT COUNT(*) AS NewCount
FROM [POWERAPPS].[dbo].[MP_REKENING_KORAN];

PRINT '';
PRINT 'Recently inserted (last 5 rows):';
SELECT TOP 5
    [id],
    [trx_date],
    [credit],
    [btp],
    LEFT([desc], 50) AS [desc],
    [created_at]
FROM [POWERAPPS].[dbo].[MP_REKENING_KORAN]
ORDER BY [created_at] DESC;

PRINT '';
PRINT 'Sample approved records from BTP_REVIEW:';
SELECT TOP 5
    ID,
    TransactionID,
    Status,
    BTP,
    IsApproved,
    ApprovedBy,
    ApprovedAt,
    LEFT(Description, 50) AS Description
FROM [POWERAPPS].[dbo].[BTP_REVIEW]
WHERE IsApproved = 1
    AND Status IN ('FAIR', 'GOOD', 'EXCELLENT')
ORDER BY ApprovedAt DESC;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ TEST COMPLETED!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
GO

