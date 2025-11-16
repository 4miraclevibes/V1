# 🎯 SOLUSI FINAL - Download via SharePoint (Bypass CSP Blob Block)

## ✅ Masalah

**CSP (Content Security Policy) di Power Apps memblokir:**
- ❌ `blob:` URLs
- ❌ JavaScript `URL.createObjectURL()`
- ❌ Data URI untuk download

**Solusi:** Upload file ke SharePoint, download dari SharePoint link!

---

## 🔧 Setup (2 Bagian)

### BAGIAN 1: Update Power Automate Flow

**File:** `FLOW_STEPS_SHAREPOINT.md`

**Perubahan:**
1. Setelah convert ke Base64, **upload file ke SharePoint**
2. **Generate SharePoint link**
3. **Return SharePoint link** ke Power Apps (bukan Base64)

**Flow Steps:**
```
SQL Query → Parse JSON → Create CSV → Convert Base64 
→ Upload to SharePoint → Get File Link → Respond to PowerApps
```

**Response dari Flow:**
```json
{
    "fileName": "RekeningKoran_Export_20250115_123456.csv",
    "sharePointLink": "https://yourcompany.sharepoint.com/.../file.csv",
    "rowCount": 100,
    "status": "success"
}
```

---

### BAGIAN 2: Update Power Apps Button

**File:** `btnDownloadFromSharePoint.c`

