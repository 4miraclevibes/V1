-- Script untuk menambahkan IDENTITY pada kolom id yang sudah ada
USE [POWERAPPS]
GO

-- Langkah 1: Hapus Primary Key constraint dulu
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_CUSTOMER')
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER] DROP CONSTRAINT PK_MP_CUSTOMER
    PRINT 'Primary Key constraint dihapus'
END
GO

-- Langkah 2: Hapus kolom id yang sudah ada
ALTER TABLE [dbo].[MP_CUSTOMER] DROP COLUMN id
GO

-- Langkah 3: Tambahkan kolom id baru dengan IDENTITY
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD id BIGINT IDENTITY(1,1) NOT NULL
GO

-- Langkah 4: Set kembali sebagai Primary Key
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD CONSTRAINT PK_MP_CUSTOMER PRIMARY KEY (id)
GO

-- Verifikasi
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('MP_CUSTOMER'), COLUMN_NAME, 'IsIdentity') AS IsIdentity,
    COLUMNPROPERTY(OBJECT_ID('MP_CUSTOMER'), COLUMN_NAME, 'IsIdentitySeed') AS IdentitySeed,
    COLUMNPROPERTY(OBJECT_ID('MP_CUSTOMER'), COLUMN_NAME, 'IsIdentityIncrement') AS IdentityIncrement
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_CUSTOMER' AND COLUMN_NAME = 'id'
GO

-- Test insert untuk memastikan identity bekerja
INSERT INTO [POWERAPPS].[dbo].[MP_CUSTOMER] (
    code, name, city, createdate, distributor_id, account_id, 
    account_trading_term, regency_id, created_at, updated_at, status
) VALUES (
    'TEST001', 'Test Customer', 'Test City', '2025-01-15', 1, 1,
    'TEST', 1, GETDATE(), GETDATE(), 'active'
)
GO

-- Cek data terakhir
SELECT TOP 3 * FROM [POWERAPPS].[dbo].[MP_CUSTOMER] ORDER BY id DESC
GO
