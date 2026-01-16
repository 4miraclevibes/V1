-- =====================================================
-- VERIFY_AMOUNT.sql
-- =====================================================
-- Purpose: Verifikasi Amount tersimpan dengan benar di BTP_REVIEW
-- =====================================================

USE POWERAPPS;
GO

-- 1. Cek struktur kolom
PRINT '═══════════════════════════════════════════════════════════════';
PRINT '1. STRUKTUR KOLOM Amount & TransactionType';
PRINT '═══════════════════════════════════════════════════════════════';

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'BTP_REVIEW'
AND COLUMN_NAME IN (
    'Amount',
    'TransactionType'
);
GO

-- 2. Cek data dengan Amount
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';
PRINT '2. SAMPLE DATA DENGAN AMOUNT';
PRINT '═══════════════════════════════════════════════════════════════';

SELECT TOP 20
    ID,
    BatchID,
    TransactionID,
    TransactionDate,
    LEFT(Description, 50) AS Description,
    CustomerName,
    BTP,
    Amount,
    TransactionType,
    BankType,
    Status
FROM [dbo].[BTP_REVIEW]
WHERE Amount IS NOT NULL
ORDER BY CreatedAt DESC;
GO

-- 3. Statistik Amount per BankType
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';
PRINT '3. STATISTIK AMOUNT PER BANK TYPE';
PRINT '═══════════════════════════════════════════════════════════════';

SELECT 
    BankType,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN Amount IS NOT NULL THEN 1 ELSE 0 END) AS WithAmount,
    SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END) AS WithoutAmount,
    SUM(CASE WHEN TransactionType = 'CR' THEN 1 ELSE 0 END) AS CreditCount,
    SUM(CASE WHEN TransactionType = 'DB' THEN 1 ELSE 0 END) AS DebitCount,
    FORMAT(SUM(CASE WHEN TransactionType = 'CR' THEN Amount ELSE 0 END), 'N2') AS TotalCredit,
    FORMAT(SUM(CASE WHEN TransactionType = 'DB' THEN Amount ELSE 0 END), 'N2') AS TotalDebit
FROM [dbo].[BTP_REVIEW]
GROUP BY BankType
ORDER BY BankType;
GO

-- 4. Cek data yang Amount-nya NULL
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';
PRINT '4. DATA DENGAN AMOUNT NULL (perlu investigasi)';
PRINT '═══════════════════════════════════════════════════════════════';

SELECT TOP 20
    ID,
    BatchID,
    TransactionID,
    LEFT(Description, 50) AS Description,
    BankType,
    Status,
    CreatedAt
FROM [dbo].[BTP_REVIEW]
WHERE Amount IS NULL
ORDER BY CreatedAt DESC;
GO

-- 5. Summary per Batch
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';
PRINT '5. SUMMARY PER BATCH (Recent 10)';
PRINT '═══════════════════════════════════════════════════════════════';

SELECT TOP 10
    BatchID,
    COUNT(*) AS TotalTransactions,
    SUM(CASE WHEN Amount IS NOT NULL THEN 1 ELSE 0 END) AS WithAmount,
    FORMAT(SUM(CASE WHEN TransactionType = 'CR' THEN Amount ELSE 0 END), 'N2') AS TotalCredit,
    FORMAT(SUM(CASE WHEN TransactionType = 'DB' THEN Amount ELSE 0 END), 'N2') AS TotalDebit,
    MIN(CreatedAt) AS FirstCreated
FROM [dbo].[BTP_REVIEW]
GROUP BY BatchID
ORDER BY MIN(CreatedAt) DESC;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';
PRINT '✅ VERIFY_AMOUNT.sql completed!';
PRINT '═══════════════════════════════════════════════════════════════';
GO
