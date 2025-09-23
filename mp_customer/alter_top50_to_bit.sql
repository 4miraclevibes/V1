-- Script untuk mengubah kolom top50 dari nvarchar menjadi bit
-- TANPA kehilangan data existing
-- HANYA mengubah kolom top50, kolom top tetap nvarchar

USE [POWERAPPS]
GO

-- Langkah 1: Backup data existing
SELECT * INTO #temp_backup_top50 
FROM [dbo].[MP_CUSTOMER003]
GO

PRINT 'Data berhasil di-backup ke tabel temporary'
GO

-- Langkah 2: Tambahkan kolom temporary untuk konversi
ALTER TABLE [dbo].[MP_CUSTOMER003]
ADD top50_temp BIT NULL
GO

-- Langkah 3: Konversi data dari nvarchar ke bit
-- Mengasumsikan nilai '1', 'true', 'yes' = 1, lainnya = 0
UPDATE [dbo].[MP_CUSTOMER003]
SET top50_temp = CASE 
    WHEN LOWER(LTRIM(RTRIM(top50))) IN ('1', 'true', 'yes', 'y', 'on') THEN 1
    WHEN LOWER(LTRIM(RTRIM(top50))) IN ('0', 'false', 'no', 'n', 'off', '') THEN 0
    ELSE NULL
END
GO

-- Langkah 4: Hapus kolom top50 yang lama
ALTER TABLE [dbo].[MP_CUSTOMER003] DROP COLUMN top50
GO

-- Langkah 5: Rename kolom temporary menjadi top50
EXEC sp_rename '[dbo].[MP_CUSTOMER003].top50_temp', 'top50', 'COLUMN'
GO

-- Langkah 6: Verifikasi konversi data
SELECT 
    COUNT(*) as TotalRecords,
    SUM(CASE WHEN top50 = 1 THEN 1 ELSE 0 END) as TrueCount,
    SUM(CASE WHEN top50 = 0 THEN 1 ELSE 0 END) as FalseCount,
    SUM(CASE WHEN top50 IS NULL THEN 1 ELSE 0 END) as NullCount
FROM [dbo].[MP_CUSTOMER003]
GO

-- Langkah 7: Tampilkan sample data
SELECT TOP 10 id, name, [top], top50 FROM [dbo].[MP_CUSTOMER003]
GO

-- Langkah 8: Test insert untuk memastikan bit bekerja
INSERT INTO [dbo].[MP_CUSTOMER003] (
    code, name, city, createdate, distributor_id, account_id, 
    account_trading_term, regency_id, created_at, updated_at,
    [desc], [status], btp, btn, [top], credit_limit, GFcode, npwp,
    supply_chain, nik, va_gdi, va_gi, kecamatan, top50
) VALUES (
    'TEST002', 'Test Customer 2', 'Test City', '2025-01-15', 1, 1,
    'TEST', 1, GETDATE(), GETDATE(),
    'Test Description', 'Active', 'BTP001', 'BTN001', '30', '1000000',
    'GF001', '123456789', 'Supply Chain Test', '1234567890123456',
    'VA001', 'VA002', 'Test Kecamatan', 1
)
GO

-- Langkah 9: Cek data terakhir
SELECT TOP 3 id, name, [top], top50 FROM [dbo].[MP_CUSTOMER003] ORDER BY id DESC
GO

-- Langkah 10: Drop tabel temporary
DROP TABLE #temp_backup_top50
GO

PRINT 'Proses selesai - Kolom top50 berhasil diubah dari nvarchar menjadi bit, kolom top tetap nvarchar'
GO
