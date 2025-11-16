# 🔧 Fix: Variable `varFileName` Tidak Ada

## ❌ Masalah: Variable `varFileName` Tidak Muncul di Dynamic Content

**Penyebab:** Variable `varFileName` belum dibuat di flow.

---

## ✅ Solusi: 2 Opsi

### **OPSI 1: Langsung Ketik Nama File (PALING CEPAT!)**

**Untuk parameter `fileName` di "Respond to PowerApps":**

1. **Klik field "File Name"**
2. **Langsung ketik:** `RekeningKoran_Export.csv`
3. **Selesai!**

**Atau dengan timestamp (dynamic name):**

1. **Klik icon fx** (di kanan field)
2. **Ketik expression:**
   ```
   concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')
   ```
3. **Klik OK**

**Hasil:** `RekeningKoran_Export_20250115_123456.csv`

---

### **OPSI 2: Buat Variable Dulu (Jika Ingin Pakai Variable)**

**STEP 1: Buat Variable**

1. **Scroll ke atas flow** (sebelum "Create file")
2. **Klik "+"** (plus sign) untuk add action baru
3. **Search:** "Initialize variable"
4. **Pilih:** "Initialize variable"

**Configuration:**
- **Name:** `varFileName`
- **Type:** String
- **Value (Expression):** 
  ```
  concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')
  ```

**STEP 2: Pakai Variable di "Respond to PowerApps"**

1. **Buka action "Respond to a Power App or flow"**
2. **Parameter `fileName`:**
   - Klik field "File Name"
   - Pilih **Dynamic content**
   - Scroll ke **Variables**
   - Klik `varFileName` ✅

---

## 🎯 Rekomendasi

**Pakai OPSI 1** (langsung ketik) karena:
- ✅ Lebih cepat
- ✅ Tidak perlu buat variable
- ✅ Langsung bisa save flow

**Pakai OPSI 2** (buat variable) jika:
- Ingin nama file dinamis dengan timestamp
- Ingin pakai nama file yang sama di beberapa tempat

---

## 📝 Contoh Expression untuk Dynamic Name

**Expression dengan timestamp:**
```
concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')
```

**Hasil:** `RekeningKoran_Export_20250115_123456.csv`

**Expression dengan tanggal saja:**
```
concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd'), '.csv')
```

**Hasil:** `RekeningKoran_Export_20250115.csv`

---

## ✅ Quick Fix

**Untuk parameter `fileName`:**

1. **Klik field "File Name"**
2. **Langsung ketik:** `RekeningKoran_Export.csv`
3. **Save flow** ✅

**Atau pakai expression untuk dynamic name:**

1. **Klik icon fx**
2. **Ketik:** `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.csv')`
3. **Klik OK**
4. **Save flow** ✅

---

**Paling cepat: Langsung ketik nama file! 🎯**

