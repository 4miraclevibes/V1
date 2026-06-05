-- =====================================================
-- ALTER_ADD_DistributorScm_code.sql
-- =====================================================
-- Purpose: Tambah kolom DistributorScm dan code ke Distributors
-- =====================================================

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Updating Distributors table...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Tambah DistributorScm
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'Distributors'
      AND COLUMN_NAME = 'DistributorScm'
)
BEGIN
    ALTER TABLE [dbo].[Distributors]
    ADD [DistributorScm] NVARCHAR(255) NULL;
    PRINT '✅ Kolom DistributorScm ditambahkan ke Distributors';
END
ELSE
BEGIN
    PRINT '✓ Kolom DistributorScm sudah ada di Distributors';
END
GO

-- Tambah code
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'Distributors'
      AND COLUMN_NAME = 'code'
)
BEGIN
    ALTER TABLE [dbo].[Distributors]
    ADD [code] NVARCHAR(50) NULL;
    PRINT '✅ Kolom code ditambahkan ke Distributors';
END
ELSE
BEGIN
    PRINT '✓ Kolom code sudah ada di Distributors';
END
GO

-- Verifikasi struktur kolom
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Distributors'
  AND COLUMN_NAME IN ('DistributorScm', 'code')
ORDER BY COLUMN_NAME;
GO
