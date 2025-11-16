# 🔧 Troubleshooting Error 400 (Bad Request)

## ❌ Error yang Terjadi

```
Request failed with status code 400
ERR_BAD_REQUEST
```

**Penyebab:** Parameter yang dikirim ke Power Automate tidak sesuai atau format salah.

---

## 🔍 Checklist Troubleshooting

### 1. Check Parameter di "Respond to PowerApps"

**Masalah Umum:**
- Parameter name typo (contoh: `sharePointLir` bukan `sharePointLink`)
- Value kosong atau null
- Type tidak sesuai (contoh: Number diisi dengan Text)

**Solusi:**

#### A. Check Nama Parameter (HARUS EXACT!)

**Parameter yang Benar:**
- `fileName` (huruf kecil 'f', huruf kecil 'n')
- `sharePointLink` (huruf kecil 's', huruf kecil 'L', huruf kecil 'i')
- `rowCount` (huruf kecil 'r', huruf kecil 'c')
- `status` (huruf kecil 's')

**❌ JANGAN:**
- `sharePointLir` (typo!)
- `FileName` (huruf besar!)
- `sharepointlink` (semua huruf kecil - tidak konsisten)

#### B. Check Value Tidak Kosong

**Test setiap parameter:**

1. **`fileName`:**
   - Pastikan variable `varFileName` sudah dibuat
   - Pastikan value tidak kosong: `@{variables('varFileName')}`
   - Test: Run flow manual → Check apakah `varFileName` ada isinya

2. **`sharePointLink`:**
   - Pastikan action Compose sudah dibuat
   - Pastikan nama action Compose benar
   - Pastikan output Compose tidak kosong
   - Test: Run flow manual → Check output Compose

3. **`rowCount`:**
   - Pastikan expression benar: `length(body('Parse_JSON'))`
   - Pastikan nama action Parse JSON benar
   - Pastikan Parse JSON return array (bukan null)
   - Test: Run flow manual → Check apakah `length()` return number

4. **`status`:**
   - Pastikan value: `success` (tanpa tanda kutip di dynamic content)
   - Atau: `'success'` (dengan tanda kutip di expression)

---

### 2. Check Type Parameter

**Type yang Benar:**

| Parameter | Type | Contoh Value |
|-----------|------|--------------|
| `fileName` | **Text** | `RekeningKoran_Export_20250115.csv` |
| `sharePointLink` | **Text** | `https://...sharepoint.com/.../file.csv` |
| `rowCount` | **Number** | `100` (bukan `"100"`) |
| `status` | **Text** | `success` |

**❌ Common Mistake:**
- `rowCount` pakai Type **Text** → Harus **Number**!
- `sharePointLink` value kosong/null → Harus ada isinya!

---

### 3. Check Expression Syntax

**Expression yang Benar:**

**Untuk Variable:**
```
variables('varFileName')
```
**❌ JANGAN:**
```
@{variables('varFileName')}  ← Jangan pakai @{...} di expression!
variables(varFileName)      ← Jangan lupa tanda kutip!
```

**Untuk Output Action:**
```
outputs('Compose')
```
**❌ JANGAN:**
```
@{outputs('Compose')}        ← Jangan pakai @{...}!
outputs(Compose)            ← Jangan lupa tanda kutip!
```

**Untuk Function:**
```
length(body('Parse_JSON'))
```
**❌ JANGAN:**
```
@{length(body('Parse_JSON'))}  ← Jangan pakai @{...}!
length(body(Parse_JSON))       ← Jangan lupa tanda kutip!
```

**Note:** 
- Di **Dynamic Content**: Tidak perlu tanda kutip (otomatis)
- Di **Expression (fx)**: Perlu tanda kutip untuk string: `'Parse_JSON'`

---

### 4. Check Flow Run History

**Cara Check:**

1. Buka Power Automate → **My flows**
2. Klik flow `Export_RekeningKoran_ToExcel`
3. Klik tab **Run history**
4. Klik run terakhir yang error
5. Check setiap step:
   - ✅ Step mana yang berhasil?
   - ❌ Step mana yang gagal?
   - ⚠️ Step mana yang skip?

**Check Output dari Setiap Step:**

