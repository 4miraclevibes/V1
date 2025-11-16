# 📋 Type Parameter untuk "Respond to PowerApps"

## ✅ Type untuk Setiap Parameter

### Parameter yang Dibutuhkan:

| Parameter | Type | Icon | Value |
|-----------|------|------|-------|
| `fileName` | **Text** | AA (purple) | `@{variables('varFileName')}` |
| `sharePointLink` | **Text** | AA (purple) | `@{outputs('Compose_DownloadLink')}` |
| `rowCount` | **Number** | 123 (purple) | `@{length(body('Parse_JSON'))}` |
| `status` | **Text** | AA (purple) | `success` |

---

## 🔧 Step-by-Step Setup

### STEP 1: Klik "Add an output"

Di action "Respond to PowerApps", klik **"Add an output"** atau **"Add parameter"**

---

### STEP 2: Tambahkan Parameter 1 - `fileName`

1. **Parameter Name:** `fileName`
2. **Type:** Pilih **Text** (icon AA - purple)
3. **Value:** 
   ```
   @{variables('varFileName')}
   ```
   **Atau klik dynamic content:** `varFileName` dari Variables

---

### STEP 3: Tambahkan Parameter 2 - `sharePointLink`

1. **Parameter Name:** `sharePointLink`
2. **Type:** Pilih **Text** (icon AA - purple)
3. **Value:** 
   ```
   @{outputs('Compose_DownloadLink')}
   ```
   **Atau klik dynamic content:** Output dari action Compose kamu
   
   **Note:** 
   - Ganti `Compose_DownloadLink` dengan nama action Compose yang kamu buat
   - Bisa juga: `@{outputs('Compose')}` jika nama action-nya `Compose`

---

### STEP 4: Tambahkan Parameter 3 - `rowCount`

1. **Parameter Name:** `rowCount`
2. **Type:** Pilih **Number** (icon 123 - purple)
3. **Value:** 
   ```
   @{length(body('Parse_JSON'))}
   ```
   **Atau klik dynamic content:** Expression → `length()` → pilih output dari Parse JSON

---

### STEP 5: Tambahkan Parameter 4 - `status`

1. **Parameter Name:** `status`
2. **Type:** Pilih **Text** (icon AA - purple)
3. **Value:** 
   ```
   success
   ```
   **Atau langsung ketik:** `success` (tanpa dynamic content)

---

## 🎯 Visual Guide

```
┌─────────────────────────────────────┐
│ Respond to PowerApps                │
├─────────────────────────────────────┤
│ Parameters:                         │
│                                     │
│ fileName (Text)                     │
│   └─ @{variables('varFileName')}   │
│                                     │
│ sharePointLink (Text)               │
│   └─ @{outputs('Compose')}         │
│                                     │
│ rowCount (Number)                   │
│   └─ @{length(body('Parse_JSON'))} │
│                                     │
│ status (Text)                       │
│   └─ success                        │
└─────────────────────────────────────┘
```

---

## ⚠️ Common Mistakes

### ❌ Salah: Semua Type Text
```
fileName: Text ✅
sharePointLink: Text ✅
rowCount: Text ❌ (harus Number!)
status: Text ✅
```

### ✅ Benar: Type Sesuai Data
```
fileName: Text ✅
sharePointLink: Text ✅
rowCount: Number ✅
status: Text ✅
```

---

## 🔍 Troubleshooting

### Error: "Invalid type"

**Solusi:**
- Pastikan `rowCount` menggunakan type **Number**, bukan Text
- Check value expression apakah return number atau string

### Error: "Parameter not found"

**Solusi:**
- Pastikan nama action Compose benar
- Check dynamic content untuk melihat semua available outputs
- Pastikan variable `varFileName` sudah dibuat

### Link tidak bekerja di Power Apps

**Solusi:**
- Pastikan `sharePointLink` return full URL (bukan relative path)
- Test link di browser sebelum return ke Power Apps
- Pastikan link format benar: `https://...sharepoint.com/...`

---

## ✅ Checklist

- [ ] Parameter `fileName` ditambahkan (Type: Text)
- [ ] Parameter `sharePointLink` ditambahkan (Type: Text)
- [ ] Parameter `rowCount` ditambahkan (Type: **Number** - penting!)
- [ ] Parameter `status` ditambahkan (Type: Text)
- [ ] Semua value expression sudah benar
- [ ] Test flow untuk verify output

---

## 💡 Tips

1. **Type Number untuk `rowCount`** - Penting! Jangan pakai Text
2. **Type Text untuk link** - SharePoint link adalah string/URL
3. **Check dynamic content** - Klik dynamic content untuk lihat semua available outputs
4. **Test flow** - Run flow secara manual untuk verify semua parameter return dengan benar

---

**PENTING: `rowCount` harus Type Number, bukan Text! 🎯**

