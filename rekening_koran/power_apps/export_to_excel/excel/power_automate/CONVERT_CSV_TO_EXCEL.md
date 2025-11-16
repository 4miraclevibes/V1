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

