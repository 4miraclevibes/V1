-- Debug SP_MASTER_FindBTP_Batch line by line
-- Test each bank type one by one

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Testing SP_MASTER_FindBTP_Batch with TRSF only...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON_TRSF NVARCHAR(MAX) = N'[
    {"TransactionID": 1, "TransactionDate": "01/10/2024", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"}
]';

BEGIN TRY
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON_TRSF;
    PRINT '✅ TRSF works!';
END TRY
BEGIN CATCH
    PRINT '❌ TRSF failed: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Testing SP_MASTER_FindBTP_Batch with BIFAST only...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON_BIFAST NVARCHAR(MAX) = N'[
    {"TransactionID": 2, "TransactionDate": "02/10/2024", "Description": "BI-FAST CR TRANSFER DR 032 PT Kerry Ingredien"}
]';

BEGIN TRY
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON_BIFAST;
    PRINT '✅ BIFAST works!';
END TRY
BEGIN CATCH
    PRINT '❌ BIFAST failed: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Testing SP_MASTER_FindBTP_Batch with MANDIRI only...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON_MANDIRI NVARCHAR(MAX) = N'[
    {"TransactionID": 3, "TransactionDate": "03/10/2024", "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI RDPRLLG081025019"}
]';

BEGIN TRY
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON_MANDIRI;
    PRINT '✅ MANDIRI works!';
END TRY
BEGIN CATCH
    PRINT '❌ MANDIRI failed: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Testing SP_MASTER_FindBTP_Batch with BNI only...';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON_BNI NVARCHAR(MAX) = N'[
    {"TransactionID": 4, "TransactionDate": "04/10/2024", "Description": "KR OTOMATIS LLG-BNI PT SEJIWA COFFEE RDPRLLG081025067"}
]';

BEGIN TRY
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON_BNI;
    PRINT '✅ BNI works!';
END TRY
BEGIN CATCH
    PRINT '❌ BNI failed: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'DONE! Check which bank failed above.';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

