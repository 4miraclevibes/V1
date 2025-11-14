# 📱 Power Apps Integration - Export to Excel

## ✅ Flow Sudah Berhasil!

Flow `Export_RekeningKoran_ToExcel` sudah berhasil di-test dan menghasilkan:
- ✅ File CSV dengan 14 rows
- ✅ Base64 encoded content siap untuk download
- ✅ Filename dengan timestamp

---

## 🚀 Langkah Integrasi ke Power Apps

### STEP 1: Connect Flow ke Power Apps

1. Buka Power Apps Studio
2. Buka app yang akan digunakan
3. **Data** → **Connections** → **New connection**
4. Cari: **Power Automate**
5. Pilih flow: `Export_RekeningKoran_ToExcel`
6. Klik **Add**

**Atau:**
- Di Power Apps, klik **Action** → **Power Automate**
- Pilih flow `Export_RekeningKoran_ToExcel`
- Flow akan otomatis ter-connect

---

### STEP 2: Tambahkan Button

1. **Insert** → **Button**
2. Letakkan button di canvas
3. **Text:** "Export to Excel" atau "📥 Export CSV"

---

### STEP 3: Tambahkan Code ke Button

**Button Name:** `btnExportToExcel`

**OnSelect:**
```powerappsfx
// Set loading state
Set(varExportLoading, true);
Set(varExportMessage, "⏳ Generating file...");

// Call Power Automate Flow
Set(
    varExportResult,
    Export_RekeningKoran_ToExcel.Run()
);

// Check result
If(
    !IsBlank(varExportResult.filecontent),
    // Success - Download file
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "✅ Export successful! " & 
        varExportResult.rowcount & 
        " rows exported"
    );
    // Download CSV file menggunakan data URI (bisa dibuka di Excel)
    Launch(
        "data:text/csv;base64," & varExportResult.filecontent,
        "_blank"
    ),
    // Error handling
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "❌ Export failed. Please try again."
    );
    Notify(
        varExportMessage,
        NotificationType.Error,
        5000
    )
);
```

**Note:** 
- Property names dari flow adalah lowercase: `filecontent`, `filename`, `rowcount`
- File CSV bisa langsung dibuka di Excel

---

### STEP 4: Tambahkan HTML Text Control (UNTUK AUTO-DOWNLOAD)

**⚠️ IMPORTANT:** Untuk file langsung ter-download ke folder Downloads, perlu HTML Text control!

1. **Insert** → **HTML Text**
2. **Name:** `htmlDownloadLink`
3. **HTMLText Property:**
```powerappsfx
If(
    varTriggerDownload && !IsBlank(varDownloadData),
    "<script>
        (function(){
            var base64 = '" & varDownloadData & "';
            var filename = '" & varDownloadFileName & "';
            var byteCharacters = atob(base64);
            var byteNumbers = new Array(byteCharacters.length);
            for (var i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            var byteArray = new Uint8Array(byteNumbers);
            var blob = new Blob([byteArray], {type: 'text/csv;charset=utf-8;'});
            var url = URL.createObjectURL(blob);
            var link = document.createElement('a');
            link.href = url;
            link.download = filename;
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        })();
    </script>",
    ""
)
```

**Note:** 
- HTML Text control bisa di-hidden atau diletakkan di luar layar
- Reset variable dilakukan di **button OnSelect** dengan SetTimeout (lihat code button lengkap)

---

### STEP 5: Tambahkan Loading Indicator (Optional)

**Label Name:** `lblExportStatus`

**Text:**
```powerappsfx
If(
    varExportLoading,
    "⏳ Exporting...",
    varExportMessage
)
```

**Visible:**
```powerappsfx
!IsBlank(varExportMessage)
```

---

## 🧪 Testing

### Test dari Power Apps:

1. Buka Power Apps app
2. Klik button "Export to Excel"
3. Check:
   - ✅ Loading indicator muncul
   - ✅ File download otomatis
   - ✅ File bisa dibuka di Excel
   - ✅ Data sesuai dengan view (14 rows)

---

## 📝 Catatan Penting

### File Format:
- **File yang dihasilkan:** CSV (Comma Separated Values)
- **Bisa dibuka di:** Excel, Google Sheets, Notepad, dll
- **Excel akan auto-detect:** CSV format dan buka dengan benar

### Download Function:
- Menggunakan **HTML Text control** dengan JavaScript untuk auto-download
- File akan **langsung ter-download** ke folder **Downloads**
- Tidak perlu klik "Save" manual
- Nama file: `Rekening Koran_Export_YYYYMMDD_HHMMSS.csv`

**Setup:** Lihat file `HTML_TEXT_CONTROL_SETUP.md` untuk panduan lengkap.

### Error Handling:
- Jika flow gagal, akan muncul notification error
- Check Power Automate flow run history untuk detail error

---

## 🔧 Troubleshooting

### File tidak download?
- Check `Download()` function syntax
- Verify `filecontent` tidak kosong
- Check browser settings (allow downloads)

### Error "Flow not found"?
- Pastikan flow sudah di-connect ke Power Apps
- Refresh Power Apps connections
- Check flow name: `Export_RekeningKoran_ToExcel`

### File kosong atau corrupted?
- Check flow run history di Power Automate
- Verify stored procedure return data
- Check CSV encoding (harus UTF-8)

---

## ✅ Checklist

- [ ] Flow `Export_RekeningKoran_ToExcel` sudah dibuat dan tested
- [ ] Flow connected ke Power Apps
- [ ] Button `btnExportToExcel` ditambahkan
- [ ] Code di-copy ke button OnSelect
- [ ] Test export dari Power Apps
- [ ] File download berhasil
- [ ] File bisa dibuka di Excel
- [ ] Data sesuai dengan view

---

**Selamat! Export to Excel sudah siap digunakan! 🎉**

