CREATE OR ALTER VIEW [POWERAPPS].[dbo].[VW_BTP_REVIEW]
AS
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
    [Amount],
    [TransactionType],
    [IsApproved],
    [ApprovedBy],
    [ApprovedAt],
    [Notes],
    [CreatedAt],
    [ModifiedAt]
FROM [POWERAPPS].[dbo].[BTP_REVIEW];
GO

