# 🚀 Power Automate Flow Guide untuk Filter BTP_REVIEW

## 📋 Overview

Solusi menggunakan Power Automate Flow untuk memanggil stored procedure `SP_BTP_REVIEW_FilterComplete` dan mengembalikan hasil ke Power Apps.

**Keuntungan:**
- ✅ Tidak perlu tambahkan SP sebagai data source di Power Apps
- ✅ Lebih fleksibel untuk error handling
- ✅ Bisa tambahkan logging, notification, dll
- ✅ Bisa digunakan untuk multiple apps

---

## 🔧 STEP 1: Buat Power Automate Flow

### 1.1 Create New Flow

1. Masuk ke https://make.powerautomate.com/
2. **Create** → **Instant cloud flow**
3. **Name:** `FilterBTPReview` (atau sesuai kebutuhan)
4. **Trigger:** **PowerApps (V2)**
5. Click **Create**

### 1.2 Add Input Parameters

**Langkah-langkah:**

1. **Klik pada trigger "PowerApps (V2)"** yang sudah dibuat
2. Di panel kanan, akan muncul opsi **"Add an input"**
3. Klik **"Add an input"** untuk setiap parameter berikut:

| Input Name | Type | Required | Default Value |
|-----------|------|----------|---------------|
| `ShowReview` | Boolean | No | `true` |
| `SearchCustomer` | Text | No | (empty) |
| `SearchBatch` | Text | No | (empty) |
| `SearchDescription` | Text | No | (empty) |
| `SearchBankType` | Text | No | (empty) |
| `TransactionDate` | Text | No | (empty) |
| `UploadedAt` | Text | No | (empty) |
| `SearchBTP` | Text | No | (empty) |
| `ShowDebit` | Boolean | No | `false` |
| `SortBy` | Text | No | `MatchPercentage` |
| `SortOrder` | Text | No | `ASC` |

**Cara menambahkan (Step-by-step):**

1. **Klik tombol "Add an input"** (tombol dengan icon + di bawah parameter yang sudah ada)

2. **Untuk setiap parameter, pilih tipe:**
   - **ShowReview** → Pilih **"Yes/No"** (Boolean) → Isi nama: `ShowReview` → Default: `true`
   - **ShowDebit** → Pilih **"Yes/No"** (Boolean) → Isi nama: `ShowDebit` → Default: `false`
   - **SearchCustomer** → Pilih **"Text"** → Isi nama: `SearchCustomer` → Default: (kosongkan)
   - **SearchBatch** → Pilih **"Text"** → Isi nama: `SearchBatch` → Default: (kosongkan)
   - **SearchDescription** → Pilih **"Text"** → Isi nama: `SearchDescription` → Default: (kosongkan)
   - **SearchBankType** → Pilih **"Text"** → Isi nama: `SearchBankType` → Default: (kosongkan)
   - **TransactionDate** → Pilih **"Text"** → Isi nama: `TransactionDate` → Default: (kosongkan)
   - **UploadedAt** → Pilih **"Text"** → Isi nama: `UploadedAt` → Default: (kosongkan)
   - **SearchBTP** → Pilih **"Text"** → Isi nama: `SearchBTP` → Default: (kosongkan)
   - **SortBy** → Pilih **"Text"** → Isi nama: `SortBy` → Default: `MatchPercentage`
   - **SortOrder** → Pilih **"Text"** → Isi nama: `SortOrder` → Default: `ASC`

3. **Untuk setiap parameter:**
   - **Required**: Biarkan **unchecked** (tidak wajib) untuk semua parameter
   - **Default Value**: Isi sesuai tabel di atas (atau kosongkan untuk yang tidak ada default)

**Tips:**
- Setelah klik "Add an input", akan muncul dropdown untuk memilih tipe (Text, Yes/No, Number, dll)
- Nama parameter harus sesuai dengan yang ada di tabel (case-sensitive)
- Default value bisa dikosongkan jika tidak diperlukan

**Catatan:** 
- Input parameters ditambahkan **di trigger PowerApps (V2)**, bukan sebagai action terpisah
- Setelah semua parameter ditambahkan, trigger akan terlihat seperti:
  ```
  PowerApps (V2)
  ├─ ShowReview (Boolean)
  ├─ SearchCustomer (Text)
  ├─ SearchBatch (Text)
  └─ ... (parameter lainnya)
  ```

### 1.3 Add SQL Action

**Action:** SQL Server → **Execute stored procedure (V2)**

**Configuration:**
```
Connection: [Your SQL Server Connection]
Procedure name: [dbo].[SP_BTP_REVIEW_FilterComplete]
```

**Parameters:**
```
@ShowReview = @{triggerBody()['ShowReview']}
@SearchCustomer = @{triggerBody()['SearchCustomer']}
@SearchBatch = @{triggerBody()['SearchBatch']}
@SearchDescription = @{triggerBody()['SearchDescription']}
@SearchBankType = @{triggerBody()['SearchBankType']}
@TransactionDate = @{if(empty(triggerBody()['TransactionDate']), null, triggerBody()['TransactionDate'])}
@UploadedAt = @{if(empty(triggerBody()['UploadedAt']), null, triggerBody()['UploadedAt'])}
@SearchBTP = @{triggerBody()['SearchBTP']}
@ShowDebit = @{triggerBody()['ShowDebit']}
@SortBy = @{triggerBody()['SortBy']}
@SortOrder = @{triggerBody()['SortOrder']}
@IsApproved = 0
```

