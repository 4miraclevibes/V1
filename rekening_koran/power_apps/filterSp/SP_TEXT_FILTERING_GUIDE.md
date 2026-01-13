# 📘 Panduan Penggunaan SP_BTP_REVIEW_FilterText

## 🎯 Overview

**Stored Procedure** untuk filter `BTP_REVIEW` berdasarkan **text fields saja**. Switch/toggle tetap di Power Apps.

**Keuntungan:**
- ✅ Filter text dilakukan di SQL Server (delegation-safe)
- ✅ Switch/toggle tetap di Power Apps (fleksibel)
- ✅ Bisa dipanggil dengan `.Run()` di Power Apps
- ✅ Lebih cepat daripada filter semua di Power Apps

---

## 📋 Parameter Stored Procedure

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `@SearchCustomer` | NVARCHAR(200) | No | Filter CustomerName (LIKE '%value%') |
| `@SearchBatch` | NVARCHAR(100) | No | Filter BatchID (LIKE '%value%') |
| `@SearchDescription` | NVARCHAR(MAX) | No | Filter Description (LIKE '%value%') |
| `@SearchBankType` | NVARCHAR(50) | No | Filter BankType (LIKE '%value%') |
| `@SearchBTP` | NVARCHAR(50) | No | Filter BTP (LIKE '%value%') |
| `@UploadedAt` | DATE | No | Filter UploadedAt (exact date match) |
| `@TransactionDate` | DATE | No | Filter TransactionDate (exact date match) |

**Catatan:** Semua parameter **nullable** (bisa dikirim `Blank()` dari Power Apps).

---

## 🔧 Setup di Power Apps

### **Step 1: Tambahkan Stored Procedure sebagai Data Source**

1. Buka Power Apps Studio
2. **Data** → **Add data**
3. Cari: **SQL Server**
4. Pilih connection SQL Server Anda
5. Pilih **Stored Procedure**: `SP_BTP_REVIEW_FilterText`
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
    SP_BTP_REVIEW_FilterText.Run({
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
        SearchBatch: If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
        SearchDescription: If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
        SearchBankType: If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
        SearchBTP: If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
        UploadedAt: UaDpRvRk.SelectedDate,
        TransactionDate: TrxDpRvRk.SelectedDate
    })
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

## 🔄 Flow Kerja

1. **User isi text fields** (CustomerName, BatchID, Description, BankType, BTP, UploadedAt, TransactionDate)
2. **User klik tombol Submit Search**
3. **Power Apps memanggil SP** dengan parameter dari text fields
4. **SP return hasil filter** berdasarkan text fields
5. **Hasil disimpan ke variabel** `varFilteredData`
6. **Gallery menampilkan data** dari variabel + filter Status dan TransactionType di Power Apps

---

## 📊 Perbandingan dengan Opsi Lain

| Aspek | SP Text Only | SP Complete | View |
|-------|--------------|-------------|------|
| **Text Filter** | ✅ Di SQL | ✅ Di SQL | ⚠️ Di Power Apps |
| **Status Filter** | ⚠️ Di Power Apps | ✅ Di SQL | ⚠️ Di Power Apps |
| **TransactionType Filter** | ⚠️ Di Power Apps | ✅ Di SQL | ⚠️ Di Power Apps |
| **Delegation** | ✅ Safe (text) | ✅ Safe (semua) | ⚠️ Bisa warning |
| **Performance** | ⚡⚡ Baik | ⚡⚡⚡ Sangat baik | ⚡ Baik |
| **Fleksibilitas** | ✅ Switch di Power Apps | ⚠️ Terbatas | ✅ Sangat fleksibel |

**Rekomendasi:**
- Pakai **SP Text Only** jika ingin switch/toggle tetap di Power Apps (sesuai kebutuhan Anda)
- Pakai **SP Complete** jika ingin semua filter di SQL Server
- Pakai **View** jika dataset kecil dan tidak masalah dengan delegation warning

---

## 🧪 Testing

### **Test di SQL Server:**

```sql
-- Test 1: Tanpa parameter
EXEC [dbo].[SP_BTP_REVIEW_FilterText] NULL, NULL, NULL, NULL, NULL, NULL, NULL;

-- Test 2: Filter CustomerName
EXEC [dbo].[SP_BTP_REVIEW_FilterText] 
    @SearchCustomer = 'PT ABC',
    @SearchBatch = NULL,
    @SearchDescription = NULL,
    @SearchBankType = NULL,
    @SearchBTP = NULL,
    @UploadedAt = NULL,
    @TransactionDate = NULL;

-- Test 3: Filter multiple fields
EXEC [dbo].[SP_BTP_REVIEW_FilterText] 
    @SearchCustomer = 'PT',
    @SearchBatch = 'BATCH001',
    @SearchDescription = NULL,
    @SearchBankType = 'BCA',
    @SearchBTP = NULL,
    @UploadedAt = NULL,
    @TransactionDate = NULL;
```

### **Test di Power Apps:**

1. Isi text fields dengan nilai tertentu
2. Klik tombol Submit Search
3. Cek Gallery apakah data sudah ter-filter berdasarkan text fields
4. Toggle switch untuk cek filter Status dan TransactionType

---

## ⚠️ Catatan Penting

1. **SP harus ditambahkan sebagai Data Source** di Power Apps Studio
2. **Parameter NULL/Blank:** Jika text field kosong, kirim `Blank()` atau `NULL`
3. **Date Parameter:** Kirim sebagai `Date` type, bukan string
4. **Switch/Toggle:** Tetap di Power Apps, tidak di SP
5. **Performance:** SP akan execute di SQL Server, jadi lebih cepat untuk dataset besar
6. **Variabel:** Pastikan variabel `varFilteredData` sudah dideklarasikan sebelum digunakan

---

## 🔗 File Terkait

- `SP_BTP_REVIEW_FilterText.sql` - Stored Procedure definition
- `galleryWithSP_TextOnly.c` - Contoh implementasi di Gallery
- `btnSubmitSearch.c` - Contoh tombol Submit Search (sudah di-update)
