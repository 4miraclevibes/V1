# ✅ DEPLOY CHECKLIST - Category Fallback Fix

## 📋 Files yang Perlu Di-Execute

Setelah semua file SQL sudah di-edit, jalankan setiap file ini di SQL Server Management Studio (SSMS) untuk recreate stored procedures.

---

## 🚀 GROUP 1 (8 files)

### Array[3] + Array[4] Extraction Logic
1. ✅ `rekening_koran/stored_procedures/GROUP1/SP_BNI_FindBTP_Batch.sql`
2. ✅ `rekening_koran/stored_procedures/GROUP1/SP_BTPN_FindBTP_Batch.sql`
3. ✅ `rekening_koran/stored_procedures/GROUP1/SP_BRI_FindBTP_Batch.sql`
4. ✅ `rekening_koran/stored_procedures/GROUP1/SP_MEGA_FindBTP_Batch.sql`
5. ✅ `rekening_koran/stored_procedures/GROUP1/SP_PERMATA_FindBTP_Batch.sql`
6. ✅ `rekening_koran/stored_procedures/GROUP1/SP_DANAMON_FindBTP_Batch.sql`
7. ✅ `rekening_koran/stored_procedures/GROUP1/SP_CITIBANK_FindBTP_Batch.sql`
8. ✅ `rekening_koran/stored_procedures/GROUP1/SP_SINARMAS_FindBTP_Batch.sql`

---

## 🚀 GROUP 2 (9 files)

### Array[4] + Array[5] Extraction Logic
1. ✅ `rekening_koran/stored_procedures/GROUP2/SP_CIMB_FindBTP_Batch.sql`
2. ✅ `rekening_koran/stored_procedures/GROUP2/SP_MAYBANK_FindBTP_Batch.sql`
3. ✅ `rekening_koran/stored_procedures/GROUP2/SP_HSBC_FindBTP_Batch.sql`
4. ✅ `rekening_koran/stored_procedures/GROUP2/SP_UOB_FindBTP_Batch.sql`
5. ✅ `rekening_koran/stored_procedures/GROUP2/SP_MUAMALAT_FindBTP_Batch.sql`
6. ✅ `rekening_koran/stored_procedures/GROUP2/SP_OCBC_FindBTP_Batch.sql`
7. ✅ `rekening_koran/stored_procedures/GROUP2/SP_DBS_FindBTP_Batch.sql`
8. ✅ `rekening_koran/stored_procedures/GROUP2/SP_CAPITAL_FindBTP_Batch.sql`
9. ✅ `rekening_koran/stored_procedures/GROUP2/SP_WOORI_FindBTP_Batch.sql`

---

## 🚀 GROUP 3 (3 files)

### Special Logic
1. ✅ `rekening_koran/stored_procedures/TRSF/SP_TRSF_FindBTP_Batch.sql`
2. ✅ `rekening_koran/stored_procedures/BIFAST/SP_BIFAST_FindBTP_Batch.sql`
3. ✅ `rekening_koran/stored_procedures/MANDIRI/SP_MANDIRI_FindBTP_Batch.sql`

---

## 📝 Cara Deploy

### Option 1: Execute Satu per Satu (Recommended)
1. Buka **SQL Server Management Studio (SSMS)**
2. Connect ke database **POWERAPPS**
3. Untuk setiap file di atas:
   - Buka file SQL di SSMS
   - Klik **Execute** (F5) atau klik tombol ▶️
   - Pastikan muncul pesan "Command(s) completed successfully"
   - ✅ Centang checklist di atas

### Option 2: Execute Semua Sekaligus
Jika ingin execute semua sekaligus:

```sql
-- Buat script gabungan (atau gunakan DEPLOY_ALL_IN_ONE.sql jika tersedia)
-- Jalankan semua SP files dalam 1 query window
```

---

## ✅ Checklist Status

### GROUP 1
- [ ] SP_BNI_FindBTP_Batch
- [ ] SP_BTPN_FindBTP_Batch
- [ ] SP_BRI_FindBTP_Batch
- [ ] SP_MEGA_FindBTP_Batch
- [ ] SP_PERMATA_FindBTP_Batch
- [ ] SP_DANAMON_FindBTP_Batch
- [ ] SP_CITIBANK_FindBTP_Batch
- [ ] SP_SINARMAS_FindBTP_Batch

### GROUP 2
- [ ] SP_CIMB_FindBTP_Batch
- [ ] SP_MAYBANK_FindBTP_Batch
- [ ] SP_HSBC_FindBTP_Batch
- [ ] SP_UOB_FindBTP_Batch
- [ ] SP_MUAMALAT_FindBTP_Batch
- [ ] SP_OCBC_FindBTP_Batch
- [ ] SP_DBS_FindBTP_Batch
- [ ] SP_CAPITAL_FindBTP_Batch
- [ ] SP_WOORI_FindBTP_Batch

### GROUP 3
- [ ] SP_TRSF_FindBTP_Batch
- [ ] SP_BIFAST_FindBTP_Batch
- [ ] SP_MANDIRI_FindBTP_Batch

---

## 🧪 Testing Setelah Deploy

Setelah semua SP di-deploy, test dengan:

```sql
-- Test dengan data category = 'NEW'
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "TransactionID": 1,
        "Description": "KR OTOMATIS LLG-BNI PT VICTORY RETAILINDO"
    }
]';

-- Pastikan customer ada di category = 'NEW'
SELECT * FROM MASTER_CUSTOMER_BTP_PATTERN 
WHERE customer_name = 'PT VICTORY RETAILINDO' AND category = 'NEW';

-- Test SP
EXEC SP_BNI_FindBTP_Batch @TransactionsJSON = @JSON;

-- Expected: Harus bisa menemukan BTP meskipun category = 'NEW'
```

---

## ⚠️ Troubleshooting

### Error: "There is already an object named 'SP_[BANK]_FindBTP_Batch'"
**Solusi:** File SQL sudah menggunakan `CREATE OR ALTER PROCEDURE`, jadi tidak perlu drop manual. Jika masih error, cek apakah ada syntax error di file.

### Error: "Incorrect syntax near..."
**Solusi:** 
1. Pastikan semua file sudah di-save dengan perubahan yang benar
2. Cek apakah ada typo di CASE statement
3. Pastikan semua kurung tutup sudah benar

### SP tidak update
**Solusi:**
1. Pastikan database yang digunakan adalah **POWERAPPS**
2. Cek execution result message
3. Verify dengan: `SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.SP_[BANK]_FindBTP_Batch'))`

---

## 🎉 Setelah Semua Deployed

Setelah semua SP sudah di-deploy, semua bank SP akan:
- ✅ Mencari data `category = '[BANK]'` (prioritas 1)
- ✅ Fallback ke data `category = 'NEW'` jika tidak ditemukan (prioritas 2)

**Total SP yang perlu di-deploy: 20 files**
