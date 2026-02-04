# 📋 Setup Lengkap Flow Export Jurnal ke CSV - Step by Step

## 🎯 Tujuan

Membuat flow yang:
1. Query data jurnal dari database via **SP_EXPORT_JURNAL**
2. Convert hasil ke CSV
3. Upload CSV ke SharePoint
4. Generate download link
5. Return link ke Power Apps

---

## 📌 Prasyarat

- **SP_EXPORT_JURNAL** sudah di-deploy di database (jalankan `SP_EXPORT_JURNAL.sql` di SSMS).
- Power Automate terhubung ke SQL (on-premises gateway bila perlu).
- SharePoint site & folder untuk export sudah siap.

---

## ✅ Flow yang Sudah Ada (JANGAN DIUBAH)

**Action yang sudah ada dan bekerja:**
1. ✅ **Execute stored procedure (V2)** – Panggil **SP_EXPORT_JURNAL**
2. ✅ **Parse JSON** – Parse hasil query
3. ✅ **Create CSV table** – Convert ke CSV
4. ✅ **Compose** – Convert ke Base64

**Action ini JANGAN DIUBAH, hanya perlu dicek apakah sudah benar!**

**Cek Execute stored procedure (V2):**
- **Stored procedure:** Pilih **SP_EXPORT_JURNAL**
- **Parameter (opsional):**
  - `StartDate` – dari Power Apps atau kosong (export semua tanggal)
  - `EndDate` – dari Power Apps atau kosong

---

## 🔧 Action yang Perlu DITAMBAHKAN

### **ACTION BARU 1: Initialize variable `varFileName`**

**Lokasi:** Setelah "Compose" (Base64), sebelum "Create file"

**Cara tambah:**
1. Scroll ke action **"Compose"**
2. Klik **"+"** di bawah "Compose" → **Add an action**
3. Search: **Initialize variable** → Pilih **Initialize variable**

**Configuration:**
- **Name:** `varFileName`
- **Type:** String
- **Value (Expression – klik fx):**
  ```
  concat('Jurnal_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')
  ```

**Urutan:** `Compose → Initialize variable (BARU!) → [Create file]`

---

### **ACTION BARU 2: Create file (SharePoint)**

**Lokasi:** Setelah "Initialize variable", sebelum "Compose DownloadLink"

**Cara tambah:**
1. Di bawah "Initialize variable" → **+** → **Add an action**
2. Search: **Create file** → Pilih **SharePoint – Create file**

**Configuration:**
- **Site Address:** Pilih SharePoint site
- **Folder Path:** `/Shared Documents/Exports` (atau folder lain, mis. `Exports/Jurnal`)
- **File Name:** Dynamic content → **Variables** → `varFileName`
- **File Content:** Dynamic content → **Compose** (output) atau expression: `base64ToBinary(body('Compose'))`

**Urutan:** `Initialize variable → Create file (BARU!) → [Compose DownloadLink]`

---

### **ACTION BARU 3: Compose DownloadLink**

**Lokasi:** Setelah "Create file", sebelum "Respond to PowerApps"

**Cara tambah:**
1. Di bawah "Create file" → **+** → **Add an action** → **Compose**
2. Rename action: **Compose DownloadLink**

**Configuration:**
- **Input:** Dynamic content dari action **Create file** → pilih **Path**  
  Atau expression: `body('Create_file')?['Path']`

**Urutan:** `Create file → Compose DownloadLink (BARU!) → [Respond to PowerApps]`

---

### **ACTION BARU 4: Respond to a Power App or flow**

**Lokasi:** Setelah "Compose DownloadLink" (AKHIR FLOW)

**Cara tambah:**
1. Di bawah "Compose DownloadLink" → **+** → **Add an action**
2. Search: **Respond to Power App** → Pilih **Respond to a Power App or flow**

**Configuration – Tambahkan 4 output:**

| Name             | Type   | Value                                      |
|------------------|--------|--------------------------------------------|
| `fileName`       | Text   | `variables('varFileName')`                  |
| `sharePointLink` | Text   | Output dari **Compose DownloadLink**       |
| `rowCount`       | Number | `length(body('Parse_JSON'))`               |
| `status`         | Text   | `success`                                  |

*(Ganti `Parse_JSON` dengan nama action Parse JSON di flow kamu bila beda.)*

