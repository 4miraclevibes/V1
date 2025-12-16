# 🎯 Panduan Implementasi Filter dengan Stored Procedure

## 📋 Opsi Implementasi

Ada **3 pendekatan** untuk menggunakan stored procedure sebagai filter di Power Apps:

### ✅ **Opsi 1: Dengan Tombol Submit** (RECOMMENDED)
**Keuntungan:**
- ✅ Lebih efisien (tidak refresh setiap kali ada perubahan)
- ✅ User experience lebih jelas (user tahu kapan filter diterapkan)
- ✅ Mengurangi load pada database
- ✅ User bisa mengatur beberapa filter sekaligus sebelum submit

**Kekurangan:**
- ❌ User harus klik tombol untuk melihat hasil

### ⚡ **Opsi 2: Auto-Refresh (OnChange)**
**Keuntungan:**
- ✅ Real-time update (hasil langsung muncul)
- ✅ Tidak perlu klik tombol

**Kekurangan:**
- ❌ Bisa terlalu sering refresh (setiap perubahan text/date)
- ❌ Lebih banyak load pada database
- ❌ Bisa lambat jika user mengetik cepat

### 🔄 **Opsi 3: Hybrid (Auto + Manual)**
**Keuntungan:**
- ✅ Balance antara UX dan performance
- ✅ Filter penting auto-refresh, filter kompleks pakai submit

**Kekurangan:**
- ❌ Implementasi lebih kompleks

---

## 🚀 Implementasi Detail

### **Opsi 1: Dengan Tombol Submit** ⭐ RECOMMENDED

#### Step 1: Buat Variable untuk Menyimpan Parameter Filter

```powerappsfx
// Di OnStart atau OnVisible screen
Set(varFilterTransactionDate, Blank());
Set(varFilterUploadedAt, Blank());
Set(varSearchCustomer, "");
Set(varSearchBatch, "");
Set(varSearchDescription, "");
Set(varSearchBankType, "");
Set(varSearchBTP, "");
Set(varShowReview, true);
Set(varShowDebit, Blank());
```

#### Step 2: Buat Tombol Submit Filter

**Button Name:** `btnApplyFilter`

**OnSelect Property:**
```powerappsfx
// Simpan nilai filter ke variable
Set(varFilterTransactionDate, TrxDpRvRk.SelectedDate);
Set(varFilterUploadedAt, UaDpRvRk.SelectedDate);
Set(varSearchCustomer, searchCustomerRv.Text);
Set(varSearchBatch, searchBatchRv.Text);
Set(varSearchDescription, searchDescRv.Text);
Set(varSearchBankType, searchBtRv.Text);
Set(varSearchBTP, searchBtpRv.Text);
Set(varShowReview, rkToggleRv.Checked);
Set(varShowDebit, If(rkToggleRvCd.Checked, true, false));

// Refresh data source (jika menggunakan SP sebagai data source)
Refresh(SP_BTP_REVIEW_FilterComplete);

// Atau jika menggunakan Power Automate Flow:
Set(
    varFilteredData,
    Flow_FilterBTPReview.Run(
        varFilterTransactionDate,
        varFilterUploadedAt,
        varSearchCustomer,
        varSearchBatch,
        varSearchDescription,
        varSearchBankType,
        varSearchBTP,
        varShowReview,
        varShowDebit
    )
);
```

**Text Property:** `"Apply Filter"` atau `"🔍 Filter"`

#### Step 3: Update Gallery Items Property

**Jika menggunakan SP sebagai Data Source:**
```powerappsfx
// Gallery akan otomatis menggunakan parameter dari variable
SP_BTP_REVIEW_FilterComplete
```

**Jika menggunakan Power Automate Flow:**
```powerappsfx
// Gunakan hasil dari flow
varFilteredData
```

**Jika menggunakan Collection:**
```powerappsfx
// Setelah tombol diklik, collection diisi dengan hasil SP
colFilteredBTPReview
```

#### Step 4: (Optional) Buat Tombol Reset Filter

**Button Name:** `btnResetFilter`

**OnSelect Property:**
```powerappsfx
// Reset semua filter
Set(varFilterTransactionDate, Blank());
Set(varFilterUploadedAt, Blank());
Set(varSearchCustomer, "");
Set(varSearchBatch, "");
Set(varSearchDescription, "");
Set(varSearchBankType, "");
Set(varSearchBTP, "");

// Reset controls
Reset(TrxDpRvRk);
Reset(UaDpRvRk);
Reset(searchCustomerRv);
Reset(searchBatchRv);
Reset(searchDescRv);
Reset(searchBtRv);
Reset(searchBtpRv);

// Refresh data
Refresh(SP_BTP_REVIEW_FilterComplete);
```

**Text Property:** `"Reset Filter"` atau `"🔄 Reset"`

---

### **Opsi 2: Auto-Refresh (OnChange)**

#### Step 1: Set Variable di OnChange Control

