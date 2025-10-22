-- Test SP_MASTER_FindBTP_Batch WITHOUT capturing to temp table
-- Just execute directly

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST: Execute SP_MASTER_FindBTP_Batch with 4 banks (NO temp table)';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON NVARCHAR(MAX) = N'[
    {"TransactionID": 1, "TransactionDate": "01/10/2024", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"},
    {"TransactionID": 2, "TransactionDate": "02/10/2024", "Description": "BI-FAST CR TRANSFER DR 032 PT Kerry Ingredien"},
    {"TransactionID": 3, "TransactionDate": "03/10/2024", "Description": "KR OTOMATIS LLG-MANDIRI SUMBER ALFARIA TRI RDPRLLG081025019"},
    {"TransactionID": 4, "TransactionDate": "04/10/2024", "Description": "KR OTOMATIS LLG-BNI PT SEJIWA COFFEE RDPRLLG081025067"}
]';

-- Execute directly WITHOUT temp table
EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'If this works: Problem is with INSERT INTO #TempResults';
PRINT 'If this fails: Problem is with SP_MASTER_FindBTP_Batch itself';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

