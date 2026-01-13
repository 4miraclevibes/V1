# 📋 Checklist Parameter SQL di Power Automate

## ✅ Parameter yang HARUS di-checklist (sesuai dengan trigger):

Berdasarkan parameter yang sudah dibuat di trigger PowerApps (V2), checklist parameter berikut:

### **Parameter Wajib (9 parameter):**

| No | Parameter Name | Checklist | Value |
|----|---------------|-----------|-------|
| 1 | **ShowReview** | ✅ | `@{triggerBody()['ShowReview']}` |
| 2 | **ShowDebit** | ✅ | `@{triggerBody()['ShowDebit']}` |
| 3 | **SearchCustomer** | ✅ | `@{triggerBody()['SearchCustomer']}` |
| 4 | **SearchBatch** | ✅ | `@{triggerBody()['SearchBatch']}` |
| 5 | **SearchDescription** | ✅ | `@{triggerBody()['SearchDescription']}` |
| 6 | **SearchBankType** | ✅ | `@{triggerBody()['SearchBankType']}` |
| 7 | **TransactionDate** | ✅ | `@{if(empty(triggerBody()['TransactionDate']), null, triggerBody()['TransactionDate'])}` |
| 8 | **UploadedAt** | ✅ | `@{if(empty(triggerBody()['UploadedAt']), null, triggerBody()['UploadedAt'])}` |
| 9 | **SearchBTP** | ✅ | `@{triggerBody()['SearchBTP']}` |

### **Parameter dengan Default Value:**

| No | Parameter Name | Checklist | Value |
|----|---------------|-----------|-------|
| 10 | **IsApproved** | ✅ | `0` (hardcoded) |
| 11 | **SortBy** | ⚠️ Optional | `'MatchPercentage'` (default) |
| 12 | **SortOrder** | ⚠️ Optional | `'ASC'` (default) |

---

## ❌ Parameter yang TIDAK perlu di-checklist:

Parameter berikut **tidak perlu di-checklist** karena tidak ada di trigger:

- ❌ `IncludeNoMatch`
- ❌ `IncludeUnknownBank`
- ❌ `IncludeMissing`
- ❌ `IncludeNoPattern`
- ❌ `IncludeFair`
- ❌ `IncludeGood`
- ❌ `IncludeLow`
- ❌ `IncludeExcellent`

**Catatan:** Parameter ini akan menggunakan default value dari SP (biasanya semua = 1).

---

## 📝 Cara Mengisi Parameter:

### **1. Checklist parameter yang diperlukan:**
- Centang checkbox di sebelah kiri nama parameter
- Setelah di-checklist, akan muncul field untuk mengisi value

### **2. Isi Value untuk setiap parameter:**

**Untuk parameter dari trigger:**
```
@{triggerBody()['ShowReview']}
@{triggerBody()['SearchCustomer']}
@{triggerBody()['TransactionDate']}
```

**Untuk parameter Date yang bisa NULL:**
```
@{if(empty(triggerBody()['TransactionDate']), null, triggerBody()['TransactionDate'])}
@{if(empty(triggerBody()['UploadedAt']), null, triggerBody()['UploadedAt'])}
```

**Untuk parameter dengan default value:**
```
IsApproved = 0
SortBy = 'MatchPercentage'
SortOrder = 'ASC'
```

---

## 🎯 Ringkasan:

**Checklist (9 parameter wajib):**
- ✅ ShowReview
- ✅ ShowDebit
- ✅ SearchCustomer
- ✅ SearchBatch
- ✅ SearchDescription
- ✅ SearchBankType
- ✅ TransactionDate
- ✅ UploadedAt
- ✅ SearchBTP
- ✅ IsApproved (hardcoded = 0)

**Tidak perlu checklist:**
- ❌ IncludeNoMatch, IncludeUnknownBank, IncludeMissing, IncludeNoPattern
- ❌ IncludeFair, IncludeGood, IncludeLow, IncludeExcellent
- ⚠️ SortBy dan SortOrder (optional, bisa pakai default dari SP)

---

## 💡 Tips:

1. **Gunakan Dynamic Content:**
   - Setelah checklist parameter, klik field value
   - Pilih **"Dynamic content"** atau ketik langsung `@{triggerBody()['ParameterName']}`

2. **Untuk Date Parameter:**
   - Gunakan `if(empty(...), null, ...)` untuk handle empty string
   - Power Apps mengirim date sebagai string, jadi perlu convert ke DATE di SP

3. **Untuk Boolean Parameter:**
   - `ShowReview` dan `ShowDebit` akan otomatis convert ke BIT di SQL

4. **Test Connection:**
   - Setelah semua parameter diisi, klik **"Test"** untuk memastikan connection berhasil

