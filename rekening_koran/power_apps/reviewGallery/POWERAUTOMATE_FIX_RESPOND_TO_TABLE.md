# 🔧 Fix Power Automate Flow - Return Table Langsung (Bukan JSON String)

## 🎯 Tujuan
Mengubah Power Automate flow agar langsung return **Table/Array** ke Power Apps, bukan JSON string. Ini akan membuat code di Power Apps jadi lebih sederhana.

---

## 📋 Langkah-Langkah Perbaikan

### **Step 1: Buka Flow "FilterBTPReview" di Power Automate**

1. Login ke [Power Automate](https://make.powerautomate.com)
2. Buka flow **"FilterBTPReview"**
3. Edit flow

---

### **Step 2: Cari Action "Respond to Power Apps"**

Cari action terakhir yang bernama **"Respond to Power Apps"** atau **"Respond to a PowerApp or flow"**.

---

### **Step 3: Ubah Response Body**

**❌ YANG SALAH (Saat Ini):**
```json
{
    "success": true,
    "rowcount": 655,
    "data": "@{body('Parse_JSON')}"  // ← Ini return JSON string
}
```

**✅ YANG BENAR:**
```json
{
    "success": true,
    "rowcount": "@{length(body('Parse_JSON'))}",
    "data": "@{body('Parse_JSON')}"  // ← Langsung return array/table
}
```

**Atau jika Parse JSON output ada di `body`:**
```json
{
    "success": true,
    "rowcount": "@{length(body('Parse_JSON')?['body'])}",
    "data": "@{body('Parse_JSON')?['body']}"  // ← Langsung return array
}
```

---

### **Step 4: Pastikan Tidak Ada Stringify**

**⚠️ PASTIKAN TIDAK ADA:**
- ❌ `string()` function
- ❌ `json()` function untuk convert ke string
- ❌ Action "Compose" yang stringify data

**✅ LANGSUNG PAKAI:**
- Output dari Parse JSON action langsung
- Atau `body('Parse_JSON')` atau `body('Parse_JSON')?['body']`

---

### **Step 5: Cek Output Parse JSON**

**Cara cek struktur output Parse JSON:**

1. Klik pada action **"Parse JSON"**
2. Lihat output di bagian bawah
3. Cek apakah output langsung array `[...]` atau ada wrapper `{"body": [...]}`

**Jika output langsung array:**
```json
[
    {"ID": 422, "CustomerName": "...", ...},
    {"ID": 423, "CustomerName": "...", ...}
]
```
→ Pakai: `body('Parse_JSON')`

**Jika output ada wrapper:**
```json
{
    "body": [
        {"ID": 422, "CustomerName": "...", ...},
        {"ID": 423, "CustomerName": "...", ...}
    ]
}
```
→ Pakai: `body('Parse_JSON')?['body']`

---

### **Step 6: Update Response Body di Respond to Power Apps**

**⚠️ PENTING: Jangan ketik expression langsung di field! Harus pakai icon fx atau Code View!**

**Cara 1: Pakai Icon fx (Paling Mudah)**

1. Klik pada action **"Respond to a Power App or flow"**
2. Di field **"Data"**, klik icon **fx** (function) di sebelah kanan field
3. Di expression editor, ketik:
   ```
   body('Parse_JSON')
   ```
   Atau jika ada wrapper:
   ```
   body('Parse_JSON')?['body']
   ```
4. Klik **"OK"** atau **"Update"**

5. Di field **"RowCount"**, klik icon **fx**
6. Di expression editor, ketik:
   ```
   if(empty(body('Parse_JSON')), 0, length(body('Parse_JSON')))
   ```
   Atau jika ada wrapper:
   ```
   if(empty(body('Parse_JSON')?['body']), 0, length(body('Parse_JSON')?['body']))
   ```
7. Klik **"OK"** atau **"Update"**

**Cara 2: Pakai Code View**

1. Klik pada action **"Respond to a Power App or flow"**
2. Klik tab **"Code view"** (di bagian atas action)
3. Ganti seluruh code dengan:

**Jika output Parse JSON langsung array:**
```json
{
    "success": true,
    "rowcount": "@{if(empty(body('Parse_JSON')), 0, length(body('Parse_JSON')))}",
    "data": "@{body('Parse_JSON')}"
}
```

**Jika output Parse JSON ada wrapper:**
```json
{
    "success": true,
    "rowcount": "@{if(empty(body('Parse_JSON')?['body']), 0, length(body('Parse_JSON')?['body']))}",
    "data": "@{body('Parse_JSON')?['body']}"
}
```

4. Klik **"Done"** atau **"Save"**

**📖 Lihat file `POWERAUTOMATE_RESPOND_STEP_BY_STEP.md` untuk panduan lengkap step-by-step!**

---

### **Step 7: Test Flow**

1. Klik **"Save"** untuk menyimpan flow
2. Klik **"Test"** → **"Manually"**
3. Isi parameter test (bisa kosong semua)
4. Klik **"Run flow"**
5. Tunggu sampai selesai
6. Klik pada action **"Respond to Power Apps"**
7. Lihat output di bagian bawah

**Output yang benar:**
```json
{
    "statusCode": 200,
    "body": {
        "success": true,
        "rowcount": 655,
        "data": [
            {"ID": 422, "CustomerName": "...", ...},
            {"ID": 423, "CustomerName": "...", ...}
        ]
    }
}
```

**⚠️ Output yang SALAH (masih string):**
```json
{
    "statusCode": 200,
    "body": {
        "success": true,
        "rowcount": 655,
        "data": "[{\"ID\":422,...}]"  // ← Masih string!
    }
}
```

---

## 📱 Update Code di Power Apps

Setelah flow diubah, code di Power Apps jadi **SANGAT SEDERHANA**:

```powerappsfx
// Show loading indicator
Set(varIsLoading, true);

// Call Power Automate Flow
Set(
    varFlowResult,
    FilterBTPReview.Run({
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
        SearchBatch: If(IsBlank(searchBatchRv.Text), "", searchBatchRv.Text),
        SearchDescription: If(IsBlank(searchDescRv.Text), "", searchDescRv.Text),
        SearchBankType: If(IsBlank(searchBtRv.Text), "", searchBtRv.Text),
        SearchBTP: If(IsBlank(searchBtpRv.Text), "", searchBtpRv.Text),
        TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate)),
        UploadedAt: If(IsBlank(UaDpRvRk.SelectedDate), "", Text(UaDpRvRk.SelectedDate))
    })
);

// Langsung pakai .data (sudah Table, tidak perlu parse!)
Set(
    varBTPReviewData,
    If(
        !IsBlank(varFlowResult) && !IsBlank(varFlowResult.data),
        varFlowResult.data,  // ← Langsung Table!
        []
    )
);

// Hide loading indicator
Set(varIsLoading, false);

// Show success message
Notify(
    "Filter diterapkan",
    NotificationType.Success,
    2000
);
```

**Tidak perlu lagi:**
- ❌ `ParseJSON()`
- ❌ `ClearCollect()`
- ❌ Collection temporary
- ❌ Ribet-ribet parsing

**Cukup:**
- ✅ Langsung pakai `.data` → sudah Table!

---

## ✅ Checklist

- [ ] Flow "FilterBTPReview" sudah dibuka
- [ ] Action "Respond to Power Apps" sudah ditemukan
- [ ] Response body sudah diubah (langsung return array, bukan string)
- [ ] Tidak ada `string()` atau `json()` function yang stringify
- [ ] Flow sudah di-test dan output sudah benar (array, bukan string)
- [ ] Code di Power Apps sudah di-update (langsung pakai `.data`)

---

## 🎯 Kesimpulan

**Dengan mengubah Power Automate flow:**
- ✅ Code di Power Apps jadi **SANGAT SEDERHANA**
- ✅ Tidak perlu parse JSON lagi
- ✅ Langsung bisa digunakan di Gallery
- ✅ Lebih cepat dan tidak ribet

**Solusi ini jauh lebih baik daripada parse JSON di Power Apps!** 🚀
