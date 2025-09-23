-- Script aman untuk menambahkan IDENTITY pada kolom id yang sudah ada
-- TANPA kehilangan data existing untuk tabel MP_CUSTOMER003

USE [POWERAPPS]
GO

-- Langkah 1: Backup data existing
SELECT * INTO #temp_backup_MP_CUSTOMER003 
FROM [dbo].[MP_CUSTOMER003]
GO

PRINT 'Data berhasil di-backup ke tabel temporary'
GO

-- Langkah 2: Hapus Primary Key constraint
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_CUSTOMER003')
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER003] DROP CONSTRAINT PK_MP_CUSTOMER003
    PRINT 'Primary Key constraint dihapus'
END
GO

-- Langkah 3: Hapus kolom id yang sudah ada
ALTER TABLE [dbo].[MP_CUSTOMER003] DROP COLUMN id
GO

-- Langkah 4: Tambahkan kolom id baru dengan IDENTITY
ALTER TABLE [dbo].[MP_CUSTOMER003]
ADD id BIGINT IDENTITY(1,1) NOT NULL
GO

-- Langkah 5: Set kembali sebagai Primary Key
ALTER TABLE [dbo].[MP_CUSTOMER003]
ADD CONSTRAINT PK_MP_CUSTOMER003 PRIMARY KEY (id)
GO

-- Langkah 6: Verifikasi data tidak hilang
SELECT 
    COUNT(*) as TotalRecords,
    MIN(id) as MinID,
    MAX(id) as MaxID
FROM [dbo].[MP_CUSTOMER003]
GO

-- Langkah 7: Verifikasi backup data
SELECT 
    COUNT(*) as BackupRecords
FROM #temp_backup_MP_CUSTOMER003
GO

-- Langkah 8: Cek struktur tabel
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('MP_CUSTOMER003'), COLUMN_NAME, 'IsIdentity') AS IsIdentity,
    COLUMNPROPERTY(OBJECT_ID('MP_CUSTOMER003'), COLUMN_NAME, 'IsIdentitySeed') AS IdentitySeed,
    COLUMNPROPERTY(OBJECT_ID('MP_CUSTOMER003'), COLUMN_NAME, 'IsIdentityIncrement') AS IdentityIncrement
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_CUSTOMER003' AND COLUMN_NAME = 'id'
GO

-- Langkah 9: Tampilkan sample data
SELECT TOP 5 * FROM [dbo].[MP_CUSTOMER003] ORDER BY id ASC
GO

-- Langkah 10: Test insert untuk memastikan identity bekerja
INSERT INTO [dbo].[MP_CUSTOMER003] (
    code, name, city, createdate, distributor_id, account_id, 
    account_trading_term, regency_id, created_at, updated_at,
    [desc], [status], btp, btn, [top], credit_limit, GFcode, npwp,
    supply_chain, nik, va_gdi, va_gi, kecamatan, top50
) VALUES (
    'TEST001', 'Test Customer', 'Test City', '2025-01-15', 1, 1,
    'TEST', 1, GETDATE(), GETDATE(),
    'Test Description', 'Active', 'BTP001', 'BTN001', '30', '1000000',
    'GF001', '123456789', 'Supply Chain Test', '1234567890123456',
    'VA001', 'VA002', 'Test Kecamatan', '1'
)
GO

-- Langkah 11: Cek data terakhir
SELECT TOP 3 * FROM [dbo].[MP_CUSTOMER003] ORDER BY id DESC
GO

-- Langkah 12: Drop tabel temporary
DROP TABLE #temp_backup_MP_CUSTOMER003
GO

PRINT 'Proses selesai - Data aman dan IDENTITY sudah aktif untuk MP_CUSTOMER003'
GO
