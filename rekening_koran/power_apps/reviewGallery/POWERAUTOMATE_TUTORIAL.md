# 🚀 Tutorial Lengkap: Power Automate untuk Filter BTP_REVIEW

## 📋 Overview

Tutorial lengkap untuk membuat Power Automate Flow yang memanggil `SP_BTP_REVIEW_FilterText` dan mengembalikan hasil ke Power Apps. Switch/toggle tetap di Power Apps.

**Keuntungan:**
- ✅ Filter text dilakukan di SQL Server (delegation-safe)
- ✅ Switch/toggle tetap di Power Apps (fleksibel)
- ✅ Lebih fleksibel untuk error handling
- ✅ Bisa digunakan untuk multiple apps

---

## 🔧 STEP 1: Setup Power Automate Flow

### 1.1 Buat Flow Baru

1. Masuk ke https://make.powerautomate.com/
2. **Create** → **Instant cloud flow**
3. **Name:** `FilterBTPReviewText`
4. **Trigger:** **PowerApps (V2)**
5. Klik **Create**

---

### 1.2 Tambahkan Input Parameters

**⚠️ PENTING:** Step ini HARUS dilakukan sebelum Step 1.3 (SQL Action)!

**Langkah:**

1. **Klik pada trigger "PowerApps (V2)"** (yang berwarna ungu di flow diagram)

2. Di panel kanan, akan muncul section **"Inputs"**

3. **Tambahkan 7 parameter berikut satu per satu:**

   **Untuk setiap parameter:**
   - Klik **"Add an input"** (tombol dengan icon + di bawah "Inputs")
   - Pilih tipe: **"Text"** (dari dropdown)
   - **Name:** Ketik nama parameter sesuai tabel di bawah (case-sensitive!)
   - **Required:** Biarkan **unchecked** (tidak wajib)
   - **Default Value:** Kosongkan (biarkan empty)
   - Klik di luar field atau tekan Enter untuk save

| Input Name | Type | Required | Default Value | Catatan |
|-----------|------|----------|---------------|---------|
| `SearchCustomer` | Text | No | (kosongkan) | Nama harus tepat sama! |
| `SearchBatch` | Text | No | (kosongkan) | Nama harus tepat sama! |
| `SearchDescription` | Text | No | (kosongkan) | Nama harus tepat sama! |
| `SearchBankType` | Text | No | (kosongkan) | Nama harus tepat sama! |
| `SearchBTP` | Text | No | (kosongkan) | Nama harus tepat sama! |
| `TransactionDate` | Text | No | (kosongkan) | Nama harus tepat sama! |
| `UploadedAt` | Text | No | (kosongkan) | Nama harus tepat sama! |

**Verifikasi:**
Setelah semua parameter ditambahkan, di trigger "PowerApps (V2)" harus terlihat:
```
When Power Apps calls a flow (V2)
├─ SearchCustomer (Text)
├─ SearchBatch (Text)
├─ SearchDescription (Text)
├─ SearchBankType (Text)
├─ SearchBTP (Text)
├─ TransactionDate (Text)
└─ UploadedAt (Text)
```

**⚠️ Troubleshooting:**
- Jika parameter tidak muncul di Dynamic Content di SQL Action, berarti belum ditambahkan di trigger
- Pastikan nama parameter tepat sama (case-sensitive)
- Refresh browser jika parameter tidak muncul

---

### 1.3 Tambahkan SQL Action

**Action:** SQL Server → **Execute stored procedure (V2)**

**Configuration:**
- **Connection:** Pilih connection SQL Server Anda
- **Database name:** `POWERAPPS`
- **Procedure name:** `[dbo].[SP_BTP_REVIEW_FilterText]`

**Parameters (Checklist dan isi):**

1. Di bagian "Advanced parameters", checklist semua parameter berikut

