# Stored Procedures with Amount Support

Folder ini berisi versi updated dari stored procedures yang memastikan **Amount** dan **TransactionType** diproses dengan benar dari JSON input sampai tersimpan di BTP_REVIEW.

## Perubahan dari Versi Sebelumnya

### 1. JSON Input Support
- Amount (DECIMAL 18,2)
- TransactionType (CR/DB)

### 2. BTP_REVIEW Table
- Kolom Amount sudah ada
- Kolom TransactionType sudah ada

### 3. SP Bank-Specific
- Tidak perlu return Amount karena Amount diambil dari JSON input original

## File dalam Folder ini

| File | Keterangan |
|------|------------|
| `ALTER_BTP_REVIEW_AddAmount.sql` | Script ALTER table jika kolom belum ada |
| `SP_MASTER_FindBTP_SaveToReview_v2.sql` | Updated master SP dengan Amount handling yang lebih baik |
| `VERIFY_AMOUNT.sql` | Script untuk verifikasi Amount tersimpan dengan benar |

## Cara Pakai

1. Jalankan `ALTER_BTP_REVIEW_AddAmount.sql` untuk memastikan kolom ada
2. Deploy `SP_MASTER_FindBTP_SaveToReview_v2.sql`
3. Test dengan `VERIFY_AMOUNT.sql`

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
