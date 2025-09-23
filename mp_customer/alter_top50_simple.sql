-- Script sederhana untuk mengubah kolom top50 dari nvarchar menjadi bit
-- Tanpa backup karena data kosong

USE [POWERAPPS]
GO

-- Langkah 1: Hapus kolom top50 yang lama
ALTER TABLE [dbo].[MP_CUSTOMER003] DROP COLUMN top50
GO

-- Langkah 2: Tambahkan kolom top50 baru dengan tipe bit
ALTER TABLE [dbo].[MP_CUSTOMER003]
ADD top50 BIT NULL
GO

-- Langkah 3: Set default value menjadi 0 (false)
UPDATE [dbo].[MP_CUSTOMER003]
SET top50 = 0
GO

-- Langkah 4: Verifikasi hasil
SELECT 
    COUNT(*) as TotalRecords,
    SUM(CASE WHEN top50 = 1 THEN 1 ELSE 0 END) as TrueCount,
    SUM(CASE WHEN top50 = 0 THEN 1 ELSE 0 END) as FalseCount,
    SUM(CASE WHEN top50 IS NULL THEN 1 ELSE 0 END) as NullCount
FROM [dbo].[MP_CUSTOMER003]
GO

-- Langkah 5: Tampilkan sample data
SELECT TOP 5 id, name, [top], top50 FROM [dbo].[MP_CUSTOMER003]
GO

PRINT 'Proses selesai - Kolom top50 berhasil diubah dari nvarchar menjadi bit'
GO
