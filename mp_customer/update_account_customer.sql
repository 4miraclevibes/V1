-- Script untuk mengupdate account_id customer dengan code tertentu ke account_id 83
USE [POWERAPPS]
GO

-- Cek data yang akan diupdate dulu
SELECT code, account_id, name FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
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

-- Update account_id ke 83 untuk customer dengan code yang ditentukan
UPDATE [POWERAPPS].[dbo].[MP_CUSTOMER] 
SET account_id = 83
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

-- Verifikasi data sudah terupdate
SELECT code, account_id, name FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
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
