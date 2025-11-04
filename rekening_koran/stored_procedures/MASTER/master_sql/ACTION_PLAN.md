# 📋 ACTION PLAN: Fix Category Fallback Issue

## 🎯 Goal
Agar data master dengan `category = 'NEW'` bisa ditemukan oleh SP bank-specific.

---

## ⚡ Quick Fix (Prioritas Tinggi)

### Step 1: Fix 3 SP Utama yang dipakai di `SP_MASTER_FindBTP_SaveToReview`

SP ini yang paling penting karena langsung dipakai di SP_MASTER:

#### ✅ 1.1 Fix SP_TRSF_FindBTP_Batch
**File**: `rekening_koran/stored_procedures/TRSF/SP_TRSF_FindBTP_Batch.sql`

**Cari** (sekitar baris 165):
```sql
WHERE m.category = 'TRSF'
    AND UPPER(m.customer_name) = UPPER(@CustomerName);
```

**Ganti dengan**:
```sql
WHERE (m.category = 'TRSF' OR m.category = 'NEW')
    AND UPPER(m.customer_name) = UPPER(@CustomerName);
```

**Cari** (sekitar baris 185):
```sql
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE m.category = 'TRSF'
    AND UPPER(m.customer_name) = UPPER(@CustomerName);
```

**Ganti dengan**:
```sql
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE (m.category = 'TRSF' OR m.category = 'NEW')
    AND UPPER(m.customer_name) = UPPER(@CustomerName)
ORDER BY 
    CASE WHEN m.category = 'TRSF' THEN 1 ELSE 2 END,
    m.match_percentage DESC,
    m.total_transactions DESC,
    m.last_line_number DESC;
```

**Setelah ubah**: Jalankan file SQL ini untuk recreate SP.

---

#### ✅ 1.2 Fix SP_BIFAST_FindBTP_Batch
**File**: `rekening_koran/stored_procedures/BIFAST/SP_BIFAST_FindBTP_Batch.sql`

**Cari dan ganti** (sama seperti TRSF, tapi `'TRSF'` jadi `'BIFAST'`):

**Baris ~165**:
```sql
-- BEFORE:
WHERE m.category = 'BIFAST'

-- AFTER:
WHERE (m.category = 'BIFAST' OR m.category = 'NEW')
```

**Baris ~185**:
```sql
-- BEFORE:
WHERE m.category = 'BIFAST'

-- AFTER:
WHERE (m.category = 'BIFAST' OR m.category = 'NEW')
ORDER BY 
    CASE WHEN m.category = 'BIFAST' THEN 1 ELSE 2 END,
    m.match_percentage DESC,
    m.total_transactions DESC,
    m.last_line_number DESC;
```

**Setelah ubah**: Jalankan file SQL ini untuk recreate SP.

---

#### ✅ 1.3 Fix SP_MANDIRI_FindBTP_Batch
**File**: `rekening_koran/stored_procedures/MANDIRI/SP_MANDIRI_FindBTP_Batch.sql`

**Cari dan ganti** (sama seperti TRSF, tapi `'TRSF'` jadi `'MANDIRI'`):

**Cari semua**:
```sql
WHERE m.category = 'MANDIRI'
```

**Ganti dengan**:
```sql
WHERE (m.category = 'MANDIRI' OR m.category = 'NEW')
```

**Dan tambahkan ORDER BY**:
```sql
ORDER BY 
    CASE WHEN m.category = 'MANDIRI' THEN 1 ELSE 2 END,
    m.match_percentage DESC,
    m.total_transactions DESC,
    m.last_line_number DESC;
```

**Setelah ubah**: Jalankan file SQL ini untuk recreate SP.

---

## 🧪 Step 2: Test

Setelah fix 3 SP di atas, test dengan:

```sql
-- Test dengan data category = 'NEW'
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": 1,
        "transaction_date": "01/01/2025",
        "description": "TRSF E-BANKING CR 12345 VICTORY RETAILINDO"
    }
]';

-- Pastikan VICTORY RETAILINDO ada di category = 'NEW'
SELECT * FROM MASTER_CUSTOMER_BTP_PATTERN 
WHERE customer_name = 'VICTORY RETAILINDO';

-- Test SP
EXEC SP_TRSF_FindBTP_Batch @InputJSON = @JSON;

-- Expected: Harus bisa menemukan BTP meskipun category = 'NEW'
```

---

## 📝 Step 3: Fix SP Lainnya (Optional - Jika diperlukan)

Jika ada transaksi dari bank lain (BNI, BRI, CIMB, dll) yang perlu match dengan data `category = 'NEW'`, maka fix juga SP-nya.

**Daftar lengkap**: Lihat di `FIX_CATEGORY_FALLBACK.md`

**Pattern fix sama untuk semua**:
1. Cari: `WHERE m.category = '[BANK_NAME]'`
2. Ganti: `WHERE (m.category = '[BANK_NAME]' OR m.category = 'NEW')`
3. Tambahkan ORDER BY dengan priority

---

## ✅ Checklist

- [ ] Fix SP_TRSF_FindBTP_Batch ✅
- [ ] Fix SP_BIFAST_FindBTP_Batch ✅
- [ ] Fix SP_MANDIRI_FindBTP_Batch ✅
- [ ] Test dengan data category = 'NEW'
- [ ] Verify SP_MASTER_FindBTP_SaveToReview bisa menemukan data 'NEW'
- [ ] (Optional) Fix SP bank lainnya jika diperlukan

---

## 🎉 Setelah Fix

Setelah fix selesai, `SP_MASTER_FindBTP_SaveToReview` akan bisa menemukan:
1. ✅ Data dengan `category = 'TRSF'/'BIFAST'/'MANDIRI'` (prioritas utama)
2. ✅ Data dengan `category = 'NEW'` (fallback)

**Prioritas tetap terjaga**: Data bank-specific tetap di-ranking lebih tinggi daripada data 'NEW'.

---

## ❓ Need Help?

Jika ada pertanyaan atau error saat fix, cek:
1. `FIX_CATEGORY_FALLBACK.md` - Dokumentasi lengkap
2. `fix_category_fallback_TRSF.sql` - Contoh referensi
