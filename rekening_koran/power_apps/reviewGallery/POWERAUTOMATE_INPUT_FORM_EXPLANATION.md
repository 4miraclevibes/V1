# 📝 Penjelasan Form Input Parameter di Power Automate

## 🎯 Form Input Parameter

Ketika Anda klik **"Add an input"**, akan muncul form dengan 2 field:

```
┌─────────────────────────────────────────┐
│  [Icon]  [Field Kiri]  [Field Kanan]   │
│          ↓              ↓               │
│        TIPE          NAMA PARAMETER     │
└─────────────────────────────────────────┘
```

---

## 📋 Penjelasan Field:

### **Field Kiri (Tipe Parameter):**
- **Dropdown** untuk memilih tipe data
- **Klik dropdown** untuk memilih tipe
- Pilihan: **"Yes/No"**, **"Text"**, **"Number"**, dll
- **Yang dipilih:**
  - **"Yes/No"** untuk `ShowReview` dan `ShowDebit` ✅ (seperti di screenshot Anda)
  - **"Text"** untuk semua parameter lainnya (`SearchCustomer`, `SearchBatch`, dll)

**Contoh di screenshot Anda:**
- Field kiri menampilkan: **"Yes/No"** ← Ini adalah tipe yang dipilih dari dropdown

### **Field Kanan (Nama Parameter):**
- **Text field** untuk mengisi nama parameter
- **Ketik manual** nama parameter di sini
- **Harus sesuai** dengan nama di tabel (case-sensitive)
- Contoh: `ShowReview`, `SearchCustomer`, `SearchBatch`, dll

**Contoh di screenshot Anda:**
- Field kanan menampilkan: **"ShowReview"** ← Ini adalah nama yang diketik manual

### **Visual dari Screenshot Anda:**
```
┌─────────────────────────────────────────┐
│  [✓]  Yes/No    ShowReview              │
│       ↓          ↓                       │
│    FIELD KIRI  FIELD KANAN              │
│    (DROPDOWN)  (KETIK MANUAL)           │
│    Pilih:      Ketik:                   │
│    - Yes/No    - ShowReview             │
│    - Text      - SearchCustomer         │
│    - Number    - SearchBatch            │
└─────────────────────────────────────────┘
```

**✅ Sudah benar!** 
- Field kiri = Dropdown untuk pilih tipe (Yes/No atau Text)
- Field kanan = Text field untuk ketik nama parameter

### **Default Value (Opsional):**
- Setelah nama parameter diisi, biasanya ada field untuk **Default Value**
- Bisa dikosongkan atau diisi sesuai tabel

---

## ✅ Contoh Lengkap untuk Setiap Parameter:

### 1. **ShowReview** (Sudah ada di screenshot Anda)
```
┌─────────────────────────────────────────┐
│  [✓]  Yes/No    ShowReview    true      │
│       ↓          ↓            ↓         │
│      TIPE      NAMA        DEFAULT      │
└─────────────────────────────────────────┘
```

### 2. **ShowDebit**
```
Klik "Add an input" →
┌─────────────────────────────────────────┐
│  [✓]  Yes/No    ShowDebit     false     │
│       ↓          ↓            ↓         │
│      TIPE      NAMA        DEFAULT      │
└─────────────────────────────────────────┘
```

### 3. **SearchCustomer**
```
Klik "Add an input" →
┌─────────────────────────────────────────┐
│  [T]  Text      SearchCustomer   (kosong)│
│       ↓          ↓                      │
│      TIPE      NAMA                     │
└─────────────────────────────────────────┘
```

### 4. **SearchBatch**
```
Klik "Add an input" →
┌─────────────────────────────────────────┐
│  [T]  Text      SearchBatch     (kosong)│
│       ↓          ↓                      │
│      TIPE      NAMA                     │
└─────────────────────────────────────────┘
```

