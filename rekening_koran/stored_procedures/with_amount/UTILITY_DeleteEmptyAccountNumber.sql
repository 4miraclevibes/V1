-- =====================================================
-- UTILITY_DeleteEmptyAccountNumber.sql
-- =====================================================
-- Purpose: Delete data yang AccountNumber kosong (NULL atau string kosong)
--   dari [POWERAPPS].[dbo].[BTP_REVIEW] dan [POWERAPPS].[dbo].[MP_REKENING_KORAN]
--
-- Kondisi: AccountNumber IS NULL OR LTRIM(RTRIM(AccountNumber)) = ''
-- =====================================================

USE [POWERAPPS];
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'UTILITY_DeleteEmptyAccountNumber';
PRINT 'Menghapus data dengan AccountNumber kosong';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════
-- 1. BTP_REVIEW
-- ═══════════════════════════════════════════════════════════════════════

DECLARE @BTP_Count INT;
SELECT @BTP_Count = COUNT(*)
FROM [dbo].[BTP_REVIEW]
WHERE AccountNumber IS NULL
   OR LTRIM(RTRIM(ISNULL(AccountNumber, ''))) = '';

PRINT '1. BTP_REVIEW';
PRINT '   Rows dengan AccountNumber kosong: ' + CAST(ISNULL(@BTP_Count, 0) AS VARCHAR);

DELETE FROM [dbo].[BTP_REVIEW]
WHERE AccountNumber IS NULL
   OR LTRIM(RTRIM(ISNULL(AccountNumber, ''))) = '';

PRINT '   ✅ Deleted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════
-- 2. MP_REKENING_KORAN
-- ═══════════════════════════════════════════════════════════════════════

DECLARE @MP_Count INT;
SELECT @MP_Count = COUNT(*)
FROM [dbo].[MP_REKENING_KORAN]
WHERE AccountNumber IS NULL
   OR LTRIM(RTRIM(ISNULL(AccountNumber, ''))) = '';

PRINT '2. MP_REKENING_KORAN';
PRINT '   Rows dengan AccountNumber kosong: ' + CAST(ISNULL(@MP_Count, 0) AS VARCHAR);

DELETE FROM [dbo].[MP_REKENING_KORAN]
WHERE AccountNumber IS NULL
   OR LTRIM(RTRIM(ISNULL(AccountNumber, ''))) = '';

PRINT '   ✅ Deleted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ UTILITY_DeleteEmptyAccountNumber completed!';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
