-- =====================================================
-- VW_BTP_REVIEW_COUNT
-- =====================================================
-- Purpose: View untuk menghitung total row BTP_REVIEW
--          Langsung dari table tanpa filter
-- Output: TotalRows, TotalCR, TotalDB
-- =====================================================

CREATE OR ALTER VIEW [dbo].[VW_BTP_REVIEW_COUNT]
AS
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN TransactionType = 'CR' THEN 1 ELSE 0 END) AS TotalCR,
    SUM(CASE WHEN TransactionType = 'DB' THEN 1 ELSE 0 END) AS TotalDB
FROM [POWERAPPS].[dbo].[BTP_REVIEW];
GO

-- =====================================================
-- Contoh penggunaan di SSMS:
-- SELECT * FROM [dbo].[VW_BTP_REVIEW_COUNT]
-- 
-- Hasil:
-- TotalRows | TotalCR | TotalDB
-- 5000      | 3000    | 2000
-- =====================================================