**DatePicker (TrxDpRvRk) - OnChange Property:**
```powerappsfx
Set(varFilterTransactionDate, TrxDpRvRk.SelectedDate);
Refresh(SP_BTP_REVIEW_FilterByTransactionDate);
```

**TextInput (searchCustomerRv) - OnChange Property:**
```powerappsfx
Set(varSearchCustomer, searchCustomerRv.Text);
// Debounce: tunggu 1 detik setelah user berhenti mengetik
Set(varSearchCustomerTimer, Now());
```

**Timer Control - OnTimerEnd Property:**
```powerappsfx
// Refresh setelah 1 detik user berhenti mengetik
Refresh(SP_BTP_REVIEW_FilterComplete);
```

**Timer Duration:** `1000` (1 detik)

---

### **Opsi 3: Hybrid Approach**

#### Kombinasi:
- **DatePicker**: Auto-refresh (OnChange)
- **Text Search**: Auto-refresh dengan debounce (Timer)
- **Toggle**: Auto-refresh (OnChange)
- **Complex Filter**: Pakai tombol submit

**Contoh:**
```powerappsfx
// DatePicker - Auto refresh
TrxDpRvRk.OnChange = Set(varFilterTransactionDate, TrxDpRvRk.SelectedDate);
                     Refresh(SP_BTP_REVIEW_FilterByTransactionDate);

// Text Search - Debounce dengan timer
searchCustomerRv.OnChange = Set(varSearchCustomer, searchCustomerRv.Text);
                            Reset(tmrDebounceSearch);
                            StartTimer(tmrDebounceSearch);

// Toggle - Auto refresh
rkToggleRv.OnChange = Set(varShowReview, rkToggleRv.Checked);
                     Refresh(SP_BTP_REVIEW_FilterComplete);

// Complex filter - Pakai tombol submit
btnApplyFilter.OnSelect = [complex filter logic dengan banyak parameter]
```

---

## 📝 Contoh Lengkap: Implementasi dengan Tombol Submit

### **Screen Structure:**
```
┌─────────────────────────────────────────────────┐
│  Filter Panel                                   │
│  ┌───────────────────────────────────────────┐ │
│  │ Transaction Date: [DatePicker]             │ │
│  │ Uploaded At:     [DatePicker]             │ │
│  │ Customer:        [TextInput]              │ │
│  │ Batch:           [TextInput]              │ │
│  │ Description:     [TextInput]              │ │
│  │ Bank Type:       [TextInput]              │ │
│  │ BTP:             [TextInput]              │ │
│  │ Show Review:     [Toggle]                 │ │
│  │ Show Debit:      [Toggle]                 │ │
│  │ [Apply Filter] [Reset Filter]             │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  Gallery (galReview)                            │
│  ┌───────────────────────────────────────────┐ │
│  │ [Transaction Data...]                     │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### **Power Automate Flow: FilterBTPReview**

**Trigger:** PowerApps (V2)

**Input Parameters:**
- `TransactionDate` (Date, optional)
- `UploadedAt` (Date, optional)
- `SearchCustomer` (Text, optional)
- `SearchBatch` (Text, optional)
- `SearchDescription` (Text, optional)
- `SearchBankType` (Text, optional)
- `SearchBTP` (Text, optional)
- `ShowReview` (Boolean)
- `ShowDebit` (Boolean, optional)

**Action:** Execute SQL Stored Procedure
- **Stored Procedure:** `SP_BTP_REVIEW_FilterComplete`
- **Parameters:** Map dari input Power Apps

**Response:** Return result set ke Power Apps

---

## 🎨 Best Practices

1. **Loading Indicator**: Tampilkan loading saat filter sedang diproses
   ```powerappsfx
   Set(varIsFiltering, true);
   // ... filter logic ...
   Set(varIsFiltering, false);
   ```

2. **Error Handling**: Handle error jika SP gagal
   ```powerappsfx
   If(
       !IsBlank(varFilterError),
       Notify("Error: " & varFilterError, NotificationType.Error),
       // Success
   )
   ```

3. **Empty State**: Tampilkan pesan jika tidak ada hasil
   ```powerappsfx
   If(
       CountRows(galReview.AllItems) = 0,
       "No results found",
       ""
   )
   ```

4. **Filter Summary**: Tampilkan jumlah filter aktif
   ```powerappsfx
   "Active filters: " & 
   If(!IsBlank(varFilterTransactionDate), "TransactionDate, ", "") &
   If(!IsBlank(varSearchCustomer), "Customer, ", "") &
   "..."
   ```

---

## ✅ Rekomendasi

**Untuk kasus ini, saya rekomendasikan Opsi 1 (Tombol Submit)** karena:
1. Filter cukup kompleks (banyak parameter)
2. User biasanya mengatur beberapa filter sekaligus
3. Lebih efisien untuk database
4. UX lebih jelas dan predictable

**Tombol Submit akan:**
- Mengumpulkan semua nilai filter
- Memanggil stored procedure dengan parameter lengkap
- Menampilkan hasil di gallery
- Memberikan feedback ke user (loading, success, error)