2. **Cara mengisi Value (PENTING!):**

   **⚠️ JANGAN ketik langsung `@{triggerBody()['SearchCustomer']}`**
   
   **Gunakan Dynamic Content:**
   
   a. **Untuk parameter text (SearchCustomer, SearchBatch, dll):**
   - Checklist parameter (misalnya `@SearchCustomer`)
   - Klik field Value
   - Klik icon `{}` atau **"Dynamic content"** (di kanan field)
   - Di popup, cari dan pilih **"SearchCustomer"** dari list **"When Power Apps calls a flow (V2)"**
   - Power Automate akan otomatis mengisi: `@{triggerBody()['SearchCustomer']}`
   - Ulangi untuk semua parameter text lainnya
   
   b. **Untuk parameter date (UploadedAt, TransactionDate):**
   - Checklist parameter (misalnya `@UploadedAt`)
   - Klik field Value
   - Klik icon `{}` atau **"Dynamic content"**
   - Pilih **"UploadedAt"** dari trigger
   - Setelah terisi, klik di field Value lagi → Klik **"Expression"** atau **"fx"**
   - Ubah menjadi: `if(empty(triggerBody()['UploadedAt']), null, triggerBody()['UploadedAt'])`
   - Atau biarkan saja, Power Automate akan handle NULL otomatis
   
   **Tabel Parameter:**

| Parameter | Cara Mengisi |
|-----------|--------------|
| `@SearchCustomer` | Dynamic content → Pilih "SearchCustomer" dari trigger |
| `@SearchBatch` | Dynamic content → Pilih "SearchBatch" dari trigger |
| `@SearchDescription` | Dynamic content → Pilih "SearchDescription" dari trigger |
| `@SearchBankType` | Dynamic content → Pilih "SearchBankType" dari trigger |
| `@SearchBTP` | Dynamic content → Pilih "SearchBTP" dari trigger |
| `@UploadedAt` | Dynamic content → Pilih "UploadedAt" dari trigger (atau biarkan NULL jika kosong) |
| `@TransactionDate` | Dynamic content → Pilih "TransactionDate" dari trigger (atau biarkan NULL jika kosong) |

**Catatan Penting:**
- **JANGAN ketik manual** `@{triggerBody()['SearchCustomer']}` jika parameter belum ada di trigger
- **PASTIKAN** semua 7 input parameter sudah ditambahkan di trigger terlebih dahulu (Step 1.2)
- **GUNAKAN Dynamic Content** untuk memilih dari trigger (lebih aman dan tidak error)
- Jika parameter tidak muncul di Dynamic Content, berarti belum ditambahkan di trigger

---

### 1.4 Tambahkan Parse JSON Action

**Action:** Data operation → **Parse JSON**

**Langkah:**
1. Klik **"Add an action"** (tombol biru di bawah SQL action)
2. Cari: **"Parse JSON"**
3. Pilih: **Data operation → Parse JSON**

**Configuration:**

**Content:**

**Format Standar:**
```
@body('Execute_stored_procedure_(V2)')?['body']?['ResultSets']?['Table1']
```

**Catatan:** 
- Gunakan `?['body']` untuk akses body dari response
- `ResultSets` berisi hasil dari stored procedure
- `Table1` adalah nama default untuk result set pertama

**⚠️ Troubleshooting Content:**

**Berdasarkan output yang benar:**
Dari output SQL action, struktur yang benar adalah:
```json
{
    "body": {
        "ResultSets": {},
        "OutputParameters": {}
    }
}
```

**Content yang benar:**
```
@body('Execute_stored_procedure_(V2)')?['body']?['ResultSets']?['Table1']
```

**Jika ResultSets kosong `{}`:**
- **Masalah:** Stored procedure tidak return data
- **Cek:** Test SP langsung di SQL Server dengan parameter yang sama
- **Solusi:** Pastikan SP benar-benar melakukan SELECT dan return data

**Jika mendapat error "Expected Array but got Object":**

1. **Gunakan format dengan `body`:**
   ```
   @body('Execute_stored_procedure_(V2)')?['body']?['ResultSets']?['Table1']
   ```

