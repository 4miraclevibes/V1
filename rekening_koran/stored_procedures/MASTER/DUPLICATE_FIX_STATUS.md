# Duplicate Entry Fix Status - SP_MASTER_FindBTP_SaveToReview

## 📋 Overview

Dokumentasi ini mencatat bank-bank yang sudah diatasi masalah duplikat entry-nya di `SP_MASTER_FindBTP_SaveToReview`. Masalah duplikat terjadi ketika satu transaction menghasilkan multiple rows di `BTP_REVIEW` table karena ada beberapa BTP options dengan `OptionNumber = 1` untuk transaction yang sama.

## ✅ Banks dengan Duplicate Fix (Menggunakan ROW_NUMBER())

**SEMUA BANK SUDAH DIPERBAIKI!** ✅

Semua bank sudah menggunakan `ROW_NUMBER()` dengan `PARTITION BY TransactionID` untuk memastikan hanya **1 row per transaction** yang disimpan ke `BTP_REVIEW`.

### Special Logic Banks:

### 1. **TRSF** ✅
- **Status**: Fixed
- **Line**: ~332
- **Implementation**:
  ```sql
  FROM (
      SELECT *,
          ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
      FROM #TRSF_Temp
      WHERE (OptionNumber IS NULL OR OptionNumber = 1)
  ) AS temp
  INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'TRSF'
  WHERE temp.rn = 1;
  ```
- **Notes**: 
  - Fixed untuk mengatasi duplikat yang terjadi karena partial matching menghasilkan multiple matches dengan `OptionNumber = 1`
  - Menggunakan smart partial matching (exact match → partial match → word-by-word matching)

### 2. **BIFAST** ✅
- **Status**: Fixed
- **Line**: ~400
- **Implementation**: Same pattern as TRSF
- **Notes**: Special Logic bank - Fixed untuk mengatasi duplikat

### 3. **MANDIRI** ✅
- **Status**: Fixed
- **Line**: ~461
- **Implementation**: Same pattern as TRSF
- **Notes**: Special Logic bank - Fixed untuk mengatasi duplikat

### 4. **VA (RPT)** ✅
- **Status**: Fixed
- **Line**: ~646
- **Implementation**: Same pattern as TRSF
- **Notes**: Special Logic bank (Virtual Account) - Fixed untuk mengatasi duplikat

### GROUP 1 Banks (Array[3] + Array[4]):

### 5. **BNI** ✅
- **Status**: Fixed
- **Line**: ~707
- **Implementation**:
  ```sql
  FROM (
      SELECT *,
          ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
      FROM #BNI_Temp
      WHERE (OptionNumber IS NULL OR OptionNumber = 1)
  ) AS temp
  INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'BNI'
  WHERE temp.rn = 1;
  ```
- **Notes**: 
  - Fixed untuk mengatasi duplikat yang terjadi pada GROUP 1 banks
  - Pattern: Array[3] + Array[4] extraction

### 6. **BTPN** ✅
- **Status**: Fixed
- **Line**: ~774
- **Implementation**: Same pattern as BNI
- **Notes**: GROUP 1 bank - Fixed untuk mengatasi duplikat

### 7. **BRI** ✅
- **Status**: Fixed
- **Line**: ~835
- **Implementation**: Same pattern as BNI
- **Notes**: GROUP 1 bank - Fixed untuk mengatasi duplikat

### 8. **MEGA** ✅
- **Status**: Fixed
- **Line**: ~894
- **Implementation**: Same pattern as BNI
- **Notes**: GROUP 1 bank - Fixed untuk mengatasi duplikat

### 9. **PERMATA** ✅
- **Status**: Fixed
- **Line**: ~953
- **Implementation**: Same pattern as BNI
- **Notes**: GROUP 1 bank - Fixed untuk mengatasi duplikat

### 10. **DANAMON** ✅
- **Status**: Fixed
- **Line**: ~1012
- **Implementation**: Same pattern as BNI
- **Notes**: GROUP 1 bank - Fixed untuk mengatasi duplikat

### 11. **CITIBANK** ✅
- **Status**: Fixed
- **Line**: ~1071
- **Implementation**: Same pattern as BNI
- **Notes**: GROUP 1 bank - Fixed untuk mengatasi duplikat

