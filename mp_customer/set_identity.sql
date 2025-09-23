-- Script untuk mengatur Identity pada tabel MP_CUSTOMER
-- Pastikan backup data sebelum menjalankan script ini

USE [POWERAPPS]
GO

-- Langkah 1: Hapus Primary Key constraint terlebih dahulu
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_CUSTOMER')
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER] DROP CONSTRAINT PK_MP_CUSTOMER
    PRINT 'Primary Key constraint dihapus'
END
GO

-- Langkah 2: Hapus kolom id lama
ALTER TABLE [dbo].[MP_CUSTOMER] DROP COLUMN id
GO

-- Langkah 3: Tambahkan kolom id baru dengan identity
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD id INT IDENTITY(1,1) NOT NULL
GO

-- Langkah 4: Set sebagai Primary Key
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
