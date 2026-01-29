-- ═══════════════════════════════════════════════════════════════════════════
-- BTP_REVIEW Table Structure
-- Last Updated: January 2026
-- ═══════════════════════════════════════════════════════════════════════════

SELECT [ID]
      ,[BatchID]
      ,[UploadedBy]
      ,[UploadedAt]
      ,[TransactionID]
      ,[TransactionDate]
      ,[Description]
      ,[CustomerName]
      ,[BTP]
      ,[MatchPercentage]
      ,[MatchCount]
      ,[TotalTransactions]
      ,[LastLineNumber]
      ,[TotalBTPOptions]
      ,[OptionNumber]
      ,[BestFlag]
      ,[LatestFlag]
      ,[Label]
      ,[Status]
      ,[Message]
      ,[BankType]
      ,[ProcessedAt]
      ,[IsApproved]
      ,[ApprovedBy]
      ,[ApprovedAt]
      ,[Notes]
      ,[CreatedAt]
      ,[ModifiedAt]
      ,[Amount]              -- DECIMAL(18,2) - Nominal transaksi
      ,[TransactionType]     -- NVARCHAR(2) - CR atau DB
      ,[AccountNumber]       -- NVARCHAR(50) - No. Rekening (dari converter)
      ,[AccountName]         -- NVARCHAR(200) - Nama Pemilik Rekening (dari converter)
  FROM [POWERAPPS].[dbo].[BTP_REVIEW]
