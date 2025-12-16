-- =====================================================
-- SP_BTP_REVIEW_FilterByTransactionDate
-- =====================================================
-- Purpose: Filter BTP_REVIEW berdasarkan TransactionDate untuk menghindari delegation di Power Apps
-- Input: @TransactionDate (DATE, nullable) - jika NULL, return semua data
-- Output: Result set dengan semua kolom dari BTP_REVIEW yang sudah difilter
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_BTP_REVIEW_FilterByTransactionDate]
    @TransactionDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        [ID],
        [BatchID],
        [UploadedBy],
        [UploadedAt],
        [TransactionID],
        [TransactionDate],
        [Description],
        [CustomerName],
        [BTP],
        [MatchPercentage],
        [MatchCount],
        [TotalTransactions],
        [LastLineNumber],
        [TotalBTPOptions],
        [OptionNumber],
        [BestFlag],
        [LatestFlag],
        [Label],
        [Status],
        [Message],
        [BankType],
        [ProcessedAt],
        [IsApproved],
        [ApprovedBy],
        [ApprovedAt],
        [Notes],
        [CreatedAt],
        [ModifiedAt],
        [Amount],
        [TransactionType]
    FROM [POWERAPPS].[dbo].[BTP_REVIEW]
    WHERE (@TransactionDate IS NULL OR [TransactionDate] = @TransactionDate)
    ORDER BY [CreatedAt] DESC;
END
GO

