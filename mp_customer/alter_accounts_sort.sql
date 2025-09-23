-- Script untuk mengubah tipe data kolom sort dari integer ke varchar
USE [POWERAPPS]
GO

-- Ubah tipe data kolom sort dari integer ke nvarchar
ALTER TABLE [dbo].[Accounts]
ALTER COLUMN [sort] nvarchar(255) NULL
GO

-- Verifikasi perubahan
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Accounts' AND COLUMN_NAME = 'sort'
GO
