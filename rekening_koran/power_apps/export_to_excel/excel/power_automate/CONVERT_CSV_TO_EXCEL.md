# 🔄 Convert CSV to Excel - Solusi di Power Automate

## ❌ Masalah: Power Automate Tidak Punya Action "Convert CSV to Excel"

**Power Automate tidak punya action langsung untuk convert CSV ke Excel!**

---

## ✅ Solusi: 3 Cara

### **CARA 1: Pakai Excel Online Connector (RECOMMENDED - PALING SIMPLE!)**

**Approach:** Langsung create Excel worksheet dengan data array (skip CSV).

**Flow Steps:**

1. **Parse JSON** (dari stored procedure)
2. **Create Excel worksheet** langsung dengan data array
3. **Download Excel file** dari OneDrive/SharePoint

**Action yang dipakai:**
- **Excel Online (Business)** → **Create worksheet**
- Atau **Excel Online (Business)** → **Add a row into a table**

**Keuntungan:**
- ✅ Simple dan langsung
- ✅ Tidak perlu convert CSV
- ✅ Support formatting (jika pakai Office Scripts)

---

### **CARA 2: Pakai Office Scripts (LEBIH POWERFUL!)**

**Approach:** Create Excel template, lalu populate dengan Office Scripts.

**Flow Steps:**

1. **Create Excel template** di OneDrive/SharePoint (dengan header)
2. **Run Office Script** untuk populate data
3. **Download Excel file**

**Action yang dipakai:**
- **Excel Online (Business)** → **Run script**

**Keuntungan:**
- ✅ Support formatting (warna, border, font)
- ✅ Support multiple sheets
- ✅ Lebih professional

**Kekurangan:**
- ❌ Lebih kompleks (perlu buat script)

---

### **CARA 3: Create Excel File Manual (ADVANCED)**

**Approach:** Create Excel file dengan format Excel binary langsung.

**Flow Steps:**

1. **Create CSV** (temporary)
2. **Convert CSV ke Excel binary** menggunakan expression/code
3. **Upload Excel binary** ke SharePoint

**Keuntungan:**
- ✅ Full control
- ✅ Bisa custom format

**Kekurangan:**
- ❌ Sangat kompleks (perlu coding Excel format)

---

## 🎯 Rekomendasi: CARA 1 (Paling Simple!)

**Pakai Excel Online connector untuk create worksheet langsung.**

**Flow yang disederhanakan:**

```
Parse JSON → Create Excel Worksheet → Upload to SharePoint → Return Link
```

**Tidak perlu CSV step!**

---

## 🆕 CARA 4: Convert CSV File yang Sudah Dibuat (PALING SIMPLE - REUSE FLOW!)

**Approach:** Tetap pakai flow CSV yang sudah ada, lalu convert CSV file yang sudah dibuat ke Excel.

**Flow yang sudah ada:**
```
Query → Parse JSON → Create CSV → Create file (SharePoint - CSV) → Compose DownloadLink → Respond
```

**Flow baru (dengan Excel conversion):**
```
Query → Parse JSON → Create CSV → Create file (SharePoint - CSV) → Read CSV File → Convert to Excel → Create file (SharePoint - Excel) → Compose DownloadLink → Respond
```

**Keuntungan:**
- ✅ **Reuse flow CSV yang sudah ada** - tidak perlu ubah banyak
- ✅ **Minimal perubahan** - hanya tambah step setelah "Create file"
- ✅ **CSV tetap dibuat** (backup)
- ✅ **Excel juga dibuat** dari CSV yang sudah ada

**Kekurangan:**
- ❌ Sedikit lebih lambat (ada 2 file yang dibuat)
- ❌ Perlu read CSV file dulu

---

## 📋 Detail CARA 1: Create Excel Worksheet

### **STEP 1: Parse JSON** (sama seperti sebelumnya)

**Action:** Parse JSON  
**Content:** Output dari stored procedure

---

### **STEP 2: Create Excel File di OneDrive/SharePoint**

**Action:** Excel Online (Business) → **Create worksheet**

**Configuration:**
- **Location:** OneDrive for Business atau SharePoint
- **File:** Create new file
- **File name:** `RekeningKoran_Export_@{formatDateTime(utcNow(), 'yyyyMMdd_HHmmss')}.xlsx`
- **Worksheet name:** "Data"

