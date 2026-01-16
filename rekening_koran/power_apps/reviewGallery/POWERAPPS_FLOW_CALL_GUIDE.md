# 📱 Panduan: Memanggil Power Automate Flow di Power Apps

## 🎯 Format Dasar

**Format umum:**
```powerappsfx
FlowName.Run({
    parameter1: value1,
    parameter2: value2,
    ...
})
```

**Contoh dari Export Rekening Koran:**
```powerappsfx
Set(
    varExportResult,
    Export_RekeningKoran_ToExcel.Run({
        text: varStartDate,
        text_1: varEndDate,
        text_2: varBTPFilter
    })
);
```

---

## 🔧 Untuk FilterBTPReview Flow

### **Format yang Benar:**

```powerappsfx
Set(
    varBTPReviewData,
    FilterBTPReview.Run({
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
        SearchBatch: If(IsBlank(searchBatchRv.Text), "", searchBatchRv.Text),
        SearchDescription: If(IsBlank(searchDescRv.Text), "", searchDescRv.Text),
        SearchBankType: If(IsBlank(searchBtRv.Text), "", searchBtRv.Text),
        SearchBTP: If(IsBlank(searchBtpRv.Text), "", searchBtpRv.Text),
        TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate)),
        UploadedAt: If(IsBlank(UaDpRvRk.SelectedDate), "", Text(UaDpRvRk.SelectedDate))
    }).data
);
```

---

## ⚠️ Catatan Penting

### **1. Nama Flow**

**Format:** `FlowName.Run({...})`

- Nama flow harus **tepat sama** dengan yang ada di Power Automate
- **Case-sensitive** (huruf besar/kecil harus sama)
- Tidak perlu prefix `Flow_` kecuali memang nama flow-nya seperti itu

**Contoh:**
- Jika flow name di Power Automate: `FilterBTPReview` → Pakai: `FilterBTPReview.Run({...})`
- Jika flow name di Power Automate: `FilterBTPReviewText` → Pakai: `FilterBTPReviewText.Run({...})`

**Cara cek nama flow:**
1. Buka Power Automate
2. Cari flow yang sudah dibuat
3. Nama flow yang muncul di list = nama yang digunakan di Power Apps

---

### **2. Parameter Names**

**Format:** `parameterName: value`

- Nama parameter harus **tepat sama** dengan yang ada di trigger PowerApps (V2)
- **Case-sensitive**
- Gunakan nama yang sama persis seperti di Power Automate trigger

**Contoh:**
- Di trigger: `SearchCustomer` → Pakai: `SearchCustomer: value`
- Di trigger: `searchCustomer` → Pakai: `searchCustomer: value` (lowercase)

---

### **3. Response Access**

**Format:** `.Run({...}).data`

- Response menggunakan **lowercase**: `.data` (bukan `.Data`)
- Field lainnya juga lowercase: `.success`, `.rowcount`

**Contoh:**
```powerappsfx
// ✅ BENAR
varResult = FilterBTPReview.Run({...}).data

// ❌ SALAH
varResult = FilterBTPReview.Run({...}).Data
```

---

## 📋 Checklist

Sebelum menggunakan flow di Power Apps:

- [ ] Flow sudah dibuat dan di-save di Power Automate
- [ ] Flow sudah di-share ke environment yang sama dengan Power Apps
- [ ] Nama flow sudah diketahui (cek di Power Automate)
- [ ] Parameter names sudah sesuai dengan trigger (cek di Power Automate)
- [ ] Flow sudah di-test di Power Automate (manual test)
- [ ] Flow sudah di-connect di Power Apps (Data → Connections)

---

## 🔍 Troubleshooting

### **Error: Flow tidak ditemukan**

**Solusi:**
- Pastikan flow sudah di-connect di Power Apps
- Pastikan nama flow tepat sama (case-sensitive)
- Refresh Power Apps Studio
- Cek apakah flow sudah di-share ke environment yang sama

### **Error: Parameter tidak dikenal**

**Solusi:**
- Pastikan nama parameter tepat sama dengan di trigger
- Cek di Power Automate → Trigger → Inputs untuk melihat nama parameter yang benar
- Pastikan semua parameter sudah ditambahkan di trigger

### **Error: Property tidak ada**

**Solusi:**
- Pastikan menggunakan lowercase: `.data` (bukan `.Data`)
- Cek response structure di Power Automate flow run history
- Pastikan flow return data dengan benar

---

## 💡 Tips

1. **Nama Flow:** Gunakan nama yang jelas dan konsisten
2. **Parameter:** Gunakan nama yang deskriptif (bukan `text`, `text_1`, dll jika memungkinkan)
3. **Testing:** Selalu test flow di Power Automate dulu sebelum digunakan di Power Apps
4. **Error Handling:** Tambahkan error handling di Power Apps untuk handle flow failure

---

## 🔗 File Terkait

- `btnSubmitSearch_POWERAUTOMATE.c` - Contoh implementasi tombol Submit Search
- `POWERAUTOMATE_TUTORIAL.md` - Panduan lengkap Power Automate setup
- `OutputResponseToPowerApps_FORMATTED.md` - Dokumentasi response structure
