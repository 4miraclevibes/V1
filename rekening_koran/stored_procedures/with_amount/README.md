# Stored Procedures with Amount & Account Info Support

Folder ini berisi scripts untuk update stored procedures dan table structures.

## Perubahan Terbaru (Januari 2026)

### 1. Amount & TransactionType Support
- Amount (DECIMAL 18,2)
- TransactionType (CR/DB)

### 2. Account Info Support
- AccountNumber (NVARCHAR 50) - No. Rekening dari converter
- AccountName (NVARCHAR 200) - Nama Pemilik Rekening dari converter

### 3. btn & approved_by di MP_REKENING_KORAN
- **btn** (NVARCHAR 255) - Diisi dari **BTP_REVIEW.CustomerName** (tidak ada kolom baru di BTP_REVIEW)
- **approved_by** (NVARCHAR 255) - Diisi dari **BTP_REVIEW.UploadedBy** (user yang upload/approve)

### 4. BIFAST Date Fix
- Fix tanggal yang kebalik untuk BankType BIFAST

## File dalam Folder ini

| File | Keterangan |
|------|------------|
| `ALTER_BTP_REVIEW_AddAmount.sql` | Script ALTER table untuk Amount & TransactionType |
| `ALTER_ADD_ACCOUNT_INFO.sql` | Script ALTER table untuk AccountNumber & AccountName |
| `ALTER_ADD_BATCH_ISJURNAL.sql` | Script ALTER MP_REKENING_KORAN untuk BatchID & isJurnal |
| `ALTER_ADD_BTN_APPROVED_BY.sql` | Script ALTER MP_REKENING_KORAN untuk btn (dari CustomerName) & approved_by (dari UploadedBy) |
| `FIX_BIFAST_DATE.sql` | Dokumentasi fix BIFAST date issue |
| `SP_MASTER_FindBTP_SaveToReview_v2.sql` | Updated master SP dengan Amount handling |
| `VERIFY_AMOUNT.sql` | Script untuk verifikasi Amount tersimpan dengan benar |
| `TEST_AMOUNT.sql` | Test script dengan berbagai format JSON |
| `SAMPLE_JSON_WITH_AMOUNT.json` | Contoh JSON dengan Amount |
| `FLOW_AMOUNT.md` | Diagram flow Amount dari HTML ke Database |

## Cara Pakai

### Step 1: Update Table Structures
```sql
-- Jalankan di SSMS (urutan bebas):
-- ALTER_BTP_REVIEW_AddAmount.sql
-- ALTER_ADD_ACCOUNT_INFO.sql
-- ALTER_ADD_BATCH_ISJURNAL.sql
-- ALTER_ADD_BTN_APPROVED_BY.sql
```

### Step 2: Update SPs (sudah dilakukan di MASTER folder)
SP yang sudah di-update:
- `SP_MASTER_FindBTP_SaveToReview.sql` - Parameter baru: @AccountNumber, @AccountName
- `SP_MASTER_ApproveToFinal.sql` - Include AccountNumber, AccountName, BatchID, **btn** (dari CustomerName), **approved_by** (dari UploadedBy) ke MP_REKENING_KORAN

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