2. **Atau coba tanpa `?['Table1']`:**
   ```
   @body('Execute_stored_procedure_(V2)')?['body']?['ResultSets']
   ```

3. **Cara Debug:**
   - Klik pada action "Execute stored procedure (V2)"
   - Lihat output di bagian bawah
   - Cari struktur `body.ResultSets.Table1`
   - Pastikan ada data di ResultSets (bukan kosong `{}`)

**Schema (WAJIB diisi!):**

**Cara 1: Generate dari Sample (Recommended)**
1. Klik **"Use sample payload to generate schema"**
2. Klik pada action **"Execute stored procedure (V2)"**
3. Di output, cari **"ResultSets"** → **"Table1"**
4. Copy JSON sample dari Table1
5. Paste ke field Schema di Parse JSON
6. Power Automate akan otomatis generate schema

**Cara 2: Schema Manual (Jika Tidak Ada Sample)**

Copy-paste schema berikut ke field Schema:

```json
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "ID": {"type": "integer"},
            "BatchID": {"type": "string"},
            "UploadedBy": {"type": "string"},
            "UploadedAt": {"type": "string"},
            "TransactionID": {"type": "integer"},
            "TransactionDate": {"type": "string"},
            "Description": {"type": "string"},
            "CustomerName": {"type": "string"},
            "BTP": {"type": "string"},
            "MatchPercentage": {"type": "number"},
            "MatchCount": {"type": "integer"},
            "TotalTransactions": {"type": "integer"},
            "LastLineNumber": {"type": "integer"},
            "TotalBTPOptions": {"type": "integer"},
            "OptionNumber": {"type": "integer"},
            "BestFlag": {"type": "string"},
            "LatestFlag": {"type": "string"},
            "Label": {"type": "string"},
            "Status": {"type": "string"},
            "Message": {"type": "string"},
            "BankType": {"type": "string"},
            "ProcessedAt": {"type": "string"},
            "IsApproved": {"type": "boolean"},
            "ApprovedBy": {"type": "string"},
            "ApprovedAt": {"type": "string"},
            "Notes": {"type": "string"},
            "CreatedAt": {"type": "string"},
            "ModifiedAt": {"type": "string"},
            "Amount": {"type": "number"},
            "TransactionType": {"type": "string"}
        },
        "required": []
    }
}
```

**⚠️ Catatan:** Schema wajib diisi! Jika tidak, akan muncul error "Schema is required".

---

### 1.5 Tambahkan Respond to Power Apps Action

**Action:** PowerApps → **Respond to a PowerApp or flow**

**Langkah:**
1. Klik **"Add an action"** (tombol biru di bawah Parse JSON)
2. Cari: **"Respond to a PowerApp"**
3. Pilih: **PowerApps → Respond to a PowerApp or flow**

**Configuration:**

**⚠️ Catatan:** Code View biasanya **read-only** untuk action ini, jadi gunakan **Add Input** di tab Parameters.

**Langkah-langkah:**

1. **Pastikan berada di tab "Parameters"** (bukan Code view)

2. **Klik "Add an input"** (tombol dengan icon +)

3. **Parameter "Success":**
   - Pilih tipe: **"Yes/No"** (bukan Text!)
   - Name: `Success`
   - Value: Centang checkbox untuk `true`
   - Klik di luar field atau tekan Enter

4. **Klik "Add an input"** lagi

5. **Parameter "Data":**
   - Pilih tipe: **"Text"**
   - Name: `Data`
   - Value: `@{body('Parse_JSON')}`
   
   **Cara mengisi Value (pilih salah satu):**
   
   **Cara 1: Menggunakan Dynamic Content (Paling Mudah)**
   - Klik field Value
   - Klik icon `{}` atau **"Dynamic content"** (di kanan field)
   - Pilih **"Parse JSON"** dari list action sebelumnya
   - Pilih **"body"** dari output Parse JSON
   - Power Automate akan otomatis mengisi: `@{body('Parse_JSON')}`
   
   **Cara 2: Ketik Langsung**
   - Klik field Value
   - Ketik langsung: `@{body('Parse_JSON')}`
   - Pastikan format benar dengan `@{...}`
   
   **Catatan:**
   - `Parse_JSON` adalah nama action Parse JSON (cek di flow diagram jika berbeda)
   - Klik di luar field atau tekan Enter untuk save

