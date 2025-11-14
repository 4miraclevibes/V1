# 📥 HTML Text Control - Simple Setup untuk Auto-Download

## 🎯 Setup Cepat

### STEP 1: Tambahkan HTML Text Control

1. **Insert** → **HTML Text**
2. **Name:** `htmlDownloadLink`
3. Bisa di-hidden atau diletakkan di luar layar

---

### STEP 2: Set HTMLText Property

**Copy paste ini ke HTMLText property:**

```powerappsfx
If(
    varTriggerDownload && !IsBlank(varDownloadData),
    "<script>
        try {
            var base64 = '" & varDownloadData & "';
            var filename = '" & varDownloadFileName & "';
            
            // Decode base64
            var binaryString = atob(base64);
            var bytes = new Uint8Array(binaryString.length);
            for (var i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            
            // Create blob
            var blob = new Blob([bytes], {type: 'text/csv;charset=utf-8;'});
            var url = window.URL.createObjectURL(blob);
            
            // Create download link
            var a = document.createElement('a');
            a.href = url;
            a.download = filename;
            a.style.display = 'none';
            document.body.appendChild(a);
            
            // Trigger download
            a.click();
            
            // Cleanup
            setTimeout(function() {
                document.body.removeChild(a);
                window.URL.revokeObjectURL(url);
            }, 100);
        } catch(e) {
            console.error('Download error:', e);
        }
    </script>",
    ""
)
```

---

### STEP 3: Initialize Variables (di App OnStart)

```powerappsfx
Set(varTriggerDownload, false);
Set(varDownloadData, "");
Set(varDownloadFileName, "");
```

---

## ✅ Testing

1. Klik button "Export to Excel"
2. Check:
   - ✅ Notification muncul "Export successful!"
   - ✅ File langsung ter-download ke folder Downloads
   - ✅ File bisa dibuka di Excel

---

## 🔧 Troubleshooting

### File tidak ter-download?
- Check browser console (F12) untuk error JavaScript
- Pastikan HTML Text control HTMLText property sudah di-set dengan benar
- Pastikan variable `varTriggerDownload` dan `varDownloadData` ter-set

### JavaScript error di console?
- Check apakah Base64 string terlalu panjang
- Pastikan tidak ada karakter khusus yang break JavaScript string

---

**Note:** Method ini menggunakan Blob URL yang lebih reliable daripada data URI untuk download file besar.

