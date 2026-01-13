-- =====================================================
-- VW_BTP_REVIEW_FilterReady
-- =====================================================
-- Purpose: View sederhana untuk BTP_REVIEW yang siap untuk filtering di Power Apps
--          Filter text dilakukan di Power Apps dengan cara delegation-safe menggunakan "in" operator
--          Switch/toggle tetap di Power Apps (Status dan TransactionType)
-- =====================================================
-- Usage di Power Apps:
--   Langsung pakai View ini sebagai data source, lalu filter dengan:
--   - Text fields: gunakan "in" operator (delegation-safe)
--   - Status: filter langsung di Power Apps
--   - TransactionType: filter langsung di Power Apps
-- =====================================================

CREATE OR ALTER VIEW [dbo].[VW_BTP_REVIEW_FilterReady]
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
    [IsApproved],
    [ApprovedBy],
    [ApprovedAt],
    [Notes],
    [CreatedAt],
    [ModifiedAt],
    [Amount],
    [TransactionType],
    -- Helper columns untuk filtering delegation-safe
    CAST([UploadedAt] AS DATE) AS UploadedAtDate,
    CAST([TransactionDate] AS DATE) AS TransactionDateOnly
FROM [dbo].[BTP_REVIEW];
GO

-- =====================================================
-- Index untuk performa filtering
-- =====================================================
-- Pastikan index sudah ada di table BTP_REVIEW:
-- CREATE INDEX IX_BTP_REVIEW_CustomerName ON dbo.BTP_REVIEW(CustomerName);
-- CREATE INDEX IX_BTP_REVIEW_BatchID ON dbo.BTP_REVIEW(BatchID);
-- CREATE INDEX IX_BTP_REVIEW_BankType ON dbo.BTP_REVIEW(BankType);
-- CREATE INDEX IX_BTP_REVIEW_BTP ON dbo.BTP_REVIEW(BTP);
-- CREATE INDEX IX_BTP_REVIEW_Status ON dbo.BTP_REVIEW(Status);
-- CREATE INDEX IX_BTP_REVIEW_TransactionType ON dbo.BTP_REVIEW(TransactionType);
-- CREATE INDEX IX_BTP_REVIEW_IsApproved ON dbo.BTP_REVIEW(IsApproved);
-- CREATE INDEX IX_BTP_REVIEW_UploadedAt ON dbo.BTP_REVIEW(UploadedAt);
-- GO