### 12. **SINARMAS** ✅
- **Status**: Fixed
- **Line**: ~1130
- **Implementation**: Same pattern as BNI
- **Notes**: GROUP 1 bank - Fixed untuk mengatasi duplikat

### GROUP 2 Banks (Array[4] + Array[5]):

### 13. **GREENFIEL** ✅
- **Status**: Fixed
- **Line**: ~527
- **Implementation**:
  ```sql
  FROM (
      SELECT *,
          ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
      FROM #GREENFIEL_Temp
      WHERE (OptionNumber IS NULL OR OptionNumber = 1)
  ) AS temp
  INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'GREENFIEL'
  WHERE temp.rn = 1;
  ```
- **Notes**: 
  - Fixed untuk mengatasi duplikat yang terjadi karena multiple BTP options dengan `OptionNumber = 1`
  - Pattern: Extract BTP dari array terakhir yang dimulai "23..." atau "20..."

### 14. **CIMB** ✅
- **Status**: Fixed
- **Line**: ~1193
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

### 15. **MAYBANK** ✅
- **Status**: Fixed
- **Line**: ~1252
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

### 16. **HSBC** ✅
- **Status**: Fixed
- **Line**: ~1311
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

### 17. **UOB** ✅
- **Status**: Fixed
- **Line**: ~1370
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

### 18. **MUAMALAT** ✅
- **Status**: Fixed
- **Line**: ~1429
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

### 19. **OCBC** ✅
- **Status**: Fixed
- **Line**: ~1488
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

### 20. **DBS** ✅
- **Status**: Fixed
- **Line**: ~1547
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

### 21. **CAPITAL** ✅
- **Status**: Fixed
- **Line**: ~1606
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

### 22. **WOORI** ✅
- **Status**: Fixed
- **Line**: ~1665
- **Implementation**: Same pattern as GREENFIEL
- **Notes**: GROUP 2 bank - Fixed untuk mengatasi duplikat

---

## 📊 Summary

| Status | Count | Banks |
|--------|-------|-------|
| ✅ Fixed | **22** | **ALL BANKS** - TRSF, BIFAST, MANDIRI, VA, GREENFIEL, BNI, BTPN, BRI, MEGA, PERMATA, DANAMON, CITIBANK, SINARMAS, CIMB, MAYBANK, HSBC, UOB, MUAMALAT, OCBC, DBS, CAPITAL, WOORI |
| ⚠️ Not Fixed | **0** | None - All banks sudah diperbaiki! |

---

## 📝 Notes

- **ROW_NUMBER() Logic**: Memastikan hanya 1 row per `TransactionID` dengan memilih yang terbaik berdasarkan:
  1. `OptionNumber` (prioritas terendah = terbaik)
  2. `MatchPercentage DESC` (tertinggi = terbaik)
  3. `LastLineNumber DESC` (tertinggi = terbaru)

- **Filter OptionNumber**: Tetap menggunakan `WHERE (OptionNumber IS NULL OR OptionNumber = 1)` untuk hanya mengambil BEST option dari bank-specific SP, kemudian `ROW_NUMBER()` memastikan hanya 1 row yang diambil jika ada multiple rows dengan `OptionNumber = 1`.

- **Testing**: Setelah fix, test dengan sample data yang sebelumnya menghasilkan duplikat untuk memastikan masalah sudah teratasi.

---

## 🎉 Status Update

**Semua 22 bank sudah diperbaiki!** Semua bank sekarang menggunakan `ROW_NUMBER()` dengan `PARTITION BY TransactionID` untuk memastikan hanya 1 row per transaction yang disimpan ke `BTP_REVIEW`.

### Implementation Pattern (Sama untuk Semua Bank):

```sql
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
    FROM #BANKNAME_Temp
    WHERE (OptionNumber IS NULL OR OptionNumber = 1)
) AS temp
INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'BANKNAME'
WHERE temp.rn = 1;
```

### Fix Date: 2025-01-XX
**All banks fixed in single batch update**

---

**Last Updated**: 2025-01-XX  
**Maintained By**: Development Team

