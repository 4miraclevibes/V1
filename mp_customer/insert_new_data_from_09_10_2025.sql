-- Script untuk replace data MP_CUSTOMER_NEW dengan data dari MP_CUSTOMER_NEW_28_10_2025
-- Table MP_CUSTOMER_NEW akan di-truncate dulu, lalu diisi dengan data baru
-- Estimasi waktu: beberapa detik sampai beberapa menit untuk 140k records

USE [POWERAPPS]
GO

-- Step 1: Cek jumlah data di table sumber
PRINT '=== STEP 1: CEK DATA SUMBER ==='
SELECT COUNT(*) as 'Jumlah Data di MP_CUSTOMER_NEW_28_10_2025'
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_28_10_2025]
GO

-- Step 2: Cek jumlah data di table target (sebelum truncate)
PRINT '=== STEP 2: CEK DATA TARGET (SEBELUM TRUNCATE) ==='
SELECT COUNT(*) as 'Jumlah Data di MP_CUSTOMER_NEW (Sebelum Truncate)'
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
GO

-- Step 3: Truncate table target
PRINT '=== STEP 3: TRUNCATE TABLE MP_CUSTOMER_NEW ==='
IF EXISTS (SELECT * FROM sysobjects WHERE name='MP_CUSTOMER_NEW' AND xtype='U')
BEGIN
    TRUNCATE TABLE [POWERAPPS].[dbo].[MP_CUSTOMER_NEW];
    PRINT 'Table MP_CUSTOMER_NEW berhasil di-truncate.';
END
ELSE
BEGIN
    PRINT 'Table MP_CUSTOMER_NEW tidak ditemukan!';
END
GO

-- Step 4: Tampilkan sample data yang akan diinsert
PRINT '=== STEP 4: SAMPLE DATA YANG AKAN DIINSERT (10 RECORD PERTAMA) ==='
SELECT TOP 10 
    [code],
    [name],
    [distributor_id],
    [city]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_28_10_2025]
GO

-- Step 5: Insert semua data dari table sumber
PRINT '=== STEP 5: MULAI INSERT DATA ==='
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
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_28_10_2025]

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

