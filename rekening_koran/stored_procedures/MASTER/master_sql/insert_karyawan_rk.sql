-- ═══════════════════════════════════════════════════════════════════════════
-- INSERT: KARYAWAN_RK.csv to MASTER_CUSTOMER_BTP_PATTERN
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Database: POWERAPPS
-- Table: [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
--
-- Source: KARYAWAN_RK.csv
-- Type: KARYAWAN
--
-- Purpose:
--   Insert data karyawan dari CSV ke tabel MASTER_CUSTOMER_BTP_PATTERN
--   Set match_count = 1, total_transactions = 1, match_percentage = 100
--   last_line_number = MAX(id) + row number
--
-- ═══════════════════════════════════════════════════════════════════════════

USE [POWERAPPS];
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Inserting KARYAWAN data to MASTER_CUSTOMER_BTP_PATTERN...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Get current max ID for last_line_number calculation
DECLARE @MaxID INT;
SELECT @MaxID = ISNULL(MAX(id), 0) 
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN];

PRINT 'Current max ID: ' + CAST(@MaxID AS VARCHAR);
PRINT '';

BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Insert karyawan data
    INSERT INTO [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN] (
        [customer_name],
        [btp],
        [category],
        [match_count],
        [total_transactions],
        [match_percentage],
        [last_line_number],
        [created_date],
        [type]
    )
    VALUES
        ('ADITYA PRIAMBODO', '9110076505', 'UNKNOWN', 1, 1, 100.00, @MaxID + 1, GETDATE(), 'KARYAWAN'),
        ('AHMAD FADHLI FIRSY', '9110080210', 'UNKNOWN', 1, 1, 100.00, @MaxID + 2, GETDATE(), 'KARYAWAN'),
        ('AMANDA PUSPA DEWI', '9110080074', 'UNKNOWN', 1, 1, 100.00, @MaxID + 3, GETDATE(), 'KARYAWAN'),
        ('ANDY ELFASA', '9110080164', 'UNKNOWN', 1, 1, 100.00, @MaxID + 4, GETDATE(), 'KARYAWAN'),
        ('BAYU SAMUDRA MASTI', '9110080157', 'UNKNOWN', 1, 1, 100.00, @MaxID + 5, GETDATE(), 'KARYAWAN'),
        ('CHRISTY BETJE', '9110003556', 'UNKNOWN', 1, 1, 100.00, @MaxID + 6, GETDATE(), 'KARYAWAN'),
        ('DANNY TRI SAPUTRA', '9110073587', 'UNKNOWN', 1, 1, 100.00, @MaxID + 7, GETDATE(), 'KARYAWAN'),
        ('DARYANTO', '9110040585', 'UNKNOWN', 1, 1, 100.00, @MaxID + 8, GETDATE(), 'KARYAWAN'),
        ('GANDHI SANDRYA', '9110076529', 'UNKNOWN', 1, 1, 100.00, @MaxID + 9, GETDATE(), 'KARYAWAN'),
        ('GHEO ERALDIKA', '9110080132', 'UNKNOWN', 1, 1, 100.00, @MaxID + 10, GETDATE(), 'KARYAWAN'),
        ('GHINA NABILAH MIZA', '9110080069', 'UNKNOWN', 1, 1, 100.00, @MaxID + 11, GETDATE(), 'KARYAWAN'),
        ('HARDIAN PRAMANA', '9110046725', 'UNKNOWN', 1, 1, 100.00, @MaxID + 12, GETDATE(), 'KARYAWAN');
    
    DECLARE @RowsInserted INT = @@ROWCOUNT;
    
    COMMIT TRANSACTION;
    
    PRINT '✅ Insert completed successfully!';
    PRINT '   Rows inserted: ' + CAST(@RowsInserted AS VARCHAR);
    PRINT '';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT '❌ Error occurred during insert:';
    PRINT '   Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT '   Error Message: ' + ERROR_MESSAGE();
    PRINT '';
    RETURN;
END CATCH
GO

-- Verify insert results
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Verifying insert results...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

SELECT 
    [type],
    COUNT(*) AS RecordCount
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
WHERE [type] = 'KARYAWAN'
GROUP BY [type];
GO

PRINT '';
PRINT '✅ Script completed!';
PRINT '';
