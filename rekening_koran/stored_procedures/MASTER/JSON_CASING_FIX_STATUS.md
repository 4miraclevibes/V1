# JSON Casing Fix Status - PascalCase vs lowercase

## 📋 Overview

Dokumentasi ini mencatat bank-bank yang sudah diatasi masalah JSON casing-nya. Masalah terjadi ketika `SP_MASTER_FindBTP_SaveToReview` mengirim JSON dengan PascalCase (`TransactionID`, `TransactionDate`, `Description`), tetapi sub-stored procedure mengharapkan lowercase (`transaction_id`, `transaction_date`, `description`).

**Contoh Masalah:**
- **SP_MASTER mengirim**: `{"TransactionID": 1, "TransactionDate": "13/11/2025", "Description": "..."}`
- **Sub-SP mengharapkan**: `{"transaction_id": 1, "transaction_date": "13/11/2025", "description": "..."}`
- **Hasil**: Sub-SP tidak bisa parse JSON, BTP tidak ditemukan

**Solusi**: Menggunakan alias lowercase di `SELECT ... FOR JSON PATH`:
```sql
SELECT 
    TransactionID AS transaction_id,
    TransactionDate AS transaction_date,
    Description AS description
FROM @Transactions WHERE BankType = 'BANK_NAME' FOR JSON PATH
```

---

## ✅ Banks dengan JSON Casing Fix

### 1. **TRSF** ✅
- **Status**: Fixed
- **File**: `MASTER/SP_MASTER_FindBTP_SaveToReview.sql`
- **Line**: ~283-286
- **Implementation**:
  ```sql
  SELECT @TRSF_JSON = (
      SELECT 
          TransactionID AS transaction_id,
          TransactionDate AS transaction_date,
          Description AS description
      FROM @Transactions WHERE BankType = 'TRSF' FOR JSON PATH
  );
  ```
- **Fixed Date**: 2025-01-XX
- **Notes**: Fixed setelah issue dengan TRSF_SAMPLE.json tidak menemukan BTP

### 2. **MANDIRI** ✅
- **Status**: Fixed
- **File**: `MASTER/SP_MASTER_FindBTP_SaveToReview.sql`
- **Line**: ~419-424
- **Implementation**:
  ```sql
  SELECT @MANDIRI_JSON = (
      SELECT 
          TransactionID AS transaction_id,
          TransactionDate AS transaction_date,
          Description AS description
      FROM @Transactions WHERE BankType = 'MANDIRI' FOR JSON PATH
  );
  ```
- **Fixed Date**: 2025-01-XX
- **Notes**: Fixed setelah issue dengan MANDIRI_SAMPLE.json tidak menemukan BTP meskipun Test_SP_MANDIRI_Debug.sql berhasil

### 3. **GREENFIEL** ✅
- **Status**: Fixed
- **File**: `MASTER/SP_MASTER_FindBTP_SaveToReview.sql`
- **Line**: ~490-493
- **Implementation**:
  ```sql
  SELECT @GREENFIEL_JSON = (
      SELECT 
          TransactionID AS transaction_id,
          TransactionDate AS transaction_date,
          Description AS description
      FROM @Transactions WHERE BankType = 'GREENFIEL' FOR JSON PATH
  );
  ```
- **Fixed Date**: 2025-01-XX
- **Notes**: Fixed setelah issue dengan GREENFIEL tidak processing dengan benar

### 4. **BIFAST** ✅
- **Status**: Fixed
- **File**: `MASTER/SP_MASTER_FindBTP_SaveToReview.sql`
- **Line**: ~354-358
- **Implementation**:
  ```sql
  SELECT @BIFAST_JSON = (
      SELECT 
          TransactionID AS transaction_id,
          TransactionDate AS transaction_date,
          Description AS description
      FROM @Transactions WHERE BankType = 'BIFAST' FOR JSON PATH
  );
  ```
- **Fixed Date**: 2025-01-XX
- **Notes**: SP_BIFAST_FindBTP_Batch mengharapkan lowercase (dari codebase_search)

---

## ⏳ Banks Belum Diperbaiki

### Group 2: Standard LLG Pattern
- **BNI** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_BNI_FindBTP_Batch
  - **Line**: ~681-682
- **BTPN** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_BTPN_FindBTP_Batch
  - **Line**: ~745-746
- **BRI** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_BRI_FindBTP_Batch
  - **Line**: ~809-810
- **MEGA** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_MEGA_FindBTP_Batch
  - **Line**: ~875-876
- **PERMATA** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_PERMATA_FindBTP_Batch
  - **Line**: ~939-940