---

### **STEP 3: Add Headers**

**Action:** Excel Online (Business) → **Add a row into a table**

**Configuration:**
- **Location:** File yang baru dibuat
- **Worksheet:** "Data"
- **Table:** Create new table
- **Values:** `["Tanggal Transaksi", "Keterangan", "Jumlah", "DB/CR", "Bill To Party", "Bank Type"]`

---

### **STEP 4: Add Data Rows**

**Action:** Excel Online (Business) → **Add rows into a table**

**Configuration:**
- **Location:** Same file
- **Worksheet:** "Data"
- **Table:** Table yang baru dibuat
- **Values:** Data dari Parse JSON (array of arrays)

**Expression untuk Values:**
```
@body('Parse_JSON')
```

**Atau convert ke array format:**
```
@map(body('Parse_JSON'), item => [
    item?['Tanggal Transaksi'],
    item?['Keterangan'],
    item?['Jumlah'],
    item?['DB/CR'],
    item?['Bill To Party'],
    item?['Bank Type']
])
```

---

### **STEP 5: Get File Link**

**Action:** SharePoint → **Get file properties**

**Configuration:**
- **Site Address:** Same as Excel file location
- **File Identifier:** File ID dari "Create worksheet"

---

### **STEP 6: Compose Download Link**

**Action:** Compose

**Input:**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy',
    body('Get_file_properties')?['Path']
)
```

---

### **STEP 7: Respond to PowerApps**

**Action:** Respond to PowerApps

**Parameters:**
- `fileName` → Excel filename
- `sharePointLink` → Download link
- `rowCount` → Number of rows
- `status` → "success"

---

## 📊 Flow Diagram (CARA 1)

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
│ Create Excel Worksheet      │ ← NEW! Langsung create Excel
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Add Headers                 │ ← Add table headers
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Add Data Rows               │ ← Add data ke table
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
│ Respond to PowerApps        │
└─────────────────────────────┘
```

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
2. **Check:** Excel file ter-create di OneDrive/SharePoint
3. **Download file** → Buka di Excel
4. **Verify:** 
   - ✅ File format Excel (.xlsx)
   - ✅ Data benar
   - ✅ Headers ada
   - ✅ Bisa di-edit di Excel

---

**CARA 1 paling simple dan recommended! 📊**

---

## 📋 Detail CARA 4: Convert CSV File ke Excel (Reuse Flow)

### **STEP 1-6: Sama Seperti Flow CSV yang Sudah Ada**

1. ✅ **Execute stored procedure (V2)** - Query database
2. ✅ **Parse JSON** - Parse hasil query
3. ✅ **Create CSV table** - Convert ke CSV
4. ✅ **Compose (Base64)** - Convert CSV ke Base64
5. ✅ **Initialize variable** - Set file name (CSV)
6. ✅ **Create file** - Upload CSV ke SharePoint

**Note:** Step 1-6 sama dengan flow CSV yang sudah ada. CSV file sudah ter-create di SharePoint.

---

### **STEP 7: Get CSV File Content**

**Action:** SharePoint → **Get file content**

**Configuration:**
- **Site Address:** Same as CSV file location
- **File Identifier:** File ID dari "Create file" (CSV)

**Output:** CSV file content (binary atau text)

---

### **STEP 8: Convert CSV Content ke Text**

**Action:** Data operation → **Compose**

**Input (Expression):**
```
base64ToString(body('Get_file_content')?['$content'])
```

**Penjelasan:**
- Convert binary CSV content ke string text
- CSV content akan digunakan untuk populate Excel

---

### **STEP 9: Create Excel File di OneDrive/SharePoint**

**Action:** Excel Online (Business) → **Create worksheet**

**Configuration:**
- **Location:** OneDrive for Business atau SharePoint (same location)
- **File:** Create new file
- **File name:** 
  ```
  RekeningKoran_Export_@{formatDateTime(utcNow(), 'yyyyMMdd_HHmmss')}.xlsx
  ```
- **Worksheet name:** "Data"

**Output:** Excel file ID dan path

---

### **STEP 10: Parse CSV String ke Array**

