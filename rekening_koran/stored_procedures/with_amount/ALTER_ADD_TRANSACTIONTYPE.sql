-- =====================================================
-- ALTER_ADD_TRANSACTIONTYPE.sql
-- =====================================================
-- Purpose: Tambah kolom TransactionType ke MP_REKENING_KORAN
-- - TransactionType: NVARCHAR(2) - CR atau DB (dari BTP_REVIEW)
-- =====================================================

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════
-- ALTER MP_REKENING_KORAN - Tambah TransactionType
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Updating MP_REKENING_KORAN table (TransactionType)...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Tambah TransactionType (NVARCHAR(2) - CR atau DB)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MP_REKENING_KORAN' AND COLUMN_NAME = 'TransactionType'
)
BEGIN
    ALTER TABLE [dbo].[MP_REKENING_KORAN]
    ADD [TransactionType] NVARCHAR(2) NULL;
    PRINT '✅ Kolom TransactionType ditambahkan ke MP_REKENING_KORAN';
END
ELSE
BEGIN
    PRINT '✓ Kolom TransactionType sudah ada di MP_REKENING_KORAN';
END
GO

-- ═══════════════════════════════════════════════════════════════════════
-- Verifikasi struktur tabel
-- ═══════════════════════════════════════════════════════════════════════

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Verifikasi struktur...';
PRINT '═══════════════════════════════════════════════════════════════════════';

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_REKENING_KORAN'
AND COLUMN_NAME = 'TransactionType';
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ ALTER_ADD_TRANSACTIONTYPE.sql completed!';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
