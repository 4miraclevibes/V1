# 🔧 Fix Error 400 Tanpa "Respond to PowerApps"

## ❌ Masalah: Error 400 Saat Save (Tanpa Respond)

**Penyebab:** Action lain di flow belum dikonfigurasi dengan benar atau ada field yang kosong.

---

## 🔍 Checklist: Action yang Perlu Dicek

### 1. Check "Create file" (SharePoint)

**Field yang HARUS diisi:**
- ✅ **Site Address:** Pilih SharePoint site
- ✅ **Folder Path:** Contoh: `/Shared Documents/Exports`
- ✅ **File Name:** Harus ada value (bisa dari variable atau langsung)
- ✅ **File Content:** Harus ada value (dari Compose sebelumnya)

**Common Mistakes:**

#### ❌ Salah: File Name kosong
```
File Name: [kosong]  ← Harus ada isinya!
```

#### ✅ Benar: File Name dari variable
```
File Name: @{variables('varFileName')}
```
**Atau langsung ketik:** `RekeningKoran_Export.csv`

#### ❌ Salah: File Content kosong
```
File Content: [kosong]  ← Harus ada isinya!
```

#### ✅ Benar: File Content dari Compose
```
File Content: @{base64ToBinary(body('Compose'))}
```
**Atau dynamic content:** Output dari Compose (Base64)

---

### 2. Check "Compose DownloadLink"

**Field yang HARUS diisi:**
- ✅ **Input:** Harus ada expression atau dynamic content

**Common Mistakes:**

#### ❌ Salah: Input kosong
```
Input: [kosong]  ← Harus ada isinya!
```

#### ✅ Benar: Input dari Create file
```
Input: body('Create_file')?['Path']
```
**Atau dynamic content:** Output dari "Create file"

**Check nama action:**
- Pastikan nama action "Create file" sesuai
- Jika nama-nya `Create_file` → Pakai: `body('Create_file')`
- Jika nama-nya `Create_file_1` → Pakai: `body('Create_file_1')`

---

### 3. Check "Compose" (Base64)

**Field yang HARUS diisi:**
- ✅ **Input:** Harus ada expression

**Common Mistakes:**

#### ❌ Salah: Input kosong
```
Input: [kosong]  ← Harus ada isinya!
```

#### ✅ Benar: Input dari Create CSV table
```
Input: base64(body('Create_CSV_table'))
```
**Atau dynamic content:** Output dari "Create CSV table"

**Check nama action:**
- Pastikan nama action "Create CSV table" sesuai
- Jika nama-nya `Create_CSV_table` → Pakai: `body('Create_CSV_table')`
- Jika nama-nya `Create_CSV_table_1` → Pakai: `body('Create_CSV_table_1')`

---

### 4. Check "Create CSV table"

**Field yang HARUS diisi:**
- ✅ **From:** Harus ada dynamic content atau expression

**Common Mistakes:**

#### ❌ Salah: From kosong
```
From: [kosong]  ← Harus ada isinya!
```

#### ✅ Benar: From dari Parse JSON
```
From: body('Parse_JSON')
```
**Atau dynamic content:** Output dari "Parse JSON"

---

### 5. Check "Parse JSON"

**Field yang HARUS diisi:**
- ✅ **Content:** Harus ada dynamic content atau expression
- ✅ **Schema:** Harus ada JSON schema

**Common Mistakes:**

#### ❌ Salah: Content kosong
```
Content: [kosong]  ← Harus ada isinya!
```

#### ✅ Benar: Content dari Execute stored procedure
```
Content: body('Execute_stored_procedure_(V2)')?['ResultSets']?['Table1']
```
**Atau dynamic content:** Output dari "Execute stored procedure (V2)"

#### ❌ Salah: Schema kosong
```
Schema: [kosong]  ← Harus ada isinya!
```

