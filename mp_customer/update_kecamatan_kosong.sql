-- Script untuk update kecamatan MP_CUSTOMER menjadi 'kosong'
USE [POWERAPPS]
GO

-- Cek data kecamatan sebelum update
SELECT COUNT(*) as TotalRecords, 
       COUNT(CASE WHEN kecamatan IS NULL THEN 1 END) as NullRecords,
       COUNT(CASE WHEN kecamatan = '' THEN 1 END) as EmptyRecords
FROM [dbo].[MP_CUSTOMER]
GO

-- Update semua kecamatan menjadi 'kosong'
UPDATE [dbo].[MP_CUSTOMER]
SET kecamatan = 'kosong'
GO

-- Verifikasi update berhasil
SELECT COUNT(*) as TotalRecords,
       COUNT(CASE WHEN kecamatan = 'kosong' THEN 1 END) as UpdatedRecords
FROM [dbo].[MP_CUSTOMER]
GO

-- Tampilkan sample data untuk konfirmasi
SELECT TOP 10 id, code, name, kecamatan 
FROM [dbo].[MP_CUSTOMER]
ORDER BY id DESC
GO
