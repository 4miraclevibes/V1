# 🔧 Fix Flow Order - Urutan Flow yang Benar

## ❌ Masalah: Urutan Flow Salah!

**Flow saat ini (SALAH):**
```
1. Execute stored procedure (V2)
2. Parse JSON
3. Create CSV table
4. Compose
5. Respond to a Power App or flow  ← SALAH! Masih di tengah!
6. Create file (SharePoint)
7. Compose DownloadLink
```

**Masalah:** 
- "Respond to a Power App or flow" mencoba return `sharePointLink` yang **belum ada**
- Karena "Create file" dan "Compose DownloadLink" **belum dijalankan**!
- Ini menyebabkan error 400 karena parameter `sharePointLink` kosong/null

---

## ✅ Solusi: Pindahkan "Respond to a Power App or flow" ke AKHIR

**Flow yang benar:**
```
1. Execute stored procedure (V2)
2. Parse JSON
3. Create CSV table
4. Compose (Base64)
5. Create file (SharePoint)          ← Upload file dulu
6. Compose DownloadLink              ← Generate link dulu
7. Respond to a Power App or flow    ← Baru return response!
```

---

## 🔧 Cara Fix

### STEP 1: Hapus "Respond to a Power App or flow" yang di tengah

1. Klik action **"Respond to a Power App or flow"** (yang di posisi 5)
2. Klik **"..."** (three dots) di kanan atas action
3. Pilih **"Delete"**
4. Confirm delete

---

### STEP 2: Tambahkan "Respond to a Power App or flow" di AKHIR

1. Scroll ke bawah ke action **"Compose DownloadLink"** (yang terakhir)
2. Klik **"+"** (plus sign) di bawah "Compose DownloadLink"
3. Pilih **"Add an action"**
4. Search: **"Respond to a Power App"**
5. Pilih **"Respond to a Power App or flow"**

---

### STEP 3: Setup Parameter di "Respond to a Power App or flow"

**Sekarang parameter bisa diisi dengan benar karena semua step sebelumnya sudah selesai!**

**Parameter 1: `fileName`**
- **Type:** Text
- **Value:** Dynamic content → `varFileName` dari Variables

**Parameter 2: `sharePointLink`**
- **Type:** Text
- **Value:** Dynamic content → Output dari **"Compose DownloadLink"**

**Parameter 3: `rowCount`**
- **Type:** Number
- **Value:** Expression (fx) → `length(body('Parse_JSON'))`

**Parameter 4: `status`**
- **Type:** Text
- **Value:** Langsung ketik: `success`

---

## ✅ Urutan Flow yang Benar (Detail)

### 1. Execute stored procedure (V2)
- Query database
- Return data

### 2. Parse JSON
- Parse hasil dari stored procedure
- Return array

### 3. Create CSV table
- Convert array ke CSV format
- Return CSV string

### 4. Compose (Base64)
- Convert CSV ke Base64
- Input: `base64(body('Create_CSV_table'))`
- Return Base64 string

### 5. Create file (SharePoint)
- Upload file ke SharePoint
- File Content: `base64ToBinary(body('Compose'))`
- Return file info (Path, Id, dll)

### 6. Compose DownloadLink
- Generate download link
- Input: `body('Create_file')?['Path']` (atau sesuai output Create file)
- Return SharePoint link

### 7. Respond to a Power App or flow ✅
- Return response ke Power Apps
- Sekarang semua parameter sudah tersedia!

---

## 🎯 Visual Flow yang Benar

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
│ Create CSV table            │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Compose (Base64)            │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Create file (SharePoint)    │ ← Upload file
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Compose DownloadLink        │ ← Generate link
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Respond to Power App        │ ← Return response (AKHIR!)
└─────────────────────────────┘
```

---

## ⚠️ Common Mistakes

### ❌ Salah: Respond di tengah
```
... → Compose → Respond → Create file → Compose DownloadLink
```
**Masalah:** `sharePointLink` belum ada!

### ✅ Benar: Respond di akhir
```
... → Compose → Create file → Compose DownloadLink → Respond
```
**Benar:** Semua parameter sudah tersedia!

---

## ✅ Checklist

- [ ] Hapus "Respond to a Power App or flow" yang di tengah
- [ ] Tambahkan "Respond to a Power App or flow" di akhir (setelah Compose DownloadLink)
- [ ] Setup parameter dengan benar:
  - [ ] `fileName` dari Variables
  - [ ] `sharePointLink` dari Compose DownloadLink
  - [ ] `rowCount` dari Parse JSON
  - [ ] `status` = `success`
- [ ] Test flow manual → Semua step berhasil
- [ ] Test dari Power Apps → Download bekerja

---

## 💡 Tips

1. **Selalu letakkan "Respond" di akhir** setelah semua proses selesai
2. **Check urutan flow** sebelum test
3. **Test flow manual** untuk verify semua step berhasil

---

**Fix urutan flow ini, error 400 akan hilang! 🎯**

