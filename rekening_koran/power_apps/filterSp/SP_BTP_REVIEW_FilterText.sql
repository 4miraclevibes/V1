-- =====================================================
-- SP_BTP_REVIEW_FilterText
-- =====================================================
-- Purpose: Stored Procedure untuk filter BTP_REVIEW berdasarkan text fields saja
--          Switch/toggle tetap di Power Apps (Status dan TransactionType)
-- Input: Parameter untuk text filtering (semua nullable)
-- Output: Result set dengan semua kolom dari BTP_REVIEW yang sudah difilter
-- =====================================================
-- Usage di Power Apps:
--   SP_BTP_REVIEW_FilterText.Run({
--       SearchCustomer: searchCustomerRv.Text,
--       SearchBatch: searchBatchRv.Text,
--       SearchDescription: searchDescRv.Text,
--       SearchBankType: searchBtRv.Text,
--       SearchBTP: searchBtpRv.Text,
--       UploadedAt: UaDpRvRk.SelectedDate,
--       TransactionDate: TrxDpRvRk.SelectedDate
--   })
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_BTP_REVIEW_FilterText]
    @SearchCustomer NVARCHAR(200) = NULL,
    @SearchBatch NVARCHAR(100) = NULL,
    @SearchDescription NVARCHAR(MAX) = NULL,
    @SearchBankType NVARCHAR(50) = NULL,
    @SearchBTP NVARCHAR(50) = NULL,
    @UploadedAt DATE = NULL,
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
    FROM [dbo].[BTP_REVIEW]
    WHERE 
        -- Filter CustomerName (LIKE untuk partial match)
        (@SearchCustomer IS NULL OR @SearchCustomer = '' OR [CustomerName] LIKE '%' + @SearchCustomer + '%')
        
        -- Filter BatchID
        AND (@SearchBatch IS NULL OR @SearchBatch = '' OR [BatchID] LIKE '%' + @SearchBatch + '%')
        
        -- Filter Description
        AND (@SearchDescription IS NULL OR @SearchDescription = '' OR [Description] LIKE '%' + @SearchDescription + '%')
        
        -- Filter BankType
        AND (@SearchBankType IS NULL OR @SearchBankType = '' OR [BankType] LIKE '%' + @SearchBankType + '%')
        
        -- Filter BTP
        AND (@SearchBTP IS NULL OR @SearchBTP = '' OR [BTP] LIKE '%' + @SearchBTP + '%')
        
        -- Filter UploadedAt (exact date match)
        AND (@UploadedAt IS NULL OR CAST([UploadedAt] AS DATE) = @UploadedAt)
        
        -- Filter TransactionDate (exact date match)
        AND (@TransactionDate IS NULL OR CAST([TransactionDate] AS DATE) = @TransactionDate)
    ORDER BY 
        [MatchPercentage] ASC,
        [CreatedAt] DESC;
END
GO

-- =====================================================
-- Test Stored Procedure
-- =====================================================
/*
-- Test 1: Tanpa parameter (return semua data)
EXEC [dbo].[SP_BTP_REVIEW_FilterText] NULL, NULL, NULL, NULL, NULL, NULL, NULL;

-- Test 2: Filter CustomerName
EXEC [dbo].[SP_BTP_REVIEW_FilterText] 
    @SearchCustomer = 'PT ABC',
    @SearchBatch = NULL,
    @SearchDescription = NULL,
    @SearchBankType = NULL,
    @SearchBTP = NULL,
    @UploadedAt = NULL,
    @TransactionDate = NULL;

-- Test 3: Filter multiple fields
EXEC [dbo].[SP_BTP_REVIEW_FilterText] 
    @SearchCustomer = 'PT',
    @SearchBatch = 'BATCH001',
    @SearchDescription = NULL,
    @SearchBankType = 'BCA',
    @SearchBTP = NULL,
    @UploadedAt = NULL,
    @TransactionDate = NULL;

-- Test 4: Filter dengan date
EXEC [dbo].[SP_BTP_REVIEW_FilterText] 
    @SearchCustomer = NULL,
    @SearchBatch = NULL,
    @SearchDescription = NULL,
    @SearchBankType = NULL,
    @SearchBTP = NULL,
    @UploadedAt = '2025-01-15',
    @TransactionDate = NULL;
*/