6. **Klik "Add an input"** lagi

7. **Parameter "RowCount":**
   - Pilih tipe: **"Number"**
   - Name: `RowCount`
   - Value: `@{length(body('Parse_JSON'))}`
   
   **Cara mengisi Value (pilih salah satu):**
   
   **Cara 1: Menggunakan Expression (Recommended)**
   - Klik field Value
   - Di kanan field, cari tombol **"Expression"** atau **"fx"** atau **"Insert expression"**
   - Klik tombol tersebut
   - Ketik: `length(body('Parse_JSON'))`
   - Klik **"OK"** atau **"Done"**
   - Power Automate akan otomatis menambahkan `@{...}` di sekelilingnya
   
   **Cara 2: Ketik Langsung**
   - Klik field Value
   - Ketik langsung: `@{length(body('Parse_JSON'))}`
   - Pastikan format benar dengan `@{...}`
   
   **Cara 3: Menggunakan Dynamic Content + Expression**
   - Klik field Value
   - Klik icon `{}` atau **"Dynamic content"**
   - Di bagian bawah, klik **"Expression"** atau **"fx"**
   - Ketik: `length(body('Parse_JSON'))`
   - Klik **"OK"**
   
   **Catatan:**
   - `Parse_JSON` adalah nama action Parse JSON (cek di flow diagram jika berbeda)
   - Formula akan menjadi: `@{length(body('Parse_JSON'))}`
   - Klik di luar field atau tekan Enter untuk save

**Hasil akhir harus terlihat:**
```
Respond to a PowerApp or flow
├─ Success: true (Yes/No)
├─ Data: @{body('Parse_JSON')} (Text)
└─ RowCount: @{length(body('Parse_JSON'))} (Number)
```

---

## ✅ Checklist Flow Setup

- [ ] Flow sudah dibuat dengan nama `FilterBTPReviewText`
- [ ] Trigger PowerApps (V2) sudah ditambahkan
- [ ] 7 input parameters sudah ditambahkan
- [ ] SQL Action sudah dikonfigurasi dengan semua parameter
- [ ] Parse JSON action sudah ditambahkan dengan Content dan Schema
- [ ] Respond to Power Apps action sudah ditambahkan dengan 3 parameter
- [ ] Flow sudah di-save
- [ ] Flow sudah di-test

---

## 🧪 Testing Flow

1. Klik **"Test"** di kanan atas
2. Pilih **"Manual"**
3. Klik **"Run flow"**
4. Isi parameter test:
   ```
   SearchCustomer: "PT ABC"
   SearchBatch: ""
   SearchDescription: ""
   SearchBankType: ""
   SearchBTP: ""
   TransactionDate: ""
   UploadedAt: ""
   ```
5. Klik **"Run flow"**
6. Cek hasil:
   - **Parse JSON** → harus ada output dengan struktur data
   - **Respond to Power Apps** → Success: true, Data: array, RowCount: number

---

## 📱 STEP 2: Setup Power Apps

### 2.1 Buat Variabel

**OnStart** atau **OnVisible** screen:

```powerappsfx
Set(varBTPReviewData, []);
Set(varIsLoading, false);
```

---

### 2.2 Buat Tombol Submit Search

**Button OnSelect Property:**

```powerappsfx
// Show loading
Set(varIsLoading, true);

// Call Flow
Set(
    varBTPReviewData,
    Flow_FilterBTPReviewText.Run({
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
        SearchBatch: If(IsBlank(searchBatchRv.Text), "", searchBatchRv.Text),
        SearchDescription: If(IsBlank(searchDescRv.Text), "", searchDescRv.Text),
        SearchBankType: If(IsBlank(searchBtRv.Text), "", searchBtRv.Text),
        SearchBTP: If(IsBlank(searchBtpRv.Text), "", searchBtpRv.Text),
        TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate)),
        UploadedAt: If(IsBlank(UaDpRvRk.SelectedDate), "", Text(UaDpRvRk.SelectedDate))
    }).Data
);

// Hide loading
Set(varIsLoading, false);

// Show success message
Notify(
    "Filter diterapkan: " & CountRows(varBTPReviewData) & " rows",
    NotificationType.Success,
    2000
);
```

