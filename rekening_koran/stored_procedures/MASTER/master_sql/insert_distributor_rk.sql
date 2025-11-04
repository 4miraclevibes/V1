-- ═══════════════════════════════════════════════════════════════════════════
-- INSERT: DISTRIBUTOR_RK.csv to MASTER_CUSTOMER_BTP_PATTERN
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Database: POWERAPPS
-- Table: [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
--
-- Source: DISTRIBUTOR_RK.csv
-- Type: DISTRIBUTOR
--
-- Purpose:
--   Insert data distributor dari CSV ke tabel MASTER_CUSTOMER_BTP_PATTERN
--   Set match_count = 1, total_transactions = 1, match_percentage = 100
--   last_line_number = MAX(id) + row number
--
-- ═══════════════════════════════════════════════════════════════════════════

USE [POWERAPPS];
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Inserting DISTRIBUTOR data to MASTER_CUSTOMER_BTP_PATTERN...';
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
    
    -- Insert distributor data
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
        ('BPN BARU INDAH PT', '2300015470', 'UNKNOWN', 1, 1, 100.00, @MaxID + 1, GETDATE(), 'DISTRIBUTOR'),
        ('CAHAYALESTARI TEGU', '2300016440', 'UNKNOWN', 1, 1, 100.00, @MaxID + 2, GETDATE(), 'DISTRIBUTOR'),
        ('SETORAN PEMBAYARAN INV', '2300015457', 'UNKNOWN', 1, 1, 100.00, @MaxID + 3, GETDATE(), 'DISTRIBUTOR'),
        ('CIPTA ANUGERAH REZ', '2300007974', 'UNKNOWN', 1, 1, 100.00, @MaxID + 4, GETDATE(), 'DISTRIBUTOR'),
        ('COLAMAS SUKSES MANDIRI', '2300016536', 'UNKNOWN', 1, 1, 100.00, @MaxID + 5, GETDATE(), 'DISTRIBUTOR'),
        ('CV SUMBER BARU DAMAI SEJAHTERA', '2300016368', 'UNKNOWN', 1, 1, 100.00, @MaxID + 6, GETDATE(), 'DISTRIBUTOR'),
        ('CV. Makmur Sentosa', '2300018949', 'UNKNOWN', 1, 1, 100.00, @MaxID + 7, GETDATE(), 'DISTRIBUTOR'),
        ('MAKMUR SENTOSA PER', '2300016707', 'UNKNOWN', 1, 1, 100.00, @MaxID + 8, GETDATE(), 'DISTRIBUTOR'),
        ('GDI/Prima', '2300018959', 'UNKNOWN', 1, 1, 100.00, @MaxID + 9, GETDATE(), 'DISTRIBUTOR'),
        ('HOSADA PERMAI', '2300019157', 'UNKNOWN', 1, 1, 100.00, @MaxID + 10, GETDATE(), 'DISTRIBUTOR'),
        ('O KONG JUNG', '2300012978', 'UNKNOWN', 1, 1, 100.00, @MaxID + 11, GETDATE(), 'DISTRIBUTOR'),
        ('PERMATA SURYA BAHARI PEKA', '2300019068', 'UNKNOWN', 1, 1, 100.00, @MaxID + 12, GETDATE(), 'DISTRIBUTOR'),
        ('PRESTASI MITRA DUMAI', '2300019067', 'UNKNOWN', 1, 1, 100.00, @MaxID + 13, GETDATE(), 'DISTRIBUTOR'),
        ('PT MENARA NUSANTARA PERSADA', '2300016441', 'UNKNOWN', 1, 1, 100.00, @MaxID + 14, GETDATE(), 'DISTRIBUTOR'),
        ('PT MULTI SUKSES MAKMUR PERKASA', '2300009599', 'UNKNOWN', 1, 1, 100.00, @MaxID + 15, GETDATE(), 'DISTRIBUTOR'),
        ('PT. ANUGRAH BERKAT ANDA', '2300006328', 'UNKNOWN', 1, 1, 100.00, @MaxID + 16, GETDATE(), 'DISTRIBUTOR'),
        ('PT. KURNIA MAJU PERKASA', '2300016411', 'UNKNOWN', 1, 1, 100.00, @MaxID + 17, GETDATE(), 'DISTRIBUTOR'),
        ('PT. PULAU BARU MANDIRI', '2300015467', 'UNKNOWN', 1, 1, 100.00, @MaxID + 18, GETDATE(), 'DISTRIBUTOR'),
        ('PT. PUNCAK LEMBAH HIJAU', '2300011171', 'UNKNOWN', 1, 1, 100.00, @MaxID + 19, GETDATE(), 'DISTRIBUTOR'),
        ('PT. SINAR MAYURI', '2300006332', 'UNKNOWN', 1, 1, 100.00, @MaxID + 20, GETDATE(), 'DISTRIBUTOR'),
        ('PUJI SURYA INDAH', '2300006333', 'UNKNOWN', 1, 1, 100.00, @MaxID + 21, GETDATE(), 'DISTRIBUTOR'),
        ('PULAUBARU JAYA', '2300014473', 'UNKNOWN', 1, 1, 100.00, @MaxID + 22, GETDATE(), 'DISTRIBUTOR'),
        ('SAMPURNA', '2300008359', 'UNKNOWN', 1, 1, 100.00, @MaxID + 23, GETDATE(), 'DISTRIBUTOR'),
        ('SUFO TRITAMA', '2300008010', 'UNKNOWN', 1, 1, 100.00, @MaxID + 24, GETDATE(), 'DISTRIBUTOR'),
        ('SURYA ANUGERAH SENTOSA', '2300010519', 'UNKNOWN', 1, 1, 100.00, @MaxID + 25, GETDATE(), 'DISTRIBUTOR'),
        ('TELAGA MAS CV', '2300008839', 'UNKNOWN', 1, 1, 100.00, @MaxID + 26, GETDATE(), 'DISTRIBUTOR'),
        ('UNIGEMILANGSENTOSA', '2300011921', 'UNKNOWN', 1, 1, 100.00, @MaxID + 27, GETDATE(), 'DISTRIBUTOR');
    
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
WHERE [type] = 'DISTRIBUTOR'
GROUP BY [type];
GO

PRINT '';
PRINT '✅ Script completed!';
PRINT '';