**⚠️ IMPORTANT:** Kita perlu parse CSV string ke array untuk Excel.

**Action:** Data operation → **Compose**

**Input (Expression):**
```
split(body('Compose_CSV_Text'), '\n')
```

**Penjelasan:**
- Split CSV string per baris (newline)
- Hasilnya array of strings (setiap baris CSV)

---

### **STEP 11: Convert CSV Rows ke Excel Format**

**Action:** Data operation → **Compose**

**Input (Expression):**
```
map(split(body('Compose_CSV_Text'), '\n'), row => split(row, ','))
```

**Penjelasan:**
- Split setiap baris CSV menjadi array of values
- Hasilnya array of arrays (siap untuk Excel)

**Atau pakai data dari Parse JSON langsung (lebih reliable):**
```
map(body('Parse_JSON'), item => [
    item?['id'],
    item?['trx_date'],
    item?['created_at'],
    item?['updated_at'],
    item?['credit'],
    item?['btp'],
    item?['desc']
])
```

---

### **STEP 12: Add Data ke Excel**

**Action:** Excel Online (Business) → **Add rows into a table**

**Configuration:**
- **Location:** File dari STEP 9
- **Worksheet:** "Data"
- **Table:** Create new table
- **Address:** "A1"
- **Has headers:** Yes
- **Values:** Output dari STEP 11 (array of arrays)

**Penjelasan:**
- Excel akan otomatis detect headers dari baris pertama
- Data rows akan di-add setelah headers

---

### **STEP 13: Get Excel File Link**

**Action:** SharePoint → **Get file properties**

**Configuration:**
- **Site Address:** Same as Excel file location
- **File Identifier:** File ID dari STEP 9

---

### **STEP 14: Compose Download Link (Excel)**

**Action:** Data operation → **Compose**

**Input (Expression):**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy',
    body('Get_file_properties_Excel')?['Path']
)
```

**Atau langsung pakai:**
```
body('Get_file_properties_Excel')?['Path']
```

---

### **STEP 15: Update Variable File Name (Excel)**

**Action:** Set variable

**Name:** `varFileName`  
**Value:**
```
concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')
```

---

### **STEP 16: Respond to PowerApps**

**Action:** Respond to a Power App or flow

**Parameters:**
- `fileName` (Text) → `@{variables('varFileName')}` (Excel filename)
- `sharePointLink` (Text) → Output dari STEP 14 (Excel download link)
- `rowCount` (Number) → `@{length(body('Parse_JSON'))}`
- `status` (Text) → `success`

---

## 📊 Flow Diagram (CARA 4)

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
│ Create CSV table            │ ← Convert ke CSV
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Compose (Base64)            │ ← Convert ke Base64
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Initialize variable         │ ← Set CSV filename
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create file (CSV)           │ ← Upload CSV ke SharePoint
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Get file content (CSV)      │ ← NEW! Read CSV file
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Compose (CSV Text)          │ ← NEW! Convert to text
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create Excel Worksheet      │ ← NEW! Create Excel file
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Compose (Parse CSV)         │ ← NEW! Parse CSV to array
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Add rows into a table       │ ← NEW! Add data ke Excel
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Get file properties (Excel) │ ← NEW! Get Excel file info
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Compose DownloadLink        │ ← Excel download link
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Respond to PowerApps        │ ← Return Excel link
└─────────────────────────────┘
```

---

## ✅ Keuntungan CARA 4

1. ✅ **Minimal perubahan** - hanya tambah step setelah "Create file"
2. ✅ **Reuse flow CSV** yang sudah ada dan bekerja
3. ✅ **CSV tetap dibuat** sebagai backup
4. ✅ **Excel juga dibuat** dari CSV yang sudah ada
5. ✅ **Tidak perlu ubah step sebelumnya**

---

## ⚠️ Catatan Penting (CARA 4)

**Perlu:**
- ✅ SharePoint connection untuk read CSV file
- ✅ Excel Online (Business) connector
- ✅ Permission untuk read dan create files

**File yang dibuat:**
- ✅ CSV file (tetap ada di SharePoint)
- ✅ Excel file (.xlsx) - baru dibuat

