-- =====================================================
-- SP_BTP_REVIEW_CountRows
-- =====================================================
-- Purpose: Menghitung total row BTP_REVIEW berdasarkan filter
--          Untuk mengatasi batasan 2000 row di Power Apps
-- Input: Semua parameter filter (semua nullable)
-- Output: TotalRows (integer)
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_BTP_REVIEW_CountRows]
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
    @ShowDebit BIT = NULL  -- NULL = show all, 1 = DB only, 0 = CR only
    
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(*) AS TotalRows
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
        );
END
GO

-- =====================================================
-- Contoh penggunaan:
-- =====================================================

-- Hitung total row untuk review mode (NO_MATCH, UNKNOWN_BANK, dll)
-- EXEC [dbo].[SP_BTP_REVIEW_CountRows] @ShowReview = 1

-- Hitung total row untuk approved mode (FAIR, GOOD, dll)
-- EXEC [dbo].[SP_BTP_REVIEW_CountRows] @ShowReview = 0

-- Hitung dengan filter BatchID
-- EXEC [dbo].[SP_BTP_REVIEW_CountRows] @ShowReview = 1, @SearchBatch = 'BATCH001'

-- Hitung dengan filter tanggal dan transaction type (CR)
-- EXEC [dbo].[SP_BTP_REVIEW_CountRows] 
--     @ShowReview = 1, 
--     @TransactionDate = '2025-01-08',
--     @ShowDebit = 0

