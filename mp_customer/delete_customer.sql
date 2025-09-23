-- Script untuk menghapus data customer dengan code tertentu
USE [POWERAPPS]
GO

-- Cek data yang akan dihapus dulu
SELECT * FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
WHERE code IN (
    'GF-000358',
    'A050031',
    'CSE.25VII.053',
    'P00E109',
    '2003454',
    'C.020102',
    'KB 10600 FB',
    'GF-000353',
    'C001-101625',
    'RSMMRT',
    'M2106',
    'CST-REO',
    'CST-FRZ',
    '13E020',
    'L.112060102',
    'GF-000348',
    'CM000108'
)
GO

-- Hapus data dengan code yang ditentukan
DELETE FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
WHERE code IN (
    'GF-000358',
    'A050031',
    'CSE.25VII.053',
    'P00E109',
    '2003454',
    'C.020102',
    'KB 10600 FB',
    'GF-000353',
    'C001-101625',
    'RSMMRT',
    'M2106',
    'CST-REO',
    'CST-FRZ',
    '13E020',
    'L.112060102',
    'GF-000348',
    'CM000108'
)
GO

-- Verifikasi data sudah terhapus
SELECT COUNT(*) as RemainingRecords 
FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
WHERE code IN (
    'GF-000358',
    'A050031',
    'CSE.25VII.053',
    'P00E109',
    '2003454',
    'C.020102',
    'KB 10600 FB',
    'GF-000353',
    'C001-101625',
    'RSMMRT',
    'M2106',
    'CST-REO',
    'CST-FRZ',
    '13E020',
    'L.112060102',
    'GF-000348',
    'CM000108'
)
GO

-- Tampilkan data terbaru
SELECT TOP 10 * FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
ORDER BY id DESC
GO
