-- Script untuk insert data baru dari MP_CUSTOMER_NEW_09_10_2025 ke MP_CUSTOMER_NEW
-- Data dianggap baru jika kombinasi name, code, dan distributor_id belum ada
-- Estimasi waktu: beberapa detik sampai beberapa menit untuk 140k records

USE [POWERAPPS]
GO

-- Step 1: Cek jumlah data yang akan diinsert (data baru)
PRINT '=== STEP 1: CEK DATA YANG AKAN DIINSERT ==='
SELECT COUNT(*) as 'Jumlah Data Baru Yang Akan Diinsert'
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW_09_10_2025] src
WHERE NOT EXISTS (
    SELECT 1 
    FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] tgt
    WHERE tgt.[name] = src.[name] 
      AND tgt.[code] = src.[code]
      AND tgt.[distributor_id] = src.[distributor_id]
)
GO

-- Step 2: Tampilkan sample data yang akan diinsert
PRINT '=== STEP 2: SAMPLE DATA YANG AKAN DIINSERT (10 RECORD PERTAMA) ==='
SELECT TOP 10 
    src.[code],
    src.[name],
    src.[distributor_id],
    src.[city]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW_09_10_2025] src
WHERE NOT EXISTS (
    SELECT 1 
    FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] tgt
    WHERE tgt.[name] = src.[name] 
      AND tgt.[code] = src.[code]
      AND tgt.[distributor_id] = src.[distributor_id]
)
GO

-- Step 3: Insert data baru
PRINT '=== STEP 3: MULAI INSERT DATA BARU ==='
PRINT 'Waktu mulai: ' + CONVERT(VARCHAR, GETDATE(), 120)

BEGIN TRANSACTION

INSERT INTO [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
(
    [code],
    [name],
    [city],
    [createdate],
    [distributor_id],
    [account_id],
    [account_trading_term],
    [regency_id],
    [created_at],
    [updated_at]
)
SELECT 
    src.[code],
    src.[name],
    src.[city],
    src.[createdate],
    src.[distributor_id],
    src.[account_id],
    src.[account_trading_term],
    src.[regency_id],
    src.[created_at],
    src.[updated_at]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW_09_10_2025] src
WHERE NOT EXISTS (
    SELECT 1 
    FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] tgt
    WHERE tgt.[name] = src.[name] 
      AND tgt.[code] = src.[code]
      AND tgt.[distributor_id] = src.[distributor_id]
)

-- Tampilkan jumlah record yang berhasil diinsert
PRINT 'Jumlah record yang berhasil diinsert: ' + CAST(@@ROWCOUNT AS VARCHAR)
PRINT 'Waktu selesai: ' + CONVERT(VARCHAR, GETDATE(), 120)

COMMIT TRANSACTION

PRINT '=== INSERT SELESAI ==='
GO

-- Step 4: Verifikasi hasil insert
PRINT '=== STEP 4: VERIFIKASI HASIL ==='
SELECT COUNT(*) as 'Total Data di MP_CUSTOMER_NEW Setelah Insert'
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
GO

PRINT 'Script selesai dijalankan!'

