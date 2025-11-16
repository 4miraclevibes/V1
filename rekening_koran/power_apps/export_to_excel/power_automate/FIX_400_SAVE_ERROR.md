# 🔧 Fix Error 400 Saat Save Flow

## ❌ Error: "Request failed with status code 400" saat Save Flow

**Penyebab:** Parameter di "Respond to PowerApps" tidak valid atau value kosong/null.

---

## 🔍 Checklist Troubleshooting

### 1. Check Semua Parameter Sudah Di-Add

**Parameter yang HARUS ada:**
- ✅ `fileName` (Type: Text)
- ✅ `sharePointLink` (Type: Text)
- ✅ `rowCount` (Type: Number)
- ✅ `status` (Type: Text)

**Cara check:**
- Buka action "Respond to a Power App or flow"
- Lihat di panel kanan → Tab "Parameters"
- Pastikan semua 4 parameter sudah ada

---

### 2. Check Value Tidak Kosong

**Test setiap parameter:**

#### Parameter `fileName`:
- **Value harus:** Dynamic content `varFileName` ATAU Expression `variables('varFileName')`
- **❌ JANGAN:** Kosong atau null
- **Test:** Klik dynamic content → Pastikan `varFileName` muncul di list Variables

#### Parameter `sharePointLink`:
- **Value harus:** Dynamic content dari **"Compose DownloadLink"** ATAU Expression `outputs('Compose_DownloadLink')`
- **❌ JANGAN:** Kosong atau null
- **Test:** Klik dynamic content → Pastikan output dari "Compose DownloadLink" muncul

#### Parameter `rowCount`:
- **Value harus:** Expression `length(body('Parse_JSON'))`
- **Type HARUS:** Number (bukan Text!)
- **❌ JANGAN:** Kosong atau null
- **Test:** Klik fx → Pastikan expression valid

#### Parameter `status`:
- **Value harus:** Langsung ketik `success` (tanpa tanda kutip)
- **❌ JANGAN:** Kosong atau null

---

### 3. Check Expression Syntax

**Common Mistakes:**

#### ❌ Salah: Pakai @{...} di Expression
```
@{variables('varFileName')}  ← JANGAN!
```

#### ✅ Benar: Tanpa @{...} di Expression
```
variables('varFileName')  ← BENAR!
```

**Note:**
- Di **Dynamic Content**: Tidak perlu tanda kutip (otomatis)
- Di **Expression (fx)**: Perlu tanda kutip untuk string: `'Parse_JSON'`

---

### 4. Check Nama Action di Expression

**Pastikan nama action EXACT:**

#### Untuk `sharePointLink`:
```
outputs('Compose_DownloadLink')
```
**Check:** 
- Nama action Compose kamu apa?
- Jika nama-nya `Compose` → Pakai: `outputs('Compose')`
- Jika nama-nya `Compose_DownloadLink` → Pakai: `outputs('Compose_DownloadLink')`

#### Untuk `rowCount`:
```
length(body('Parse_JSON'))
```
**Check:**
- Nama action Parse JSON kamu apa?
- Jika nama-nya `Parse_JSON` → Pakai: `length(body('Parse_JSON'))`
- Jika nama-nya `Parse_JSON_1` → Pakai: `length(body('Parse_JSON_1'))`

---

### 5. Check Variable Sudah Dibuat

**Variable yang diperlukan:**
- `varFileName` (Type: String)

**Cara check:**
1. Scroll ke atas flow
2. Cari action **"Initialize variable"** dengan nama `varFileName`
3. Pastikan sudah dibuat sebelum digunakan

**Jika belum ada:**
- Tambahkan action **"Initialize variable"** sebelum "Create file"
- **Name:** `varFileName`
- **Type:** String
- **Value:** `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')`

---

## 🔧 Step-by-Step Fix

### STEP 1: Check Variable `varFileName`

1. Scroll ke atas flow
2. Cari action **"Initialize variable"** dengan nama `varFileName`
3. **Jika TIDAK ADA:**
   - Tambahkan sebelum "Create file"
   - **Name:** `varFileName`
   - **Type:** String
   - **Value (Expression):** `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')`

---

### STEP 2: Check Action Names

