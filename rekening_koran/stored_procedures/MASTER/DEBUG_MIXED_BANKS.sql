-- Debug SP_MASTER_FindBTP_Batch with mixed bank types
-- Test combinations to find which bank causes issues when mixed

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 1: TRSF + BIFAST (2 banks)';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON1 NVARCHAR(MAX) = N'[
    {"TransactionID": 1, "TransactionDate": "01/10/2024", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"},
    {"TransactionID": 2, "TransactionDate": "02/10/2024", "Description": "BI-FAST CR TRANSFER DR 032 PT Kerry Ingredien"}
]';

BEGIN TRY
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON1;
    PRINT '✅ TEST 1 works!';
END TRY
BEGIN CATCH
    PRINT '❌ TEST 1 failed at line ' + CAST(ERROR_LINE() AS VARCHAR) + ': ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 2: TRSF + MANDIRI (2 banks)';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON2 NVARCHAR(MAX) = N'[
    {"TransactionID": 1, "TransactionDate": "01/10/2024", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"},
    {"TransactionID": 3, "TransactionDate": "03/10/2024", "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI RDPRLLG081025019"}
]';

BEGIN TRY
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON2;
    PRINT '✅ TEST 2 works!';
END TRY
BEGIN CATCH
    PRINT '❌ TEST 2 failed at line ' + CAST(ERROR_LINE() AS VARCHAR) + ': ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 3: TRSF + BNI (2 banks)';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON3 NVARCHAR(MAX) = N'[
    {"TransactionID": 1, "TransactionDate": "01/10/2024", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"},
    {"TransactionID": 4, "TransactionDate": "04/10/2024", "Description": "KR OTOMATIS LLG-BNI PT SEJIWA COFFEE RDPRLLG081025067"}
]';

BEGIN TRY
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON3;
    PRINT '✅ TEST 3 works!';
END TRY
BEGIN CATCH
    PRINT '❌ TEST 3 failed at line ' + CAST(ERROR_LINE() AS VARCHAR) + ': ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 4: ALL 4 BANKS TOGETHER';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON4 NVARCHAR(MAX) = N'[
    {"TransactionID": 1, "TransactionDate": "01/10/2024", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"},
    {"TransactionID": 2, "TransactionDate": "02/10/2024", "Description": "BI-FAST CR TRANSFER DR 032 PT Kerry Ingredien"},
    {"TransactionID": 3, "TransactionDate": "03/10/2024", "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI RDPRLLG081025019"},
    {"TransactionID": 4, "TransactionDate": "04/10/2024", "Description": "KR OTOMATIS LLG-BNI PT SEJIWA COFFEE RDPRLLG081025067"}
]';

BEGIN TRY
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON4;
    PRINT '✅ TEST 4 works! (ALL 4 BANKS)';
END TRY
BEGIN CATCH
    PRINT '❌ TEST 4 failed at line ' + CAST(ERROR_LINE() AS VARCHAR) + ': ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'DONE! Analysis:';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'If TEST 1-3 work but TEST 4 fails:';
PRINT '  → Problem with processing multiple banks simultaneously';
PRINT '  → Issue with @AllResults aggregation';
PRINT '';
PRINT 'If specific TEST fails:';
PRINT '  → That bank combination has column mismatch';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

