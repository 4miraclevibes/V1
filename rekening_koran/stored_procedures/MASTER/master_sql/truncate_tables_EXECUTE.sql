-- ═══════════════════════════════════════════════════════════════════════════
-- TRUNCATE TABLES: BTP_REVIEW & MP_REKENING_KORAN
-- ═══════════════════════════════════════════════════════════════════════════
--
-- ⚠️  WARNING: TRUNCATE akan menghapus SEMUA data dari tabel!
-- ⚠️  Operasi ini TIDAK BISA di-rollback!
--
-- ═══════════════════════════════════════════════════════════════════════════

USE [POWERAPPS];
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TRUNCATE TABLES';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

BEGIN TRY
    -- Check current row counts before truncate
    DECLARE @BTP_REVIEW_Count INT;
    DECLARE @MP_REKENING_KORAN_Count INT;
    
    SELECT @BTP_REVIEW_Count = COUNT(*) FROM [POWERAPPS].[dbo].[BTP_REVIEW];
    SELECT @MP_REKENING_KORAN_Count = COUNT(*) FROM [POWERAPPS].[dbo].[MP_REKENING_KORAN];
    
    PRINT '📊 Current Row Counts:';
    PRINT '   BTP_REVIEW: ' + CAST(@BTP_REVIEW_Count AS VARCHAR) + ' rows';
    PRINT '   MP_REKENING_KORAN: ' + CAST(@MP_REKENING_KORAN_Count AS VARCHAR) + ' rows';
    PRINT '';
    PRINT '🔄 Starting truncate operations...';
    PRINT '';
    
    -- Truncate BTP_REVIEW
    PRINT '🔄 Truncating BTP_REVIEW...';
    TRUNCATE TABLE [POWERAPPS].[dbo].[BTP_REVIEW];
    PRINT '✅ BTP_REVIEW truncated successfully';
    PRINT '';
    
    -- Truncate MP_REKENING_KORAN
    PRINT '🔄 Truncating MP_REKENING_KORAN...';
    TRUNCATE TABLE [POWERAPPS].[dbo].[MP_REKENING_KORAN];
    PRINT '✅ MP_REKENING_KORAN truncated successfully';
    PRINT '';
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '✅ All tables truncated successfully!';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    
    -- Verify row counts after truncate
    DECLARE @After_BTP_REVIEW_Count INT;
    DECLARE @After_MP_REKENING_KORAN_Count INT;
    
    SELECT @After_BTP_REVIEW_Count = COUNT(*) FROM [POWERAPPS].[dbo].[BTP_REVIEW];
    SELECT @After_MP_REKENING_KORAN_Count = COUNT(*) FROM [POWERAPPS].[dbo].[MP_REKENING_KORAN];
    
    PRINT '';
    PRINT '📊 Row Counts After Truncate:';
    PRINT '   BTP_REVIEW: ' + CAST(@After_BTP_REVIEW_Count AS VARCHAR) + ' rows';
    PRINT '   MP_REKENING_KORAN: ' + CAST(@After_MP_REKENING_KORAN_Count AS VARCHAR) + ' rows';
    PRINT '';
    
END TRY
BEGIN CATCH
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '❌ Error occurred during truncate:';
    PRINT '   Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT '   Error Message: ' + ERROR_MESSAGE();
    PRINT '   Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '═══════════════════════════════════════════════════════════════════════';
    RETURN;
END CATCH
GO
