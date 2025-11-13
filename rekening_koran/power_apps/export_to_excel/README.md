# 📊 Export to Excel - Database View Export

## 🎯 Overview

Solusi untuk export data dari database view (`VW_REKENING_KORAN`) ke Excel **tanpa expose credential database** ke user.

### ❌ Masalah Sebelumnya
- Excel langsung connect ke database → **credential database ter-expose**
- User bisa lihat username/password di Excel connection string
- Security risk tinggi!

### ✅ Solusi Sekarang
- Power Automate query database (credential hanya di Power Automate)
- Generate Excel file dari hasil query
- User download Excel file (tanpa credential)
- **100% secure!** 🔒

---

## 🏗️ Architecture

```
┌─────────────┐
│ Power Apps  │ ← User klik "Export to Excel"
│   Button    │
└──────┬──────┘
       │ Trigger Flow
       ↓
┌─────────────────────────┐
│  Power Automate Flow    │
│                         │
│  1. Query SQL View      │ ← Credential hanya di sini!
│  2. Generate Excel       │
│  3. Return File         │
└──────┬──────────────────┘
       │ Return Excel File
       ↓
┌─────────────┐
│ Power Apps  │ ← Download Excel
│   (User)    │
└─────────────┘
```

---

## 📋 Prerequisites

### 1. Database View
✅ View `VW_MP_REKENING_KORAN` sudah dibuat di database:
```sql
SELECT [id], [trx_date], [created_at], [updated_at], [btp], [desc], 
       [Amount], [TransactionType], [BankType]
FROM [POWERAPPS].[dbo].[MP_REKENING_KORAN]
```

**Note:** Field `credit` **TIDAK DIIKUTSERTAKAN** dalam export (excluded).

### 2. Power Platform
- ✅ Power Apps license
- ✅ Power Automate license
- ✅ SQL Server connector access (untuk Power Automate)

---

## 🚀 Setup Guide

### STEP 1: Create Power Automate Flow

#### 1.1 Create New Flow

1. Masuk ke https://make.powerautomate.com/
2. **Create** → **Instant cloud flow**
3. **Name:** `Export_RekeningKoran_ToExcel`
4. **Trigger:** **PowerApps (V2)**
5. Click **Create**

#### 1.2 Add SQL Query Action

**Action:** SQL Server → **Execute stored procedure (V2)** (untuk on-premises gateway)

**Configuration:**
```
Connection: [Your SQL Server Connection]
Procedure name: [dbo].[SP_EXPORT_REKENING_KORAN]
Parameters: (Optional - bisa dikosongkan)
  - @StartDate
  - @EndDate
  - @BTP
```

**Note:** 
- Menggunakan stored procedure karena on-premises gateway tidak support "Execute SQL query (V2)"
- Stored procedure sudah exclude `credit` dan include `Amount`, `TransactionType`, `BankType`
- Credential SQL hanya di-setup sekali di Power Automate
- User tidak akan pernah lihat credential ini!

#### 1.3 Parse JSON Results

**Action:** Data operation → **Parse JSON**

**Content:** 
```
@body('Execute_a_SQL_query_(V2)')?['ResultSets']?['Table1']
```

**Schema:** (Auto-generate dari sample output)

Atau manual schema:
```json
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "id": {"type": "number"},
            "trx_date": {"type": "string"},
            "created_at": {"type": "string"},
            "updated_at": {"type": "string"},
            "Amount": {"type": "number"},
            "TransactionType": {"type": "string"},
            "BankType": {"type": "string"},
            "btp": {"type": "string"},
            "desc": {"type": "string"}
        }
    }
}
```

#### 1.4 Create Excel Table

**Action:** Office 365 Excel → **Create table**

**Configuration:**
```
Location: OneDrive for Business (atau SharePoint)
Document: [Create new file atau existing file]
Table: [Auto-generate dari data]
```

**Alternative (Recommended):** Gunakan **"Create CSV file"** lebih simple!

#### 1.5 Generate Excel File (CSV Method - Recommended)

**Action:** Data operation → **Create CSV table**

**From:** 
```
@body('Parse_JSON')
```

**Columns:** Auto-detect dari JSON

#### 1.6 Convert to Base64

**Action:** Data operation → **Compose**

**Input:**
```
@body('Create_CSV_table')
```

**Action:** Data operation → **Convert to Base64**

**Input:**
```
@outputs('Compose')
```

#### 1.7 Return to Power Apps

**Action:** PowerApps → **Respond to PowerApps**

**Response:**
```json
{
    "fileName": "RekeningKoran_Export_@{formatDateTime(utcNow(), 'yyyyMMdd_HHmmss')}.csv",
    "fileContent": "@{body('Convert_to_Base64')}",
    "rowCount": "@{length(body('Parse_JSON'))}",
    "exportDate": "@{utcNow()}"
}
```

---

### STEP 2: Power Apps Integration

#### 2.1 Add Button

Di Power Apps, tambahkan button untuk export:

**Button Name:** `btnExportToExcel`

**OnSelect:**
```powerappsfx
// Set loading state
Set(varExportLoading, true);
Set(varExportMessage, "⏳ Generating Excel file...");

// Call Power Automate Flow
Set(
    varExportResult,
    Export_RekeningKoran_ToExcel.Run()
);

// Check result
If(
    !IsBlank(varExportResult.fileContent),
    // Success - Download file
    Set(varExportLoading, false);
    Set(varExportMessage, "✅ Export successful! " & varExportResult.rowCount & " rows");
    // Download file
    Download(
        varExportResult.fileContent,
        varExportResult.fileName,
        "text/csv"
    ),
    // Error
    Set(varExportLoading, false);
    Set(varExportMessage, "❌ Export failed. Please try again.")
);
```

