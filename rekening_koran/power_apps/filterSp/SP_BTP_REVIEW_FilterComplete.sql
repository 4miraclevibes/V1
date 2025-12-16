-- =====================================================
-- SP_BTP_REVIEW_FilterComplete
-- =====================================================
-- Purpose: Filter BTP_REVIEW dengan semua parameter untuk menghindari delegation di Power Apps
-- Input: Semua parameter filter (semua nullable)
-- Output: Result set dengan semua kolom dari BTP_REVIEW yang sudah difilter
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_BTP_REVIEW_FilterComplete]
    -- Filter Status (untuk review atau approved)
    @ShowReview BIT = 1,  -- 1 = show review (NO_MATCH, NO_PATTERN, dll), 0 = show approved (FAIR, GOOD, dll)
    
    -- Filter Status values (untuk review)
    @IncludeNoMatch BIT = 1,
    @IncludeUnknownBank BIT = 1,
    @IncludeMissing BIT = 1,
    @IncludeNoPattern BIT = 1,
    
    -- Filter Status values (untuk approved)
    @IncludeFair BIT = 1,
    @IncludeGood BIT = 1,
    @IncludeLow BIT = 1,
    @IncludeExcellent BIT = 1,
    
    -- Filter umum
    @IsApproved BIT = 0,
    @SearchCustomer NVARCHAR(200) = NULL,
    @SearchBatch NVARCHAR(100) = NULL,
    @SearchDescription NVARCHAR(MAX) = NULL,
    @SearchBankType NVARCHAR(50) = NULL,
    @SearchBTP NVARCHAR(50) = NULL,
    
    -- Filter tanggal
    @UploadedAt DATE = NULL,
    @TransactionDate DATE = NULL,
    
    -- Filter transaction type
    @ShowDebit BIT = NULL,  -- NULL = show all, 1 = DB only, 0 = CR only
    
    -- Sorting
    @SortBy NVARCHAR(50) = 'MatchPercentage',  -- MatchPercentage, CreatedAt, TransactionDate
    @SortOrder NVARCHAR(10) = 'ASC'  -- ASC, DESC
    
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
    WHERE 
        -- Filter IsApproved
        [IsApproved] = @IsApproved
        
        -- Filter Status berdasarkan @ShowReview
        AND (
            (@ShowReview = 1 AND (
                (@IncludeNoMatch = 1 AND [Status] = 'NO_MATCH') OR
                (@IncludeUnknownBank = 1 AND [Status] = 'UNKNOWN_BANK') OR
                (@IncludeMissing = 1 AND [Status] = 'MISSING') OR
                (@IncludeNoPattern = 1 AND [Status] = 'NO_PATTERN')
            ))
            OR
            (@ShowReview = 0 AND (
                (@IncludeFair = 1 AND [Status] = 'FAIR') OR
                (@IncludeGood = 1 AND [Status] = 'GOOD') OR
                (@IncludeLow = 1 AND [Status] = 'LOW') OR
                (@IncludeExcellent = 1 AND [Status] = 'EXCELLENT')
            ))
        )
        
        -- Filter CustomerName
        AND (@SearchCustomer IS NULL OR @SearchCustomer = '' OR [CustomerName] LIKE '%' + @SearchCustomer + '%')
        
        -- Filter BatchID
        AND (@SearchBatch IS NULL OR @SearchBatch = '' OR [BatchID] LIKE '%' + @SearchBatch + '%')
        
        -- Filter Description
        AND (@SearchDescription IS NULL OR @SearchDescription = '' OR [Description] LIKE '%' + @SearchDescription + '%')
        
        -- Filter BankType
        AND (@SearchBankType IS NULL OR @SearchBankType = '' OR [BankType] LIKE '%' + @SearchBankType + '%')
        
        -- Filter BTP
        AND (@SearchBTP IS NULL OR @SearchBTP = '' OR [BTP] LIKE '%' + @SearchBTP + '%')
        
        -- Filter UploadedAt
        AND (@UploadedAt IS NULL OR CAST([UploadedAt] AS DATE) = @UploadedAt)
        
        -- Filter TransactionDate
        AND (@TransactionDate IS NULL OR [TransactionDate] = @TransactionDate)
        
        -- Filter TransactionType
        AND (
            @ShowDebit IS NULL OR
            (@ShowDebit = 1 AND [TransactionType] = 'DB') OR
            (@ShowDebit = 0 AND [TransactionType] = 'CR')
        )
    ORDER BY 
        CASE WHEN @SortBy = 'MatchPercentage' AND @SortOrder = 'ASC' THEN [MatchPercentage] END ASC,
        CASE WHEN @SortBy = 'MatchPercentage' AND @SortOrder = 'DESC' THEN [MatchPercentage] END DESC,
        CASE WHEN @SortBy = 'CreatedAt' AND @SortOrder = 'ASC' THEN [CreatedAt] END ASC,
        CASE WHEN @SortBy = 'CreatedAt' AND @SortOrder = 'DESC' THEN [CreatedAt] END DESC,
        CASE WHEN @SortBy = 'TransactionDate' AND @SortOrder = 'ASC' THEN [TransactionDate] END ASC,
        CASE WHEN @SortBy = 'TransactionDate' AND @SortOrder = 'DESC' THEN [TransactionDate] END DESC,
        -- Default sort jika tidak ada yang cocok
        [MatchPercentage] ASC;
END
GO