1. **Check nama action "Compose DownloadLink":**
   - Klik action "Compose DownloadLink"
   - Lihat nama di header action
   - Catat nama exact-nya (contoh: `Compose_DownloadLink` atau `Compose`)

2. **Check nama action "Parse JSON":**
   - Klik action "Parse JSON"
   - Lihat nama di header action
   - Catat nama exact-nya (contoh: `Parse_JSON` atau `Parse_JSON_1`)

---

### STEP 3: Fix Parameter di "Respond to PowerApps"

1. **Buka action "Respond to a Power App or flow"**

2. **Parameter `fileName`:**
   - **Cara 1 (Dynamic Content):**
     - Klik field Value
     - Pilih **Dynamic content**
     - Scroll ke **Variables**
     - Klik `varFileName`
   - **Cara 2 (Expression):**
     - Klik icon **fx**
     - Ketik: `variables('varFileName')`
     - Klik **OK**

3. **Parameter `sharePointLink`:**
   - **Cara 1 (Dynamic Content):**
     - Klik field Value
     - Pilih **Dynamic content**
     - Scroll ke action **"Compose DownloadLink"** (atau nama action Compose kamu)
     - Klik output dari Compose tersebut
   - **Cara 2 (Expression):**
     - Klik icon **fx**
     - Ketik: `outputs('Compose_DownloadLink')` (ganti dengan nama action Compose kamu)
     - Klik **OK**

4. **Parameter `rowCount`:**
   - **Type:** Pastikan **Number** (bukan Text!)
   - Klik icon **fx**
   - Ketik: `length(body('Parse_JSON'))` (ganti dengan nama action Parse JSON kamu)
   - Klik **OK**

5. **Parameter `status`:**
   - **Type:** Text
   - Langsung ketik: `success` (tanpa dynamic content atau fx)

---

### STEP 4: Test Expression Secara Terpisah

**Jika masih error, test expression di Compose terpisah:**

1. **Tambahkan Compose baru** sebelum "Respond to PowerApps"
2. **Test setiap expression:**

   **Compose Test 1:**
   ```
   variables('varFileName')
   ```

   **Compose Test 2:**
   ```
   outputs('Compose_DownloadLink')
   ```
   (Ganti dengan nama action Compose kamu)

   **Compose Test 3:**
   ```
   length(body('Parse_JSON'))
   ```
   (Ganti dengan nama action Parse JSON kamu)

3. **Save flow** (tanpa "Respond to PowerApps" dulu)
4. **Run flow manual** → Check output dari setiap Compose Test
5. **Jika ada yang null/kosong** → Itu masalahnya!

---

## ✅ Quick Fix Checklist

- [ ] Variable `varFileName` sudah dibuat (Initialize variable)
- [ ] Semua 4 parameter sudah di-add di "Respond to PowerApps"
- [ ] Parameter `fileName` → Value: `varFileName` dari Variables
- [ ] Parameter `sharePointLink` → Value: Output dari "Compose DownloadLink"
- [ ] Parameter `rowCount` → Type: **Number**, Value: `length(body('Parse_JSON'))`
- [ ] Parameter `status` → Value: `success`
- [ ] Semua value tidak kosong/null
- [ ] Nama action di expression sesuai dengan nama di flow
- [ ] Expression syntax benar (tanpa @{...})

---

## 🧪 Test Save Flow

1. **Fix semua parameter** sesuai checklist di atas
2. **Klik "Save"** di Power Automate
3. **Jika masih error:**
   - Check error message detail (klik error untuk expand)
   - Lihat parameter mana yang error
   - Fix parameter tersebut

---

## 💡 Tips

1. **Pakai Dynamic Content** untuk semua yang bisa (lebih mudah dan reliable)
2. **Test expression di Compose terpisah** jika masih error
3. **Check nama action EXACT** - case sensitive!
4. **Pastikan variable sudah dibuat** sebelum digunakan

---

**Jika masih error setelah checklist di atas, share screenshot dari:**
1. **Parameter di "Respond to PowerApps"** (panel kanan)
2. **Error message detail** (klik error untuk expand)
3. **Output dari Compose Test** (jika sudah test)

🔍

