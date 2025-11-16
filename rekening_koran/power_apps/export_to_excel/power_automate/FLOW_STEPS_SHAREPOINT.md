# 🔄 Power Automate Flow - Upload ke SharePoint & Return Link

## Flow Name: `Export_RekeningKoran_ToExcel`

**Perubahan:** Upload file ke SharePoint, return SharePoint link untuk download

---

## 🔧 Step-by-Step Configuration

### STEP 1-5: Sama seperti sebelumnya
(Trigger, SQL Query, Parse JSON, Create CSV, Convert to Base64)

---

### STEP 6: Create File Name Variable

**Action:** Initialize variable

**Name:** `varFileName`  
**Type:** String  
**Value:**
```
concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')
```

---

### STEP 7: Upload File to SharePoint

**Action:** SharePoint → **Create file**

**Configuration:**

1. **Site Address:** Pilih SharePoint site (contoh: `https://yourcompany.sharepoint.com/sites/YourSite`)
2. **Folder Path:** `/Shared Documents/Exports` (atau folder lain yang diinginkan)
3. **File Name:** 
   ```
   @{variables('varFileName')}
   ```
4. **File Content:** 
   ```
   @{base64ToBinary(body('Compose'))}
   ```
   **Note:** `Compose` adalah action dari STEP 5 (Convert to Base64)

**Penjelasan:**
- `base64ToBinary()` convert Base64 string ke binary untuk upload
- File akan tersimpan di SharePoint folder

---

### STEP 8: Create Download Link

**Action:** Data operation → **Compose**

**💡 PENTING:** Langsung ambil dari output "Create file", tidak perlu action terpisah!

**Input (Pilih salah satu yang bekerja):**

**Option A - Langsung dari Create file (PALING SIMPLE - COBA INI DULU!):**
```
body('Create_file')?['Path']
```
**Atau:**
```
body('Create_file')?['{Link}']
```

**Option B - Buat download link manual:**
```
concat(
    'https://yourcompany.sharepoint.com/sites/YourSite/_layouts/15/download.aspx?SourceUrl=',
    encodeUriComponent(body('Create_file')?['Path']),
    '&download=1'
)
```
**Note:** Ganti `yourcompany.sharepoint.com` dan `YourSite` dengan SharePoint site kamu

**Option C - Gunakan Create sharing link (jika Option A/B tidak bekerja):**

**Action:** SharePoint → **Create sharing link for a file or folder**
- **Site Address:** Same as STEP 7
- **File Identifier:** `@{body('Create_file')?['Id']}`
- **Link Type:** `View`
- **Scope:** `Organization`

Lalu di Compose, gunakan:
```
body('Create_sharing_link_for_a_file_or_folder')?['link']?['webUrl']
```

**💡 TIP:** 
- Test dulu Option A dengan check output dari "Create file" action
- Klik output "Create file" → lihat properties yang tersedia
- Biasanya ada `Path`, `{Link}`, atau `{WebUrl}` yang bisa digunakan

---

### STEP 10: Respond to PowerApps

**Action:** PowerApps → **Respond to PowerApps**

**Tambahkan Parameters (klik "Add an output" untuk setiap parameter):**

**Parameter 1: `fileName`**
- **Type:** Text (icon AA - purple)
- **Value:** `@{variables('varFileName')}`

**Parameter 2: `sharePointLink`**
- **Type:** Text (icon AA - purple)
- **Value:** `@{outputs('Compose_DownloadLink')}`
- **Note:** Ganti `Compose_DownloadLink` dengan nama action Compose kamu

**Parameter 3: `rowCount`**
- **Type:** Number (icon 123 - purple)
- **Value:** `@{length(body('Parse_JSON'))}`

**Parameter 4: `status`**
- **Type:** Text (icon AA - purple)
- **Value:** `success`

**Optional Parameter 5: `exportDate`**
- **Type:** Date (icon calendar - blue)
- **Value:** `@{utcNow()}`

**Penjelasan:**
- `sharePointLink` adalah link langsung ke file di SharePoint (Type: **Text**)
- Power Apps bisa menggunakan `Download()` function dengan link ini
- Semua parameter harus di-add satu per satu dengan type yang sesuai

---

## 🔄 Alternative: Generate Share Link (Jika perlu public link)

### STEP 8B: Create Sharing Link

**Action:** SharePoint → **Create sharing link for a file or folder**

**Configuration:**

1. **Site Address:** Same as STEP 7
2. **File Identifier:** 
   ```
   @{body('Create_file')?['Id']}
   ```
3. **Link Type:** `View` atau `Edit`
4. **Scope:** `Organization` (atau `Anonymous` jika perlu public)

**Output:** Link akan otomatis di-generate di `body('Create_sharing_link')?['link']?['webUrl']`

---

## 📊 Flow Diagram

```
┌─────────────────────┐
│ PowerApps Trigger   │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Execute SQL Query   │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│   Parse JSON        │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  Create CSV Table   │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Convert to Base64   │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Upload to SharePoint│ ← NEW!
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Get File Properties │ ← NEW!
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Create Download Link│ ← NEW!
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Respond to PowerApps│ ← Return SharePoint link
└─────────────────────┘
```

---

## 🧪 Testing

### Test Manually

1. Run flow di Power Automate
2. Check:
   - ✅ File ter-upload ke SharePoint
   - ✅ Link di-generate dengan benar
   - ✅ Link bisa diakses

### Test from Power Apps

1. Klik button export
2. Check:
   - ✅ Flow return SharePoint link
   - ✅ `Download()` function bekerja dengan link SharePoint
   - ✅ File ter-download langsung

---

## ⚙️ Setup SharePoint Folder

### Buat Folder di SharePoint

1. Buka SharePoint site
2. Navigate ke **Documents** atau **Shared Documents**
3. Buat folder baru: **Exports**
4. Set permissions sesuai kebutuhan (biasanya semua user bisa read)

---

## 📝 Notes

1. **Permissions:**
   - Pastikan Power Automate connection punya akses ke SharePoint
   - User yang run flow harus punya permission untuk upload file

2. **File Cleanup:**
   - File akan tetap tersimpan di SharePoint
   - Pertimbangkan cleanup otomatis (delete file lama setelah X hari)

3. **Link Format:**
   - SharePoint link biasanya format: `https://...sharepoint.com/.../filename.csv`
   - `Download()` function di Power Apps support SharePoint link

---

## ✅ Checklist

- [ ] SharePoint folder dibuat
- [ ] Power Automate connection ke SharePoint configured
- [ ] Flow updated dengan upload ke SharePoint
- [ ] Link generation tested
- [ ] Power Apps button updated untuk download dari SharePoint link
- [ ] Tested end-to-end

---

**Last Updated:** 2025-01-XX  
**Version:** 2.0 (SharePoint Integration)