**Catatan:**
- Ganti `Flow_FilterBTPReviewText` dengan nama flow yang dibuat di Power Automate
- Pastikan nama control text field sesuai (searchCustomerRv, searchBatchRv, dll)
- Pastikan nama control date picker sesuai (TrxDpRvRk, UaDpRvRk)

---

### 2.3 Update Gallery Items Property

**Items Property:**

```powerappsfx
FirstN(
    Sort(
        Filter(
            varBTPReviewData,
            // Filter Status (switch rkToggleRv) - tetap di Power Apps
            (
                rkToggleRv.Checked && (
                    Status = "NO_MATCH" ||
                    Status = "UNKNOWN_BANK" ||
                    Status = "MISSING" ||
                    Status = "NO_PATTERN"
                )
            ) || (
                !rkToggleRv.Checked && (
                    Status = "FAIR" ||
                    Status = "GOOD" ||
                    Status = "LOW" ||
                    Status = "EXCELLENT"
                )
            ) &&
            IsApproved = false &&
            // Filter TransactionType (switch rkToggleRvCd) - tetap di Power Apps
            (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
        ),
        MatchPercentage,
        SortOrder.Ascending
    ),
    200000
)
```

---

## 🔄 Flow Kerja

1. User isi text fields (CustomerName, BatchID, Description, BankType, BTP, UploadedAt, TransactionDate)
2. User klik tombol Submit Search
3. Power Apps memanggil Flow dengan parameter dari text fields
4. Flow memanggil SP_BTP_REVIEW_FilterText di SQL Server
5. SP return hasil filter berdasarkan text fields
6. Flow parse JSON dan kirim kembali ke Power Apps
7. Power Apps simpan hasil ke variabel `varBTPReviewData`
8. Gallery menampilkan data dari variabel + filter Status dan TransactionType di Power Apps

---

## ⚠️ Troubleshooting

### **Error: "Schema is required" di Parse JSON**

**Solusi:**
- Pastikan field Schema sudah diisi
- Copy-paste schema manual di atas
- Atau gunakan "Generate from sample" jika sudah ada sample data

### **Error: "Expected Array but got Object" di Parse JSON**

**Solusi:**
- **Masalah:** Content field mengakses object, bukan array
- **Cek struktur data:** Klik pada action "Execute stored procedure (V2)" → Lihat output → Cari struktur yang benar
- **Coba variasi Content:**
  1. `@body('Execute_stored_procedure_(V2)')?['body']?['ResultSets']?['Table1']` (dengan body - recommended)
  2. `@body('Execute_stored_procedure_(V2)')?['ResultSets']?['Table1']` (tanpa body)
  3. `@outputs('Execute_stored_procedure_(V2)')?['body']?['ResultSets']?['Table1']` (dengan outputs)
- **Jika masih error:** Coba generate schema dari sample yang benar (klik "Use sample payload" → ambil dari output SQL action)

### **Error: ResultSets Kosong `{}`**

**Solusi:**
- **Masalah:** Stored procedure tidak return data atau tidak ada rows yang match filter
- **Cek di SQL Server:** Test SP langsung dengan parameter yang sama
  ```sql
  EXEC [dbo].[SP_BTP_REVIEW_FilterText] 
      @SearchCustomer = NULL,
      @SearchBatch = NULL,
      ...
  ```
- **Jika SP return data tapi ResultSets kosong:** 
  - Cek apakah SP menggunakan `SET NOCOUNT ON` (harus ada)
  - Cek apakah SP benar-benar melakukan `SELECT` statement
  - Cek apakah ada error di SP execution
