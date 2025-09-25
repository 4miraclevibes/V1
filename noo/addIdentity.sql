-- Script untuk menambahkan IDENTITY ke 3 tabel sekaligus
-- MP_FSS_KC_NEW, MP_FSS_DIST_NEW, MP_FSS_OD_NEW
USE [POWERAPPS]
GO

-- =============================================
-- TABLE 1: MP_FSS_KC_NEW
-- =============================================
PRINT 'Memproses tabel MP_FSS_KC_NEW...'

-- Hapus Primary Key constraint jika ada
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_FSS_KC_NEW')
BEGIN
    ALTER TABLE [dbo].[MP_FSS_KC_NEW] DROP CONSTRAINT PK_MP_FSS_KC_NEW
    PRINT 'Primary Key constraint dihapus dari MP_FSS_KC_NEW'
END
GO

-- Set kolom id sebagai IDENTITY (jika belum)
IF NOT EXISTS (SELECT * FROM sys.identity_columns WHERE object_id = OBJECT_ID('MP_FSS_KC_NEW') AND name = 'id')
BEGIN
    -- Tambahkan kolom id_identity sebagai IDENTITY
    ALTER TABLE [dbo].[MP_FSS_KC_NEW]
    ADD id_identity BIGINT IDENTITY(1,1) NOT NULL
    
    -- Update nilai dari id ke id_identity
    UPDATE [dbo].[MP_FSS_KC_NEW] SET id_identity = id
    
    -- Hapus kolom id lama
    ALTER TABLE [dbo].[MP_FSS_KC_NEW] DROP COLUMN id
    
    -- Rename id_identity menjadi id
    EXEC sp_rename '[dbo].[MP_FSS_KC_NEW].id_identity', 'id', 'COLUMN'
    
    PRINT 'Kolom id di MP_FSS_KC_NEW diubah menjadi IDENTITY'
END
ELSE
BEGIN
    PRINT 'Kolom id di MP_FSS_KC_NEW sudah IDENTITY'
END
GO

-- Set id sebagai Primary Key
ALTER TABLE [dbo].[MP_FSS_KC_NEW]
ADD CONSTRAINT PK_MP_FSS_KC_NEW PRIMARY KEY (id)
GO

-- =============================================
-- TABLE 2: MP_FSS_DIST_NEW
-- =============================================
PRINT 'Memproses tabel MP_FSS_DIST_NEW...'

-- Hapus Primary Key constraint jika ada
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_FSS_DIST_NEW')
BEGIN
    ALTER TABLE [dbo].[MP_FSS_DIST_NEW] DROP CONSTRAINT PK_MP_FSS_DIST_NEW
    PRINT 'Primary Key constraint dihapus dari MP_FSS_DIST_NEW'
END
GO

-- Set kolom id sebagai IDENTITY (jika belum)
IF NOT EXISTS (SELECT * FROM sys.identity_columns WHERE object_id = OBJECT_ID('MP_FSS_DIST_NEW') AND name = 'id')
BEGIN
    -- Tambahkan kolom id_identity sebagai IDENTITY
    ALTER TABLE [dbo].[MP_FSS_DIST_NEW]
    ADD id_identity BIGINT IDENTITY(1,1) NOT NULL
    
    -- Update nilai dari id ke id_identity
    UPDATE [dbo].[MP_FSS_DIST_NEW] SET id_identity = id
    
    -- Hapus kolom id lama
    ALTER TABLE [dbo].[MP_FSS_DIST_NEW] DROP COLUMN id
    
    -- Rename id_identity menjadi id
    EXEC sp_rename '[dbo].[MP_FSS_DIST_NEW].id_identity', 'id', 'COLUMN'
    
    PRINT 'Kolom id di MP_FSS_DIST_NEW diubah menjadi IDENTITY'
END
ELSE
BEGIN
    PRINT 'Kolom id di MP_FSS_DIST_NEW sudah IDENTITY'
END
GO

-- Set id sebagai Primary Key
ALTER TABLE [dbo].[MP_FSS_DIST_NEW]
ADD CONSTRAINT PK_MP_FSS_DIST_NEW PRIMARY KEY (id)
GO

-- =============================================
-- TABLE 3: MP_FSS_OD_NEW
-- =============================================
PRINT 'Memproses tabel MP_FSS_OD_NEW...'

-- Hapus Primary Key constraint jika ada
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_FSS_OD_NEW')
BEGIN
    ALTER TABLE [dbo].[MP_FSS_OD_NEW] DROP CONSTRAINT PK_MP_FSS_OD_NEW
    PRINT 'Primary Key constraint dihapus dari MP_FSS_OD_NEW'
END
GO

-- Set kolom id sebagai IDENTITY (jika belum)
IF NOT EXISTS (SELECT * FROM sys.identity_columns WHERE object_id = OBJECT_ID('MP_FSS_OD_NEW') AND name = 'id')
BEGIN
    -- Tambahkan kolom id_identity sebagai IDENTITY
    ALTER TABLE [dbo].[MP_FSS_OD_NEW]
    ADD id_identity BIGINT IDENTITY(1,1) NOT NULL
    
    -- Update nilai dari id ke id_identity
    UPDATE [dbo].[MP_FSS_OD_NEW] SET id_identity = id
    
    -- Hapus kolom id lama
    ALTER TABLE [dbo].[MP_FSS_OD_NEW] DROP COLUMN id
    
    -- Rename id_identity menjadi id
    EXEC sp_rename '[dbo].[MP_FSS_OD_NEW].id_identity', 'id', 'COLUMN'
    
    PRINT 'Kolom id di MP_FSS_OD_NEW diubah menjadi IDENTITY'
END
ELSE
BEGIN
    PRINT 'Kolom id di MP_FSS_OD_NEW sudah IDENTITY'
END
GO

-- Set id sebagai Primary Key
ALTER TABLE [dbo].[MP_FSS_OD_NEW]
ADD CONSTRAINT PK_MP_FSS_OD_NEW PRIMARY KEY (id)
GO

-- =============================================
-- VERIFIKASI SEMUA TABEL
-- =============================================
PRINT 'Verifikasi hasil...'

-- Verifikasi MP_FSS_KC_NEW
SELECT 
    'MP_FSS_KC_NEW' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('MP_FSS_KC_NEW'), COLUMN_NAME, 'IsIdentity') AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_FSS_KC_NEW' AND COLUMN_NAME = 'id'

UNION ALL

-- Verifikasi MP_FSS_DIST_NEW
SELECT 
    'MP_FSS_DIST_NEW' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('MP_FSS_DIST_NEW'), COLUMN_NAME, 'IsIdentity') AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_FSS_DIST_NEW' AND COLUMN_NAME = 'id'

UNION ALL

-- Verifikasi MP_FSS_OD_NEW
SELECT 
    'MP_FSS_OD_NEW' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMNPROPERTY(OBJECT_ID('MP_FSS_OD_NEW'), COLUMN_NAME, 'IsIdentity') AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_FSS_OD_NEW' AND COLUMN_NAME = 'id'
GO

PRINT 'Script selesai dijalankan!'
