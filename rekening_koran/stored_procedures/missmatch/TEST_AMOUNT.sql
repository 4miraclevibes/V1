-- =====================================================
-- TEST_AMOUNT.sql
-- =====================================================
-- Purpose: Test SP_MASTER dengan Amount dari JSON
-- =====================================================

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 1: JSON dengan Amount (format dari BCA converter)';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON1 NVARCHAR(MAX) = N'[
    {
        "TransactionID": 1,
        "TransactionDate": "08/10/24",
        "Description": "TRSF E-BANKING CR 0809/FTSCY/WS95051 50104163963 PT MEGASARI MAKMUR",
        "Amount": 1500000.00,
        "TransactionType": "CR"
    },
    {
        "TransactionID": 2,
        "TransactionDate": "08/10/24",
        "Description": "BI-FAST CR 081019010110220 ARIFAH SEPTYANA",
        "Amount": 2500000.50,
        "TransactionType": "CR"
    },
    {
        "TransactionID": 3,
        "TransactionDate": "09/10/24",
        "Description": "DB OTOMATIS BIAYA ADM",
        "Amount": 15000.00,
        "TransactionType": "DB"
    }
]';

EXEC SP_MASTER_FindBTP_SaveToReview_v2
    @TransactionsJSON = @JSON1,
    @Debug = 1;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 2: JSON dengan lowercase keys (format RPT/VA)';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON2 NVARCHAR(MAX) = N'[
    {
        "transaction_id": 1,
        "transaction_date": "08/10/24",
        "description": "RPT: TOKO ABC | Transfer | Payment",
        "amount": 3500000.00,
        "transaction_type": "CR",
        "btp": "23123456",
        "customer_name": "TOKO ABC",
        "bank_type": "VA"
    },
    {
        "transaction_id": 2,
        "transaction_date": "08/10/24",
        "description": "RPT: CV MAJU JAYA | Transfer | Invoice",
        "amount": 1750000.00,
        "transaction_type": "CR",
        "btp": "23654321",
        "customer_name": "CV MAJU JAYA",
        "bank_type": "VA"
    }
]';

EXEC SP_MASTER_FindBTP_SaveToReview_v2
    @TransactionsJSON = @JSON2,
    @Debug = 1;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST 3: JSON tanpa Amount (backward compatibility)';
PRINT '═══════════════════════════════════════════════════════════════════════';

DECLARE @JSON3 NVARCHAR(MAX) = N'[
    {
        "TransactionID": 1,
        "TransactionDate": "08/10/24",
        "Description": "TRSF E-BANKING CR 0809/FTSCY/WS95051 50104163963 PT MEGASARI MAKMUR"
    },
    {
        "TransactionID": 2,
        "TransactionDate": "08/10/24",
        "Description": "BI-FAST CR 081019010110220 ARIFAH SEPTYANA"
    }
]';

EXEC SP_MASTER_FindBTP_SaveToReview_v2
    @TransactionsJSON = @JSON3,
    @Debug = 1;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ All tests completed!';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
