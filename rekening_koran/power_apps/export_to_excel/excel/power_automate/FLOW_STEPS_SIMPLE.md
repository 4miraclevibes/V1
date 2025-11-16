# 🔄 Flow Steps: CSV → Excel (Simple Approach)

## 🎯 Tujuan

**Reuse flow CSV yang sudah ada**, tambahkan step untuk **convert CSV ke Excel**.

**Flow yang sudah ada:**
```
Query → Parse JSON → Create CSV → Compose (Base64) → Create file (SharePoint - CSV)
```

**Flow baru:**
```
Query → Parse JSON → Create CSV → Create Excel from Data → Create file (SharePoint - Excel)
```

---

## ✅ Solusi Paling Simple

**Skip CSV file creation**, langsung **create Excel dari data JSON**!

**Kenapa?**
- ✅ Lebih simple (tidak perlu convert CSV)
- ✅ Lebih cepat (langsung ke Excel)
- ✅ Lebih reliable (tidak ada conversion step)

---

## 📋 Flow Steps (Simple)

### STEP 1-3: Sama Seperti CSV Flow

1. ✅ **Execute stored procedure (V2)** - Query database
2. ✅ **Parse JSON** - Parse hasil query
3. ✅ **Create CSV table** - Convert ke CSV (untuk reference, tidak dipakai)

**Note:** Step 1-3 sama dengan CSV flow.

---

### STEP 4: Create Excel File

**Action:** Excel Online (Business) → **Create worksheet**

**Configuration:**
- **Location:** OneDrive for Business atau SharePoint
- **File:** Create new file
- **File name:** 
  ```
  RekeningKoran_Export_@{formatDateTime(utcNow(), 'yyyyMMdd_HHmmss')}.xlsx
  ```
- **Worksheet name:** "Data"

**Output:** Excel file ID

---

### STEP 5: Create Table di Excel

**Action:** Excel Online (Business) → **Create table**

**Configuration:**
- **Location:** File dari STEP 4
- **Worksheet:** "Data"
- **Address:** "A1"
- **Has headers:** Yes

**Output:** Table ID

---

### STEP 6: Add Headers

**Action:** Excel Online (Business) → **Add a row into a table**

**Configuration:**
- **Location:** File dari STEP 4
- **Worksheet:** "Data"
- **Table:** Table dari STEP 5
- **Values:** 
  ```
  ["Tanggal Transaksi", "Keterangan", "Jumlah", "DB/CR", "Bill To Party", "Bank Type"]
  ```

---

### STEP 7: Convert JSON Data ke Array Format

**Action:** Data operation → **Compose**

**Input (Expression):**
```
map(body('Parse_JSON'), item => [
    item?['Tanggal Transaksi'],
    item?['Keterangan'],
    item?['Jumlah'],
    item?['DB/CR'],
    item?['Bill To Party'],
    item?['Bank Type']
])
```

**Penjelasan:**
- Convert array of objects ke array of arrays
- Setiap row menjadi array sesuai urutan kolom

---

### STEP 8: Add Data Rows ke Excel

**Action:** Excel Online (Business) → **Add rows into a table**

**Configuration:**
- **Location:** File dari STEP 4
- **Worksheet:** "Data"
- **Table:** Table dari STEP 5
- **Values:** Output dari STEP 7 (Compose)

**Atau langsung pakai dynamic content dari Parse JSON jika format sudah benar.**

---

### STEP 9: Get Excel File Link

**Action:** SharePoint → **Get file properties**

**Configuration:**
- **Site Address:** Same as Excel file location
- **File Identifier:** File ID dari STEP 4

---

### STEP 10: Compose Download Link

**Action:** Data operation → **Compose**

**Input (Expression):**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy',
    body('Get_file_properties')?['Path']
)
```

---

### STEP 11: Initialize Variable (File Name)

**Action:** Initialize variable

**Name:** `varFileName`  
**Type:** String  
**Value:**
```
concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')
```

---

### STEP 12: Respond to PowerApps

**Action:** PowerApps → **Respond to a Power App or flow**

**Parameters:**
- `fileName` (Text) → `@{variables('varFileName')}`
- `sharePointLink` (Text) → `@{outputs('Compose_DownloadLink')}`
- `rowCount` (Number) → `@{length(body('Parse_JSON'))}`
- `status` (Text) → `success`

---

## 📊 Flow Diagram (Simple)

```
┌─────────────────────────────┐
│ Execute stored procedure    │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Parse JSON                  │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create CSV table            │ ← Reference only (optional)
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create Excel Worksheet       │ ← NEW! Create Excel file
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create Table                │ ← Create Excel table
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Add Headers                 │ ← Add table headers
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Compose (Convert Data)      │ ← Convert JSON to array
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Add Data Rows               │ ← Add data ke Excel
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Get File Link               │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Compose DownloadLink        │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Respond to PowerApps        │ ← Return Excel link
└─────────────────────────────┘
```

---

## ✅ Keuntungan Approach Simple

1. ✅ **Tidak perlu convert CSV** → Langsung dari JSON ke Excel
2. ✅ **Lebih cepat** → Skip CSV conversion step
3. ✅ **Lebih reliable** → Tidak ada conversion error
4. ✅ **File Excel asli** → Format `.xlsx`

---

## ⚠️ Catatan Penting

**Excel Online connector:**
- ✅ Perlu OneDrive for Business atau SharePoint connection
- ✅ Excel file akan tersimpan di OneDrive/SharePoint
- ✅ Bisa di-edit langsung di Excel Online

**Data format:**
- ✅ Data dari Parse JSON langsung di-convert ke array format
- ✅ Tidak perlu CSV intermediate step
- ✅ Lebih efficient

---

## 🧪 Testing

1. **Run flow manual** di Power Automate
2. **Check:**
   - ✅ Excel file ter-create di OneDrive/SharePoint
   - ✅ Headers ter-add
   - ✅ Data ter-populate
3. **Download Excel file** → Buka di Excel
4. **Verify:**
   - ✅ File format Excel (.xlsx)
   - ✅ Data benar
   - ✅ Bisa di-edit di Excel

---

**Approach simple: Langsung dari JSON ke Excel, skip CSV! 📊**

