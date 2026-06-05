-- =====================================================
-- ALTER_ADD_accountCap_Accounts.sql
-- =====================================================
-- Purpose: Tambah kolom accountCap ke Accounts
-- =====================================================

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Updating Accounts table...';
PRINT '═══════════════════════════════════════════════════════════════════════';

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'Accounts'
      AND COLUMN_NAME = 'accountCap'
)
BEGIN
    ALTER TABLE [dbo].[Accounts]
    ADD [accountCap] NVARCHAR(255) NULL;
    PRINT '✅ Kolom accountCap ditambahkan ke Accounts';
END
ELSE
BEGIN
    PRINT '✓ Kolom accountCap sudah ada di Accounts';
END
GO

-- Pastikan tipe teks (bukan angka)
IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'Accounts'
      AND COLUMN_NAME = 'accountCap'
      AND DATA_TYPE IN ('float', 'real', 'decimal', 'numeric', 'int', 'bigint')
)
BEGIN
    ALTER TABLE [dbo].[Accounts]
    ALTER COLUMN [accountCap] NVARCHAR(255) NULL;
    PRINT 'Kolom accountCap diubah ke NVARCHAR(255)';
END
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Accounts'
  AND COLUMN_NAME = 'accountCap';
GO
