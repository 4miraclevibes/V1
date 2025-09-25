-- Script sederhana untuk menambahkan IDENTITY ke MP_FSS_DIST_NEW
USE [POWERAPPS]
GO

PRINT 'Memproses tabel MP_FSS_DIST_NEW...'

-- Cek apakah tabel ada
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MP_FSS_DIST_NEW')
BEGIN
    PRINT 'Tabel MP_FSS_DIST_NEW tidak ditemukan!'
    RETURN
END

-- Cek apakah kolom id ada
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MP_FSS_DIST_NEW') AND name = 'id')
BEGIN
    PRINT 'Kolom id tidak ditemukan di MP_FSS_DIST_NEW!'
    RETURN
END

-- Cek apakah sudah IDENTITY
IF EXISTS (SELECT * FROM sys.identity_columns WHERE object_id = OBJECT_ID('MP_FSS_DIST_NEW') AND name = 'id')
BEGIN
    PRINT 'Kolom id di MP_FSS_DIST_NEW sudah IDENTITY'
    RETURN
END

PRINT 'Memulai proses konversi ke IDENTITY...'

-- Hapus Primary Key constraint jika ada
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_FSS_DIST_NEW')
BEGIN
    ALTER TABLE [dbo].[MP_FSS_DIST_NEW] DROP CONSTRAINT PK_MP_FSS_DIST_NEW
    PRINT 'Primary Key constraint dihapus'
END
GO

-- Tambahkan kolom id_identity sebagai IDENTITY
ALTER TABLE [dbo].[MP_FSS_DIST_NEW]
ADD id_identity BIGINT IDENTITY(1,1) NOT NULL
PRINT 'Kolom id_identity ditambahkan'
GO

-- Update nilai dari id ke id_identity
UPDATE [dbo].[MP_FSS_DIST_NEW] SET id_identity = id
PRINT 'Data berhasil di-copy'
GO

-- Hapus kolom id lama
ALTER TABLE [dbo].[MP_FSS_DIST_NEW] DROP COLUMN id
PRINT 'Kolom id lama dihapus'
GO

-- Rename id_identity menjadi id
EXEC sp_rename '[dbo].[MP_FSS_DIST_NEW].id_identity', 'id', 'COLUMN'
PRINT 'Kolom di-rename menjadi id'
GO

-- Set id sebagai Primary Key
ALTER TABLE [dbo].[MP_FSS_DIST_NEW]
ADD CONSTRAINT PK_MP_FSS_DIST_NEW PRIMARY KEY (id)
PRINT 'Primary Key berhasil ditambahkan'
GO

-- Verifikasi
PRINT 'Verifikasi hasil...'
SELECT 
    'MP_FSS_DIST_NEW' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('MP_FSS_DIST_NEW'), COLUMN_NAME, 'IsIdentity') AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_FSS_DIST_NEW' AND COLUMN_NAME = 'id'
GO

PRINT 'Script selesai!'
