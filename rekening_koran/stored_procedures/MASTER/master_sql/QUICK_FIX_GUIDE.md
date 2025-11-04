# 🚀 QUICK FIX GUIDE - Category Fallback

## TL;DR - Yang Harus Dilakukan Sekarang

### ⚡ 3 Langkah Sederhana:

1. **Buka file SP_TRSF_FindBTP_Batch.sql**
   - Cari: `WHERE m.category = 'TRSF'` (ada 2 tempat)
   - Ganti: `WHERE (m.category = 'TRSF' OR m.category = 'NEW')`
   - Simpan & jalankan file SQL untuk recreate SP

2. **Buka file SP_BIFAST_FindBTP_Batch.sql**
   - Cari: `WHERE m.category = 'BIFAST'` (ada 2 tempat)
   - Ganti: `WHERE (m.category = 'BIFAST' OR m.category = 'NEW')`
   - Simpan & jalankan file SQL untuk recreate SP

3. **Buka file SP_MANDIRI_FindBTP_Batch.sql**
   - Cari: `WHERE m.category = 'MANDIRI'` (semua tempat)
   - Ganti: `WHERE (m.category = 'MANDIRI' OR m.category = 'NEW')`
   - Simpan & jalankan file SQL untuk recreate SP

---

## 📍 Lokasi File

```
rekening_koran/stored_procedures/
├── TRSF/SP_TRSF_FindBTP_Batch.sql          ← Fix ini
├── BIFAST/SP_BIFAST_FindBTP_Batch.sql      ← Fix ini
└── MANDIRI/SP_MANDIRI_FindBTP_Batch.sql    ← Fix ini
```

---

## 🔍 Cara Cari di File

### Di setiap file, cari dengan CTRL+F:
```
WHERE m.category = '
```

### Atau cari:
```
category = 'TRSF'
category = 'BIFAST'
category = 'MANDIRI'
```

---

## ✏️ Contoh Perubahan

### Contoh untuk TRSF:

**SEBELUM** (baris ~165):
```sql
SELECT @TotalOptions = COUNT(DISTINCT btp)
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE m.category = 'TRSF'
    AND UPPER(m.customer_name) = UPPER(@CustomerName);
```

**SESUDAH**:
```sql
SELECT @TotalOptions = COUNT(DISTINCT btp)
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE (m.category = 'TRSF' OR m.category = 'NEW')
    AND UPPER(m.customer_name) = UPPER(@CustomerName);
```

**SEBELUM** (baris ~185):
```sql
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE m.category = 'TRSF'
    AND UPPER(m.customer_name) = UPPER(@CustomerName);
```

**SESUDAH**:
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

**Catatan**: Untuk baris kedua, tambahkan `ORDER BY` agar data TRSF tetap prioritas.

---

## ✅ Setelah Fix

1. **Jalankan setiap file SQL** yang sudah di-ubah untuk recreate SP
2. **Test** dengan query di `ACTION_PLAN.md` Step 2
3. **Selesai!** 🎉

---

## 🆘 Masalah?

- Pastikan syntax SQL benar (tutup kurung, koma, dll)
- Pastikan file SP di-save sebelum dijalankan
- Jika error, cek apakah SP sudah di-drop dulu sebelum create
