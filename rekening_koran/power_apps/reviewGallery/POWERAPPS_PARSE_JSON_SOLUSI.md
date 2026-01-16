# 🎯 Solusi: Parse JSON String di Power Apps

## 📋 Masalah
- Power Automate return JSON string (bukan Table langsung)
- Di Power Apps, `.data` masih string, bukan Table
- Tidak bisa langsung digunakan di Gallery

## ✅ Solusi: Parse JSON di Power Apps

### **Step 1: Buat Collection dan Variabel di Power Apps**

**Di OnStart atau OnVisible screen, tambahkan:**

```powerappsfx
// Buat collection kosong dulu
ClearCollect(colBTPReviewData, []);

// Buat variabel untuk parsed data (optional, tapi recommended)
Set(varParsedData, []);
```

**Cara:**
1. Buka Power Apps Studio
2. Pilih screen (misalnya `scrReviewGallery`)
3. Klik **OnStart** atau **OnVisible** property
4. Tambahkan code di atas

---

### **Step 2: Update Button OnSelect**

**Code lengkap untuk tombol Submit Search:**

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

// Parse JSON string menjadi Collection
If(
    !IsBlank(varFlowResult) && !IsBlank(varFlowResult.data),
    // Clear collection dulu, lalu parse JSON string
    ClearCollect(
        colBTPReviewData,
        ParseJSON(varFlowResult.data)
    )
);

// Set variabel dari collection (untuk digunakan di Gallery)
Set(
    varBTPReviewData,
    If(
        !IsBlank(varFlowResult) && !IsBlank(varFlowResult.data),
        colBTPReviewData,  // ← Collection yang sudah di-parse
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

---

### **Step 3: Update Gallery Items Property**

**Di Gallery, set Items property ke:**

```powerappsfx
colBTPReviewData
```

**Atau jika pakai variabel:**

```powerappsfx
varBTPReviewData
```

**Contoh lengkap dengan filter:**

```powerappsfx
Filter(
    colBTPReviewData,
    // Filter Status
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
    // Filter TransactionType
    (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
)
```

---

## 🔍 Cara Cek Apakah Data Sudah Ter-parse

### **Test 1: Cek Collection**

**Di Power Apps Studio:**
1. Klik **View** → **Collections**
2. Cari `colBTPReviewData`
3. Klik untuk lihat isinya
4. Harus muncul data dalam bentuk Table (bukan string)

### **Test 2: Cek di Gallery**

**Setelah klik tombol Submit:**
1. Gallery harus menampilkan data
2. Jika masih kosong, cek:
   - Apakah collection sudah terisi?
   - Apakah filter Gallery terlalu ketat?
   - Apakah ada error di formula?

---

## ⚠️ Troubleshooting

### **Error: "Collection 'colBTPReviewData' doesn't exist"**

**Solusi:**
- Pastikan collection sudah dibuat di OnStart/OnVisible:
  ```powerappsfx
  ClearCollect(colBTPReviewData, []);
  ```

---

### **Error: "The function 'ClearCollect' has some invalid arguments"**

**Penyebab:**
- `ParseJSON()` tidak bisa langsung digunakan di `ClearCollect()`
- Harus parse dulu, baru collect

**Solusi:**
- Gunakan cara yang benar:
  1. Parse dulu: `Set(varParsedData, ParseJSON(varFlowResult.data));`
  2. Clear collection: `Clear(colBTPReviewData);`
  3. Collect parsed data: `Collect(colBTPReviewData, varParsedData);`

---

### **Error: "Invalid argument type" di ParseJSON**

**Penyebab:**
- `varFlowResult.data` masih kosong atau bukan string JSON

**Solusi:**
- Cek apakah flow return data dengan benar
- Pastikan `.data` adalah string JSON (bisa cek di Notify untuk debug):
  ```powerappsfx
  Notify(
      "Data: " & varFlowResult.data,
      NotificationType.Information,
      5000
  );
  ```

---

### **Gallery Kosong Setelah Parse**

**Penyebab:**
- JSON string tidak valid
- Collection kosong setelah parse
- Filter Gallery terlalu ketat

**Solusi:**
1. Cek collection di View → Collections
2. Jika collection kosong, berarti parse gagal
3. Cek format JSON string dari flow
4. Coba tanpa filter dulu untuk test:
   ```powerappsfx
   Items: colBTPReviewData
   ```

---

### **Data Masih String, Bukan Table**

**Penyebab:**
- ParseJSON tidak berjalan
- Collection tidak ter-update

**Solusi:**
- Pastikan `ClearCollect` dijalankan setelah flow selesai
- Pastikan `ParseJSON()` syntax benar
- Cek apakah ada error di formula bar

---

## ✅ Checklist

- [ ] Collection `colBTPReviewData` sudah dibuat di OnStart/OnVisible: `ClearCollect(colBTPReviewData, []);`
- [ ] Variabel `varParsedData` sudah dibuat di OnStart/OnVisible: `Set(varParsedData, []);`
- [ ] Button OnSelect sudah di-update dengan cara yang benar (Parse dulu, lalu Collect)
- [ ] Variabel `varBTPReviewData` di-set dari collection
- [ ] Gallery Items property sudah di-set ke `colBTPReviewData` atau `varBTPReviewData`
- [ ] Flow sudah di-test dan return data
- [ ] Collection sudah terisi setelah klik Submit
- [ ] Gallery sudah menampilkan data

---

## 🎯 Kesimpulan

**Yang penting:**
1. ✅ Buat collection dulu: `ClearCollect(colBTPReviewData, []);`
2. ✅ Parse JSON dengan: `ClearCollect(colBTPReviewData, ParseJSON(varFlowResult.data));`
3. ✅ Pakai collection di Gallery: `Items: colBTPReviewData`
4. ✅ Collection akan otomatis jadi Table yang bisa digunakan di Gallery

**Dengan cara ini, meskipun Power Automate return JSON string, kita bisa parse di Power Apps dan langsung pakai di Gallery!** 🚀