#### ✅ Benar: Schema dari sample atau manual
- Klik "Generate from sample" → Paste sample output
- Atau buat manual sesuai struktur data

---

### 6. Check Variable `varFileName`

**Jika digunakan di "Create file":**

**Check:**
- Scroll ke atas flow
- Cari action **"Initialize variable"** dengan nama `varFileName`

**Jika TIDAK ADA tapi digunakan:**
- Tambahkan sebelum "Create file"
- **Name:** `varFileName`
- **Type:** String
- **Value:** `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')`

**Atau:** Langsung ketik file name di "Create file" tanpa variable

---

## 🔧 Step-by-Step Fix

### STEP 1: Check Setiap Action

**Buka setiap action dan check:**

1. **"Execute stored procedure (V2)"**
   - ✅ Connection sudah setup?
   - ✅ Procedure name sudah diisi?
   - ✅ Parameters sudah diisi (jika ada)?

2. **"Parse JSON"**
   - ✅ Content sudah diisi?
   - ✅ Schema sudah diisi?

3. **"Create CSV table"**
   - ✅ From sudah diisi?

4. **"Compose" (Base64)**
   - ✅ Input sudah diisi?

5. **"Create file" (SharePoint)**
   - ✅ Site Address sudah dipilih?
   - ✅ Folder Path sudah diisi?
   - ✅ File Name sudah diisi?
   - ✅ File Content sudah diisi?
   - ✅ Connection sudah setup?

6. **"Compose DownloadLink"**
   - ✅ Input sudah diisi?

---

### STEP 2: Fix Field yang Kosong

**Untuk setiap action yang ada field kosong:**

1. Klik action tersebut
2. Check setiap field
3. Isi field yang kosong dengan:
   - **Dynamic content** (jika tersedia)
   - **Expression (fx)** (jika perlu formula)
   - **Static value** (jika langsung ketik)

---

### STEP 3: Check Connection

**Untuk action yang perlu connection:**

1. **"Execute stored procedure (V2)"**
   - Check connection SQL Server sudah setup
   - Jika belum, klik "New connection" → Setup connection

2. **"Create file" (SharePoint)**
   - Check connection SharePoint sudah setup
   - Jika belum, klik "New connection" → Setup connection

---

### STEP 4: Test Save

1. Fix semua field yang kosong
2. Fix semua connection yang belum setup
3. Klik **"Save"**
4. Jika masih error:
   - Klik error untuk lihat detail
   - Lihat action mana yang error
   - Fix action tersebut

---

## ✅ Quick Fix Checklist

- [ ] "Execute stored procedure (V2)" → Connection setup, Procedure name diisi
- [ ] "Parse JSON" → Content diisi, Schema diisi
- [ ] "Create CSV table" → From diisi
- [ ] "Compose" (Base64) → Input diisi
- [ ] "Create file" (SharePoint) → Site Address dipilih, Folder Path diisi, File Name diisi, File Content diisi, Connection setup
- [ ] "Compose DownloadLink" → Input diisi
- [ ] Variable `varFileName` dibuat (jika digunakan)
- [ ] Semua field tidak kosong
- [ ] Semua connection sudah setup

---

## 🧪 Test Save Flow

1. **Fix semua field yang kosong**
2. **Fix semua connection yang belum setup**
3. **Klik "Save"**
4. **Jika masih error:**
   - Klik error untuk expand detail
   - Lihat action mana yang error
   - Check field mana yang bermasalah
   - Fix field tersebut

---

## 💡 Tips

1. **Check setiap action satu per satu** - Jangan skip!
2. **Pastikan semua field required sudah diisi**
3. **Pastikan semua connection sudah setup**
4. **Test save setelah fix setiap action**

---

**Yang perlu dicek sekarang:**
1. **Action mana yang error?** (klik error untuk lihat detail)
2. **Field mana yang kosong?** (check setiap action)
3. **Connection mana yang belum setup?** (check action yang perlu connection)

🔍

