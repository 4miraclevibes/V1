-- Script untuk memulihkan data dengan ID baru
-- Data lama akan tetap ada, tapi dengan ID yang baru

USE [POWERAPPS]
GO

-- Langkah 1: Backup data existing ke tabel temporary
SELECT * INTO #temp_MP_CUSTOMER_backup 
FROM [POWERAPPS].[dbo].[MP_CUSTOMER]
GO

-- Langkah 2: Hapus Primary Key constraint pada code (jika ada)
IF EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'PK_MP_CUSTOMER')
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER] DROP CONSTRAINT PK_MP_CUSTOMER
    PRINT 'Primary Key constraint dihapus'
END
GO

-- Langkah 3: Tambahkan kolom id baru sebagai BIGINT IDENTITY
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD id BIGINT IDENTITY(1,1) NOT NULL
GO

-- Langkah 4: Set id sebagai Primary Key
ALTER TABLE [dbo].[MP_CUSTOMER]
ADD CONSTRAINT PK_MP_CUSTOMER PRIMARY KEY (id)
GO

-- Langkah 5: Verifikasi data sudah pulih dengan ID baru
SELECT 
    id,
    code,
    name,
    city,
    createdate,
    distributor_id,
    account_id,
    status,
    created_at
FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
ORDER BY id ASC
GO

-- Langkah 6: Cek berapa banyak data yang berhasil dipulihkan
SELECT 
    COUNT(*) as TotalRecords,
    MIN(id) as MinID,
    MAX(id) as MaxID
FROM [POWERAPPS].[dbo].[MP_CUSTOMER]
GO

-- Langkah 7: Verifikasi backup data
SELECT 
    COUNT(*) as BackupRecords
FROM #temp_MP_CUSTOMER_backup
GO

-- Langkah 8: Drop tabel temporary
DROP TABLE #temp_MP_CUSTOMER_backup
GO

-- Verifikasi struktur tabel akhir
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CASE WHEN COLUMN_NAME = 'id' THEN 'YES' ELSE 'NO' END AS IsPrimaryKey,
    COLUMNPROPERTY(OBJECT_ID('MP_CUSTOMER'), COLUMN_NAME, 'IsIdentity') AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MP_CUSTOMER'
ORDER BY ORDINAL_POSITION
GO
