# Stored Procedures with Amount & Account Info Support

Folder ini berisi scripts untuk update stored procedures dan table structures.

## Perubahan Terbaru (Januari 2026)

### 1. Amount & TransactionType Support
- Amount (DECIMAL 18,2)
- TransactionType (CR/DB)

### 2. Account Info Support (BARU!)
- AccountNumber (NVARCHAR 50) - No. Rekening dari converter
- AccountName (NVARCHAR 200) - Nama Pemilik Rekening dari converter

### 3. BIFAST Date Fix
- Fix tanggal yang kebalik untuk BankType BIFAST

## File dalam Folder ini

| File | Keterangan |
|------|------------|
| `ALTER_BTP_REVIEW_AddAmount.sql` | Script ALTER table untuk Amount & TransactionType |
| `ALTER_ADD_ACCOUNT_INFO.sql` | **BARU!** Script ALTER table untuk AccountNumber & AccountName |
| `FIX_BIFAST_DATE.sql` | **BARU!** Dokumentasi fix BIFAST date issue |
| `SP_MASTER_FindBTP_SaveToReview_v2.sql` | Updated master SP dengan Amount handling |
| `VERIFY_AMOUNT.sql` | Script untuk verifikasi Amount tersimpan dengan benar |
| `TEST_AMOUNT.sql` | Test script dengan berbagai format JSON |
| `SAMPLE_JSON_WITH_AMOUNT.json` | Contoh JSON dengan Amount |
| `FLOW_AMOUNT.md` | Diagram flow Amount dari HTML ke Database |

## Cara Pakai

### Step 1: Update Table Structures
```sql
-- Jalankan di SSMS:
EXEC ALTER_BTP_REVIEW_AddAmount.sql
EXEC ALTER_ADD_ACCOUNT_INFO.sql
```

### Step 2: Update SPs (sudah dilakukan di MASTER folder)
SP yang sudah di-update:
- `SP_MASTER_FindBTP_SaveToReview.sql` - Parameter baru: @AccountNumber, @AccountName
- `SP_MASTER_ApproveToFinal.sql` - Include AccountNumber & AccountName ke MP_REKENING_KORAN

## JSON Format dari Converter

```json
[
  {
    "TransactionID": 1,
    "TransactionDate": "08/10/2024",
    "Description": "TRSF E-BANKING...",
    "Amount": 1500000.00,
    "TransactionType": "CR"
  }
]
```

## Flow Amount

```
HTML/TXT File
    ↓
converter.html (parser.js)
    ↓
JSON dengan Amount & TransactionType
    ↓
SP_MASTER_FindBTP_SaveToReview
    ↓
BTP_REVIEW table (Amount & TransactionType tersimpan)
```
