-- Script untuk membuat kolom id menjadi IDENTITY (auto increment)
USE [POWERAPPS]
GO

PRINT 'Mengecek status tabel MP_FSS_DIST_NEW...'

-- Cek apakah kolom id sudah IDENTITY
IF EXISTS (SELECT * FROM sys.identity_columns WHERE object_id = OBJECT_ID('MP_FSS_DIST_NEW') AND name = 'id')
BEGIN
    PRINT 'Kolom id sudah IDENTITY - tidak perlu diubah'
    RETURN
END

PRINT 'Kolom id belum IDENTITY - akan diubah...'

-- Hapus Primary Key jika ada
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_FSS_DIST_NEW')
BEGIN
    ALTER TABLE [dbo].[MP_FSS_DIST_NEW] DROP CONSTRAINT PK_MP_FSS_DIST_NEW
    PRINT 'Primary Key dihapus'
END
GO

-- Backup data id ke kolom sementara
ALTER TABLE [dbo].[MP_FSS_DIST_NEW] ADD id_backup BIGINT
PRINT 'Kolom backup ditambahkan'
GO

-- Copy data id ke backup
UPDATE [dbo].[MP_FSS_DIST_NEW] SET id_backup = id
PRINT 'Data id di-backup'
GO

-- Hapus kolom id lama
ALTER TABLE [dbo].[MP_FSS_DIST_NEW] DROP COLUMN id
PRINT 'Kolom id lama dihapus'
GO

-- Tambah kolom id baru sebagai IDENTITY
ALTER TABLE [dbo].[MP_FSS_DIST_NEW] ADD id BIGINT IDENTITY(1,1) NOT NULL
PRINT 'Kolom id baru ditambahkan sebagai IDENTITY'
GO

-- Copy data dari backup ke id baru
UPDATE [dbo].[MP_FSS_DIST_NEW] SET id = id_backup
PRINT 'Data di-restore ke id baru'
GO

-- Hapus kolom backup
ALTER TABLE [dbo].[MP_FSS_DIST_NEW] DROP COLUMN id_backup
PRINT 'Kolom backup dihapus'
GO

-- Set Primary Key
ALTER TABLE [dbo].[MP_FSS_DIST_NEW] ADD CONSTRAINT PK_MP_FSS_DIST_NEW PRIMARY KEY (id)
PRINT 'Primary Key ditambahkan'
GO

-- Verifikasi
SELECT 
    'MP_FSS_DIST_NEW' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('MP_FSS_DIST_NEW'), COLUMN_NAME, 'IsIdentity') AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_FSS_DIST_NEW' AND COLUMN_NAME = 'id'
GO

PRINT 'Selesai! Kolom id sekarang IDENTITY (auto increment)'
