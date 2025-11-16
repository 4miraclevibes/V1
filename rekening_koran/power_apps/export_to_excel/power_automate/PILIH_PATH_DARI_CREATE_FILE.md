# 📋 Pilih Path dari "Create file" untuk Compose DownloadLink

## ✅ Yang Harus Dipilih

**Untuk "Compose DownloadLink" → Input:**

**Pilih:** `body/Path` dari "Create file"

---

## 🎯 Detail Output dari "Create file"

Dari screenshot, ada banyak output dari "Create file":

| Output | Deskripsi | Dipakai untuk? |
|--------|-----------|----------------|
| `body/ItemId` | ID untuk Get/Update file | ❌ Tidak dipakai |
| `body/Id` | Unique ID file | ❌ Tidak dipakai |
| `body/Name` | Nama file saja | ❌ Tidak dipakai |
| `body/DisplayName` | Display name file | ❌ Tidak dipakai |
| **`body/Path`** | **Path lengkap file di SharePoint** | ✅ **INI YANG DIPILIH!** |
| `body/LastModified` | Tanggal modifikasi | ❌ Tidak dipakai |

---

## 🔧 Cara Pilih

### **Cara 1: Dynamic Content (PALING MUDAH)**

1. **Buka action "Compose DownloadLink"**
2. **Klik field "Input"**
3. **Pilih Dynamic content** (panel kanan muncul)
4. **Scroll ke action "Create file"**
5. **Pilih `body/Path`** ← INI YANG DIPILIH!
6. **Selesai!**

**Visual:**
```
Compose DownloadLink
  Input: [Klik di sini]
    ↓
Dynamic content panel:
  Create file
    body/ItemId
    body/Id
    body/Name
    body/DisplayName
    body/Path  ← KLIK INI!
    body/LastModified
```

---

### **Cara 2: Expression (fx)**

1. **Buka action "Compose DownloadLink"**
2. **Klik icon fx** (di kanan field Input)
3. **Ketik:**
   ```
   body('Create_file')?['Path']
   ```
4. **Klik OK**

**Note:** Ganti `Create_file` dengan nama action "Create file" kamu jika berbeda.

---

## 💡 Kenapa Pilih `Path`?

**`body/Path`** berisi:
- Path lengkap file di SharePoint
- Format: `/sites/SiteName/Shared Documents/Exports/filename.csv`
- Bisa digunakan untuk download link SharePoint

**Contoh value `Path`:**
```
/sites/YourSite/Shared Documents/Exports/RekeningKoran_Export_20250115_123456.csv
```

**Contoh value `Id`:**
```
12345-67890-abcdef
```
❌ Ini hanya ID, bukan path untuk download!

---

## ✅ Checklist

- [ ] Buka action "Compose DownloadLink"
- [ ] Klik field "Input"
- [ ] Pilih Dynamic content
- [ ] Scroll ke "Create file"
- [ ] Pilih **`body/Path`** (bukan yang lain!)
- [ ] Selesai!

---

## ⚠️ Common Mistakes

### ❌ Salah: Pilih `Id`
```
Input: body/Id  ← SALAH! Ini hanya ID, bukan path
```

### ❌ Salah: Pilih `Name`
```
Input: body/Name  ← SALAH! Ini hanya nama file, bukan path lengkap
```

### ✅ Benar: Pilih `Path`
```
Input: body/Path  ← BENAR! Ini path lengkap untuk download
```

---

## 🎯 Summary

**Untuk "Compose DownloadLink" → Input:**
- **Pilih:** `body/Path` dari "Create file"
- **Bukan:** `Id`, `Name`, `DisplayName`, atau yang lain
- **Kenapa:** `Path` adalah path lengkap file di SharePoint untuk download

---

**Pilih `body/Path` dari "Create file"! 🎯**