**Code:**
```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.sharePointLink),
    Download(varExportResult.sharePointLink);
    Notify("✅ Download started!", NotificationType.Success, 3000),
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

**Penjelasan:**
- `Download()` function di Power Apps **SUPPORT SharePoint link** ✅
- Tidak perlu HTML Text control
- Tidak perlu JavaScript
- Langsung download ke folder Downloads!

---

## 📋 Step-by-Step Setup

### STEP 1: Setup SharePoint Folder

1. Buka SharePoint site
2. Navigate ke **Documents** atau **Shared Documents**
3. Buat folder: **Exports**
4. Set permissions: **Everyone** bisa read (atau sesuai kebutuhan)

---

### STEP 2: Update Power Automate Flow

1. Buka flow `Export_RekeningKoran_ToExcel`
2. Setelah action **"Compose"** (Convert to Base64), tambahkan:

   **Action:** SharePoint → **Create file**
   - **Site Address:** Pilih SharePoint site
   - **Folder Path:** `/Shared Documents/Exports`
   - **File Name:** `@{variables('varFileName')}`
   - **File Content:** `@{base64ToBinary(body('Compose'))}`

3. **SKIP STEP INI** - Langsung ke STEP 4!

   **Note:** Output dari "Create file" sudah mengandung link, tidak perlu action terpisah.

4. Tambahkan **Compose** untuk ambil link dari output "Create file":

   **Action:** Data operation → **Compose**
   
   **Input (Pilih salah satu):**
   
   **Option A - Langsung dari Create file (PALING SIMPLE):**
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
   
   **Option C - Gunakan Create sharing link (jika Option A/B tidak bekerja):**
   
   Setelah "Create file", tambahkan:
   - **Action:** SharePoint → **Create sharing link for a file or folder**
     - **Site Address:** Same as above
     - **File Identifier:** `@{body('Create_file')?['Id']}`
     - **Link Type:** `View`
     - **Scope:** `Organization`
   
   Lalu di Compose, gunakan:
   ```
   body('Create_sharing_link_for_a_file_or_folder')?['link']?['webUrl']
   ```
   
   **💡 TIP:** Test dulu Option A, jika tidak bekerja coba Option B atau C.

5. Update **Respond to PowerApps**:

   **Action:** PowerApps → **Respond to PowerApps**
   
   **Tambahkan Parameters (klik "Add an output" untuk setiap parameter):**
   
   **Parameter 1: `fileName`**
   - **Type:** Text (icon AA)
   - **Value:** 
     - **Cara 1 (Dynamic Content):** Klik field → Pilih **Dynamic content** → Pilih `varFileName` dari **Variables**
     - **Cara 2 (Expression):** Klik **fx** → Ketik: `variables('varFileName')`
   
   **Parameter 2: `sharePointLink`**
   - **Type:** Text (icon AA)
   - **Value:**
     - **Cara 1 (Dynamic Content):** Klik field → Pilih **Dynamic content** → Pilih output dari action **Compose** (nama action Compose kamu)
     - **Cara 2 (Expression):** Klik **fx** → Ketik: `outputs('Compose')` (ganti `Compose` dengan nama action Compose kamu)
     - **Note:** Jika nama action Compose-nya `Compose_DownloadLink`, maka: `outputs('Compose_DownloadLink')`
   
   **Parameter 3: `rowCount`**
   - **Type:** Number (icon 123)
   - **Value:**
     - **Cara 1 (Expression - RECOMMENDED):** Klik **fx** → Ketik: `length(body('Parse_JSON'))`
     - **Cara 2 (Dynamic Content + Expression):** Klik field → Pilih **Dynamic content** → Pilih output dari **Parse JSON** → Klik **fx** → Wrap dengan `length(...)`
   
   **Parameter 4: `status`**
   - **Type:** Text (icon AA)
   - **Value:**
     - **Cara 1 (Static Text):** Langsung ketik: `success` (tanpa dynamic content atau fx)
     - **Cara 2 (Expression):** Klik **fx** → Ketik: `'success'` (dengan tanda kutip)
   
   **💡 TIP:**
   - Untuk **variable** → Pakai Dynamic Content (lebih mudah) atau Expression `variables('varName')`
   - Untuk **output action** → Pakai Dynamic Content (lebih mudah) atau Expression `outputs('ActionName')`
   - Untuk **function/expression** → Pakai **fx** Expression (contoh: `length()`, `concat()`, dll)
   - Untuk **static text** → Langsung ketik tanpa dynamic content atau fx

---

### STEP 3: Update Power Apps Button

**Button Name:** `btnExportToExcel`

**OnSelect:** (Gunakan code dari `btnDownloadFromSharePoint.c`)

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.sharePointLink),
    Download(varExportResult.sharePointLink);
    Notify("✅ Download started!", NotificationType.Success, 3000),
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

**PENTING:**
- Hapus HTML Text control (tidak perlu lagi!)
- Hapus variable `varTriggerDownload`, `varDownloadData`, dll (tidak perlu lagi!)
- Hanya perlu `varExportResult`

---

## ✅ Keuntungan Solusi Ini

1. ✅ **Bypass CSP** - Tidak perlu blob URL atau JavaScript
2. ✅ **Download langsung** - File langsung ke folder Downloads
3. ✅ **Lebih reliable** - Menggunakan `Download()` function yang native
4. ✅ **File tersimpan** - File juga tersimpan di SharePoint (backup)
5. ✅ **Lebih sederhana** - Tidak perlu HTML Text control

---

## 🔍 Troubleshooting

### Error: "File not found" atau "Access denied"

**Solusi:**
- Check SharePoint folder permissions
- Pastikan Power Automate connection punya akses ke SharePoint
- Check file path di action "Create file"

### Error: "Invalid link format"

**Solusi:**
- Check output dari action "Get file properties"
- Pastikan property `{Link}` atau `{Path}` ada
- Coba gunakan `body('Create_file')?['{Link}']` langsung

### Download tidak bekerja

**Solusi:**
- Pastikan SharePoint link format benar
- Check apakah link bisa diakses di browser
- Pastikan `Download()` function menerima SharePoint link (bukan data URI)

---

## 📝 Catatan Penting

1. **File Cleanup:**
   - File akan tetap tersimpan di SharePoint
   - Pertimbangkan cleanup otomatis (delete file lama setelah 7 hari)

2. **Permissions:**
   - User yang run flow harus punya permission untuk upload ke SharePoint
   - User yang download harus punya permission untuk read file

3. **Performance:**
   - Upload ke SharePoint membutuhkan waktu tambahan (~2-5 detik)
   - Tapi lebih reliable daripada blob URL

---

## ✅ Checklist

- [ ] SharePoint folder dibuat
- [ ] Power Automate flow updated (upload ke SharePoint)
- [ ] SharePoint link di-return ke Power Apps
- [ ] Power Apps button updated (gunakan `Download()` dengan SharePoint link)
- [ ] HTML Text control dihapus (tidak perlu lagi)
- [ ] Tested end-to-end
- [ ] File ter-download langsung ke Downloads folder

---

**Solusi ini bypass CSP blob block dengan upload ke SharePoint! 🎉**

