-- Script sederhana untuk menambahkan kolom id sebagai BIGINT IDENTITY
USE [POWERAPPS]
GO

-- Hapus Primary Key constraint pada code (jika ada)
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_CUSTOMER')
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER] DROP CONSTRAINT PK_MP_CUSTOMER
    PRINT 'Primary Key constraint dihapus'
END
GO

-- Tambahkan kolom id sebagai BIGINT IDENTITY
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD id BIGINT IDENTITY(1,1) NOT NULL
GO

-- Set id sebagai Primary Key
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD CONSTRAINT PK_MP_CUSTOMER PRIMARY KEY (id)
GO

-- Verifikasi
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('MP_CUSTOMER'), COLUMN_NAME, 'IsIdentity') AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_CUSTOMER' AND COLUMN_NAME = 'id'
GO
