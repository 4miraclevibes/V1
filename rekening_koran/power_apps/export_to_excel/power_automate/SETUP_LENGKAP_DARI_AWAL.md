# 📋 Setup Lengkap Flow dari Awal - Step by Step

## 🎯 Tujuan

Membuat flow yang:
1. Query database via stored procedure
2. Convert ke CSV
3. Upload ke SharePoint
4. Generate download link
5. Return link ke Power Apps

---

## ✅ Flow yang Sudah Ada (JANGAN DIUBAH)

**Action yang sudah ada dan bekerja:**
1. ✅ **Execute stored procedure (V2)** - Query database
2. ✅ **Parse JSON** - Parse hasil query
3. ✅ **Create CSV table** - Convert ke CSV
4. ✅ **Compose** - Convert ke Base64

**Action ini JANGAN DIUBAH, hanya perlu dicek apakah sudah benar!**

---

## 🔧 Action yang Perlu DITAMBAHKAN

### **ACTION BARU 1: Initialize variable `varFileName`**

**Lokasi:** Setelah "Compose" (Base64), sebelum "Create file"

**Cara tambah:**
1. Scroll ke action **"Compose"** (yang terakhir)
2. Klik **"+"** (plus sign) di bawah "Compose"
3. Pilih **"Add an action"**
4. Search: **"Initialize variable"**
5. Pilih: **"Initialize variable"**

**Configuration:**
- **Name:** `varFileName`
- **Type:** String
- **Value (Expression):** 
  - Klik icon **fx**
  - Ketik: `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')`
  - Klik **OK**

**Urutan flow setelah ini:**
```
Compose → Initialize variable (BARU!) → [Create file]
```

---

### **ACTION BARU 2: Create file (SharePoint)**

**Lokasi:** Setelah "Initialize variable", sebelum "Compose DownloadLink"

**Cara tambah:**
1. Scroll ke action **"Initialize variable"** (yang baru dibuat)
2. Klik **"+"** (plus sign) di bawah "Initialize variable"
3. Pilih **"Add an action"**
4. Search: **"Create file"**
5. Pilih: **SharePoint → Create file**

**Configuration:**
- **Site Address:** Pilih SharePoint site kamu
- **Folder Path:** `/Shared Documents/Exports` (atau folder lain)
- **File Name:** 
  - Klik field → Pilih **Dynamic content**
  - Scroll ke **Variables**
  - Pilih `varFileName`
- **File Content:** 
  - Klik field → Pilih **Dynamic content**
  - Scroll ke action **"Compose"**
  - Pilih output dari Compose
  - **Atau klik fx** → Ketik: `base64ToBinary(body('Compose'))`

**Urutan flow setelah ini:**
```
Initialize variable → Create file (BARU!) → [Compose DownloadLink]
```

---

### **ACTION BARU 3: Compose DownloadLink**

**Lokasi:** Setelah "Create file", sebelum "Respond to PowerApps"

**Cara tambah:**
1. Scroll ke action **"Create file"** (yang baru dibuat)
2. Klik **"+"** (plus sign) di bawah "Create file"
3. Pilih **"Add an action"**
4. Search: **"Compose"**
5. Pilih: **Data operation → Compose**

**Rename action:**
- Klik **"..."** (three dots) di kanan atas action
- Pilih **"Rename"**
- Ketik: `Compose DownloadLink`
- Klik **OK**

**Configuration:**
- **Input:**
  - **Cara 1 (Dynamic Content - PALING MUDAH):**
    - Klik field "Input"
    - Pilih **Dynamic content**
    - Scroll ke action **"Create file"**
    - Pilih **`body/Path`** ← INI YANG DIPILIH!
    - **Penjelasan:** `Path` adalah path lengkap file di SharePoint untuk download
  - **Cara 2 (Expression):**
    - Klik icon **fx**
    - Ketik: `body('Create_file')?['Path']`
    - Klik **OK**

**💡 PENTING:** Pilih **`body/Path`** (bukan `Id`, `Name`, atau yang lain!)

**Urutan flow setelah ini:**
```
Create file → Compose DownloadLink (BARU!) → [Respond to PowerApps]
```

---

### **ACTION BARU 4: Respond to a Power App or flow**

**Lokasi:** Setelah "Compose DownloadLink" (AKHIR FLOW!)

**Cara tambah:**
1. Scroll ke action **"Compose DownloadLink"** (yang baru dibuat)
2. Klik **"+"** (plus sign) di bawah "Compose DownloadLink"
3. Pilih **"Add an action"**
4. Search: **"Respond to Power App"**
5. Pilih: **PowerApps → Respond to a Power App or flow**

**Configuration - Tambahkan Parameter:**

**Parameter 1: `fileName`**
- Klik **"+ Add an output"**
- **Name:** `fileName`
- **Type:** Text (icon AA)
- **Value:**
  - Klik field → Pilih **Dynamic content**
  - Scroll ke **Variables**
  - Pilih `varFileName`
  - **Atau klik fx** → Ketik: `variables('varFileName')`

