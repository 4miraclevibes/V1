# 📋 Setup Export Jurnal CSV Pipe – Power Apps + Power Automate

Panduan setup flow export jurnal ke CSV dengan **separator pipe (|)** via **SP_EXPORT_JURNAL_CSV_PIPE**.

---

## 🎯 Perbedaan dengan flow standar

| Aspek | Flow standar (SP_EXPORT_JURNAL) | Flow Pipe (SP_EXPORT_JURNAL_CSV_PIPE) |
|-------|---------------------------------|--------------------------------------|
| SP | SP_EXPORT_JURNAL | **SP_EXPORT_JURNAL_CSV_PIPE** |
| Output SP | Banyak baris (array) | **1 baris, 1 kolom (CSVContent)** |
| Parse JSON | Perlu | **Tidak perlu** |
| Create CSV table | Perlu | **Tidak perlu** |
| Separator | Comma | **Pipe (\|)** |
| Nama file | .csv | .csv atau .psv |

---

## 📌 Prasyarat

- **SP_EXPORT_JURNAL_CSV_PIPE** sudah di-deploy (jalankan `SP_EXPORT_JURNAL_CSV_PIPE.sql` di SSMS)
- Power Automate terhubung ke SQL Server
- SharePoint site & folder export sudah tersedia

---

## ✅ Urutan flow (6 action)

| # | Action | Keterangan |
|---|--------|------------|
| 1 | **When Power Apps calls a flow (V2)** | Trigger; input: StartDate, EndDate (opsional) |
| 2 | **Execute stored procedure (V2)** | Panggil **SP_EXPORT_JURNAL_CSV_PIPE** |
| 3 | **Compose (CSV to Base64)** | Ambil CSVContent dari hasil SP, encode ke Base64 |
| 4 | **Initialize variable** | `varFileName` = Jurnal_Export_yyyyMMdd_HHmmss.psv |
| 5 | **Create file** (SharePoint) | Simpan CSV; File Content = base64ToBinary |
| 6 | **Respond to a Power App or flow** | Output: fileName, sharePointLink, status |

---

## 🔧 Step-by-step

### STEP 1: Trigger – Power Apps (V2)

**Input (Add input → Text):**
- `StartDate` (Optional)
- `EndDate` (Optional)

---

### STEP 2: Execute stored procedure (V2)

- **Procedure:** `[dbo].[SP_EXPORT_JURNAL_CSV_PIPE]`
- **Parameters:**
  - `StartDate` = `triggerBody()?['StartDate']` (atau `null`)
  - `EndDate` = `triggerBody()?['EndDate']` (atau `null`)

---

### STEP 3: Compose (CSV to Base64)

**Action:** Data operation → **Compose**

**Input (Expression – fx):**
```
base64(
  coalesce(
    first(body('Execute_stored_procedure_(V2)')?['ResultSets']?['Table1'])?['CSVContent'],
    ''
  )
)
```

*(Ganti `Execute_stored_procedure_(V2)` dengan nama action Execute SP di flow kamu.)*

**Penjelasan:** SP return 1 row, kolom `CSVContent`. Kita ambil baris pertama, kolom CSVContent, lalu encode Base64.

---

### STEP 4: Initialize variable

- **Name:** `varFileName`
- **Type:** String
- **Value (Expression):**
```
concat('Jurnal_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.psv')
```

*(Bisa juga `.csv` jika prefer.)*

---

### STEP 5: Create file (SharePoint)

- **Site Address:** Pilih site
- **Folder Path:** mis. `/Shared Documents/Exports` atau `Exports/Jurnal`
- **File Name:** `variables('varFileName')`
- **File Content (Expression):**
```
base64ToBinary(outputs('Compose'))
```

*(Ganti `Compose` dengan nama action Compose di step 3.)*

---

### STEP 6: Respond to a Power App or flow

**Outputs:**

| Name | Type | Value |
|------|------|--------|
| fileName | Text | `variables('varFileName')` |
| sharePointLink | Text | `body('Create_file')?['Path']` |
| status | Text | `'success'` |

*(Untuk rowCount bisa ditambah jika diperlukan, tapi SP pipe return 1 row jadi rowCount kurang berguna.)*

---

## 📱 Power Apps – Tombol Export

### OnSelect tombol Export Jurnal (CSV Pipe)

```powerappsfx
// Panggil flow export jurnal CSV pipe
Set(varLoading, true);
Set(varExportStatus, "Exporting...");

// Panggil flow (sesuaikan nama flow)
ExportJurnalCSVPipe.Run(
    StartDate: If(IsBlank(dpStartDate), "", Text(dpStartDate, "yyyy-mm-dd")),
    EndDate: If(IsBlank(dpEndDate), "", Text(dpEndDate, "yyyy-mm-dd"))
);

// Setelah flow selesai (jika pakai OnSuccess)
Set(varLoading, false);
Set(varExportStatus, "Exported: " & ExportJurnalCSVPipe.fileName);
Set(varSharePointLink, ExportJurnalCSVPipe.sharePointLink);
```

### Variabel di Power Apps

- `varSharePointLink` – untuk tampil link download
- `varExportStatus` – status export
- `varLoading` – loading state

### Tampilkan link download

```powerappsfx
If(
    !IsBlank(varSharePointLink),
    Navigate(ScrSuccess, ScreenTransition.None),
    Notify("Export gagal", NotificationType.Error)
)
```

Di layar `ScrSuccess`, tambah **Hyperlink** atau **Button**:

```powerappsfx
// Text: "Download Jurnal Export"
// OnSelect: Launch(varSharePointLink)
```

---

## 📊 Diagram flow

```
┌─────────────────────────────┐
│ PowerApps (V2) Trigger      │  StartDate, EndDate (optional)
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Execute stored procedure    │  SP_EXPORT_JURNAL_CSV_PIPE
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Compose (CSV to Base64)     │  base64(first(...)?['CSVContent'])
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Initialize varFileName      │  Jurnal_Export_yyyyMMdd_HHmmss.psv
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Create file (SharePoint)    │  base64ToBinary(Compose)
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Respond to PowerApps        │  fileName, sharePointLink, status
└─────────────────────────────┘
```

---

## ⚠️ Catatan

- **Nama kolom di result:** SQL Server bisa return `CSVContent` atau `CSVcontent` (case). Jika error, cek output Execute SP dan sesuaikan path di Compose.
- **Encoding:** CSV dari SP memakai NVARCHAR; Base64 encode menjaga karakter UTF-8.
- **Gateway:** Untuk SQL on-premises, pakai connector yang support stored procedure (V2).
