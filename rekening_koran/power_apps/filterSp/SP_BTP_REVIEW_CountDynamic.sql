-- =====================================================
-- SP_BTP_REVIEW_CountDynamic
-- =====================================================
-- Purpose: Hitung total row dengan filter BatchID dan TransactionDate
-- Output: TotalRows, TotalCR, TotalDB
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_BTP_REVIEW_CountDynamic]
    @SearchBatch NVARCHAR(100) = NULL,
    @TransactionDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(*) AS TotalRows,
        SUM(CASE WHEN TransactionType = 'CR' THEN 1 ELSE 0 END) AS TotalCR,
        SUM(CASE WHEN TransactionType = 'DB' THEN 1 ELSE 0 END) AS TotalDB
    FROM [POWERAPPS].[dbo].[BTP_REVIEW]
    WHERE 
        (@SearchBatch IS NULL OR @SearchBatch = '' OR BatchID LIKE '%' + @SearchBatch + '%')
        AND (@TransactionDate IS NULL OR TransactionDate = @TransactionDate);
END
GO

-- =====================================================
-- Contoh penggunaan:
-- 
-- Tanpa filter (semua data):
-- EXEC [dbo].[SP_BTP_REVIEW_CountDynamic]
--
-- Filter BatchID:
-- EXEC [dbo].[SP_BTP_REVIEW_CountDynamic] @SearchBatch = 'BATCH001'
--
-- Filter TransactionDate:
-- EXEC [dbo].[SP_BTP_REVIEW_CountDynamic] @TransactionDate = '2025-01-08'
--
-- Filter keduanya:
-- EXEC [dbo].[SP_BTP_REVIEW_CountDynamic] @SearchBatch = 'BATCH001', @TransactionDate = '2025-01-08'
-- =====================================================
