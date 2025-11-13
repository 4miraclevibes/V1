# 🔄 Power Automate Flow Steps - Export to Excel

## Flow Name: `Export_RekeningKoran_ToExcel`

---

## 📋 Flow Overview

**Trigger:** PowerApps (V2)  
**Purpose:** Query database view dan return Excel file
**Output:** CSV file (Base64 encoded)

---

## 🔧 Step-by-Step Configuration

### STEP 1: Trigger - PowerApps (V2)

**Note:** Trigger sudah otomatis dibuat saat membuat flow dengan trigger "PowerApps (V2)"!

**Cara menambahkan Input Parameters (Optional):**

1. **Klik box trigger "PowerApps (V2)"** di canvas flow
2. Di panel kanan, scroll ke bawah ke bagian **"Inputs"**
3. Klik **"Add an input"** → Pilih **"Text"**
4. Ulangi untuk setiap parameter:
   - `StartDate` (Text, Optional) - untuk filter tanggal mulai
   - `EndDate` (Text, Optional) - untuk filter tanggal akhir  
   - `BTP` (Text, Optional) - untuk filter BTP

**Atau skip dulu** jika mau export semua data tanpa filter (bisa ditambah nanti).

**Setelah trigger siap, klik "+ New step" untuk lanjut ke STEP 2.**

---

### STEP 2: Execute SQL Query

**⚠️ IMPORTANT: On-Premises Gateway Limitation**

Jika menggunakan **on-premises gateway**, action "Execute a SQL query (V2)" dengan Query Type "Text" **TIDAK DIDUKUNG**.

**Solusi: Gunakan Stored Procedure!**

---

#### **Option A: Execute Stored Procedure (RECOMMENDED untuk On-Prem)**

**Action:** SQL Server → **Execute stored procedure (V2)**

**Configuration:**

1. **Server name:** Use connection settings (auto-filled)
2. **Database name:** Use connection settings (auto-filled)
3. **Procedure name:** `[dbo].[SP_EXPORT_REKENING_KORAN]`

**Parameters:**
- `@StartDate` = `@{triggerBody()?['StartDate']}` (atau kosongkan jika tidak digunakan)
- `@EndDate` = `@{triggerBody()?['EndDate']}` (atau kosongkan jika tidak digunakan)
- `@BTP` = `@{triggerBody()?['BTP']}` (atau kosongkan jika tidak digunakan)

**Note:** Buat stored procedure dulu dengan script di `SP_EXPORT_REKENING_KORAN.sql`

---

#### **Option B: Execute SQL Query (Hanya untuk Azure SQL Cloud)**

**Action:** SQL Server → **Execute a SQL query (V2)**

**Query Type:** Text

**Query Text:**
```sql
SELECT 
    [id],
    [trx_date],
    [created_at],
    [updated_at],
    [credit],
    [btp],
    [desc]
FROM [POWERAPPS].[dbo].[VW_REKENING_KORAN]
ORDER BY [id] DESC
```

**Note:** 
- Hanya bekerja untuk **Azure SQL (cloud)**, bukan on-premises!
- Jika ada filter parameter, gunakan stored procedure (Option A)

---

### STEP 3: Parse JSON Results

**Action:** Data operation → **Parse JSON**

**Content:**
```
@body('Execute_stored_procedure_(V2)')?['ResultSets']?['Table1']
```

**Note:** 
- Ganti `Execute_a_SQL_query_(V2)` dengan nama action stored procedure yang kamu buat
- Biasanya: `Execute_stored_procedure_(V2)` atau sesuai nama action di flow kamu

**Schema:** (Click "Generate from sample" dan paste sample output)

**Or manual schema:**
```json
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "id": {
                "type": "number"
            },
            "trx_date": {
                "type": "string"
            },
            "created_at": {
                "type": "string"
            },
            "updated_at": {
                "type": "string"
            },
            "btp": {
                "type": "string"
            },
            "desc": {
                "type": "string"
            },
            "Amount": {
                "type": "number"
            },
            "TransactionType": {
                "type": "string"
            },
            "BankType": {
                "type": "string"
            }
        },
        "required": []
    }
}
```

**⚠️ IMPORTANT:** 
- Field `credit` **TIDAK DIIKUTSERTAKAN** (excluded)
- Field baru: `Amount`, `TransactionType`, `BankType` ditambahkan
- `Amount` bisa `number` atau `string` tergantung database (jika error, ubah ke `"string"`)
- Jika masih error, gunakan "Generate from sample" dengan copy output dari stored procedure

---

### STEP 4: Create CSV Table

**Action:** Data operation → **Create CSV table**

**From:**
```
@body('Parse_JSON')
```

**Columns:** Auto-detect (atau manual specify)

**Delimiter:** Comma (`,`)

**Encoding:** UTF-8

---

### STEP 5: Convert to Base64

**⚠️ Jika "Convert to Base64" tidak tersedia, gunakan Compose dengan expression!**

