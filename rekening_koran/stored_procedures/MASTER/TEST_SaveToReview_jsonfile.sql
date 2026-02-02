-- ═══════════════════════════════════════════════════════════════════════════
-- TEST: SP_MASTER_FindBTP_SaveToReview
-- Data dari testingSaveToReview.json (23 transaksi)
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

SET NOCOUNT ON;

DECLARE @JSON NVARCHAR(MAX) = N'[
    {
      "TransactionID": 1,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/ATSCY/WS95051 REF:25123000901182 Payment sushitei Payment sushitei SUSHI-TEI INDONESI",
      "Amount": 20626020,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 2,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 188853979.00 MENARA NUSANTARA P",
      "Amount": 188853979,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 3,
      "TransactionDate": "02/01/2026",
      "Description": "KR OTOMATIS LLG-CIMB NIAGA PT.PUJI SURYA INDA GF",
      "Amount": 249555342,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 4,
      "TransactionDate": "02/01/2026",
      "Description": "KR OTOMATIS LLG-CIMB NIAGA PT.PUJI SURYA INDA GF",
      "Amount": 166165145,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 5,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 159243264.00 No.5222531340,5222 531339, 5222531338 KURNIA MAJU PERKAS",
      "Amount": 159243264,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 6,
      "TransactionDate": "02/01/2026",
      "Description": "KR OTOMATIS LLG-DANAMON PULAUBARU JAYA`PT PBJ WESEL 1208 PCM 0053061777",
      "Amount": 872714425,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 7,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 358077968.00 PEMBAYARAN PT GDI SURYA ANUGERAH SEN",
      "Amount": 358077968,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 8,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95271 455520.00 NATHASIA I TOBING",
      "Amount": 455520,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 9,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95271 407991.00 Inv 9 des MELIZA MILANOVA",
      "Amount": 407991,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 10,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95271 227760.00 tea time city reso rt k002000198271 SUMARNI",
      "Amount": 227760,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 11,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95011 683280.00 N9654675 ANCILLA BETARIA TI",
      "Amount": 683280,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 12,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95031 694904.00 resepnenek SITI HANIFATIN SUW",
      "Amount": 694904,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 13,
      "TransactionDate": "02/01/2026",
      "Description": "SETORAN PEMBAYARAN INV",
      "Amount": 534232646,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 14,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 455520.00 susu 1210650245 19/12 CAHAYA BOGA NUSANT",
      "Amount": 455520,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 15,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 683280.00 susu 22/12 1210653766 CAHAYA BOGA NUSANT",
      "Amount": 683280,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 16,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 683280.00 susu 22/12 1210654722 CAHAYA BOGA NUSANT",
      "Amount": 683280,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 17,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 455520.00 K002000196171 BUMI BERKAH RASA P",
      "Amount": 455520,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 18,
      "TransactionDate": "02/01/2026",
      "Description": "KR OTOMATIS RTGS-PT. BANK DANA BDINIDJA/007715 WIRA EKA PERSADATA wira eka PCM005306 1777",
      "Amount": 1993529799,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 19,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 231634.00 KONGMI N9571838 KONGMI KOREA ALAMI",
      "Amount": 231634,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 20,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95031 227760.00 N9620600 22122025 ROSALIA PUTRI HERM",
      "Amount": 227760,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 21,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 1138800.00 K002000196252 24/12 PROSPERA SEJAHTERA",
      "Amount": 1138800,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 22,
      "TransactionDate": "02/01/2026",
      "Description": "TRSF E-BANKING CR 0201/FTSCY/WS95051 463269.00 N9530079 DOUGHZEN BOGA KULI",
      "Amount": 463269,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    },
    {
      "TransactionID": 23,
      "TransactionDate": "02/01/2026",
      "Description": "BI-FAST CR TRANSFER DR 008 JEDO ABADI LESTARI",
      "Amount": 680780,
      "TransactionType": "CR",
      "accountNumber": "0053061777",
      "accountName": "GREENFIELDS DAIRY I PT"
    }
]';

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🧪 TEST: SP_MASTER_FindBTP_SaveToReview (23 transaksi)';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

EXEC [dbo].[SP_MASTER_FindBTP_SaveToReview]
    @TransactionsJSON = @JSON,
    @BatchID = NULL,
    @UploadedBy = 'test_save_to_review@company.com';

PRINT '';
PRINT '─────────────────────────────────────────────────────────────────────';
PRINT '📊 Verifikasi: Data terakhir di BTP_REVIEW';
PRINT '─────────────────────────────────────────────────────────────────────';

SELECT TOP 25
    ID,
    BatchID,
    TransactionID,
    LEFT(Description, 50) + '...' AS Description,
    CustomerName,
    BTP,
    Status,
    BankType,
    Amount,
    AccountNumber,
    AccountName,
    IsApproved
FROM dbo.BTP_REVIEW
ORDER BY ID DESC;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ TEST SELESAI';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
