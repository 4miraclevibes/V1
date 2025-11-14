# 📥 Setup HTML Text Control untuk Auto-Download

## 🎯 Tujuan

Membuat file CSV langsung ter-download ke folder **Downloads** (bukan hanya buka di tab baru).

---

## 🔧 Setup HTML Text Control

### STEP 1: Tambahkan HTML Text Control

1. Di Power Apps Studio, **Insert** → **HTML Text**
2. Letakkan HTML Text control di canvas (bisa di luar layar atau hidden)
3. **Name:** `htmlDownloadLink`

---

### STEP 2: Konfigurasi HTML Text Control

**HTMLText Property:**
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

**Penjelasan:**
- JavaScript decode Base64 ke Blob
- Membuat temporary download link dengan Blob URL
- Auto-click link untuk trigger download
- File akan langsung ter-download ke folder Downloads
- Cleanup: remove link dan revoke URL setelah download

---

### STEP 3: Reset Variable Setelah Download

**HTML Text control tidak punya OnChange!** Reset variable harus dilakukan di **button OnSelect** setelah trigger download:

Tambahkan di button OnSelect menggunakan **toggle pattern**:

```powerappsfx
// Toggle pattern: reset dulu, lalu set true untuk trigger download
Set(varTriggerDownload, false);  // Reset dulu
Set(varTriggerDownload, true);   // Lalu set true untuk trigger download
```

**Penjelasan:**
- Reset dulu ke `false` untuk memastikan HTML Text control detect perubahan
- Lalu set ke `true` untuk trigger download
- HTML Text control akan auto-trigger saat variable berubah dari `false` ke `true`

---

## 📝 Code Lengkap Button

**Button OnSelect:**
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
    // Success - Prepare download
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "✅ Export successful! " & 
        varExportResult.rowcount & 
        " rows exported"
    );
    // Simpan data ke variable untuk HTML Text control
    Set(
        varDownloadData,
        varExportResult.filecontent
    );
    Set(
        varDownloadFileName,
        varExportResult.filename
    );
    // Trigger download via HTML Text control
    // Toggle pattern: reset dulu, lalu set true untuk trigger download
    Set(varTriggerDownload, false);  // Reset dulu
    Set(varTriggerDownload, true),   // Lalu set true untuk trigger download
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

---

## ✅ Testing

1. Klik button "Export to Excel"
2. Check:
   - ✅ File langsung ter-download ke folder Downloads
   - ✅ Nama file sesuai: `Rekening Koran_Export_YYYYMMDD_HHMMSS.csv`
   - ✅ File bisa dibuka di Excel

---

## 🔧 Troubleshooting

### File tidak ter-download?
- Check browser settings (allow downloads)
- Pastikan HTML Text control sudah di-setup dengan benar
- Check console browser untuk error JavaScript

### File ter-download tapi kosong?
- Check `varDownloadData` tidak kosong
- Verify Base64 content dari flow

### Download terjadi berkali-kali?
- Pastikan `varTriggerDownload` di-reset setelah download
- Gunakan `SetTimeout` untuk delay reset

---

## 📚 Catatan

- **Browser Compatibility:** Method ini bekerja di Chrome, Edge, Firefox modern
- **Security:** Browser mungkin meminta permission untuk download
- **File Location:** File akan tersimpan di folder Downloads default browser

---

**Selamat! File sekarang akan langsung ter-download ke folder Downloads! 🎉**

