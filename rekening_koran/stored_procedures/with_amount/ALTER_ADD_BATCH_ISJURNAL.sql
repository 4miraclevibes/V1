-- =====================================================
-- ALTER_ADD_BATCH_ISJURNAL.sql
-- =====================================================
-- Purpose: Tambah kolom BatchID dan isJurnal ke MP_REKENING_KORAN
-- - BatchID: dari BTP_REVIEW.BatchID (sama tipe data)
-- - isJurnal: boolean (BIT), tidak dari BTP_REVIEW
-- =====================================================

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════
-- ALTER MP_REKENING_KORAN - Tambah BatchID dan isJurnal
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Updating MP_REKENING_KORAN table (BatchID + isJurnal)...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Tambah BatchID (dari BTP_REVIEW, tipe NVARCHAR(100))
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MP_REKENING_KORAN' AND COLUMN_NAME = 'BatchID'
)
BEGIN
    ALTER TABLE [dbo].[MP_REKENING_KORAN]
    ADD [BatchID] NVARCHAR(100) NULL;
    PRINT '✅ Kolom BatchID ditambahkan ke MP_REKENING_KORAN';
END
ELSE
BEGIN
    PRINT '✓ Kolom BatchID sudah ada di MP_REKENING_KORAN';
END
GO

-- Tambah isJurnal (boolean/BIT, tidak dari BTP_REVIEW)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MP_REKENING_KORAN' AND COLUMN_NAME = 'isJurnal'
)
BEGIN
    ALTER TABLE [dbo].[MP_REKENING_KORAN]
    ADD [isJurnal] BIT NULL;
    PRINT '✅ Kolom isJurnal ditambahkan ke MP_REKENING_KORAN';
END
ELSE
BEGIN
    PRINT '✓ Kolom isJurnal sudah ada di MP_REKENING_KORAN';
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
AND COLUMN_NAME IN ('BatchID', 'isJurnal')
ORDER BY COLUMN_NAME;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ ALTER_ADD_BATCH_ISJURNAL.sql completed!';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
