-- ═══════════════════════════════════════════════════════════════════════════
-- SP_SAVE_TO_STAGING_DIRECT
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   Execute SP_MASTER_FindBTP_Batch and save results directly to staging
--   WITHOUT using INSERT-EXEC (to avoid nested INSERT-EXEC issue)
--
-- Solution:
--   Instead of capturing SP results, we INSERT directly to staging
--   from within the loop, bank by bank
--
-- Parameters:
--   @TransactionsJSON - JSON array of transactions
--   @BatchID - Optional batch identifier
--   @UploadedBy - Optional user identifier
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_SAVE_TO_STAGING_DIRECT]
    @TransactionsJSON NVARCHAR(MAX),
    @BatchID NVARCHAR(50) = NULL,
    @UploadedBy NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate BatchID if not provided
    IF @BatchID IS NULL
    BEGIN
        SET @BatchID = 'BATCH_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + 
                       REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
    END
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_SAVE_TO_STAGING_DIRECT - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'BatchID: ' + @BatchID;
    IF @UploadedBy IS NOT NULL
        PRINT 'Uploaded By: ' + @UploadedBy;
    PRINT '';
    
    -- Parse JSON and detect bank types
    DECLARE @Transactions TABLE (
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX),
        BankType NVARCHAR(50)
    );
    
    INSERT INTO @Transactions (TransactionID, TransactionDate, Description, BankType)
    SELECT 
        TransactionID,
        TransactionDate,
        Description,
        CASE
            -- Group 3: Special Logic
            WHEN Description LIKE 'TRSF E-BANKING%' OR Description LIKE 'TRSF FROM%' THEN 'TRSF'
            WHEN Description LIKE 'BI-FAST%' THEN 'BIFAST'
            -- Group 1
            WHEN Description LIKE '%LLG-BNI %' THEN 'BNI'
            WHEN Description LIKE '%LLG-BTPN %' THEN 'BTPN'
            WHEN Description LIKE '%LLG-MANDIRI %' THEN 'MANDIRI'
            WHEN Description LIKE '%LLG-BRI %' THEN 'BRI'
            WHEN Description LIKE '%LLG-MEGA %' THEN 'MEGA'
            WHEN Description LIKE '%LLG-PERMATA %' THEN 'PERMATA'
            WHEN Description LIKE '%LLG-DANAMON %' THEN 'DANAMON'
            WHEN Description LIKE '%LLG-CITIBANK %' THEN 'CITIBANK'
            WHEN Description LIKE '%LLG-SINARMAS %' THEN 'SINARMAS'
            -- Group 2
            WHEN Description LIKE '%LLG-CIMB NIAGA%' THEN 'CIMB'
            WHEN Description LIKE '%LLG-MAYBANK INDONE%' THEN 'MAYBANK'
            WHEN Description LIKE '%LLG-HSBC INDONESIA%' THEN 'HSBC'
            WHEN Description LIKE '%LLG-UOB INDONESIA%' THEN 'UOB'
            WHEN Description LIKE '%LLG-MUAMALAT INDON%' THEN 'MUAMALAT'
            WHEN Description LIKE '%LLG-OCBC NISP%' THEN 'OCBC'
            WHEN Description LIKE '%LLG-DBS INDONESIA%' THEN 'DBS'
            WHEN Description LIKE '%LLG-CAPITAL INDONE%' THEN 'CAPITAL'
            WHEN Description LIKE '%LLG-WOORI SAUDARA%' THEN 'WOORI'
            ELSE 'UNKNOWN'
        END as BankType
    FROM OPENJSON(@TransactionsJSON)
    WITH (
        TransactionID INT '$.TransactionID',
        TransactionDate NVARCHAR(50) '$.TransactionDate',
        Description NVARCHAR(MAX) '$.Description'
    );
    
    DECLARE @TotalTransactions INT;
    SELECT @TotalTransactions = COUNT(*) FROM @Transactions;
    PRINT 'Total transactions: ' + CAST(@TotalTransactions AS VARCHAR);
    PRINT '';
    
    -- Process each bank type and save directly to staging
    DECLARE @SavedCount INT = 0;
    
    -- TRSF
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'TRSF')
    BEGIN
        PRINT '🔄 Processing TRSF...';
        
        DECLARE @TRSF_JSON NVARCHAR(MAX);
        SELECT @TRSF_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'TRSF' FOR JSON PATH
        );
        
        INSERT INTO dbo.REKENING_KORAN_STAGING (
            TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage,
            MatchCount, TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
            BestFlag, LatestFlag, Label, Status, Message, BankType, ProcessedAt,
            CreatedAt, BatchID, UploadedBy, UploadedAt
        )
        SELECT 
            TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage,
            MatchCount, TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
            BestFlag, LatestFlag, Label, Status, Message, 'TRSF' AS BankType, ProcessedAt,
            GETDATE(), @BatchID, @UploadedBy, GETDATE()
        FROM OPENROWSET(BULK N'', FORMATFILE = N'')  -- This won't work, need different approach
        -- We still have the nested INSERT-EXEC problem!
    END
    
    -- ... (This approach still has the same problem!)
    
    PRINT '';
    PRINT '❌ APPROACH FAILED: Still has nested INSERT-EXEC issue!';
    PRINT '';
END;
GO

