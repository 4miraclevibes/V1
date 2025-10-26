-- ═══════════════════════════════════════════════════════════════════════════════
-- CEK HASIL FLOW TEST (10 Transactions)
-- ═══════════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

-- 1️⃣ CEK 10 ROWS TERAKHIR
PRINT '═══════════════════════════════════════════════════════════════════════════════';
PRINT '1️⃣  CHECK LAST 10 ROWS IN BTP_REVIEW';
PRINT '═══════════════════════════════════════════════════════════════════════════════';

SELECT TOP 10
    ID,
    BatchID,
    TransactionID,
    TransactionDate,
    LEFT(Description, 50) AS Description,
    CustomerName,
    BTP,
    MatchPercentage,
    Status,
    BankType,
    LEFT(Notes, 50) AS Notes,
    CreatedAt
FROM [dbo].[BTP_REVIEW]
ORDER BY CreatedAt DESC;

PRINT '';
PRINT '';

-- 2️⃣ CEK BATCH TERAKHIR (dari test)
PRINT '═══════════════════════════════════════════════════════════════════════════════';
PRINT '2️⃣  CHECK LAST BATCH DETAILS';
PRINT '═══════════════════════════════════════════════════════════════════════════════';

SELECT TOP 1
    BatchID,
    COUNT(*) AS TotalRows,
    MIN(CreatedAt) AS FirstInsert,
    MAX(CreatedAt) AS LastInsert,
    UploadedBy
FROM [dbo].[BTP_REVIEW]
GROUP BY BatchID, UploadedBy
ORDER BY MIN(CreatedAt) DESC;

PRINT '';
PRINT '';

-- 3️⃣ CEK STATUS BREAKDOWN
PRINT '═══════════════════════════════════════════════════════════════════════════════';
PRINT '3️⃣  STATUS BREAKDOWN (Last Batch)';
PRINT '═══════════════════════════════════════════════════════════════════════════════';

DECLARE @LastBatchID NVARCHAR(50);

SELECT TOP 1 @LastBatchID = BatchID
FROM [dbo].[BTP_REVIEW]
ORDER BY CreatedAt DESC;

SELECT
    Status,
    BankType,
    COUNT(*) AS Count,
    AVG(MatchPercentage) AS AvgMatchPercentage
FROM [dbo].[BTP_REVIEW]
WHERE BatchID = @LastBatchID
GROUP BY Status, BankType
ORDER BY Count DESC;

PRINT '';
PRINT '';

-- 4️⃣ CEK SPECIFIC TRANSACTIONS (TransactionID 1-10)
PRINT '═══════════════════════════════════════════════════════════════════════════════';
PRINT '4️⃣  CHECK TEST TRANSACTIONS (TransactionID 1-10)';
PRINT '═══════════════════════════════════════════════════════════════════════════════';

SELECT
    TransactionID,
    LEFT(Description, 60) AS Description,
    BankType,
    Status,
    CustomerName,
    BTP,
    MatchPercentage,
    LEFT(Notes, 80) AS Notes
FROM [dbo].[BTP_REVIEW]
WHERE BatchID = @LastBatchID
  AND TransactionID BETWEEN 1 AND 10
ORDER BY TransactionID;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════════════';
PRINT '✅ DONE! Check results above.';
PRINT '═══════════════════════════════════════════════════════════════════════════════';

