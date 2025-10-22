-- Debug ToStaging SP structure

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Checking SP_MASTER_FindBTP_Batch_ToStaging structure...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- Check SP definition length
SELECT 
    name,
    modify_date,
    LEN(OBJECT_DEFINITION(object_id)) as DefinitionLength
FROM sys.procedures
WHERE name = 'SP_MASTER_FindBTP_Batch_ToStaging';

-- Check if #Results table has correct structure
PRINT '';
PRINT 'Expected #Results columns (18 total):';
PRINT '  1. TransactionID INT';
PRINT '  2. TransactionDate NVARCHAR(50)';
PRINT '  3. Description NVARCHAR(MAX)';
PRINT '  4. CustomerName NVARCHAR(200)';
PRINT '  5. BTP NVARCHAR(50)';
PRINT '  6. MatchPercentage DECIMAL(5,2)';
PRINT '  7. MatchCount INT';
PRINT '  8. TotalTransactions INT';
PRINT '  9. LastLineNumber INT';
PRINT ' 10. TotalBTPOptions INT';
PRINT ' 11. OptionNumber INT';
PRINT ' 12. BestFlag NVARCHAR(10)';
PRINT ' 13. LatestFlag NVARCHAR(10)';
PRINT ' 14. Label NVARCHAR(50)';
PRINT ' 15. Status NVARCHAR(20)';
PRINT ' 16. Message NVARCHAR(500)';
PRINT ' 17. BankType NVARCHAR(50)';
PRINT ' 18. ProcessedAt DATETIME';
PRINT '';

-- Extract #Results definition from SP
DECLARE @SPDef NVARCHAR(MAX);
SELECT @SPDef = OBJECT_DEFINITION(object_id)
FROM sys.procedures
WHERE name = 'SP_MASTER_FindBTP_Batch_ToStaging';

-- Find CREATE TABLE #Results
DECLARE @StartPos INT = CHARINDEX('CREATE TABLE #Results', @SPDef);
DECLARE @EndPos INT = CHARINDEX(');', @SPDef, @StartPos) + 2;
DECLARE @TableDef NVARCHAR(MAX) = SUBSTRING(@SPDef, @StartPos, @EndPos - @StartPos);

PRINT 'Actual #Results definition in ToStaging SP:';
PRINT @TableDef;
PRINT '';

-- Count columns
DECLARE @ColCount INT = (LEN(@TableDef) - LEN(REPLACE(@TableDef, ',', '')));
PRINT 'Column count (approximate): ' + CAST(@ColCount AS VARCHAR);

