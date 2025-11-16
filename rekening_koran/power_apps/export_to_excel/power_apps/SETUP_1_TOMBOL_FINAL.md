# ✅ Setup 1 Tombol - Final

## 🎯 Tombol yang Dipakai

**Pakai:** `btnDownloadFromSharePoint.c`

**Ini adalah solusi 1 tombol yang paling sederhana!**

---

## 📋 Code Tombol

**Button Name:** `btnExportToExcel` (atau nama lain sesuai kebutuhan)

**OnSelect:** (Code dari `btnDownloadFromSharePoint.c`)

```powerappsfx
// Call Power Automate Flow
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

// Check result & download dari SharePoint link
If(
    !IsBlank(varExportResult.sharePointLink),
    // Success - Download dari SharePoint link
    Download(varExportResult.sharePointLink);
    Notify(
        "✅ Download started! " & varExportResult.rowCount & " rows exported.",
        NotificationType.Success,
        3000
    ),
    // Error
    Notify("❌ Export failed. Please try again.", NotificationType.Error, 3000)
);
```

---

## ✅ Cara Kerja

1. **User klik tombol** → Flow dipanggil
2. **Flow:**
   - Query database
   - Convert ke CSV
   - Upload ke SharePoint
   - Generate SharePoint link
   - Return link ke Power Apps
3. **Power Apps:**
   - Terima link dari flow
   - Langsung download menggunakan `Download()` function
4. **File ter-download** ke folder Downloads!

---

## 🎨 Setup Tombol

### **STEP 1: Tambahkan Button**

1. **Insert** → **Button**
2. **Name:** `btnExportToExcel` (atau nama lain)
3. **Text:** "📥 Export to Excel" (atau sesuai kebutuhan)

---

### **STEP 2: Set OnSelect Property**

**Copy paste code dari `btnDownloadFromSharePoint.c`:**

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.sharePointLink),
    Download(varExportResult.sharePointLink);
    Notify("✅ Download started! " & varExportResult.rowCount & " rows.", NotificationType.Success, 3000),
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

---

### **STEP 3: Pastikan Flow Sudah Terhubung**

1. **Power Apps** → **Data** → **Flows**
2. **Pastikan flow `Export_RekeningKoran_ToExcel` sudah ditambahkan**
3. **Jika belum:** Tambahkan flow dari Power Automate

---

## ✅ Checklist

- [ ] Button sudah dibuat
- [ ] OnSelect property sudah di-set dengan code dari `btnDownloadFromSharePoint.c`
- [ ] Flow `Export_RekeningKoran_ToExcel` sudah terhubung
- [ ] Test button → Flow dipanggil
- [ ] Test download → File ter-download

---

## 🧪 Testing

1. **Klik button "Export to Excel"**
2. **Check:**
   - ✅ Notification muncul: "Download started!"
   - ✅ File ter-download ke folder Downloads
   - ✅ File bisa dibuka di Excel
   - ✅ Data sesuai dengan database

---

## 💡 Tips

**Jika download tidak bekerja:**

1. **Check flow:** Pastikan flow berhasil di-run dan return `sharePointLink`
2. **Check URL:** Pastikan SharePoint link format benar (full URL)
3. **Check browser:** Pastikan browser allow downloads
4. **Check notification:** Lihat apakah ada error message

---

## 🎯 Summary

**Pakai `btnDownloadFromSharePoint.c` untuk solusi 1 tombol!**

**Cara kerja:**
- 1 klik → Flow dipanggil → File ter-download langsung

**Tidak perlu:**
- Variable tambahan
- Tombol kedua
- Setup kompleks

**Selesai! 🎉**