- **DANAMON** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_DANAMON_FindBTP_Batch
  - **Line**: ~1003-1004
- **CITIBANK** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_CITIBANK_FindBTP_Batch
  - **Line**: ~1067-1068
- **SINARMAS** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_SINARMAS_FindBTP_Batch
  - **Line**: ~1131-1132

### Group 3: Foreign Banks
- **CIMB** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_CIMB_FindBTP_Batch
  - **Line**: ~1199-1200
- **MAYBANK** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_MAYBANK_FindBTP_Batch
  - **Line**: ~1263-1264
- **HSBC** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_HSBC_FindBTP_Batch
  - **Line**: ~1327-1328
- **UOB** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_UOB_FindBTP_Batch
  - **Line**: ~1391-1392
- **MUAMALAT** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_MUAMALAT_FindBTP_Batch
  - **Line**: ~1455-1456
- **OCBC** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_OCBC_FindBTP_Batch
  - **Line**: ~1519-1520
- **DBS** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_DBS_FindBTP_Batch
  - **Line**: ~1583-1584
- **CAPITAL** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_CAPITAL_FindBTP_Batch
  - **Line**: ~1647-1648
- **WOORI** ❌
  - **Current**: PascalCase
  - **Expected**: Perlu verifikasi format yang diharapkan SP_WOORI_FindBTP_Batch
  - **Line**: ~1711-1712

### Group 4: Virtual Account
- **VA (RPT)** ✅
  - **Status**: Already correct (uses different format)
  - **Line**: ~571-574
  - **Notes**: VA menggunakan format berbeda dengan field tambahan (location, keterangan1, keterangan2)

---

## 🔍 Cara Verifikasi Format JSON yang Diharapkan

Untuk memverifikasi format JSON yang diharapkan oleh sub-stored procedure:

1. Buka file sub-SP (contoh: `BIFAST/SP_BIFAST_FindBTP_Batch.sql`)
2. Cari bagian `OPENJSON` dengan `WITH` clause:
   ```sql
   FROM OPENJSON(@InputJSON)
   WITH (
       TransactionID INT '$.transaction_id',  -- ← Perhatikan casing di sini
       TransactionDate NVARCHAR(50) '$.transaction_date',
       Description NVARCHAR(MAX) '$.description'
   );
   ```
3. Jika menggunakan `$.transaction_id` (lowercase), berarti perlu alias lowercase
4. Jika menggunakan `$.TransactionID` (PascalCase), berarti sudah benar

---

## 📝 Template Fix

Untuk memperbaiki bank yang belum di-fix, gunakan template berikut:

```sql
-- SEBELUM (PascalCase):
DECLARE @BANK_JSON NVARCHAR(MAX);
SELECT @BANK_JSON = (
    SELECT TransactionID, TransactionDate, Description
    FROM @Transactions WHERE BankType = 'BANK_NAME' FOR JSON PATH
);

-- SESUDAH (lowercase alias):
DECLARE @BANK_JSON NVARCHAR(MAX);
SELECT @BANK_JSON = (
    SELECT 
        TransactionID AS transaction_id,
        TransactionDate AS transaction_date,
        Description AS description
    FROM @Transactions WHERE BankType = 'BANK_NAME' FOR JSON PATH
);
```

---

## 📊 Summary

| Status | Count | Banks |
|--------|-------|-------|
| ✅ Fixed | 4 | TRSF, MANDIRI, GREENFIEL, BIFAST |
| ❌ Pending | 18 | BNI, BTPN, BRI, MEGA, PERMATA, DANAMON, CITIBANK, SINARMAS, CIMB, MAYBANK, HSBC, UOB, MUAMALAT, OCBC, DBS, CAPITAL, WOORI |
| ✅ N/A | 1 | VA (RPT) - format berbeda |

**Total Banks**: 23 (20 banks + 1 RPT + 2 special logic)
**Fixed**: 4/22 (18.2%)
**Pending**: 18/22 (81.8%)

---

## 🔄 Update History

- **2025-01-XX**: Created documentation
- **2025-01-XX**: Fixed TRSF JSON casing
- **2025-01-XX**: Fixed GREENFIEL JSON casing
- **2025-01-XX**: Fixed MANDIRI JSON casing
- **2025-01-XX**: Fixed BIFAST JSON casing

---

## ⚠️ Notes

- Semua bank yang sudah di-fix menggunakan format lowercase untuk konsistensi
- VA (RPT) menggunakan format berbeda karena memiliki field tambahan
- Perlu verifikasi format untuk semua bank yang belum di-fix sebelum melakukan perubahan
- Setelah fix, pastikan untuk test dengan sample data untuk memastikan BTP ditemukan

