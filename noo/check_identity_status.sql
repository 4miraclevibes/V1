-- Script untuk cek status IDENTITY di MP_FSS_DIST_NEW
USE [POWERAPPS]
GO

PRINT 'Mengecek status tabel MP_FSS_DIST_NEW...'

-- Cek struktur tabel
SELECT 
    'Table Info' AS Info,
    name AS TableName,
    create_date,
    modify_date
FROM sys.tables 
WHERE name = 'MP_FSS_DIST_NEW'
GO

-- Cek kolom id
SELECT 
    'Column Info' AS Info,
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable,
    c.is_identity,
    c.seed_value,
    c.increment_value
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('MP_FSS_DIST_NEW') 
AND c.name = 'id'
GO

-- Cek Primary Key
SELECT 
    'Primary Key Info' AS Info,
    kc.name AS ConstraintName,
    c.name AS ColumnName
FROM sys.key_constraints kc
INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID('MP_FSS_DIST_NEW')
AND kc.type = 'PK'
GO

-- Cek semua kolom
SELECT 
    'All Columns' AS Info,
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('MP_FSS_DIST_NEW')
ORDER BY c.column_id
GO

PRINT 'Pengecekan selesai!'
