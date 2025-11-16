# 🔄 Flow Steps: CSV → Excel Conversion

## 🎯 Tujuan

**Menggunakan flow CSV yang sudah ada**, lalu **convert CSV ke Excel** sebelum upload ke SharePoint.

**Flow yang sudah ada:**
```
Query → Parse JSON → Create CSV → Compose (Base64) → Create file (SharePoint)
```

**Flow baru (dengan Excel conversion):**
```
Query → Parse JSON → Create CSV → Convert CSV to Excel → Create file (SharePoint - Excel)
```

---

## 🔧 Solusi: Convert CSV ke Excel

**Power Automate tidak punya action langsung "Convert CSV to Excel"!**

**Solusi:** Pakai **Excel Online connector** untuk create Excel file dari CSV data.

---

## 📋 Flow Steps Lengkap

### STEP 1-4: Sama Seperti CSV Flow

1. ✅ **Execute stored procedure (V2)** - Query database
2. ✅ **Parse JSON** - Parse hasil query
3. ✅ **Create CSV table** - Convert ke CSV (temporary)
4. ✅ **Compose (Base64)** - Convert CSV ke Base64

**Note:** Step 1-4 sama dengan CSV flow yang sudah ada.

---

### STEP 5: Create Excel File di OneDrive/SharePoint

**Action:** Excel Online (Business) → **Create worksheet**

**Configuration:**
- **Location:** OneDrive for Business atau SharePoint
- **File:** Create new file
- **File name:** 
  ```
  RekeningKoran_Export_@{formatDateTime(utcNow(), 'yyyyMMdd_HHmmss')}.xlsx
  ```
- **Worksheet name:** "Data"

**Output:** Excel file ID dan path

---

### STEP 6: Add Headers ke Excel

**Action:** Excel Online (Business) → **Add a row into a table**

**Configuration:**
- **Location:** File dari STEP 5
- **Worksheet:** "Data"
- **Table:** Create new table
- **Values:** 
  ```
  ["Tanggal Transaksi", "Keterangan", "Jumlah", "DB/CR", "Bill To Party", "Bank Type"]
  ```

**Atau pakai dynamic content dari Parse JSON untuk ambil headers.**

---

### STEP 7: Convert CSV Data ke Excel Rows

**⚠️ IMPORTANT:** Kita perlu convert CSV string ke array of arrays untuk Excel.

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
- `map()` convert array of objects ke array of arrays
- Setiap object di-convert ke array sesuai urutan kolom

---

### STEP 8: Add Data Rows ke Excel

**Action:** Excel Online (Business) → **Add rows into a table**

**Configuration:**
- **Location:** File dari STEP 5
- **Worksheet:** "Data"
- **Table:** Table yang dibuat di STEP 6
- **Values:** Output dari STEP 7 (Compose)

**Atau langsung pakai:**
```
@body('Parse_JSON')
```
**Tapi perlu convert format dulu!**

---

### STEP 9: Get Excel File Link

**Action:** SharePoint → **Get file properties**

**Configuration:**
- **Site Address:** Same as Excel file location
- **File Identifier:** File ID dari STEP 5

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

### STEP 11: Respond to PowerApps

**Action:** PowerApps → **Respond to a Power App or flow**

**Parameters:**
- `fileName` (Text) → Excel filename dengan extension `.xlsx`
- `sharePointLink` (Text) → Download link
- `rowCount` (Number) → `@{length(body('Parse_JSON'))}`
- `status` (Text) → `success`

---

## 🔄 Alternative: Pakai Office Scripts (Lebih Powerful)

### STEP 5B: Create Excel Template

1. **Buat Excel template** dengan header di OneDrive/SharePoint
2. **Atau create Excel file kosong** via flow

### STEP 6B: Run Office Script untuk Populate Data

**Action:** Excel Online (Business) → **Run script**

**Script:**
```typescript
function main(workbook: ExcelScript.Workbook, csvData: string) {
  let sheet = workbook.getActiveWorksheet();
  
  // Parse CSV data (dari CSV table yang sudah dibuat)
  let rows = csvData.split('\n');
  
  // Clear existing data
  sheet.getUsedRange()?.clear();
  
  // Add headers
  let headers = rows[0].split(',');
  sheet.getRange("A1:F1").setValues([headers]);
  
  // Format headers
  let headerRange = sheet.getRange("A1:F1");
  headerRange.getFormat().getFont().setBold(true);
  headerRange.getFormat().getFill().setColor("#4472C4");
  headerRange.getFormat().getFont().setColor("#FFFFFF");
  
  // Add data rows
  for (let i = 1; i < rows.length; i++) {
    if (rows[i].trim()) {
      let values = rows[i].split(',');
      sheet.getRange(`A${i+1}:F${i+1}`).setValues([values]);
    }
  }
  
  // Auto-fit columns
  sheet.getUsedRange().getFormat().autofitColumns();
}
```

**Input:** CSV string dari "Create CSV table"

---

## 📊 Flow Diagram

```
┌─────────────────────────────┐
│ Execute stored procedure    │ ← Query database
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Parse JSON                  │ ← Parse hasil query
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create CSV table            │ ← Convert ke CSV (temporary)
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create Excel Worksheet       │ ← NEW! Create Excel file
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

## ✅ Keuntungan Approach Ini

1. ✅ **Reuse CSV flow** yang sudah ada
2. ✅ **Convert ke Excel** setelah dapat CSV
3. ✅ **File Excel asli** (.xlsx)
4. ✅ **Support formatting** (jika pakai Office Scripts)

---

## ⚠️ Catatan Penting

**Excel Online connector memerlukan:**
- ✅ OneDrive for Business atau SharePoint connection
- ✅ Permission untuk create/edit Excel files
- ✅ Excel file akan tersimpan di OneDrive/SharePoint

**File Excel akan:**
- ✅ Format `.xlsx` (Excel asli)
- ✅ Bisa dibuka langsung di Excel
- ✅ Support formatting (jika pakai Office Scripts)

---

## 🧪 Testing

1. **Run flow manual** di Power Automate
2. **Check:** 
   - ✅ CSV ter-create (temporary)
   - ✅ Excel file ter-create di OneDrive/SharePoint
   - ✅ Data ter-populate di Excel
3. **Download Excel file** → Buka di Excel
4. **Verify:** 
   - ✅ File format Excel (.xlsx)
   - ✅ Data benar
   - ✅ Headers ada
   - ✅ Bisa di-edit di Excel

---

**Solusi ini reuse CSV flow yang sudah ada, lalu convert ke Excel! 📊**

