-- Check REKENING_KORAN_STAGING table structure

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Checking REKENING_KORAN_STAGING table structure...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

-- Get column list
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'REKENING_KORAN_STAGING'
  AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION;

-- Count columns
DECLARE @ColCount INT;
SELECT @ColCount = COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'REKENING_KORAN_STAGING'
  AND TABLE_SCHEMA = 'dbo';

PRINT '';
PRINT 'Total columns in REKENING_KORAN_STAGING: ' + CAST(@ColCount AS VARCHAR);
PRINT '';

-- Expected: 22 columns
PRINT 'Expected columns (22 total):';
PRINT '  1. ID (BIGINT, PK, IDENTITY)';
PRINT '  2. BatchID';
PRINT '  3. UploadedBy';
PRINT '  4. UploadedAt';
PRINT '  5. TransactionID';
PRINT '  6. TransactionDate';
PRINT '  7. Description';
PRINT '  8. CustomerName';
PRINT '  9. BTP';
PRINT ' 10. MatchPercentage';
PRINT ' 11. MatchCount';
PRINT ' 12. TotalTransactions';
PRINT ' 13. LastLineNumber';
PRINT ' 14. TotalBTPOptions';
PRINT ' 15. OptionNumber';
PRINT ' 16. BestFlag';
PRINT ' 17. LatestFlag';
PRINT ' 18. Label';
PRINT ' 19. Status';
PRINT ' 20. Message';
PRINT ' 21. BankType';
PRINT ' 22. ProcessedAt';

PRINT '';
PRINT 'If column count does not match, table needs to be recreated!';
PRINT '';

-- Show table creation date
SELECT 
    name AS TableName,
    create_date AS CreateDate,
    modify_date AS ModifyDate
FROM sys.tables
WHERE name = 'REKENING_KORAN_STAGING';

