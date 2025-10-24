# 📝 BTP_REVIEW Notes Column - Auto-Population Guide

## **Overview**

Column `Notes` di table `BTP_REVIEW` **otomatis terisi** oleh `SP_MASTER_FindBTP_SaveToReview` untuk membantu finance team memahami kenapa suatu transaksi perlu direview.

---

## **📊 Notes by Status**

### **1. NO_PATTERN** 
**Meaning:** Customer name tidak bisa di-extract dari description  
**Notes:** `"Customer name tidak ditemukan di description - perlu review format extraction"`  
**Action Required:**
- Cek format description transaksi
- Mungkin perlu update extraction logic di SP bank-specific
- Atau format transaksi memang tidak standard

---

### **2. NO_MATCH**
**Meaning:** Customer name berhasil di-extract, tapi belum ada di master data  
**Notes:** `"Customer '[CustomerName]' belum ada di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN"`  
**Action Required:**
- Tambahkan customer ini ke `MASTER_CUSTOMER_BTP_PATTERN` table
- Isi BTP dan category yang sesuai
- Jalankan test lagi untuk verify

**Example:**
```
Notes: Customer "PT SEJIWA COFFEE" belum ada di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN
```

---

### **3. LOW Confidence Match**
**Meaning:** BTP ditemukan tapi match percentage < 70%  
**Notes:** `"Match confidence rendah ([MatchPercentage]%) - perlu verifikasi manual"`  
**Action Required:**
- Review apakah BTP yang di-suggest memang benar
- Kalau salah, pilih BTP yang benar secara manual
- Kalau customer name di master data typo, perbaiki master data

**Example:**
```
Notes: Match confidence rendah (45.50%) - perlu verifikasi manual
```

---

### **4. Multiple BTP Options**
**Meaning:** Ditemukan lebih dari 1 BTP untuk customer yang sama  
**Notes:** `"Ditemukan [TotalBTPOptions] opsi BTP - pilih yang paling sesuai"`  
**Action Required:**
- Review semua opsi BTP yang tersedia (lihat `OptionNumber`)
- Pilih yang paling sesuai berdasarkan context/history
- Gunakan `BestFlag` dan `LatestFlag` sebagai guidance

**Example:**
```
Notes: Ditemukan 3 opsi BTP - pilih yang paling sesuai

Row 1: BTP 2300009823, BestFlag: YES, LatestFlag: YES, Label: BEST + LATEST
Row 2: BTP 2300005555, BestFlag: , LatestFlag: , Label: 
Row 3: BTP 2300001111, BestFlag: , LatestFlag: , Label: 
```

---

### **5. EXCELLENT, GOOD, FAIR** (Single Match)
**Meaning:** BTP ditemukan dengan confidence tinggi/medium dan hanya 1 opsi  
**Notes:** `NULL` (tidak perlu notes)  
**Action Required:**
- Biasanya aman untuk di-approve langsung
- Tapi tetap bisa direview kalau diperlukan

---

## **⚠️ UNKNOWN Bank Types**

Transaksi dengan `BankType = 'UNKNOWN'` mendapat **Notes khusus** berdasarkan pattern description:

| **Description Pattern** | **Notes** | **Action** |
|------------------------|-----------|------------|
| `SETORAN%` | `"Transaksi SETORAN - tidak perlu BTP matching"` | Skip/Ignore |
| `DB OTOMATIS%` | `"Transaksi DEBIT - tidak perlu BTP matching"` | Skip/Ignore |
| `SWITCHING%` | `"Transaksi SWITCHING - cek apakah perlu ditambahkan ke pattern bank"` | Review apakah ini bank baru |
| `FLAZZ%` | `"Transaksi FLAZZ - tidak perlu BTP matching"` | Skip/Ignore |
| `KR OTOMATIS%` (tanpa keyword bank) | `"Transaksi KR OTOMATIS tanpa keyword bank spesifik - cek description untuk identifikasi bank"` | Manual review untuk identifikasi |
| **Other** | `"Format transaksi tidak dikenali - perlu review manual untuk identifikasi bank atau kategori"` | Deep investigation |

---

## **🎯 Workflow for Finance Team**

### **Step 1: Filter by Notes**
```sql
-- Prioritas tinggi: NO_MATCH (customer baru)
SELECT * FROM BTP_REVIEW 
WHERE Status = 'NO_MATCH' 
  AND IsApproved = 0
ORDER BY TransactionDate;

-- Review manual: LOW confidence
SELECT * FROM BTP_REVIEW 
WHERE Status = 'LOW' 
  AND IsApproved = 0
ORDER BY MatchPercentage ASC;

-- Multiple options: perlu pilihan
SELECT * FROM BTP_REVIEW 
WHERE TotalBTPOptions > 1 
  AND IsApproved = 0
ORDER BY TransactionID, OptionNumber;
```

### **Step 2: Take Action**
- **NO_MATCH:** Add to master data first
- **LOW:** Manual verify BTP
- **Multiple Options:** Choose the best one
- **UNKNOWN:** Categorize or skip

### **Step 3: Approve**
```sql
UPDATE BTP_REVIEW 
SET IsApproved = 1,
    ApprovedBy = 'finance@company.com',
    ApprovedAt = GETDATE(),
    Notes = Notes + ' | Approved by Finance Team'  -- Optional: append approval note
WHERE ID = [specific_id];
```

---

## **📈 Statistics Query**

```sql
-- Summary by Notes category
SELECT 
    CASE 
        WHEN Notes LIKE '%tidak ditemukan di description%' THEN 'NO_PATTERN'
        WHEN Notes LIKE '%belum ada di master data%' THEN 'NO_MATCH - New Customer'
        WHEN Notes LIKE '%Match confidence rendah%' THEN 'LOW Confidence'
        WHEN Notes LIKE '%opsi BTP%' THEN 'Multiple Options'
        WHEN BankType = 'UNKNOWN' THEN 'UNKNOWN Bank'
        WHEN Notes IS NULL THEN 'Good Match'
        ELSE 'Other'
    END AS Category,
    COUNT(*) AS [Count],
    AVG(MatchPercentage) AS AvgMatchPct
FROM BTP_REVIEW
WHERE BatchID = 'BATCH_20251024_095440'  -- Replace with your BatchID
GROUP BY 
    CASE 
        WHEN Notes LIKE '%tidak ditemukan di description%' THEN 'NO_PATTERN'
        WHEN Notes LIKE '%belum ada di master data%' THEN 'NO_MATCH - New Customer'
        WHEN Notes LIKE '%Match confidence rendah%' THEN 'LOW Confidence'
        WHEN Notes LIKE '%opsi BTP%' THEN 'Multiple Options'
        WHEN BankType = 'UNKNOWN' THEN 'UNKNOWN Bank'
        WHEN Notes IS NULL THEN 'Good Match'
        ELSE 'Other'
    END
ORDER BY [Count] DESC;
```

---

## **✅ Benefits**

1. **Clear Guidance:** Finance team tahu exactly kenapa suatu transaksi perlu direview
2. **Faster Processing:** Tidak perlu investigation manual untuk tiap transaksi
3. **Data Quality:** Membantu identify gaps di master data
4. **Audit Trail:** Notes bisa di-append untuk track approval history
5. **Prioritization:** Bisa filter dan sort berdasarkan severity

---

**Last Updated:** 2025-10-24  
**Related Files:**
- `SP_MASTER_FindBTP_SaveToReview.sql`
- `BTP_REVIEW` table
- `TEST_200_ROWS.sql`

