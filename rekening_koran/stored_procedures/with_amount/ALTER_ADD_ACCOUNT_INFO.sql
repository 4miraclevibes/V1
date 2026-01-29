-- =====================================================
-- ALTER_ADD_ACCOUNT_INFO.sql
-- =====================================================
-- Purpose: Tambah kolom AccountNumber dan AccountName ke BTP_REVIEW dan MP_REKENING_KORAN
-- Data dari converter.html: accountInfo.accountNumber, accountInfo.accountName
-- =====================================================

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════
-- 1. ALTER BTP_REVIEW - Tambah AccountNumber dan AccountName
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '1. Updating BTP_REVIEW table...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Tambah AccountNumber
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'BTP_REVIEW' AND COLUMN_NAME = 'AccountNumber'
)
BEGIN
    ALTER TABLE [dbo].[BTP_REVIEW]
    ADD [AccountNumber] NVARCHAR(50) NULL;
    PRINT '✅ Kolom AccountNumber ditambahkan ke BTP_REVIEW';
END
ELSE
BEGIN
    PRINT '✓ Kolom AccountNumber sudah ada di BTP_REVIEW';
END
GO

-- Tambah AccountName
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'BTP_REVIEW' AND COLUMN_NAME = 'AccountName'
)
BEGIN
    ALTER TABLE [dbo].[BTP_REVIEW]
    ADD [AccountName] NVARCHAR(200) NULL;
    PRINT '✅ Kolom AccountName ditambahkan ke BTP_REVIEW';
END
ELSE
BEGIN
    PRINT '✓ Kolom AccountName sudah ada di BTP_REVIEW';
END
GO

-- ═══════════════════════════════════════════════════════════════════════
-- 2. ALTER MP_REKENING_KORAN - Tambah AccountNumber dan AccountName
-- ═══════════════════════════════════════════════════════════════════════

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '2. Updating MP_REKENING_KORAN table...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Tambah AccountNumber
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MP_REKENING_KORAN' AND COLUMN_NAME = 'AccountNumber'
)
BEGIN
    ALTER TABLE [dbo].[MP_REKENING_KORAN]
    ADD [AccountNumber] NVARCHAR(50) NULL;
    PRINT '✅ Kolom AccountNumber ditambahkan ke MP_REKENING_KORAN';
END
ELSE
BEGIN
    PRINT '✓ Kolom AccountNumber sudah ada di MP_REKENING_KORAN';
END
GO

-- Tambah AccountName
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MP_REKENING_KORAN' AND COLUMN_NAME = 'AccountName'
)
BEGIN
    ALTER TABLE [dbo].[MP_REKENING_KORAN]
    ADD [AccountName] NVARCHAR(200) NULL;
    PRINT '✅ Kolom AccountName ditambahkan ke MP_REKENING_KORAN';
END
ELSE
BEGIN
    PRINT '✓ Kolom AccountName sudah ada di MP_REKENING_KORAN';
END
GO

-- ═══════════════════════════════════════════════════════════════════════
-- 3. Verifikasi struktur tabel
-- ═══════════════════════════════════════════════════════════════════════

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '3. Verifikasi struktur...';
PRINT '═══════════════════════════════════════════════════════════════════════';

SELECT 
    'BTP_REVIEW' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'BTP_REVIEW'
AND COLUMN_NAME IN ('AccountNumber', 'AccountName')
UNION ALL
SELECT 
    'MP_REKENING_KORAN' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_REKENING_KORAN'
AND COLUMN_NAME IN ('AccountNumber', 'AccountName')
ORDER BY TableName, COLUMN_NAME;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ ALTER_ADD_ACCOUNT_INFO.sql completed!';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
