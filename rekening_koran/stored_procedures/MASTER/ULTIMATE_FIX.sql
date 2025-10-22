-- ULTIMATE FIX: Drop and recreate SP with explicit column list

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'ULTIMATE FIX: Dropping SP_MASTER_FindBTP_Batch_ToStaging...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Force drop
IF OBJECT_ID('dbo.SP_MASTER_FindBTP_Batch_ToStaging', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.SP_MASTER_FindBTP_Batch_ToStaging;
    PRINT '✅ Dropped!';
END
ELSE
BEGIN
    PRINT '⚠️  SP does not exist';
END
GO

PRINT '';
PRINT '📦 Creating NEW SP with explicit column mapping...';
PRINT '';
GO

CREATE PROCEDURE [dbo].[SP_MASTER_FindBTP_Batch_ToStaging]
    @TransactionsJSON NVARCHAR(MAX),
    @BatchID NVARCHAR(50) = NULL,
    @UploadedBy NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
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
    
    -- Create temp table matching Master SP output (18 columns)
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
    
    PRINT '🔄 Saving to REKENING_KORAN_STAGING...';
    
    -- Insert with EXPLICIT column mapping (22 columns, ID is auto-increment)
    -- Table has 23 columns: ID (1) + 22 data columns (2-23)
    INSERT INTO dbo.REKENING_KORAN_STAGING (
        TransactionID,       -- Column 2
        TransactionDate,     -- Column 3
        Description,         -- Column 4
        CustomerName,        -- Column 5
        BTP,                 -- Column 6
        MatchPercentage,     -- Column 7
        MatchCount,          -- Column 8
        TotalTransactions,   -- Column 9
        LastLineNumber,      -- Column 10
        TotalBTPOptions,     -- Column 11
        OptionNumber,        -- Column 12
        BestFlag,            -- Column 13
        LatestFlag,          -- Column 14
        Label,               -- Column 15
        Status,              -- Column 16
        Message,             -- Column 17
        BankType,            -- Column 18
        ProcessedAt,         -- Column 19
        CreatedAt,           -- Column 20
        BatchID,             -- Column 21
        UploadedBy,          -- Column 22
        UploadedAt           -- Column 23
    )
    SELECT
        r.TransactionID,
        r.TransactionDate,
        r.Description,
        r.CustomerName,
        r.BTP,
        r.MatchPercentage,
        r.MatchCount,
        r.TotalTransactions,
        r.LastLineNumber,
        r.TotalBTPOptions,
        r.OptionNumber,
        r.BestFlag,
        r.LatestFlag,
        r.Label,
        r.Status,
        r.Message,
        r.BankType,
        r.ProcessedAt,
        GETDATE(),    -- CreatedAt
        @BatchID,     -- BatchID
        @UploadedBy,  -- UploadedBy
        GETDATE()     -- UploadedAt
    FROM #Results r;
    
    DECLARE @SavedCount INT = @@ROWCOUNT;
    PRINT '✅ Saved ' + CAST(@SavedCount AS VARCHAR) + ' rows';
    PRINT '';
    
    SELECT * FROM #Results
    ORDER BY TransactionID, OptionNumber;
    
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
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ SP_MASTER_FindBTP_Batch_ToStaging RECREATED SUCCESSFULLY!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Now run: TEST_SIMPLE.sql';
PRINT '';
GO

