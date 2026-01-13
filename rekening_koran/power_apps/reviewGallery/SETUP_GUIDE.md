# 🚀 Setup Guide: SP_BTP_REVIEW_FilterText untuk Gallery

## 📋 Overview

Mengganti filter di Gallery dari direct table filtering ke Stored Procedure untuk menghindari delegation warning.

**File yang perlu diubah:**
- `galleryNew.c` → Ganti dengan code dari `galleryNew_WITH_SP.c`
- Tambahkan tombol Submit Search dengan code dari `btnSubmitSearch.c`

---

## 🔧 Step-by-Step Setup

### **Step 1: Execute Stored Procedure di SQL Server**

1. Buka SQL Server Management Studio
2. Connect ke database `POWERAPPS`
3. Execute file: `rekening_koran/power_apps/filterSp/SP_BTP_REVIEW_FilterText.sql`
4. Pastikan SP berhasil dibuat tanpa error

---

### **Step 2: Tambahkan SP sebagai Data Source di Power Apps**

1. Buka Power Apps Studio
2. Klik **Data** di sidebar kiri
3. Klik **Add data**
4. Cari: **SQL Server**
5. Pilih connection SQL Server Anda (atau buat baru jika belum ada)
6. Di list, cari dan pilih: **SP_BTP_REVIEW_FilterText**
7. Klik **Connect**

**Verifikasi:**
- SP_BTP_REVIEW_FilterText harus muncul di list Data Sources

---

### **Step 3: Buat Variabel di Screen**

**Di OnStart atau OnVisible screen (screen yang berisi Gallery):**

```powerappsfx
Set(varFilteredData, []);
```

**Lokasi:**
- Klik pada Screen (bukan control)
- Pilih **OnStart** atau **OnVisible** property
- Tambahkan code di atas

---

### **Step 4: Update Tombol Submit Search**

**Jika sudah ada tombol Submit Search:**

1. Klik tombol Submit Search
2. Pilih **OnSelect** property
3. Ganti dengan code berikut:

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

**Jika belum ada tombol Submit Search:**

1. Tambahkan Button baru
2. Set **Text** property: `"Search"` atau `"Apply Filter"`
3. Set **OnSelect** property dengan code di atas

---

### **Step 5: Update Gallery Items Property**

1. Klik Gallery (gallery yang menampilkan BTP_REVIEW)
2. Pilih **Items** property
3. Ganti dengan code dari `galleryNew_WITH_SP.c`:

```powerappsfx
FirstN(
    Sort(
        Filter(
            varFilteredData,
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

---

## ✅ Checklist

- [ ] SP_BTP_REVIEW_FilterText sudah di-execute di SQL Server
- [ ] SP_BTP_REVIEW_FilterText sudah ditambahkan sebagai Data Source di Power Apps
- [ ] Variabel `varFilteredData` sudah dibuat di OnStart/OnVisible screen
- [ ] Tombol Submit Search sudah di-update dengan code baru
- [ ] Gallery Items Property sudah di-update dengan code baru
- [ ] Test: Isi text fields → Klik Submit → Cek Gallery apakah data ter-filter
- [ ] Test: Toggle switch → Cek Gallery apakah Status dan TransactionType ter-filter

---

## 🧪 Testing

### **Test 1: Text Filtering**

1. Isi salah satu text field (misalnya `searchCustomerRv` dengan "PT ABC")
2. Klik tombol Submit Search
3. **Expected:** Gallery hanya menampilkan data dengan CustomerName mengandung "PT ABC"

### **Test 2: Multiple Text Filters**

1. Isi beberapa text fields sekaligus
2. Klik tombol Submit Search
3. **Expected:** Gallery menampilkan data yang memenuhi semua filter

### **Test 3: Switch/Toggle**

1. Setelah Submit Search, toggle switch `rkToggleRv`
2. **Expected:** Gallery menampilkan data dengan Status sesuai switch (NO_MATCH, dll atau FAIR, dll)

### **Test 4: TransactionType Filter**

1. Setelah Submit Search, toggle switch `rkToggleRvCd`
2. **Expected:** Gallery menampilkan data dengan TransactionType sesuai switch (DB atau CR)

---

## ⚠️ Troubleshooting

### **Error: "SP_BTP_REVIEW_FilterText is not recognized"**

**Solusi:**
- Pastikan SP sudah ditambahkan sebagai Data Source
- Refresh Power Apps Studio
- Cek apakah nama SP benar (case-sensitive)

### **Error: "varFilteredData is not recognized"**

**Solusi:**
- Pastikan variabel sudah dibuat di OnStart/OnVisible screen
- Cek apakah nama variabel benar (case-sensitive)

### **Gallery kosong setelah Submit Search**

**Solusi:**
- Cek apakah SP return data (test di SQL Server)
- Cek apakah parameter dikirim dengan benar (gunakan `Notify()` untuk debug)
- Pastikan filter Status dan TransactionType tidak terlalu ketat

### **Delegation Warning masih muncul**

**Solusi:**
- Pastikan menggunakan `varFilteredData` (hasil dari SP), bukan langsung dari table
- Pastikan filter Status dan TransactionType menggunakan operator yang delegation-safe (=, &&, ||)

---

## 📚 File Terkait

- `SP_BTP_REVIEW_FilterText.sql` - Stored Procedure definition
- `galleryNew_WITH_SP.c` - Code untuk Gallery Items Property
- `btnSubmitSearch.c` - Code untuk tombol Submit Search
- `SP_TEXT_FILTERING_GUIDE.md` - Panduan lengkap penggunaan SP

---

## 💡 Tips

1. **Performance:** SP akan execute di SQL Server, jadi lebih cepat untuk dataset besar
2. **Caching:** Variabel `varFilteredData` akan di-cache, jadi tidak perlu panggil SP setiap kali Gallery refresh
3. **Debugging:** Gunakan `Notify()` untuk melihat apakah SP dipanggil dengan benar
4. **Empty Fields:** Jika text field kosong, kirim `Blank()` ke SP (akan di-handle sebagai NULL)
