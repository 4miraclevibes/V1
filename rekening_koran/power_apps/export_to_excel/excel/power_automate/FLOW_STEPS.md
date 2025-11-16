# 🔄 Power Automate Flow Steps - Export to Excel (.xlsx)

## Flow Name: `Export_RekeningKoran_ToExcel_XLSX`

**Approach:** Reuse CSV flow yang sudah ada, lalu convert CSV ke Excel file (.xlsx) sebelum upload ke SharePoint.

**Alternatif:** Langsung create Excel dari JSON data (lebih simple) - lihat `FLOW_STEPS_SIMPLE.md`

---

## 📋 Flow Overview

**Trigger:** PowerApps (V2)  
**Purpose:** Query database, convert ke Excel, upload ke SharePoint  
**Output:** Excel file (.xlsx) download link

---

## 🔧 Step-by-Step Configuration

### STEP 1: Trigger - PowerApps (V2)

**Action:** PowerApps → **PowerApps (V2)**

**Input Parameters (Optional):**
- `StartDate` (Text, Optional)
- `EndDate` (Text, Optional)
- `BTP` (Text, Optional)

---

### STEP 2: Execute Stored Procedure

**Action:** SQL Server → **Execute stored procedure (V2)**

**Configuration:**
- **Server name:** Use connection settings
- **Database name:** Use connection settings
- **Procedure name:** `[dbo].[SP_EXPORT_REKENING_KORAN]`

**Parameters:**
- `@StartDate` = `@{triggerBody()?['StartDate']}`
- `@EndDate` = `@{triggerBody()?['EndDate']}`
- `@BTP` = `@{triggerBody()?['BTP']}`

**Note:** Bisa pakai stored procedure yang sama dengan CSV solution.

---

### STEP 3: Parse JSON

**Action:** Data operation → **Parse JSON**

**Content:**
```
@body('Execute_stored_procedure_(V2)')?['ResultSets']?['Table1']
```

**Schema:** (Generate from sample atau manual)

```json
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "Tanggal Transaksi": {"type": "string"},
            "Keterangan": {"type": "string"},
            "Jumlah": {"type": "number"},
            "DB/CR": {"type": "string"},
            "Bill To Party": {"type": "string"},
            "Bank Type": {"type": "string"}
        }
    }
}
```

---

### STEP 4: Create CSV Table (Temporary)

**Action:** Data operation → **Create CSV table**

**From:**
```
@body('Parse_JSON')
```

**Columns:** Auto-detect  
**Delimiter:** Comma (`,`)

**Note:** CSV ini temporary, akan di-convert ke Excel di step berikutnya.

---

### STEP 5: Convert CSV to Excel

**⚠️ IMPORTANT:** Power Automate tidak punya action langsung "Convert CSV to Excel"!

**Solusi: Gunakan Office Scripts atau Create Excel Table**

#### **Option A: Create Excel Table (RECOMMENDED - PALING SIMPLE!)**

**Action:** Excel Online (Business) → **Create table**

**Configuration:**
1. **Location:** OneDrive for Business atau SharePoint
2. **Document Library:** Pilih library
3. **File:** Buat file baru atau pakai template
4. **Table:** Create table dari data

**Tapi ini tidak langsung create Excel file untuk download...**

#### **Option B: Use Office Scripts (ADVANCED)**

**Action:** Excel Online (Business) → **Run script**

**Script:** Convert CSV data ke Excel workbook

**Lebih kompleks tapi lebih powerful.**

#### **Option C: Create Excel File dengan Data (SIMPLE & RECOMMENDED!)**

**Action:** Excel Online (Business) → **Create worksheet**

**Configuration:**
- **Location:** OneDrive for Business atau SharePoint
- **File:** Create new file
- **Worksheet name:** "Data"
- **Values:** Data dari Parse JSON

**Lalu download file Excel tersebut.**

---

### STEP 6: Initialize Variable (Excel File Name)

**Action:** Initialize variable

**Name:** `varFileName`  
**Type:** String  
**Value (Expression):**
```
concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')
```

---

### STEP 7: Create File in SharePoint (Excel)

**Action:** SharePoint → **Create file**

**Configuration:**
- **Site Address:** Pilih SharePoint site
- **Folder Path:** `/Shared Documents/Exports`
- **File Name:** `@{variables('varFileName')}`
- **File Content:** Excel file content dari step sebelumnya

**Note:** File content harus dalam format Excel binary.

---

### STEP 8: Compose Download Link

**Action:** Data operation → **Compose**

**Input (Expression):**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy',
    body('Create_file')?['Path']
)
```

---

### STEP 9: Respond to PowerApps

**Action:** PowerApps → **Respond to a Power App or flow**

**Parameters:**
- `fileName` (Text) → `@{variables('varFileName')}`
- `sharePointLink` (Text) → `@{outputs('Compose_DownloadLink')}`
- `rowCount` (Number) → `@{length(body('Parse_JSON'))}`
- `status` (Text) → `success`

---

## 🔄 Alternative: Pakai Office Scripts (Lebih Powerful)

### STEP 5B: Create Excel Template di OneDrive/SharePoint

1. **Buat Excel template** dengan header yang benar
2. **Upload ke OneDrive/SharePoint**
3. **Gunakan Office Scripts** untuk populate data

### STEP 6B: Run Office Script

**Action:** Excel Online (Business) → **Run script**

**Script:**
```typescript
function main(workbook: ExcelScript.Workbook, data: any[]) {
  let sheet = workbook.getActiveWorksheet();
  // Clear existing data
  sheet.getUsedRange()?.clear();
  // Add headers
  sheet.getRange("A1:F1").setValues([["Tanggal Transaksi", "Keterangan", "Jumlah", "DB/CR", "Bill To Party", "Bank Type"]]);
  // Add data
  let dataRange = sheet.getRange("A2:F" + (data.length + 1));
  dataRange.setValues(data.map(row => [row["Tanggal Transaksi"], row["Keterangan"], row["Jumlah"], row["DB/CR"], row["Bill To Party"], row["Bank Type"]]));
  // Format header
  sheet.getRange("A1:F1").getFormat().getFont().setBold(true);
  sheet.getRange("A1:F1").getFormat().getFill().setColor("#4472C4");
  sheet.getRange("A1:F1").getFormat().getFont().setColor("#FFFFFF");
}
```

**Input:** Data dari Parse JSON

---

## 📊 Flow Diagram

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
│ Create CSV table            │ ← Temporary
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Convert CSV to Excel        │ ← NEW!
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Initialize variable         │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create file (SharePoint)    │ ← Excel file
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

**Power Automate tidak punya action langsung "Convert CSV to Excel"!**

**Solusi yang bisa dipakai:**
1. **Office Scripts** (recommended untuk formatting)
2. **Excel Online connector** untuk create worksheet
3. **Create Excel file manual** dengan data array

**Untuk solusi paling simple:** Pakai approach yang sama dengan CSV, tapi file extension `.xlsx` dan content format Excel.

---

## 🧪 Testing

1. **Run flow manual** di Power Automate
2. **Check:** Excel file ter-create di SharePoint
3. **Download file** → Buka di Excel
4. **Verify:** Data benar, format Excel (bukan CSV)

---

**Note:** Flow ini lebih kompleks dari CSV solution karena perlu convert ke Excel format. Tapi hasilnya lebih professional! 📊