**Urutan:** `Compose DownloadLink → Respond to PowerApps (AKHIR!)`

---

## 📊 Urutan Flow Lengkap (Final)

```
1. Execute stored procedure (V2)   ← Panggil SP_EXPORT_JURNAL
   ↓
2. Parse JSON                      ← Parse hasil query
   ↓
3. Create CSV table               ← Convert ke CSV
   ↓
4. Compose (Base64)                ← Convert ke Base64
   ↓
5. Initialize variable (varFileName) ← Jurnal_Export_yyyyMMdd_HHmmss.csv
   ↓
6. Create file (SharePoint)        ← Simpan CSV
   ↓
7. Compose DownloadLink            ← Ambil Path file
   ↓
8. Respond to PowerApps            ← Return fileName, sharePointLink, rowCount, status
```

---

## 📋 Output SP_EXPORT_JURNAL (untuk Parse JSON)

SP mengembalikan hanya kolom **document data** dengan nama berikut (gunakan untuk schema Parse JSON jika generate from sample):

- `DocumentDate`, `DocumentType`, `CompanyCode`, `PostingDate`, `Currency`, `CountryGrouping`, `Reference`, `Material`, `DocumentHeaderText`, `PostingKey`, `Customer`, `Account`, `Special`, `Amount`, `ValueDate`, `Assignment`, `Text`, `ProfitCenter`, `CostCenter`, `Order`, `TaxCode`, `Customer2`, `SalesOrganization`, `ReasonCode`

**Tip:** Jalankan sekali flow dengan **Execute SP** saja, lalu di action **Parse JSON** pilih **Use sample payload to generate schema** dan paste hasil dari run tersebut.

---

## ✅ Checklist Setup

### Action yang sudah ada (cek saja)
- [ ] Execute stored procedure (V2) – memanggil **SP_EXPORT_JURNAL**, parameter opsional
- [ ] Parse JSON – schema sesuai output SP_EXPORT_JURNAL
- [ ] Create CSV table – input dari Parse JSON
- [ ] Compose (Base64) – input dari Create CSV table

### Action yang perlu ditambahkan
- [ ] Initialize variable `varFileName` – value: `Jurnal_Export_` + timestamp + `.csv`
- [ ] Create file (SharePoint) – File Name = varFileName, File Content = Compose
- [ ] Compose DownloadLink – Input = Create file → Path
- [ ] Respond to PowerApps – 4 output: fileName, sharePointLink, rowCount, status

### Konfigurasi
- [ ] Nama file: **Jurnal_Export_** (bukan RekeningKoran_Export_)
- [ ] Stored procedure: **SP_EXPORT_JURNAL**
- [ ] Respond to PowerApps: rowCount pakai **Number**, bukan Text

---

## 🎯 Ringkasan

1. **SP:** Pastikan **SP_EXPORT_JURNAL** sudah ada di database.
2. **Flow:** Execute SP → Parse JSON → Create CSV table → Compose Base64 → Initialize varFileName → Create file → Compose DownloadLink → Respond to PowerApps.
3. **File name:** `Jurnal_Export_yyyyMMdd_HHmmss.csv`.
4. **Parameter SP (opsional):** StartDate, EndDate.

Ikuti urutan di atas step by step, flow export jurnal ke CSV siap dipakai dari Power Apps.

---

# 🔄 Flow Steps - Export Jurnal ke CSV (Step-by-Step)

## Flow Name

`Export_Jurnal_ToCSV` (atau nama lain yang dipakai di Power Automate)

---

## 📋 Flow Overview

| Item | Keterangan |
|------|------------|
| **Trigger** | PowerApps (V2) |
| **Purpose** | Query data jurnal via SP_EXPORT_JURNAL, convert ke CSV, upload ke SharePoint, return link |
| **Output ke Power Apps** | fileName, sharePointLink, rowCount, status |

---

## 🔧 Step-by-Step Configuration

### STEP 1: Trigger – PowerApps (V2)

Trigger otomatis ada saat flow dibuat dengan "PowerApps (V2)".

**Input parameters (opsional):**

1. Klik trigger **PowerApps (V2)** → panel kanan → **Inputs** → **Add an input** → **Text**
2. Tambah:
   - `StartDate` (Text, Optional) – filter tanggal mulai
   - `EndDate` (Text, Optional) – filter tanggal akhir

