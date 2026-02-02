-- =====================================================
-- ALTER_ADD_BTN_APPROVED_BY.sql
-- =====================================================
-- Purpose: Tambah kolom btn dan approved_by ke MP_REKENING_KORAN
-- - btn: diisi dari BTP_REVIEW.CustomerName (tidak ada kolom baru di BTP_REVIEW)
-- - approved_by: dari BTP_REVIEW.UploadedBy (user yang upload/approve)
-- =====================================================

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════
-- ALTER MP_REKENING_KORAN - Tambah btn dan approved_by
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Updating MP_REKENING_KORAN table (btn + approved_by)...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Tambah btn (diisi dari BTP_REVIEW.CustomerName, tipe NVARCHAR)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MP_REKENING_KORAN' AND COLUMN_NAME = 'btn'
)
BEGIN
    ALTER TABLE [dbo].[MP_REKENING_KORAN]
    ADD [btn] NVARCHAR(255) NULL;
    PRINT '✅ Kolom btn ditambahkan ke MP_REKENING_KORAN';
END
ELSE
BEGIN
    PRINT '✓ Kolom btn sudah ada di MP_REKENING_KORAN';
END
GO

-- Tambah approved_by (dari BTP_REVIEW.UploadedBy)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MP_REKENING_KORAN' AND COLUMN_NAME = 'approved_by'
)
BEGIN
    ALTER TABLE [dbo].[MP_REKENING_KORAN]
    ADD [approved_by] NVARCHAR(255) NULL;
    PRINT '✅ Kolom approved_by ditambahkan ke MP_REKENING_KORAN';
END
ELSE
BEGIN
    PRINT '✓ Kolom approved_by sudah ada di MP_REKENING_KORAN';
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
AND COLUMN_NAME IN ('btn', 'approved_by')
ORDER BY COLUMN_NAME;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ ALTER_ADD_BTN_APPROVED_BY.sql completed!';
PRINT '  - MP_REKENING_KORAN.btn = BTP_REVIEW.CustomerName';
PRINT '  - MP_REKENING_KORAN.approved_by = BTP_REVIEW.UploadedBy';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
