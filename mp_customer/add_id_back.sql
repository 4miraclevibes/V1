-- Script untuk menambahkan kembali kolom id sebagai BIGINT IDENTITY dengan Primary Key
-- Setelah kolom id dan id_new terhapus

USE [POWERAPPS]
GO

-- Langkah 1: Hapus Primary Key constraint pada kolom code (jika ada)
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_CUSTOMER')
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER] DROP CONSTRAINT PK_MP_CUSTOMER
    PRINT 'Primary Key constraint pada code dihapus'
END
GO

-- Langkah 2: Tambahkan kolom id baru sebagai BIGINT IDENTITY
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD id BIGINT IDENTITY(1,1) NOT NULL
GO

-- Langkah 3: Set id sebagai Primary Key
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD CONSTRAINT PK_MP_CUSTOMER PRIMARY KEY (id)
GO

-- Verifikasi hasil
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

-- Cek struktur tabel lengkap
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CASE WHEN COLUMN_NAME = 'id' THEN 'YES' ELSE 'NO' END AS IsPrimaryKey
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_CUSTOMER'
ORDER BY ORDINAL_POSITION
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
SELECT TOP 5 * FROM [POWERAPPS].[dbo].[MP_CUSTOMER] ORDER BY id DESC
GO
