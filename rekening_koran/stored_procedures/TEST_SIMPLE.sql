-- Simple isolated test

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 1: Direct call to SP_MASTER_FindBTP_Batch';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON1 NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "TransactionDate": "08/10/2025", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE"}
]';

EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @JSON1;

PRINT '';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 2: Call via SP_MASTER_FindBTP_Batch_ToStaging';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON2 NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "TransactionDate": "08/10/2025", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE"}
]';

EXEC SP_MASTER_FindBTP_Batch_ToStaging 
    @TransactionsJSON = @JSON2,
    @BatchID = 'TEST_SIMPLE',
    @UploadedBy = 'test@test.com';

PRINT '';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'If TEST 1 works but TEST 2 fails:';
PRINT '  → SP_MASTER_FindBTP_Batch_ToStaging needs to be redeployed!';
PRINT '═══════════════════════════════════════════════════════════════════════';

