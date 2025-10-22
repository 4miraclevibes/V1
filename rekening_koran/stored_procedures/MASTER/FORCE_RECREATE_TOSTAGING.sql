-- FORCE RECREATE SP_MASTER_FindBTP_Batch_ToStaging
-- Drop and recreate to ensure clean state

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'FORCE RECREATING SP_MASTER_FindBTP_Batch_ToStaging...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Step 1: DROP if exists
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'SP_MASTER_FindBTP_Batch_ToStaging')
BEGIN
    PRINT '🗑️  Dropping old SP_MASTER_FindBTP_Batch_ToStaging...';
    DROP PROCEDURE [dbo].[SP_MASTER_FindBTP_Batch_ToStaging];
    PRINT '✅ Dropped!';
END
ELSE
BEGIN
    PRINT '⚠️  SP_MASTER_FindBTP_Batch_ToStaging does not exist';
END

PRINT '';
PRINT '📦 Creating NEW SP_MASTER_FindBTP_Batch_ToStaging...';
PRINT '';
GO

-- Step 2: CREATE (not ALTER)
CREATE PROCEDURE [dbo].[SP_MASTER_FindBTP_Batch_ToStaging]
    @TransactionsJSON NVARCHAR(MAX),
    @BatchID NVARCHAR(50) = NULL,
    @UploadedBy NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate BatchID jika tidak disediakan
    IF @BatchID IS NULL
    BEGIN
        SET @BatchID = 'BATCH_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + 
                       REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
    END
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_Batch_ToStaging - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'BatchID: ' + @BatchID;
    IF @UploadedBy IS NOT NULL
        PRINT 'Uploaded By: ' + @UploadedBy;
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Execute MASTER SP dan capture results
    -- ═══════════════════════════════════════════════════════════════════════
    
    CREATE TABLE #Results (
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX),
        CustomerName NVARCHAR(200),
        BTP NVARCHAR(50),
        MatchPercentage DECIMAL(5,2),
        MatchCount INT,
        TotalTransactions INT,
        LastLineNumber INT,
        TotalBTPOptions INT,
        OptionNumber INT,
        BestFlag NVARCHAR(10),
        LatestFlag NVARCHAR(10),
        Label NVARCHAR(50),
        Status NVARCHAR(20),
        Message NVARCHAR(500),
        BankType NVARCHAR(50),
        ProcessedAt DATETIME
    );
    
    PRINT '🔄 Executing SP_MASTER_FindBTP_Batch...';
    
    INSERT INTO #Results
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @TransactionsJSON;
    
    DECLARE @ResultCount INT = @@ROWCOUNT;
    PRINT '✅ Processed ' + CAST(@ResultCount AS VARCHAR) + ' rows';
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Save results ke staging table
    -- ═══════════════════════════════════════════════════════════════════════
    
    PRINT '🔄 Saving to REKENING_KORAN_STAGING...';
    
    INSERT INTO dbo.REKENING_KORAN_STAGING (
        TransactionID,
        TransactionDate,
        Description,
        CustomerName,
        BTP,
        MatchPercentage,
        MatchCount,
        TotalTransactions,
        LastLineNumber,
        TotalBTPOptions,
        OptionNumber,
        BestFlag,
        LatestFlag,
        Label,
        Status,
        Message,
        BankType,
        ProcessedAt,
        CreatedAt,
        BatchID,
        UploadedBy,
        UploadedAt
    )
    SELECT
        TransactionID,
        TransactionDate,
        Description,
        CustomerName,
        BTP,
        MatchPercentage,
        MatchCount,
        TotalTransactions,
        LastLineNumber,
        TotalBTPOptions,
        OptionNumber,
        BestFlag,
        LatestFlag,
        Label,
        Status,
        Message,
        BankType,
        ProcessedAt,
        GETDATE(),  -- CreatedAt
        @BatchID,
        @UploadedBy,
        GETDATE()   -- UploadedAt
    FROM #Results;
    
    DECLARE @SavedCount INT = @@ROWCOUNT;
    PRINT '✅ Saved ' + CAST(@SavedCount AS VARCHAR) + ' rows';
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Return results untuk display
    -- ═══════════════════════════════════════════════════════════════════════
    
    SELECT * FROM #Results
    ORDER BY TransactionID, OptionNumber;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Return summary
    -- ═══════════════════════════════════════════════════════════════════════
    
    SELECT 
        @BatchID AS BatchID,
        @UploadedBy AS UploadedBy,
        @SavedCount AS TotalRowsSaved,
        GETDATE() AS SavedAt,
        'SUCCESS' AS Status;
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'COMPLETED!';
    PRINT 'BatchID: ' + @BatchID;
    PRINT 'Rows Saved: ' + CAST(@SavedCount AS VARCHAR);
    PRINT '═══════════════════════════════════════════════════════════════════════';
    
    DROP TABLE #Results;
END;
GO

PRINT '';
PRINT '✅ SP_MASTER_FindBTP_Batch_ToStaging RECREATED!';
PRINT '';
GO