### 5. **TransactionDate**
```
Klik "Add an input" →
┌─────────────────────────────────────────┐
│  [T]  Text      TransactionDate  (kosong)│
│       ↓          ↓                       │
│      TIPE      NAMA                      │
└─────────────────────────────────────────┘
```

### 6. **SortBy**
```
Klik "Add an input" →
┌─────────────────────────────────────────┐
│  [T]  Text      SortBy    MatchPercentage│
│       ↓          ↓          ↓            │
│      TIPE      NAMA      DEFAULT        │
└─────────────────────────────────────────┘
```

### 7. **SortOrder**
```
Klik "Add an input" →
┌─────────────────────────────────────────┐
│  [T]  Text      SortOrder      ASC       │
│       ↓          ↓            ↓          │
│      TIPE      NAMA        DEFAULT      │
└─────────────────────────────────────────┘
```

---

## 📝 Checklist Lengkap:

| No | Parameter Name | Field Kiri (Tipe) | Field Kanan (Nama) | Default Value |
|----|---------------|-------------------|-------------------|---------------|
| 1 | ShowReview | **Yes/No** | `ShowReview` | `true` |
| 2 | ShowDebit | **Yes/No** | `ShowDebit` | `false` |
| 3 | SearchCustomer | **Text** | `SearchCustomer` | (kosong) |
| 4 | SearchBatch | **Text** | `SearchBatch` | (kosong) |
| 5 | SearchDescription | **Text** | `SearchDescription` | (kosong) |
| 6 | SearchBankType | **Text** | `SearchBankType` | (kosong) |
| 7 | TransactionDate | **Text** | `TransactionDate` | (kosong) |
| 8 | UploadedAt | **Text** | `UploadedAt` | (kosong) |
| 9 | SearchBTP | **Text** | `SearchBTP` | (kosong) |
| 10 | SortBy | **Text** | `SortBy` | `MatchPercentage` |
| 11 | SortOrder | **Text** | `SortOrder` | `ASC` |

---

## ⚠️ Catatan Penting:

1. **Field Kiri = Tipe Data:**
   - Pilih dari dropdown: **"Yes/No"** atau **"Text"**
   - Tidak perlu ketik manual, cukup pilih dari dropdown

2. **Field Kanan = Nama Parameter:**
   - **Harus ketik manual** sesuai nama di tabel
   - **Case-sensitive**: `SearchCustomer` (bukan `searchcustomer`)
   - **Tidak boleh ada spasi**: `SearchCustomer` (bukan `Search Customer`)

3. **Default Value:**
   - Bisa dikosongkan untuk parameter Text
   - Untuk Yes/No: isi `true` atau `false`
   - Untuk Text dengan default: isi sesuai tabel

4. **Required:**
   - Biarkan **unchecked** (tidak wajib) untuk semua parameter
   - Semua parameter adalah optional

---

## 🎯 Langkah-Langkah Singkat:

1. Klik **"Add an input"**
2. **Field Kiri**: Pilih **"Yes/No"** atau **"Text"** dari dropdown
3. **Field Kanan**: Ketik nama parameter (contoh: `SearchCustomer`)
4. **Default Value** (jika ada): Isi sesuai tabel atau kosongkan
5. **Required**: Biarkan unchecked
6. Ulangi untuk semua parameter

---

## ✅ Setelah Semua Parameter Ditambahkan:

Trigger Anda akan terlihat seperti ini:

```
When Power Apps calls a flow (V2)
├─ ShowReview (Yes/No) = true
├─ ShowDebit (Yes/No) = false
├─ SearchCustomer (Text)
├─ SearchBatch (Text)
├─ SearchDescription (Text)
├─ SearchBankType (Text)
├─ TransactionDate (Text)
├─ UploadedAt (Text)
├─ SearchBTP (Text)
├─ SortBy (Text) = MatchPercentage
└─ SortOrder (Text) = ASC
```

Setelah itu, lanjutkan ke **Step 1.3** untuk menambahkan action SQL!