#### 2.2 Add Loading Indicator (Optional)

**Label Name:** `lblExportStatus`

**Text:**
```powerappsfx
If(
    varExportLoading,
    "⏳ Exporting...",
    varExportMessage
)
```

**Visible:**
```powerappsfx
!IsBlank(varExportMessage)
```

---

## 🔧 Alternative: Direct Excel Generation (Advanced)

Jika ingin generate Excel file (bukan CSV), gunakan approach berikut:

### Option A: Use Office Scripts (Recommended)

1. Upload Excel template ke OneDrive/SharePoint
2. Power Automate call Office Scripts untuk populate data
3. Return file URL

### Option B: Use Power Automate Excel Actions

1. Create Excel file di OneDrive
2. Add rows menggunakan "Add a row into a table"
3. Return file URL untuk download

**Flow Example:**
```
1. Create Excel file (OneDrive)
2. Create table in Excel
3. Apply to each (from SQL results)
   → Add row to Excel table
4. Get file content
5. Return to Power Apps
```

---

## 📝 File Structure

```
export_to_excel/
├── README.md                    ← Dokumentasi ini
├── power_automate/
│   └── Export_RekeningKoran_ToExcel.json  ← Flow definition (export dari Power Automate)
└── power_apps/
    └── btnExportToExcel.c       ← Button code untuk Power Apps
```

---

## 🧪 Testing

### Test Flow di Power Automate

1. Buka flow `Export_RekeningKoran_ToExcel`
2. Click **Test** → **Manually**
3. Run flow
4. Check output:
   - ✅ SQL query berhasil
   - ✅ JSON parsed dengan benar
   - ✅ File content generated
   - ✅ Response ke Power Apps berisi file

### Test dari Power Apps

1. Buka Power Apps
2. Click button "Export to Excel"
3. Check:
   - ✅ Loading indicator muncul
   - ✅ File download otomatis
   - ✅ File bisa dibuka di Excel
   - ✅ Data sesuai dengan view

---

## 🔒 Security Notes

### ✅ Keamanan Terjamin

1. **Credential hanya di Power Automate**
   - User tidak pernah lihat SQL username/password
   - Credential di-manage oleh Power Platform

2. **No direct database connection**
   - Excel tidak connect langsung ke database
   - Semua melalui Power Automate

3. **Access control**
   - Hanya user yang punya akses Power Apps bisa export
   - Bisa tambahkan role-based access di Power Apps

### ⚠️ Best Practices

1. **Limit data size**
   - Tambahkan `TOP 10000` di query jika data terlalu besar
   - Atau tambahkan filter parameter dari Power Apps

2. **Error handling**
   - Tambahkan try-catch di Power Automate
   - Return error message ke Power Apps

3. **Audit trail**
   - Log setiap export (siapa, kapan, berapa rows)
   - Bisa simpan ke audit table

---

## 🎨 Customization

### Add Filter Parameters

**Power Automate Flow Input:**
- `StartDate` (optional)
- `EndDate` (optional)
- `BTP` (optional)

**SQL Query:**
```sql
SELECT * FROM VW_MP_REKENING_KORAN
WHERE 
    (@StartDate IS NULL OR trx_date >= @StartDate)
    AND (@EndDate IS NULL OR trx_date <= @EndDate)
    AND (@BTP IS NULL OR btp = @BTP)
ORDER BY id DESC
```

**Power Apps:**
```powerappsfx
Export_RekeningKoran_ToExcel.Run(
    DatePickerStart.SelectedDate,
    DatePickerEnd.SelectedDate,
    TextInputBTP.Text
)
```

### Add Multiple Views

Bisa buat flow terpisah untuk setiap view:
- `Export_RekeningKoran_ToExcel`
- `Export_BTPReview_ToExcel`
- `Export_CustomerMaster_ToExcel`

---

## 📚 Related Documentation

- [Power Apps Quick Reference](../QUICK_REFERENCE.md)
- [Power Automate SQL Connector](https://docs.microsoft.com/en-us/connectors/sql/)
- [VW_MP_REKENING_KORAN View](../../stored_procedures/MASTER/[POWERAPPS].[dbo].[vw_MP_REKENING_KORAN].sql)

---

## 🐛 Troubleshooting

### Error: "Failed to execute SQL query"

**Solution:**
- Check SQL connection di Power Automate
- Verify view `VW_MP_REKENING_KORAN` exists
- Check SQL query syntax

### Error: "File download failed"

**Solution:**
- Check file content format (harus Base64)
- Verify Power Apps memiliki permission download
- Check browser settings (allow downloads)

### Error: "Excel file corrupted"

**Solution:**
- Pastikan CSV format benar
- Check encoding (UTF-8)
- Verify semua special characters di-handle

---

## ✅ Checklist

- [ ] SQL Server connection setup di Power Automate
- [ ] Flow `Export_RekeningKoran_ToExcel` dibuat
- [ ] Flow tested di Power Automate
- [ ] Button `btnExportToExcel` ditambahkan di Power Apps
- [ ] Test export dari Power Apps
- [ ] Verify file download berhasil
- [ ] Verify data sesuai dengan view
- [ ] Document customizations (jika ada)

---

**Last Updated:** 2025-01-XX  
**Author:** Development Team  
**Version:** 1.0

