# 📝 Step-by-Step: Update Respond to Power Apps dengan Expression

## 🎯 Tujuan
Mengisi field "Data" dan "RowCount" di action "Respond to a Power App or flow" dengan expression dari Parse JSON.

---

## ✅ Cara 1: Pakai Dynamic Content (Recommended)

### **Step 1: Buka Action "Respond to a Power App or flow"**

1. Klik pada action **"Respond to a Power App or flow"** di flow canvas
2. Pastikan tab **"Parameters"** aktif (bukan "Settings" atau "Code view")

---

### **Step 2: Isi Field "Data"**

1. Klik pada field **"Data"** (yang ada icon purple "AA")
2. **JANGAN ketik langsung di field!**
3. Klik icon **fx** (function) di sebelah kanan field (atau klik "Add dynamic content")
4. Di expression editor yang muncul, ketik salah satu:

**Jika Parse JSON output langsung array:**
```
body('Parse_JSON')
```

**Jika Parse JSON output ada wrapper:**
```
body('Parse_JSON')?['body']
```

5. Klik **"OK"** atau **"Update"**

**✅ Hasil:** Field "Data" sekarang berisi expression dari Parse JSON

---

### **Step 3: Isi Field "RowCount"**

1. Klik pada field **"RowCount"** (yang ada icon purple "123")
2. **JANGAN ketik langsung di field!**
3. Klik icon **fx** (function) di sebelah kanan field
4. Di expression editor yang muncul, ketik salah satu:

**Jika Parse JSON output langsung array:**
```
if(empty(body('Parse_JSON')), 0, length(body('Parse_JSON')))
```

**Jika Parse JSON output ada wrapper:**
```
if(empty(body('Parse_JSON')?['body']), 0, length(body('Parse_JSON')?['body']))
```

5. Klik **"OK"** atau **"Update"**

**✅ Hasil:** Field "RowCount" sekarang berisi jumlah rows dari Parse JSON

---

## ✅ Cara 2: Pakai Code View (Jika Dynamic Content Error)

### **Step 1: Buka Code View**

1. Klik pada action **"Respond to a Power App or flow"**
2. Klik tab **"Code view"** (di bagian atas action, sebelah "Parameters")

---

### **Step 2: Copy-Paste Code**

**Ganti seluruh code di Code View dengan salah satu:**

**Jika Parse JSON output langsung array:**
```json
{
    "success": true,
    "rowcount": "@{if(empty(body('Parse_JSON')), 0, length(body('Parse_JSON')))}",
    "data": "@{body('Parse_JSON')}"
}
```

**Jika Parse JSON output ada wrapper:**
```json
{
    "success": true,
    "rowcount": "@{if(empty(body('Parse_JSON')?['body']), 0, length(body('Parse_JSON')?['body']))}",
    "data": "@{body('Parse_JSON')?['body']}"
}
```

---

### **Step 3: Save**

1. Klik **"Done"** atau **"Save"**
2. Klik tab **"Parameters"** untuk kembali ke view normal
3. Pastikan field "Data" dan "RowCount" sudah terisi (akan muncul sebagai expression)

---

## 🔍 Cara Cek Output Parse JSON

**Untuk tahu apakah Parse JSON output langsung array atau ada wrapper:**

1. Klik pada action **"Parse JSON"** di flow
2. Lihat output di bagian bawah action
3. Cek struktur output:

**Jika langsung array:**
```json
[
    {"ID": 422, "CustomerName": "..."},
    {"ID": 423, "CustomerName": "..."}
]
```
→ Pakai: `body('Parse_JSON')`

**Jika ada wrapper:**
```json
{
    "body": [
        {"ID": 422, "CustomerName": "..."},
        {"ID": 423, "CustomerName": "..."}
    ]
}
```
→ Pakai: `body('Parse_JSON')?['body']`

---

## ⚠️ Troubleshooting

### **Error: "The expression is invalid"**

**Penyebab:**
- Ketik expression langsung di field input (tidak boleh!)
- Nama action Parse JSON tidak sesuai
- Syntax expression salah

**Solusi:**
1. Pastikan klik icon **fx** dulu sebelum ketik expression
2. Cek nama action Parse JSON di flow (harus tepat sama, case-sensitive)
3. Pastikan syntax benar:
   - Di Dynamic Content: langsung `body('Parse_JSON')`
   - Di Code View: pakai `@{body('Parse_JSON')}`

---

### **Error: "Cannot find 'Parse_JSON'"**

**Penyebab:**
- Nama action Parse JSON berbeda
- Action Parse JSON belum dibuat

**Solusi:**
1. Cek nama action Parse JSON di flow canvas
2. Ganti `'Parse_JSON'` dengan nama yang benar, contoh:
   - `'Parse JSON'` (dengan spasi)
   - `'Parse_JSON_1'` (jika ada angka)
   - Nama lain sesuai flow Anda

---

### **Field "Data" masih kosong setelah diisi**

**Penyebab:**
- Expression tidak tersimpan
- Klik "Cancel" bukan "OK"

**Solusi:**
1. Klik icon **fx** lagi
2. Pastikan expression sudah benar
3. Klik **"OK"** atau **"Update"** (jangan klik "Cancel"!)
4. Refresh browser jika perlu

---

## ✅ Checklist

- [ ] Action "Respond to a Power App or flow" sudah dibuka
- [ ] Field "Data" sudah diisi dengan expression (pakai icon fx)
- [ ] Field "RowCount" sudah diisi dengan expression (pakai icon fx)
- [ ] Expression tidak error (tidak ada pesan merah)
- [ ] Flow sudah di-save
- [ ] Flow sudah di-test dan output benar

---

## 🎯 Kesimpulan

**Yang penting:**
- ✅ Jangan ketik expression langsung di field input!
- ✅ Harus klik icon **fx** dulu untuk masuk ke expression editor
- ✅ Atau pakai **Code View** untuk input expression kompleks
- ✅ Pastikan nama action Parse JSON sesuai dengan yang ada di flow

Setelah ini, flow akan langsung return Table ke Power Apps tanpa perlu parse JSON lagi! 🚀