**Action:** Data operation → **Compose**

**Input:**
```
base64(body('Create_CSV_table'))
```

**Penjelasan:**
- `base64()` adalah built-in function di Power Automate
- Langsung convert output dari Create CSV table ke Base64
- Tidak perlu action terpisah "Convert to Base64"

**Alternative (jika Compose juga tidak ada):**
- Langsung gunakan expression `base64()` di STEP 6 (Respond to PowerApps)

---

### STEP 6: Initialize Variables (Optional)

**Action:** Initialize variable

**Name:** `varRowCount`  
**Type:** Integer  
**Value:**
```
length(body('Parse_JSON'))
```

**Action:** Initialize variable

**Name:** `varFileName`  
**Type:** String  
**Value:**
```
concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')
```

---

### STEP 7: Respond to PowerApps

**Action:** PowerApps → **Respond to PowerApps**

**Response Body (JSON):**
```json
{
    "fileName": "@{variables('varFileName')}",
    "fileContent": "@{body('Convert_to_Base64')}",
    "rowCount": "@{variables('varRowCount')}",
    "exportDate": "@{utcNow()}",
    "status": "success"
}
```

---

## 🔄 Alternative Flow: With Error Handling

### Add Try-Catch

**After STEP 2 (SQL Query):**

**Action:** Control → **Configure run after**

**Configure:**
- ✅ is successful
- ✅ has failed
- ✅ is skipped
- ✅ is timed out

**If Failed:**

**Action:** Compose (Error Message)

**Input:**
```
concat('SQL Query Error: ', outputs('Execute_a_SQL_query_(V2)')?['body']?['error']?['message'])
```

**Action:** Respond to PowerApps (Error)

**Response Body:**
```json
{
    "status": "error",
    "error": "@{outputs('Compose_Error')}",
    "fileName": "",
    "fileContent": "",
    "rowCount": 0
}
```

---

## 📊 Flow Diagram

```
┌─────────────────────┐
│ PowerApps Trigger   │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Execute SQL Query   │ ← Query VW_REKENING_KORAN
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│   Parse JSON        │ ← Parse SQL results
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  Create CSV Table   │ ← Convert to CSV
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Convert to Base64   │ ← Encode for download
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Respond to PowerApps│ ← Return file
└─────────────────────┘
```

---

## 🧪 Testing

### Test Manually

1. Buka flow di Power Automate
2. Click **Test** → **Manually**
3. Click **Run flow**
4. Check each step:
   - ✅ SQL query returns data
   - ✅ JSON parsed correctly
   - ✅ CSV created
   - ✅ Base64 encoded
   - ✅ Response sent

### Test from Power Apps

1. Buka Power Apps
2. Click export button
3. Verify:
   - ✅ Flow triggered
   - ✅ File downloaded
   - ✅ File opens correctly
   - ✅ Data matches view

---

## ⚙️ Advanced: Add Filters

### Add Input Parameters to Trigger

**PowerApps (V2) Input:**
- `StartDate` (Text, Optional)
- `EndDate` (Text, Optional)
- `BTP` (Text, Optional)

### Modify SQL Query

**Query Text:**
```sql
DECLARE @StartDate DATETIME = TRY_CAST('@{triggerBody()?['StartDate']}' AS DATETIME);
DECLARE @EndDate DATETIME = TRY_CAST('@{triggerBody()?['EndDate']}' AS DATETIME);
DECLARE @BTP NVARCHAR(50) = '@{triggerBody()?['BTP']}';

SELECT 
    [id],
    [trx_date],
    [created_at],
    [updated_at],
    [credit],
    [btp],
    [desc]
FROM [POWERAPPS].[dbo].[VW_REKENING_KORAN]
WHERE 
    (@StartDate IS NULL OR trx_date >= @StartDate)
    AND (@EndDate IS NULL OR trx_date <= @EndDate)
    AND (@BTP IS NULL OR btp = @BTP)
ORDER BY [id] DESC
```

---

## 📝 Notes

1. **Performance:**
   - Untuk data besar (>10k rows), pertimbangkan pagination
   - Atau tambahkan `TOP 50000` di query

2. **File Size:**
   - CSV file biasanya lebih kecil dari Excel
   - Base64 encoding menambah ~33% size

3. **Encoding:**
   - Pastikan UTF-8 untuk support special characters
   - Excel bisa auto-detect UTF-8 dengan BOM

4. **Security:**
   - Credential hanya di Power Automate connection
   - User tidak pernah lihat SQL credentials
   - Flow bisa di-restrict per user/role

---

## ✅ Checklist

- [ ] Flow created
- [ ] SQL connection configured
- [ ] All steps configured correctly
- [ ] Error handling added
- [ ] Tested manually
- [ ] Tested from Power Apps
- [ ] Documentation updated

---

**Last Updated:** 2025-01-XX  
**Version:** 1.0

