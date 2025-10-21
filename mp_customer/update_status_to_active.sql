    -- Script untuk update status NULL menjadi 'active' di MP_CUSTOMER_NEW

    USE [POWERAPPS]
    GO

    -- Step 1: Cek jumlah data dengan status NULL
    PRINT '=== STEP 1: CEK DATA DENGAN STATUS NULL ==='
    SELECT COUNT(*) as 'Jumlah Data Dengan Status NULL'
    FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
    WHERE [status] IS NULL
    GO

    -- Step 2: Tampilkan sample data yang akan diupdate
    PRINT '=== STEP 2: SAMPLE DATA YANG AKAN DIUPDATE (10 RECORD) ==='
    SELECT TOP 10 
        [id],
        [code],
        [name],
        [status],
        [distributor_id]
    FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
    WHERE [status] IS NULL
    ORDER BY [id]
    GO

    -- Step 3: Update status NULL menjadi 'active'
    PRINT '=== STEP 3: MULAI UPDATE STATUS ==='
    PRINT 'Waktu mulai: ' + CONVERT(VARCHAR, GETDATE(), 120)

    BEGIN TRANSACTION

    UPDATE [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
    SET [status] = 'active',
        [updated_at] = GETDATE()
    WHERE [status] IS NULL

    -- Tampilkan jumlah data yang berhasil diupdate
    DECLARE @UpdatedCount INT = @@ROWCOUNT
    PRINT 'Jumlah data yang berhasil diupdate: ' + CAST(@UpdatedCount AS VARCHAR)
    PRINT 'Waktu selesai: ' + CONVERT(VARCHAR, GETDATE(), 120)

    COMMIT TRANSACTION

    PRINT '=== UPDATE SELESAI ==='
    GO

    -- Step 4: Verifikasi hasil update
    PRINT '=== STEP 4: VERIFIKASI HASIL ==='
    SELECT COUNT(*) as 'Jumlah Data Dengan Status NULL (Seharusnya 0)'
    FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
    WHERE [status] IS NULL

    SELECT COUNT(*) as 'Total Data Dengan Status Active'
    FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
    WHERE [status] = 'active'
    GO

    PRINT 'Script selesai dijalankan!'

