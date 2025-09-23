-- Script untuk rename tabel MP_CUSTOMER003 menjadi MP_CUSTOMER_NEW

USE [POWERAPPS]
GO

-- Langkah 1: Rename tabel
EXEC sp_rename '[dbo].[MP_CUSTOMER003]', 'MP_CUSTOMER_NEW'
GO

-- Langkah 2: Verifikasi rename berhasil
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('MP_CUSTOMER003', 'MP_CUSTOMER_NEW')
GO

-- Langkah 3: Cek struktur tabel baru
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_CUSTOMER_NEW'
ORDER BY ORDINAL_POSITION
GO

-- Langkah 4: Cek jumlah data
SELECT 
    COUNT(*) as TotalRecords
FROM [dbo].[MP_CUSTOMER_NEW]
GO

-- Langkah 5: Tampilkan sample data
SELECT TOP 5 * FROM [dbo].[MP_CUSTOMER_NEW]
GO

PRINT 'Proses selesai - Tabel MP_CUSTOMER003 berhasil di-rename menjadi MP_CUSTOMER_NEW'
GO
