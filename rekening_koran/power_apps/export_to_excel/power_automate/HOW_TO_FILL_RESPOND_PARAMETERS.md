# 📝 Cara Mengisi Value di "Respond to PowerApps"

## ✅ 3 Cara Mengisi Value

### **CARA 1: Dynamic Content (PALING MUDAH!)**

**Langkah:**
1. Klik field **Value** (yang kosong)
2. Panel kanan akan muncul dengan **Dynamic content**
3. Scroll atau cari output yang diinginkan
4. Klik output tersebut → Otomatis terisi!

**Contoh:**
- Untuk `fileName`: Klik field → Pilih `varFileName` dari **Variables**
- Untuk `sharePointLink`: Klik field → Pilih output dari action **Compose**

---

### **CARA 2: Expression (fx) - Untuk Function/Formula**

**Langkah:**
1. Klik icon **fx** (di kanan field)
2. Ketik expression manual
3. Klik **OK**

**Contoh:**
- Untuk `rowCount`: Klik **fx** → Ketik: `length(body('Parse_JSON'))`
- Untuk `fileName`: Klik **fx** → Ketik: `variables('varFileName')`

---

### **CARA 3: Static Text (Langsung Ketik)**

**Langkah:**
1. Klik field **Value**
2. Langsung ketik text (tanpa dynamic content atau fx)

**Contoh:**
- Untuk `status`: Langsung ketik: `success`

---

## 🎯 Detail untuk Setiap Parameter

### Parameter 1: `fileName`

**Type:** Text

**Value Options:**

**Option A - Dynamic Content (MUDAH):**
1. Klik field Value
2. Pilih **Dynamic content**
3. Scroll ke **Variables**
4. Klik `varFileName`

**Option B - Expression (fx):**
1. Klik icon **fx**
2. Ketik: `variables('varFileName')`
3. Klik **OK**

---

### Parameter 2: `sharePointLink`

**Type:** Text

**Value Options:**

**Option A - Dynamic Content (MUDAH):**
1. Klik field Value
2. Pilih **Dynamic content**
3. Scroll ke action **Compose** (atau nama action Compose kamu)
4. Klik output dari Compose tersebut

**Option B - Expression (fx):**
1. Klik icon **fx**
2. Ketik: `outputs('Compose')`
   - **Note:** Ganti `Compose` dengan nama action Compose kamu
   - Contoh: `outputs('Compose_DownloadLink')` jika nama action-nya `Compose_DownloadLink`
3. Klik **OK**

**💡 TIP:** 
- Nama action Compose biasanya muncul di dynamic content
- Jika tidak muncul, check apakah action Compose sudah dibuat sebelumnya

---

### Parameter 3: `rowCount`

**Type:** Number

**Value Options:**

**Option A - Expression (fx) - RECOMMENDED:**
1. Klik icon **fx**
2. Ketik: `length(body('Parse_JSON'))`
   - **Note:** Ganti `Parse_JSON` dengan nama action Parse JSON kamu
   - Contoh: `length(body('Parse_JSON_1'))` jika nama action-nya `Parse_JSON_1`
3. Klik **OK**

**Option B - Dynamic Content + Expression:**
1. Klik field Value
2. Pilih **Dynamic content**
3. Pilih output dari **Parse JSON**
4. Klik icon **fx** untuk edit
5. Wrap dengan `length(...)` → Jadi: `length(body('Parse_JSON'))`

---

### Parameter 4: `status`

**Type:** Text

**Value Options:**

**Option A - Static Text (PALING SIMPLE):**
1. Klik field Value
2. Langsung ketik: `success`
3. Tidak perlu dynamic content atau fx!

**Option B - Expression (fx):**
1. Klik icon **fx**
2. Ketik: `'success'` (dengan tanda kutip)
3. Klik **OK**

---

## 🔍 Visual Guide

### Dynamic Content
```
┌─────────────────────────┐
│ Value: [Click here]     │ ← Klik ini
└─────────────────────────┘
         ↓
┌─────────────────────────┐
│ Dynamic content         │
│                         │
│ Variables:              │
│   varFileName          │ ← Klik ini
│                         │
│ Compose:                │
│   Outputs              │
└─────────────────────────┘
```

### Expression (fx)
```
┌─────────────────────────┐
│ Value: [fx] [Click]     │ ← Klik fx
└─────────────────────────┘
         ↓
┌─────────────────────────┐
│ Expression              │
│                         │
│ length(body('Parse_... │ ← Ketik expression
│                         │
│ [OK]                    │
└─────────────────────────┘
```

---

## ⚠️ Common Mistakes

### ❌ Salah: Pakai JSON Format di Value Field
```
Value: {
    "fileName": "@{variables('varFileName')}",
    ...
}
```
**Masalah:** Power Automate tidak support JSON format langsung di value field!

### ✅ Benar: Tambahkan Parameter Satu Per Satu
```
Parameter 1: fileName
  Value: [Dynamic content: varFileName]

Parameter 2: sharePointLink
  Value: [Dynamic content: Compose output]

Parameter 3: rowCount
  Value: [fx: length(body('Parse_JSON'))]

Parameter 4: status
  Value: success
```

---

## 💡 Tips

1. **Pakai Dynamic Content** untuk variable dan output action (lebih mudah!)
2. **Pakai Expression (fx)** untuk function seperti `length()`, `concat()`, dll
3. **Langsung ketik** untuk static text seperti `success`
4. **Check nama action** - Pastikan nama action di expression sesuai dengan nama di flow
5. **Test flow** - Run flow secara manual untuk verify semua value benar

---

## ✅ Checklist

- [ ] Parameter `fileName` → Value: Dynamic content `varFileName` atau Expression `variables('varFileName')`
- [ ] Parameter `sharePointLink` → Value: Dynamic content dari Compose atau Expression `outputs('Compose')`
- [ ] Parameter `rowCount` → Value: Expression `length(body('Parse_JSON'))`
- [ ] Parameter `status` → Value: Langsung ketik `success`
- [ ] Semua parameter sudah di-add
- [ ] Test flow untuk verify output

---

**PALING MUDAH: Pakai Dynamic Content untuk semua yang bisa! 🎯**

