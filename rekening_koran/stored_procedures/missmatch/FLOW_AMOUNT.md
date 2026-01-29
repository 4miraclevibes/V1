# Flow Amount: Dari HTML/TXT ke Database

## Overview

Diagram flow Amount dari file source sampai tersimpan di BTP_REVIEW:

```
┌─────────────────────────────────────────────────────────────────┐
│                    1. SOURCE FILE                                │
├─────────────────────────────────────────────────────────────────┤
│  BCA HTML                          │  RPT TXT                   │
│  - Amount dalam kolom "Jumlah"     │  - Amount setelah "IDR"   │
│  - Format: "1,500,000.00 CR"       │  - Format: "1,500,000.00" │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    2. CONVERTER (parser.js)                      │
├─────────────────────────────────────────────────────────────────┤
│  BCAStatementParser.parseTransactions()                         │
│  - Line 106-113: Parse amount string                            │
│  - Line 125: Amount: parseFloat(cleanAmount) || 0               │
│  - Line 127: TransactionType: isCredit ? 'CR' : 'DB'            │
│                                                                  │
│  RPTStatementParser.parseTransactions()                         │
│  - Line 300-301: Parse amount after "IDR"                       │
│  - Line 330: amount: amountValue                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    3. JSON OUTPUT                                │
├─────────────────────────────────────────────────────────────────┤
│  getTransactionsForStoredProcedure()                            │
│                                                                  │
│  BCA Format:                        RPT Format:                 │
│  {                                  {                           │
│    "TransactionID": 1,               "transaction_id": 1,      │
│    "TransactionDate": "08/10/24",    "transaction_date": "...",│
│    "Description": "...",             "description": "...",     │
│    "Amount": 1500000.00,             "amount": 1500000.00,     │
│    "TransactionType": "CR"           "transaction_type": "CR"  │
│  }                                  }                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    4. STORED PROCEDURE                           │
├─────────────────────────────────────────────────────────────────┤
│  SP_MASTER_FindBTP_SaveToReview(_v2)                            │
│                                                                  │
│  OPENJSON parsing:                                               │
│  - AmountValue DECIMAL(18,2) '$.Amount'                         │
│  - AmountValueLower DECIMAL(18,2) '$.amount'                    │
│  - TransactionTypeInput NVARCHAR(10) '$.TransactionType'        │
│  - TransactionTypeLower NVARCHAR(10) '$.transaction_type'       │
│                                                                  │
│  COALESCE:                                                       │
│  - COALESCE(AmountValue, AmountValueLower) AS Amount            │
│  - COALESCE(TransactionTypeInput, TransactionTypeLower)         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    5. BTP_REVIEW TABLE                           │
├─────────────────────────────────────────────────────────────────┤
│  INSERT INTO BTP_REVIEW (..., Amount, TransactionType, ...)     │
│                                                                  │
│  Columns:                                                        │
│  - [Amount] DECIMAL(18,2) NULL                                  │
│  - [TransactionType] NVARCHAR(2) NULL                           │
└─────────────────────────────────────────────────────────────────┘
```

## Checklist Verifikasi

### 1. Converter Output
Pastikan JSON dari converter memiliki Amount:

```javascript
// Di browser console setelah upload file
console.log(parsedData.transactions[0].Amount);
console.log(parsedData.transactions[0].TransactionType);
```

### 2. Copy for Stored Procedure
Pastikan output "Copy for Stored Procedure" include Amount:

```json
{
  "TransactionID": 1,
  "Amount": 1500000.00,
  "TransactionType": "CR"
}
```

### 3. Database
Jalankan query untuk verifikasi:

```sql
SELECT TOP 10 
    TransactionID, 
    Amount, 
    TransactionType 
FROM BTP_REVIEW 
WHERE BatchID = 'YOUR_BATCH_ID';
```

## Troubleshooting

### Amount NULL di database

1. **Cek JSON output dari converter**
   - Pastikan Amount ada di JSON
   - Pastikan format number benar (tidak ada string)

2. **Cek SP parsing**
   - Jalankan SP dengan @Debug = 1
   - Lihat "AMOUNT STATISTICS FROM JSON"

3. **Cek kolom table**
   - Jalankan ALTER_BTP_REVIEW_AddAmount.sql

### TransactionType NULL

1. **BCA**: Cek apakah amount string mengandung "CR" atau "DB"
2. **RPT**: TransactionType di-derive dari amount (positive = CR, negative = DB)