- **Untuk handle empty result di Parse JSON:** Gunakan Content dengan if statement:
  ```
  @if(empty(body('Execute_stored_procedure_(V2)')?['body']?['ResultSets']?['Table1']), json('[]'), body('Execute_stored_procedure_(V2)')?['body']?['ResultSets']?['Table1'])
  ```

### **Error: Code View Read-Only di Respond to Power Apps**

**Solusi:** Ini normal! Gunakan **Add Input** di tab Parameters seperti di panduan.

### **Error: Flow tidak ditemukan di Power Apps**

**Solusi:**
- Pastikan flow sudah di-save di Power Automate
- Pastikan nama flow sesuai (case-sensitive)
- Refresh Power Apps Studio
- Pastikan flow sudah di-share ke environment yang sama

### **Error: "property 'SearchCustomer' doesn't exist" di SQL Action**

**Solusi:**
- **Masalah:** Parameter belum ditambahkan di trigger atau nama tidak sesuai
- **Cek:** Klik pada trigger "PowerApps (V2)" → Pastikan parameter "SearchCustomer" ada di list Inputs
- **Jika belum ada:** Tambahkan parameter di trigger terlebih dahulu (Step 1.2)
- **Jika sudah ada tapi masih error:** 
  - Pastikan nama parameter tepat sama (case-sensitive)
  - Gunakan **Dynamic Content** untuk memilih parameter (jangan ketik manual)
  - Refresh browser dan coba lagi
- **Verifikasi:** Di Dynamic Content, parameter harus muncul di bawah "When Power Apps calls a flow (V2)"

### **Error: Dynamic Content tidak muncul**

**Solusi:**
- Pastikan action sebelumnya sudah ada dan berhasil di-run
- Coba ketik langsung formula: `@{body('Parse_JSON')}`
- Pastikan nama action sesuai (cek di flow diagram)

### **Gallery kosong setelah Submit Search**

**Solusi:**
- Cek apakah flow return data (test di Power Automate)
- Cek apakah parameter dikirim dengan benar (gunakan `Notify()` untuk debug)
- Pastikan filter Status dan TransactionType tidak terlalu ketat
- Cek apakah variabel `varBTPReviewData` sudah dideklarasikan

---

## 💡 Tips

1. **Flow Name:** Pastikan nama flow di Power Automate sesuai dengan yang dipanggil di Power Apps (case-sensitive)
2. **Error Handling:** Bisa tambahkan "Configure run after" di flow untuk handle error
3. **Performance:** Flow akan execute di cloud, jadi lebih cepat daripada direct SQL connection
4. **Caching:** Variabel `varBTPReviewData` akan di-cache, jadi tidak perlu panggil flow setiap kali Gallery refresh
5. **Empty Fields:** Jika text field kosong, kirim empty string `""` ke flow (akan di-handle sebagai NULL di SP)
6. **Testing:** Selalu test flow di Power Automate sebelum digunakan di Power Apps

---

## 🔗 File Terkait

- `SP_BTP_REVIEW_FilterText.sql` - Stored Procedure definition
- `gallery_WITH_POWERAUTOMATE_TEXT.c` - Contoh implementasi Gallery
- `btnSubmitSearch_POWERAUTOMATE.c` - Contoh tombol Submit Search

---

## 📝 Quick Reference

**Flow Name:** `FilterBTPReviewText`

**Input Parameters (7):**
- SearchCustomer (Text)
- SearchBatch (Text)
- SearchDescription (Text)
- SearchBankType (Text)
- SearchBTP (Text)
- TransactionDate (Text)
- UploadedAt (Text)

**SQL SP:** `[dbo].[SP_BTP_REVIEW_FilterText]`

**Response:**
- Success (Yes/No)
- Data (Text/Array)
- RowCount (Number)

**Power Apps Variable:** `varBTPReviewData`

**Power Apps Formula:**
```powerappsfx
Flow_FilterBTPReviewText.Run({...}).Data
```