**Parameter 2: `sharePointLink`**
- Klik **"+ Add an output"**
- **Name:** `sharePointLink`
- **Type:** Text (icon AA)
- **Value:**
  - Klik field → Pilih **Dynamic content**
  - Scroll ke action **"Compose DownloadLink"**
  - Pilih output dari Compose DownloadLink
  - **Atau klik fx** → Ketik: `outputs('Compose_DownloadLink')`

**Parameter 3: `rowCount`**
- Klik **"+ Add an output"**
- **Name:** `rowCount`
- **Type:** Number (icon 123) ← PENTING: Number, bukan Text!
- **Value:**
  - Klik icon **fx**
  - Ketik: `length(body('Parse_JSON'))`
  - **Note:** Ganti `Parse_JSON` dengan nama action Parse JSON kamu
  - Klik **OK**

**Parameter 4: `status`**
- Klik **"+ Add an output"**
- **Name:** `status`
- **Type:** Text (icon AA)
- **Value:**
  - Langsung ketik: `success` (tanpa dynamic content atau fx)

**Urutan flow setelah ini:**
```
Compose DownloadLink → Respond to PowerApps (BARU! - AKHIR FLOW!)
```

---

## 📊 Urutan Flow Lengkap (Final)

```
1. Execute stored procedure (V2)     ← SUDAH ADA
   ↓
2. Parse JSON                         ← SUDAH ADA
   ↓
3. Create CSV table                  ← SUDAH ADA
   ↓
4. Compose (Base64)                  ← SUDAH ADA
   ↓
5. Initialize variable (varFileName) ← TAMBAH BARU!
   ↓
6. Create file (SharePoint)          ← TAMBAH BARU!
   ↓
7. Compose DownloadLink              ← TAMBAH BARU!
   ↓
8. Respond to PowerApps              ← TAMBAH BARU! (AKHIR)
```

---

## ✅ Checklist Setup

### Action yang Sudah Ada (Cek saja):
- [ ] Execute stored procedure (V2) - Sudah ada dan bekerja
- [ ] Parse JSON - Sudah ada dan bekerja
- [ ] Create CSV table - Sudah ada dan bekerja
- [ ] Compose (Base64) - Sudah ada dan bekerja

### Action yang Perlu Ditambahkan:
- [ ] Initialize variable `varFileName` - Setelah "Compose"
- [ ] Create file (SharePoint) - Setelah "Initialize variable"
- [ ] Compose DownloadLink - Setelah "Create file"
- [ ] Respond to PowerApps - Setelah "Compose DownloadLink" (AKHIR!)

### Configuration yang Perlu Dicek:
- [ ] Initialize variable: Name = `varFileName`, Type = String, Value = expression dengan timestamp
- [ ] Create file: Site Address dipilih, Folder Path diisi, File Name dari `varFileName`, File Content dari Compose
- [ ] Compose DownloadLink: Input dari `Create_file` Path
- [ ] Respond to PowerApps: 4 parameter sudah di-add (fileName, sharePointLink, rowCount, status)

---

## 🔍 Detail Setiap Action

### 1. Initialize variable `varFileName`

**Lokasi:** Setelah "Compose"

**Setup:**
- **Name:** `varFileName`
- **Type:** String
- **Value:** `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')`

---

### 2. Create file (SharePoint)

**Lokasi:** Setelah "Initialize variable"

**Setup:**
- **Site Address:** Pilih SharePoint site
- **Folder Path:** `/Shared Documents/Exports`
- **File Name:** `varFileName` (dari Variables)
- **File Content:** Output dari "Compose" atau `base64ToBinary(body('Compose'))`

---

### 3. Compose DownloadLink

**Lokasi:** Setelah "Create file"

**Setup:**
- **Rename:** `Compose DownloadLink`
- **Input:** `body('Create_file')?['Path']` atau dynamic content Path dari "Create file"

---

### 4. Respond to PowerApps

**Lokasi:** Setelah "Compose DownloadLink" (AKHIR!)

**Setup:**
- **Parameter 1:** `fileName` (Text) → `varFileName` dari Variables
- **Parameter 2:** `sharePointLink` (Text) → Output dari "Compose DownloadLink"
- **Parameter 3:** `rowCount` (Number) → `length(body('Parse_JSON'))`
- **Parameter 4:** `status` (Text) → `success`

---

## 🎯 Summary: Yang Perlu Dilakukan

1. **TAMBAH** Initialize variable setelah "Compose"
2. **TAMBAH** Create file setelah "Initialize variable"
3. **TAMBAH** Compose DownloadLink setelah "Create file"
4. **TAMBAH** Respond to PowerApps setelah "Compose DownloadLink" (AKHIR!)
5. **CEK** semua action yang sudah ada (jangan diubah, hanya dicek)

---

**Ikuti urutan ini step by step, flow akan bekerja dengan benar! 🎯**