**Alternative yang lebih simple (RECOMMENDED!):**
- ✅ **Langsung pakai CSV content dari memory** - tidak perlu "Get file content"
- ✅ CSV content masih ada di `body('Create_CSV_table')` 
- ✅ Langsung convert dari memory ke Excel (lebih cepat!)

**Flow yang lebih optimal:**
```
Query → Parse JSON → Create CSV → Create file (CSV) → Create Excel → Add Data (dari Parse JSON) → Respond
```

**Skip STEP 7-8**, langsung pakai data dari `body('Parse_JSON')` untuk populate Excel!

---

## 🚀 CARA 4 OPTIMIZED: Pakai Data dari Memory (LEBIH CEPAT!)

**Approach:** Tetap create CSV file, tapi untuk Excel langsung pakai data dari Parse JSON (tidak perlu read CSV file).

**Flow:**
```
Query → Parse JSON → Create CSV → Create file (CSV) → Create Excel → Add Data (dari Parse JSON) → Respond
```

### **STEP 1-6: Sama Seperti Flow CSV yang Sudah Ada**

1. ✅ **Execute stored procedure (V2)**
2. ✅ **Parse JSON**
3. ✅ **Create CSV table**
4. ✅ **Compose (Base64)**
5. ✅ **Initialize variable** (CSV filename)
6. ✅ **Create file** (CSV ke SharePoint)

---

### **STEP 7: Create Excel File**

**Action:** Excel Online (Business) → **Create worksheet**

**Configuration:**
- **Location:** Same SharePoint location
- **File:** Create new file
- **File name:** 
  ```
  RekeningKoran_Export_@{formatDateTime(utcNow(), 'yyyyMMdd_HHmmss')}.xlsx
  ```
- **Worksheet name:** "Data"

---

### **STEP 8: Convert JSON Data ke Excel Format**

**Action:** Data operation → **Compose**

**Input (Expression):**
```
map(body('Parse_JSON'), item => [
    item?['id'],
    item?['trx_date'],
    item?['created_at'],
    item?['updated_at'],
    item?['credit'],
    item?['btp'],
    item?['desc']
])
```

**Penjelasan:**
- Langsung pakai data dari Parse JSON (masih di memory)
- Convert ke array of arrays untuk Excel
- **Tidak perlu read CSV file!**

---

### **STEP 9: Add Data ke Excel**

**Action:** Excel Online (Business) → **Add rows into a table**

**Configuration:**
- **Location:** File dari STEP 7
- **Worksheet:** "Data"
- **Table:** Create new table
- **Address:** "A1"
- **Has headers:** Yes
- **Values:** Output dari STEP 8

**Penjelasan:**
- Excel otomatis detect headers dari baris pertama array
- Data rows di-add setelah headers

---

### **STEP 10-12: Get Link & Respond**

Sama seperti STEP 13-16 di atas.

---

## ✅ Keuntungan CARA 4 OPTIMIZED

1. ✅ **Lebih cepat** - tidak perlu read CSV file
2. ✅ **Lebih simple** - langsung pakai data dari memory
3. ✅ **Lebih reliable** - tidak ada parsing CSV string
4. ✅ **CSV tetap dibuat** sebagai backup
5. ✅ **Excel dibuat** dari data yang sama

**CARA 4 OPTIMIZED paling recommended! 🚀**

---

## 🎯 Rekomendasi Final

**Jika flow CSV sudah bekerja dengan baik dan ingin minimal perubahan:**
- ✅ **Pakai CARA 4 OPTIMIZED** - reuse flow CSV, langsung pakai data dari memory (paling cepat!)
- ✅ **Pakai CARA 4** - jika memang perlu read CSV file dari SharePoint

**Jika mau flow yang lebih simple (skip CSV):**
- ✅ **Pakai CARA 1** - langsung create Excel, skip CSV step

**CARA 4 OPTIMIZED paling cocok untuk reuse flow CSV yang sudah ada! 📊**

**Summary:**
- 🚀 **CARA 4 OPTIMIZED** → Reuse CSV flow + pakai data dari memory (RECOMMENDED!)
- 📋 **CARA 4** → Reuse CSV flow + read CSV file (jika perlu)
- ⚡ **CARA 1** → Skip CSV, langsung Excel (jika mau flow baru)

