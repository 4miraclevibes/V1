-- =====================================================
-- ALTER_ADD_accountCap_MP_CUSTOMER_NEW.sql
-- =====================================================
-- Purpose: Tambah kolom accountCap ke MP_CUSTOMER_NEW
-- =====================================================

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Updating MP_CUSTOMER_NEW table...';
PRINT '═══════════════════════════════════════════════════════════════════════';

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'MP_CUSTOMER_NEW'
      AND COLUMN_NAME = 'accountCap'
)
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER_NEW]
    ADD [accountCap] NVARCHAR(255) NULL;
    PRINT '✅ Kolom accountCap ditambahkan ke MP_CUSTOMER_NEW';
END
ELSE
BEGIN
    PRINT '✓ Kolom accountCap sudah ada di MP_CUSTOMER_NEW';
END
GO

-- Verifikasi struktur kolom
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'MP_CUSTOMER_NEW'
  AND COLUMN_NAME = 'accountCap';
GO
