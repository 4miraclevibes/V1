-- =====================================================
-- ALTER_ADD_shop_type_shopper_type_is_va_MP_CUSTOMER_NEW.sql
-- =====================================================
-- Purpose: Tambah kolom shop_type, shopper_type, is_va ke MP_CUSTOMER_NEW
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
      AND COLUMN_NAME = 'shop_type'
)
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER_NEW]
    ADD [shop_type] NVARCHAR(255) NULL;
    PRINT '✅ Kolom shop_type ditambahkan ke MP_CUSTOMER_NEW';
END
ELSE
BEGIN
    PRINT '✓ Kolom shop_type sudah ada di MP_CUSTOMER_NEW';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'MP_CUSTOMER_NEW'
      AND COLUMN_NAME = 'shopper_type'
)
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER_NEW]
    ADD [shopper_type] NVARCHAR(255) NULL;
    PRINT '✅ Kolom shopper_type ditambahkan ke MP_CUSTOMER_NEW';
END
ELSE
BEGIN
    PRINT '✓ Kolom shopper_type sudah ada di MP_CUSTOMER_NEW';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'MP_CUSTOMER_NEW'
      AND COLUMN_NAME = 'is_va'
)
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER_NEW]
    ADD [is_va] BIT NULL;
    PRINT '✅ Kolom is_va ditambahkan ke MP_CUSTOMER_NEW';
END
ELSE
BEGIN
    PRINT '✓ Kolom is_va sudah ada di MP_CUSTOMER_NEW';
END
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'MP_CUSTOMER_NEW'
  AND COLUMN_NAME IN ('shop_type', 'shopper_type', 'is_va')
ORDER BY COLUMN_NAME;
GO
