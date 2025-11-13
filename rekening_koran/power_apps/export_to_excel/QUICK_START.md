# ⚡ Quick Start - Export to Excel

## 🎯 Goal

Export data dari `VW_REKENING_KORAN` ke Excel dalam **5 menit**!

---

## 🚀 5-Minute Setup

### Step 1: Create Power Automate Flow (2 menit)

1. Buka https://make.powerautomate.com/
2. **Create** → **Instant cloud flow**
3. Nama: `Export_RekeningKoran_ToExcel`
4. Trigger: **PowerApps (V2)**
5. Click **Create**

### Step 2: Add SQL Query (1 menit)

**Action:** SQL Server → **Execute a SQL query (V2)**

**Query:**
```sql
SELECT * FROM [POWERAPPS].[dbo].[VW_REKENING_KORAN] ORDER BY [id] DESC
```

### Step 3: Create CSV (1 menit)

**Action:** Data operation → **Create CSV table**

**From:** `@body('Execute_a_SQL_query_(V2)')?['ResultSets']?['Table1']`

### Step 4: Convert & Return (1 menit)

**Action:** Data operation → **Convert to Base64**

**Input:** `@body('Create_CSV_table')`

**Action:** PowerApps → **Respond to PowerApps**

**Response:**
```json
{
    "fileName": "RekeningKoran_@{formatDateTime(utcNow(), 'yyyyMMdd_HHmmss')}.csv",
    "fileContent": "@{body('Convert_to_Base64')}",
    "rowCount": "@{length(body('Execute_a_SQL_query_(V2)')?['ResultSets']?['Table1'])}"
}
```

**Done!** ✅

---

## 📱 Power Apps Integration (30 detik)

**Button OnSelect:**
```powerappsfx
Set(varResult, Export_RekeningKoran_ToExcel.Run());
Download(varResult.fileContent, varResult.fileName, "text/csv");
```

**That's it!** 🎉

---

## 🧪 Test

1. Click button di Power Apps
2. File download otomatis
3. Buka di Excel
4. Verify data ✅

---

## ❓ Troubleshooting

### File tidak download?
- Check `Download()` function syntax
- Verify fileContent tidak kosong

### Data kosong?
- Check SQL query
- Verify view `VW_REKENING_KORAN` ada data

### Error "Flow not found"?
- Pastikan flow sudah di-save
- Refresh Power Apps connections

---

**Need more details?** → Baca [README.md](./README.md)

