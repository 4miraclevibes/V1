-- Script untuk mengupdate account_id customer dengan code tertentu ke account_id 83
USE [POWERAPPS]
GO

-- Cek data yang akan diupdate dulu
SELECT code, account_id, name FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
WHERE code IN (
    '1629',
    '1635',
    '1653',
    '1654',
    '1683',
    '1701',
    '1725',
    '1728',
    '1741',
    '1745',
    'C.00191',
    'C.00241',
    'C.00255',
    'C.00269',
    'C.00287',
    'C.00311',
    'C.00313',
    'C.00417',
    'C.00428',
    'C.00431',
    'C.02190',
    'C.02197',
    'C.02376',
    'C.02687',
    'C.02754',
    'C.02877',
    'C.03240',
    'C.03260',
    'C.03410',
    'CAJ-00074'
)
GO

-- Cek code mana yang tidak ditemukan di database
WITH TargetCodes AS (
    SELECT code FROM (VALUES 
        ('1629'), ('1635'), ('1653'), ('1654'), ('1683'), ('1701'), ('1725'), ('1728'), ('1741'), ('1745'),
        ('C.00191'), ('C.00241'), ('C.00255'), ('C.00269'), ('C.00287'), ('C.00311'), ('C.00313'), ('C.00417'), ('C.00428'), ('C.00431'),
        ('C.02190'), ('C.02197'), ('C.02376'), ('C.02687'), ('C.02754'), ('C.02877'), ('C.03240'), ('C.03260'), ('C.03410'), ('CAJ-00074')
    ) AS TargetCodes(code)
)
SELECT tc.code as 'Code Tidak Ditemukan'
FROM TargetCodes tc
LEFT JOIN [POWERAPPS].[dbo].[MP_CUSTOMER] mc ON tc.code = mc.code
WHERE mc.code IS NULL
GO

-- Update account_id ke 83 untuk customer dengan code yang ditentukan
UPDATE [POWERAPPS].[dbo].[MP_CUSTOMER] 
SET account_id = 83
WHERE code IN (
    '1629',
    '1635',
    '1653',
    '1654',
    '1683',
    '1701',
    '1725',
    '1728',
    '1741',
    '1745',
    'C.00191',
    'C.00241',
    'C.00255',
    'C.00269',
    'C.00287',
    'C.00311',
    'C.00313',
    'C.00417',
    'C.00428',
    'C.00431',
    'C.02190',
    'C.02197',
    'C.02376',
    'C.02687',
    'C.02754',
    'C.02877',
    'C.03240',
    'C.03260',
    'C.03410',
    'CAJ-00074'
)
GO

-- Verifikasi data sudah terupdate
SELECT code, account_id, name FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
WHERE code IN (
    '1629',
    '1635',
    '1653',
    '1654',
    '1683',
    '1701',
    '1725',
    '1728',
    '1741',
    '1745',
    'C.00191',
    'C.00241',
    'C.00255',
    'C.00269',
    'C.00287',
    'C.00311',
    'C.00313',
    'C.00417',
    'C.00428',
    'C.00431',
    'C.02190',
    'C.02197',
    'C.02376',
    'C.02687',
    'C.02754',
    'C.02877',
    'C.03240',
    'C.03260',
    'C.03410',
    'CAJ-00074'
)
GO

-- Tampilkan data terbaru
SELECT TOP 10 * FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
ORDER BY id DESC
GO
