-- ═══════════════════════════════════════════════════════════════════════════
-- SP_MASTER_ApproveToFinal
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   Move approved transactions dari BTP_REVIEW ke MP_REKENING_KORAN
--   Hanya yang Status = 'FAIR', 'GOOD', atau 'EXCELLENT'
--   Auto-update IsApproved, ApprovedBy, ApprovedAt di BTP_REVIEW
--
-- Parameters:
--   @ApprovedBy - User yang approve (optional, default SYSTEM_USER)
--
-- Returns:
--   @RowsInserted - Jumlah rows yang di-insert
--   @RowsUpdated - Jumlah rows yang di-update
--
-- Example:
--   EXEC SP_MASTER_ApproveToFinal @ApprovedBy = 'financejd@company.com';
--   
--   -- Atau tanpa parameter (pakai SYSTEM_USER)
--   EXEC SP_MASTER_ApproveToFinal;
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_MASTER_ApproveToFinal]
    @ApprovedBy NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Set default ApprovedBy
    IF @ApprovedBy IS NULL OR @ApprovedBy = ''
    BEGIN
        SET @ApprovedBy = SYSTEM_USER;
    END;
    
    DECLARE @ApprovedAt DATETIME = GETDATE();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- ═══════════════════════════════════════════════════════════════════
        -- INSERT ke MP_REKENING_KORAN
        -- ═══════════════════════════════════════════════════════════════════
        
        PRINT '🔄 Inserting approved transactions to MP_REKENING_KORAN...';
        
        INSERT INTO [POWERAPPS].[dbo].[MP_REKENING_KORAN] (
            [trx_date],
            [created_at],
            [updated_at],
            [credit],
            [btp],
            [desc],
            [Amount],
            [TransactionType],
            [BankType]
        )
        SELECT
            -- TransactionDate sudah bertipe DATE di BTP_REVIEW, langsung pakai atau default ke current date jika NULL
            COALESCE(TransactionDate, CAST(GETDATE() AS DATE)) AS [trx_date],
            
            GETDATE() AS [created_at],
            GETDATE() AS [updated_at],
            
            -- Hardcode credit = '9999' (sementara)
            '9999' AS [credit],
            
            -- BTP
            ISNULL(BTP, '') AS [btp],
            
            -- Description (truncate to 255 chars if needed)
            LEFT(ISNULL(Description, ''), 255) AS [desc],

            -- New columns
            Amount,
            ISNULL(TransactionType, 'CR') AS [TransactionType],
            ISNULL(BankType, 'UNKNOWN') AS [BankType]
            
        FROM [POWERAPPS].[dbo].[BTP_REVIEW]
        WHERE 
            -- Hanya yang status FAIR, GOOD, atau EXCELLENT
            Status IN ('FAIR', 'GOOD', 'EXCELLENT')
            -- Hanya yang belum approved
            AND IsApproved = 0
            -- Pastikan BTP tidak NULL (optional, tergantung requirement)
            -- AND BTP IS NOT NULL AND BTP <> '';
        
        SET @RowsInserted = @@ROWCOUNT;
        PRINT '✅ Inserted ' + CAST(@RowsInserted AS VARCHAR) + ' rows to MP_REKENING_KORAN';
        PRINT '';
        
        -- ═══════════════════════════════════════════════════════════════════
        -- UPDATE BTP_REVIEW: Set IsApproved = 1
        -- ═══════════════════════════════════════════════════════════════════
        
        IF @RowsInserted > 0
        BEGIN
            PRINT '🔄 Updating approval status in BTP_REVIEW...';
            
            UPDATE [POWERAPPS].[dbo].[BTP_REVIEW]
            SET 
                [IsApproved] = 1,
                [ApprovedBy] = @ApprovedBy,
                [ApprovedAt] = @ApprovedAt,
                [ModifiedAt] = GETDATE()
            WHERE 
                Status IN ('FAIR', 'GOOD', 'EXCELLENT')
                AND IsApproved = 0;
            
            SET @RowsUpdated = @@ROWCOUNT;
            PRINT '✅ Updated ' + CAST(@RowsUpdated AS VARCHAR) + ' rows in BTP_REVIEW';
            PRINT '';
        END
        ELSE
        BEGIN
            PRINT 'ℹ️  No rows to insert. No updates needed.';
            PRINT '';
        END;
        
        -- ═══════════════════════════════════════════════════════════════════
        -- COMMIT TRANSACTION
        -- ═══════════════════════════════════════════════════════════════════
        
        COMMIT TRANSACTION;
        
        -- ═══════════════════════════════════════════════════════════════════
        -- RETURN RESULTS
        -- ═══════════════════════════════════════════════════════════════════
        
        PRINT '';
        PRINT '═══════════════════════════════════════════════════════════════════════';
        PRINT '✅ APPROVAL COMPLETED SUCCESSFULLY!';
        PRINT '═══════════════════════════════════════════════════════════════════════';
        PRINT '';
        PRINT 'Summary:';
        PRINT '  📊 Rows inserted to MP_REKENING_KORAN: ' + CAST(@RowsInserted AS VARCHAR);
        PRINT '  ✅ Rows updated in BTP_REVIEW: ' + CAST(@RowsUpdated AS VARCHAR);
        PRINT '  👤 Approved by: ' + @ApprovedBy;
        PRINT '  🕐 Approved at: ' + CONVERT(VARCHAR, @ApprovedAt, 120);
        PRINT '';
        PRINT '═══════════════════════════════════════════════════════════════════════';
        PRINT '';
        
        -- Return result set
        SELECT 
            @RowsInserted AS RowsInserted,
            @RowsUpdated AS RowsUpdated,
            @ApprovedBy AS ApprovedBy,
            @ApprovedAt AS ApprovedAt;
        
    END TRY
    BEGIN CATCH
        -- ═══════════════════════════════════════════════════════════════════
        -- ERROR HANDLING
        -- ═══════════════════════════════════════════════════════════════════
        
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT '';
        PRINT '═══════════════════════════════════════════════════════════════════════';
        PRINT '❌ ERROR OCCURRED!';
        PRINT '═══════════════════════════════════════════════════════════════════════';
        PRINT 'Error Message: ' + @ErrorMessage;
        PRINT 'Error Severity: ' + CAST(@ErrorSeverity AS VARCHAR);
        PRINT 'Error State: ' + CAST(@ErrorState AS VARCHAR);
        PRINT '═══════════════════════════════════════════════════════════════════════';
        PRINT '';
        
        -- Return error
        SELECT 
            0 AS RowsInserted,
            0 AS RowsUpdated,
            @ApprovedBy AS ApprovedBy,
            NULL AS ApprovedAt,
            @ErrorMessage AS ErrorMessage;
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ SP_MASTER_ApproveToFinal created successfully!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Usage:';
PRINT '  EXEC SP_MASTER_ApproveToFinal @ApprovedBy = ''user@email.com'';';
PRINT '';
PRINT 'What it does:';
PRINT '  1. Insert approved transactions (FAIR/GOOD/EXCELLENT) to MP_REKENING_KORAN';
PRINT '  2. Update IsApproved = 1 in BTP_REVIEW';
PRINT '  3. Set ApprovedBy, ApprovedAt, ModifiedAt';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
GO