**Note:** 
- Untuk parameter yang bisa NULL (seperti TransactionDate), gunakan `if(empty(...), null, ...)`
- Untuk BIT parameter, kirim `true`/`false` atau `1`/`0`

### 1.4 Parse JSON Results

**Action:** Data operation → **Parse JSON**

**Content:**
```
@body('Execute_stored_procedure_(V2)')?['ResultSets']?['Table1']
```

**Schema:** (Click "Generate from sample" dan paste sample output dari SP)

Atau manual schema:
```json
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "ID": {"type": "integer"},
            "BatchID": {"type": "string"},
            "TransactionID": {"type": "integer"},
            "TransactionDate": {"type": "string"},
            "Description": {"type": "string"},
            "CustomerName": {"type": "string"},
            "BTP": {"type": "string"},
            "MatchPercentage": {"type": "number"},
            "Status": {"type": "string"},
            "Message": {"type": "string"},
            "BankType": {"type": "string"},
            "IsApproved": {"type": "boolean"},
            "Amount": {"type": "number"},
            "TransactionType": {"type": "string"}
        }
    }
}
```

### 1.5 Respond to Power Apps

**Action:** PowerApps → **Respond to a PowerApp or flow**

**Response Body:**
```json
{
    "Success": true,
    "Data": "@{body('Parse_JSON')}",
    "RowCount": "@{length(body('Parse_JSON'))}"
}
```

---

## 📱 STEP 2: Power Apps Implementation

### 2.1 Create Variable

**OnStart** atau **OnVisible** screen:
```powerappsfx
Set(varBTPReviewData, []);
Set(varIsLoading, false);
```

### 2.2 Create Button (Load Data)

**Button OnSelect Property:**
```powerappsfx
// Show loading
Set(varIsLoading, true);

// Call Flow
Set(
    varBTPReviewData,
    Flow_FilterBTPReview.Run({
        ShowReview: rkToggleRv.Checked,
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
        SearchBatch: If(IsBlank(searchBatchRv.Text), "", searchBatchRv.Text),
        TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate)),
        UploadedAt: If(IsBlank(UaDpRvRk.SelectedDate), "", Text(UaDpRvRk.SelectedDate)),
        ShowDebit: rkToggleRvCd.Checked,
        SortBy: "MatchPercentage",
        SortOrder: "ASC"
    }).Data
);

// Hide loading
Set(varIsLoading, false);

// Show notification
Notify(
    "Loaded " & CountRows(varBTPReviewData) & " rows",
    NotificationType.Success,
    2000
);
```

### 2.3 Gallery Items Property

```powerappsfx
varBTPReviewData
```

Atau dengan sorting:
```powerappsfx
Sort(
    varBTPReviewData,
    MatchPercentage,
    SortOrder.Ascending
)
```

---

## 🎯 STEP 3: Auto-load on Screen Open (Optional)

**OnVisible Property Screen:**
```powerappsfx
Set(
    varBTPReviewData,
    Flow_FilterBTPReview.Run({
        ShowReview: true,
        SearchCustomer: "",
        TransactionDate: "",
        ShowDebit: false
    }).Data
);
```

---

## ⚠️ Important Notes

1. **Flow Response Format:**
   - Flow mengembalikan object dengan property `Data`
   - Akses dengan `.Data` di Power Apps
   - Contoh: `Flow_FilterBTPReview.Run({...}).Data`

2. **Error Handling:**
   ```powerappsfx
   With(
       {
           flowResult: Flow_FilterBTPReview.Run({...})
       },
       If(
           flowResult.Success,
           Set(varBTPReviewData, flowResult.Data),
           Notify("Error: " & flowResult.Error, NotificationType.Error)
       )
   )
   ```

3. **Loading Indicator:**
   - Set `varIsLoading = true` sebelum call flow
   - Set `varIsLoading = false` setelah flow selesai
   - Tampilkan loading di UI dengan `If(varIsLoading, ...)`

4. **Performance:**
   - Flow akan lebih lambat daripada direct data source
   - Pertimbangkan caching jika data tidak sering berubah
   - Gunakan debounce untuk auto-refresh

---

## 📝 File Reference

- `gallery_WITH_POWERAUTOMATE.c` - Contoh implementasi di Power Apps
- `btnApplyFilter.c` - Contoh button untuk call flow

---

## ✅ Checklist

- [ ] Flow dibuat dengan trigger PowerApps (V2)
- [ ] Semua parameter input sudah ditambahkan
- [ ] SQL action memanggil SP_BTP_REVIEW_FilterComplete
- [ ] Parse JSON action sudah dikonfigurasi
- [ ] Respond to PowerApps mengembalikan data
- [ ] Variable `varBTPReviewData` dibuat di Power Apps
- [ ] Button untuk call flow sudah dibuat
- [ ] Gallery Items property menggunakan `varBTPReviewData`
- [ ] Error handling sudah ditambahkan (optional)
- [ ] Loading indicator sudah ditambahkan (optional)

