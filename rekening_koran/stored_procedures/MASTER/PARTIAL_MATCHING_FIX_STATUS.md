# Partial Matching Fix Status - Smart Matching untuk 3+ Kata

## 📋 Overview

Dokumentasi ini mencatat bank-bank yang sudah diatasi masalah partial matching-nya. Masalah terjadi ketika extracted customer name memiliki lebih banyak kata daripada yang ada di master data, atau sebaliknya.

**Contoh Masalah:**
- **Extracted Name**: "MITRA BELANJA ANDA GL PIK" (5 kata)
- **Master Data**: "MITRA BELANJA ANDA" (3 kata)
- **Hasil**: Tidak ketemu karena exact match tidak cocok

**Solusi**: Menggunakan smart partial matching dengan prioritas:
1. Exact match (prioritas tertinggi)
2. Master name contained in extracted name (paling umum)
3. Extracted name contained in master name
4. Word-by-word matching (minimal 2 kata match)

---

## ✅ Banks dengan Partial Matching Fix

### 1. **TRSF** ✅
- **Status**: Fixed
- **File**: `TRSF/SP_TRSF_FindBTP_Batch.sql`
- **Line**: ~176-206
- **Implementation**:
  ```sql
  WHERE (m.category = 'TRSF' OR m.category = 'NEW')
      AND (
          -- Priority 1: Exact match
          UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName)))
          OR
          -- Priority 2: Master name contained in extracted name
          UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%'
          OR
          -- Priority 3: Extracted name contained in master name
          UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%'
          OR
          -- Priority 4: Word-by-word matching (at least 2 words match)
          (
              SELECT COUNT(*)
              FROM (
                  SELECT value AS word
                  FROM STRING_SPLIT(UPPER(LTRIM(RTRIM(m.customer_name))), ' ')
                  WHERE LEN(LTRIM(RTRIM(value))) >= 3
              ) AS master_words
              WHERE UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + LTRIM(RTRIM(master_words.word)) + '%'
          ) >= 2
      );
  ```
- **Notes**: 
  - Fixed untuk mengatasi masalah seperti "BSD FRANKI SEPTINUS" vs "FRANKI SEPTINUS"
  - Menggunakan smart partial matching dengan 4 level prioritas
  - Extraction logic hanya mengambil ALL CAPS words (skip mixed case seperti "Domu")

### 2. **MANDIRI** ✅
- **Status**: Fixed
- **File**: `MANDIRI/SP_MANDIRI_FindBTP_Batch.sql`
- **Line**: ~144-206
- **Implementation**: Same pattern as TRSF
- **Notes**: 
  - Fixed untuk mengatasi masalah seperti "MITRA BELANJA ANDA GL PIK" vs "MITRA BELANJA ANDA"
  - Pattern: Array[3] + Array[4] extraction (smart PT/CV)
  - Menggunakan smart partial matching dengan 4 level prioritas

---

## ⚠️ Banks Belum Diperbaiki (Masih Menggunakan Exact Match)

Bank-bank berikut masih menggunakan exact match `UPPER(m.customer_name) = UPPER(@CustomerName)` tanpa partial matching. Jika terjadi masalah seperti di atas, perlu ditambahkan partial matching seperti TRSF dan MANDIRI:

### Special Logic Banks:
- **BIFAST** ⚠️
- **VA (RPT)** ⚠️ (mungkin tidak perlu karena BTP langsung dari input)

### GROUP 1 Banks (Array[3] + Array[4]):
- **BNI** ⚠️
- **BTPN** ⚠️
- **BRI** ⚠️
- **MEGA** ⚠️
- **PERMATA** ⚠️
- **DANAMON** ⚠️
- **CITIBANK** ⚠️
- **SINARMAS** ⚠️

### GROUP 2 Banks (Array[4] + Array[5]):
- **GREENFIEL** ⚠️ (mungkin tidak perlu karena menggunakan BTP matching, bukan customer name matching)
- **CIMB** ⚠️
- **MAYBANK** ⚠️
- **HSBC** ⚠️
- **UOB** ⚠️
- **MUAMALAT** ⚠️
- **OCBC** ⚠️
- **DBS** ⚠️
- **CAPITAL** ⚠️
- **WOORI** ⚠️

---

## 🔧 Cara Memperbaiki Bank yang Belum Diperbaiki

Jika bank tertentu mengalami masalah partial matching (extracted name lebih panjang dari master atau sebaliknya), ikuti pola yang sama seperti TRSF dan MANDIRI:

### Template Fix:

**Sebelum (Exact Match Only):**
```sql
SELECT @TotalOptions = COUNT(DISTINCT btp)
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE (m.category = 'BANKNAME' OR m.category = 'NEW')
    AND UPPER(m.customer_name) = UPPER(@CustomerName);
```

