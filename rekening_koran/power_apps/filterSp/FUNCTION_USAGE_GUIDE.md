# 📘 Panduan Penggunaan FN_BTP_REVIEW_FilterText

## 🎯 Overview

**Table-Valued Function** untuk filter `BTP_REVIEW` berdasarkan **text fields saja**. Switch/toggle tetap di Power Apps.

**Keuntungan:**
- ✅ Filter text dilakukan di SQL (delegation-safe)
- ✅ Switch/toggle tetap di Power Apps (fleksibel)
- ✅ Bisa dipanggil seperti View di Power Apps
- ✅ Lebih cepat daripada filter semua di Power Apps

---

## 📋 Parameter Function

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `@SearchCustomer` | NVARCHAR(200) | No | Filter CustomerName (LIKE '%value%') |
| `@SearchBatch` | NVARCHAR(100) | No | Filter BatchID (LIKE '%value%') |
| `@SearchDescription` | NVARCHAR(MAX) | No | Filter Description (LIKE '%value%') |
| `@SearchBankType` | NVARCHAR(50) | No | Filter BankType (LIKE '%value%') |
| `@SearchBTP` | NVARCHAR(50) | No | Filter BTP (LIKE '%value%') |
| `@UploadedAt` | DATE | No | Filter UploadedAt (exact date match) |
| `@TransactionDate` | DATE | No | Filter TransactionDate (exact date match) |

**Catatan:** Semua parameter **nullable** (bisa dikirim `NULL` atau `Blank()` dari Power Apps).

---

## 🔧 Setup di Power Apps

### **Step 1: Tambahkan Function sebagai Data Source**

1. Buka Power Apps Studio
2. **Data** → **Add data**
3. Cari: **SQL Server**
4. Pilih connection SQL Server Anda
5. Pilih **Function**: `FN_BTP_REVIEW_FilterText`
6. Klik **Connect**

### **Step 2: Buat Variabel**

Di **OnStart** atau **OnVisible** screen:

```powerappsfx
Set(varFilteredData, []);
```

### **Step 3: Buat Tombol Submit Search**

**Button OnSelect Property:**
```powerappsfx
Set(
    varFilteredData,
    FN_BTP_REVIEW_FilterText(
        If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
        If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
        If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
        If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
        If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
        UaDpRvRk.SelectedDate,
        TrxDpRvRk.SelectedDate
    )
);
Notify("Filter diterapkan", NotificationType.Success, 2000);
```

### **Step 4: Update Gallery Items Property**

**Items Property:**
```powerappsfx
FirstN(
    Sort(
        Filter(
            varFilteredData,
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

## 🔄 Alternatif: Langsung di Gallery (Tanpa Variabel)

Jika tidak ingin pakai variabel, bisa langsung panggil Function di Gallery:

**Items Property:**
```powerappsfx
FirstN(
    Sort(
        Filter(
            FN_BTP_REVIEW_FilterText(
                If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
                If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
                If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
                If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
                If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
                UaDpRvRk.SelectedDate,
                TrxDpRvRk.SelectedDate
            ),
            // Filter Status dan TransactionType tetap di Power Apps
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
            (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
        ),
        MatchPercentage,
        SortOrder.Ascending
    ),
    200000
)
```

**Catatan:** 
- Function akan dipanggil setiap kali Gallery refresh
- Lebih baik pakai variabel + tombol submit untuk performa lebih baik

---

## 📊 Perbandingan dengan Stored Procedure

| Aspek | Function | Stored Procedure |
|-------|----------|-------------------|
| **Cara pemanggilan** | Seperti View | `.Run()` atau via Power Automate |
| **Parameter** | ✅ Bisa | ✅ Bisa |
| **Return type** | Table (bisa di-filter) | Result set |
| **Delegation** | ✅ Safe | ✅ Safe |
| **Performance** | ⚡ Cepat | ⚡ Cepat |
| **Fleksibilitas** | ⚠️ Terbatas | ✅ Lebih fleksibel |

**Rekomendasi:**
- Pakai **Function** jika hanya perlu filter text fields
- Pakai **Stored Procedure** jika perlu filter kompleks (Status, TransactionType, dll)

---

## 🧪 Testing

### **Test di SQL Server:**

```sql
-- Test 1: Tanpa parameter
SELECT * FROM [dbo].[FN_BTP_REVIEW_FilterText](NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Test 2: Filter CustomerName
SELECT * FROM [dbo].[FN_BTP_REVIEW_FilterText](@SearchCustomer = 'PT ABC', NULL, NULL, NULL, NULL, NULL, NULL);

-- Test 3: Filter multiple
SELECT * FROM [dbo].[FN_BTP_REVIEW_FilterText](
    @SearchCustomer = 'PT',
    @SearchBatch = 'BATCH001',
    NULL, NULL, NULL, NULL, NULL
);
```

### **Test di Power Apps:**

1. Isi text fields dengan nilai tertentu
2. Klik tombol Submit Search
3. Cek Gallery apakah data sudah ter-filter
4. Toggle switch untuk cek filter Status dan TransactionType

---

## ⚠️ Catatan Penting

1. **Function harus ditambahkan sebagai Data Source** di Power Apps Studio
2. **Parameter NULL/Blank:** Jika text field kosong, kirim `Blank()` atau `NULL`
3. **Date Parameter:** Kirim sebagai `Date` type, bukan string
4. **Switch/Toggle:** Tetap di Power Apps, tidak di Function
5. **Performance:** Function akan execute di SQL Server, jadi lebih cepat untuk dataset besar

---

## 🔗 File Terkait

- `FN_BTP_REVIEW_FilterText.sql` - Function definition
- `galleryWithFunction.c` - Contoh implementasi di Gallery
- `btnSubmitSearch.c` - Contoh tombol Submit Search