- **Parse JSON:** Apakah return array?
- **Create CSV:** Apakah berhasil?
- **Compose (Base64):** Apakah ada output?
- **Create file (SharePoint):** Apakah file ter-upload?
- **Compose (Download Link):** Apakah link ter-generate?
- **Respond to PowerApps:** Apakah ini yang error?

---

### 5. Test Flow Secara Manual

**Step-by-Step:**

1. **Buka flow di Power Automate**
2. **Klik "Test"** → **"Manually"**
3. **Klik "Run flow"**
4. **Check setiap step:**

   **Step 1: Parse JSON**
   - ✅ Output ada?
   - ✅ Format array?

   **Step 2: Create CSV**
   - ✅ Output ada?
   - ✅ Format CSV?

   **Step 3: Compose (Base64)**
   - ✅ Output ada?
   - ✅ Format Base64?

   **Step 4: Create file (SharePoint)**
   - ✅ File ter-upload?
   - ✅ Output ada Path/Link?

   **Step 5: Compose (Download Link)**
   - ✅ Link ter-generate?
   - ✅ Format URL benar?

   **Step 6: Respond to PowerApps**
   - ❌ Error di sini?
   - ✅ Check output dari step sebelumnya

---

## 🔧 Solusi Per Error

### Error: "Parameter 'sharePointLink' is required"

**Penyebab:** Parameter `sharePointLink` tidak di-add atau value kosong.

**Solusi:**
1. Check apakah parameter `sharePointLink` sudah di-add
2. Check value tidak kosong
3. Test output dari Compose (Download Link)

---

### Error: "Invalid value for parameter 'rowCount'"

**Penyebab:** 
- Type `rowCount` bukan Number
- Value bukan number (contoh: string `"100"`)

**Solusi:**
1. Pastikan Type: **Number** (bukan Text!)
2. Pastikan expression: `length(body('Parse_JSON'))` return number
3. Test: Run flow → Check apakah `length()` return number

---

### Error: "Expression evaluation failed"

**Penyebab:** Expression syntax salah atau action tidak ditemukan.

**Solusi:**
1. Check nama action di expression (contoh: `Parse_JSON` vs `Parse_JSON_1`)
2. Check tanda kutip: `'Parse_JSON'` (bukan `Parse_JSON`)
3. Test expression di Compose terpisah dulu

---

### Error: "File not found" atau "SharePoint error"

**Penyebab:** File tidak ter-upload ke SharePoint atau link tidak ter-generate.

**Solusi:**
1. Check action "Create file" → Apakah berhasil?
2. Check output "Create file" → Apakah ada Path/Link?
3. Check Compose (Download Link) → Apakah link ter-generate?
4. Test link di browser → Apakah bisa diakses?

---

## ✅ Quick Fix Checklist

- [ ] Semua parameter sudah di-add (fileName, sharePointLink, rowCount, status)
- [ ] Nama parameter EXACT (huruf besar/kecil sesuai)
- [ ] Type parameter benar (rowCount = Number, lainnya = Text)
- [ ] Value tidak kosong untuk semua parameter
- [ ] Expression syntax benar (tanda kutip, nama action benar)
- [ ] Flow berhasil di-run manual sampai step "Respond to PowerApps"
- [ ] Output dari setiap step tidak null/kosong

---

## 🧪 Test Expression Secara Terpisah

**Jika masih error, test expression di Compose terpisah:**

1. **Tambahkan Compose baru** sebelum "Respond to PowerApps"
2. **Test setiap expression:**

   **Compose 1: Test fileName**
   ```
   variables('varFileName')
   ```

   **Compose 2: Test sharePointLink**
   ```
   outputs('Compose')
   ```

   **Compose 3: Test rowCount**
   ```
   length(body('Parse_JSON'))
   ```

3. **Run flow** → Check output dari setiap Compose
4. **Jika ada yang null/kosong** → Itu masalahnya!

---

## 💡 Tips

1. **Test flow manual dulu** sebelum test dari Power Apps
2. **Check run history** untuk lihat step mana yang error
3. **Test expression di Compose terpisah** jika masih error
4. **Pastikan semua step sebelumnya berhasil** sebelum "Respond to PowerApps"

---

**Jika masih error setelah checklist di atas, share output dari run history! 🔍**