**Sesudah (Smart Partial Matching):**
```sql
-- Normalize customer name first
IF @CustomerName IS NOT NULL
BEGIN
    SET @CustomerName = LTRIM(RTRIM(@CustomerName));
    WHILE CHARINDEX('  ', @CustomerName) > 0
    BEGIN
        SET @CustomerName = REPLACE(@CustomerName, '  ', ' ');
    END
END

SELECT @TotalOptions = COUNT(DISTINCT btp)
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE (m.category = 'BANKNAME' OR m.category = 'NEW')
    AND (
        -- Priority 1: Exact match
        UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName)))
        OR
        -- Priority 2: Master name contained in extracted name
        UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%'
        OR
        -- Priority 3: Extracted name contained in master name
        UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%'
        OR
        -- Priority 4: Word-by-word matching (at least 2 words match)
        (
            SELECT COUNT(*)
            FROM (
                SELECT value AS word
                FROM STRING_SPLIT(UPPER(LTRIM(RTRIM(m.customer_name))), ' ')
                WHERE LEN(LTRIM(RTRIM(value))) >= 3
            ) AS master_words
            WHERE UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + LTRIM(RTRIM(master_words.word)) + '%'
        ) >= 2
    );
```

### Langkah-langkah:
1. Tambahkan normalisasi customer name (LTRIM/RTRIM dan replace multiple spaces)
2. Ganti exact match dengan smart partial matching (4 level prioritas)
3. Update juga bagian INSERT INTO @TempOptions dengan ranking yang sama
4. Test dengan sample data yang memiliki masalah partial matching

---

## 📊 Summary

| Status | Count | Banks |
|--------|-------|-------|
| ✅ Fixed | 2 | TRSF, MANDIRI |
| ⚠️ Not Fixed | 20 | BIFAST, VA, BNI, BTPN, BRI, MEGA, PERMATA, DANAMON, CITIBANK, SINARMAS, GREENFIEL, CIMB, MAYBANK, HSBC, UOB, MUAMALAT, OCBC, DBS, CAPITAL, WOORI |

---

## 📝 Notes

### Partial Matching Logic:

1. **Priority 1: Exact Match**
   - `"MITRA BELANJA ANDA" = "MITRA BELANJA ANDA"` ✅

2. **Priority 2: Master in Extracted** (Paling Umum)
   - Master: `"MITRA BELANJA ANDA"`
   - Extracted: `"MITRA BELANJA ANDA GL PIK"`
   - Match: `"MITRA BELANJA ANDA GL PIK" LIKE '%MITRA BELANJA ANDA%'` ✅

3. **Priority 3: Extracted in Master**
   - Master: `"PT MITRA BELANJA ANDA"`
   - Extracted: `"MITRA BELANJA ANDA"`
   - Match: `"PT MITRA BELANJA ANDA" LIKE '%MITRA BELANJA ANDA%'` ✅

4. **Priority 4: Word-by-Word** (Fallback)
   - Master: `"MITRA BELANJA ANDA"` → words: ["MITRA", "BELANJA", "ANDA"]
   - Extracted: `"MITRA BELANJA ANDA GL PIK"`
   - Match: Minimal 2 words match (MITRA, BELANJA, ANDA semua match) ✅

### Ranking Order:
- Exact match diurutkan pertama
- Partial match diurutkan berdasarkan kategori (BANKNAME > NEW), lalu MatchPercentage, TotalTransactions, LastLineNumber

### Testing:
Setelah fix, test dengan sample data yang memiliki masalah partial matching untuk memastikan masalah sudah teratasi.

---

## 🎯 Use Cases

### Case 1: Extracted lebih panjang dari Master
- **Extracted**: "MITRA BELANJA ANDA GL PIK"
- **Master**: "MITRA BELANJA ANDA"
- **Result**: Match via Priority 2 ✅

### Case 2: Master lebih panjang dari Extracted
- **Extracted**: "MITRA BELANJA ANDA"
- **Master**: "PT MITRA BELANJA ANDA"
- **Result**: Match via Priority 3 ✅

### Case 3: Partial word match
- **Extracted**: "BSD FRANKI SEPTINUS"
- **Master**: "FRANKI SEPTINUS"
- **Result**: Match via Priority 2 ✅

### Case 4: Word-by-word fallback
- **Extracted**: "MITRA BELANJA ANDA GL PIK"
- **Master**: "MITRA BELANJA"
- **Result**: Match via Priority 4 (2 words match: MITRA, BELANJA) ✅

---

**Last Updated**: 2025-01-XX  
**Maintained By**: Development Team