Bisa dikosongkan jika mau export semua tanggal.

---

### STEP 2: Execute stored procedure (V2)

**Action:** SQL Server → **Execute stored procedure (V2)**

**Configuration:**

- **Procedure name:** `[dbo].[SP_EXPORT_JURNAL]`
- **Parameters:**
  - `StartDate` = `@{triggerBody()?['StartDate']}` (atau kosong)
  - `EndDate` = `@{triggerBody()?['EndDate']}` (atau kosong)

**Note:** Pastikan SP_EXPORT_JURNAL sudah di-deploy (script di `SP_EXPORT_JURNAL.sql`).

---

### STEP 3: Parse JSON

**Action:** Data operation → **Parse JSON**

**Content:**
```
@body('Execute_stored_procedure_(V2)')?['ResultSets']?['Table1']
```
(Ganti nama action jika beda, mis. `Execute_stored_procedure_(V2)`)

**Schema:** Gunakan **Generate from sample** dan paste output dari run STEP 2, atau definisikan sesuai kolom document data (DocumentDate, DocumentType, CompanyCode, dll.).

---

### STEP 4: Create CSV table

**Action:** Data operation → **Create CSV table**

- **From:** `@body('Parse_JSON')` (atau output Parse JSON)
- **Columns:** Auto-detect
- **Delimiter:** Comma (`,`)
- **Encoding:** UTF-8

---

### STEP 5: Compose (Base64)

**Action:** Data operation → **Compose**

**Input (Expression – klik fx):**
```
base64(body('Create_CSV_table'))
```
(Ganti `Create_CSV_table` dengan nama action Create CSV table di flow kamu.)

---

### STEP 6: Initialize variable `varFileName`

**Action:** Initialize variable

- **Name:** `varFileName`
- **Type:** String
- **Value (Expression):** `concat('Jurnal_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')`

---

### STEP 7: Create file (SharePoint)

**Action:** SharePoint → **Create file**

- **Site Address:** Pilih site
- **Folder Path:** mis. `/Shared Documents/Exports` atau `Exports/Jurnal`
- **File Name:** `variables('varFileName')`
- **File Content:** `base64ToBinary(body('Compose'))` (output Compose Base64)

---

### STEP 8: Compose DownloadLink

**Action:** **Compose** (rename: Compose DownloadLink)

**Input:** `body('Create_file')?['Path']` (path file yang baru dibuat)

---

### STEP 9: Respond to a Power App or flow

**Action:** PowerApps → **Respond to a Power App or flow**

**Outputs:**

| Name | Type | Value |
|------|------|--------|
| fileName | Text | `variables('varFileName')` |
| sharePointLink | Text | Output **Compose DownloadLink** |
| rowCount | Number | `length(body('Parse_JSON'))` |
| status | Text | `success` |

---

## 📊 Flow Diagram

```
┌─────────────────────────┐
│ PowerApps (V2) Trigger  │  StartDate, EndDate (optional)
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Execute stored proc (V2) │  SP_EXPORT_JURNAL
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Parse JSON              │  ResultSets/Table1
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Create CSV table        │  UTF-8, comma
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Compose (Base64)        │  base64(...)
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Initialize varFileName  │  Jurnal_Export_yyyyMMdd_HHmmss.csv
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Create file (SharePoint)│  Simpan CSV
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Compose DownloadLink    │  Path file
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Respond to PowerApps    │  fileName, sharePointLink, rowCount, status
└─────────────────────────┘
```

---

## 🧪 Testing

1. **Test manual:** Power Automate → Test → Manually → Run flow. Cek tiap step (SP return data, Parse OK, CSV & file terbentuk, Respond berisi link).
2. **Test dari Power Apps:** Klik tombol export jurnal → pastikan flow jalan, file ter-upload, dan link/fileName/rowCount kembali ke app.

---

## 📝 Notes

- **Gateway:** Untuk SQL on-premises, wajib pakai **Execute stored procedure (V2)**; "Execute SQL query" tidak didukung.
- **Encoding:** CSV pakai UTF-8 agar karakter khusus benar.
- **Parameter:** Hanya StartDate dan EndDate; kosongkan untuk export semua tanggal.
