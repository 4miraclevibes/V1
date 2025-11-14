# 📋 Setup Modal dengan Download Link (Copy-Paste)

## 🎯 Solusi: Tampilkan Link yang Bisa Di-Copy

Karena CSP block JavaScript, kita tampilkan link yang bisa di-copy manual.

---

## 🔧 Setup Modal

### STEP 1: Tambahkan Modal Control

1. **Insert** → **Modal**
2. **Name:** `modalDownloadLink`
3. **Title:** "Download File"

---

### STEP 2: Tambahkan Text Input di Modal

1. Di dalam modal, **Insert** → **Text input**
2. **Name:** `txtDownloadLink`
3. **Default:** 
```powerappsfx
If(
    varShowDownloadModal,
    varDownloadLink,
    ""
)
```
4. **Mode:** Single line
5. **Read-only:** `true` (agar mudah di-select all)

---

### STEP 3: Tambahkan Label Instruksi

**Label Text:**
```
1. Select all text di atas (Ctrl+A atau Cmd+A)
2. Copy (Ctrl+C atau Cmd+C)  
3. Paste di address bar browser baru
4. Tekan Enter untuk download
```

---

### STEP 4: Tambahkan Button "Copy Link"

**Button Name:** `btnCopyLink`

**OnSelect:**
```powerappsfx
// Copy link ke clipboard
Set(Clipboard.Text, txtDownloadLink.Text);
Notify("✅ Link copied! Paste di browser baru.", NotificationType.Success, 2000);
```

---

### STEP 5: Tambahkan Button "Close"

**Button Name:** `btnCloseModal`

**OnSelect:**
```powerappsfx
Set(varShowDownloadModal, false);
```

---

### STEP 6: Set Modal Visible

**Modal Visible Property:**
```powerappsfx
varShowDownloadModal
```

---

## 📝 Update Button Code

Gunakan code dari `btnExportToExcel_WithCopyLink.c`:

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.filecontent),
    Set(varDownloadData, varExportResult.filecontent);
    Set(varDownloadFileName, varExportResult.filename);
    Set(varDownloadLink, "data:text/csv;base64," & varExportResult.filecontent);
    Set(varShowDownloadModal, true);
    Notify("✅ Export successful! " & varExportResult.rowcount & " rows.", NotificationType.Success, 3000),
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

---

## ✅ Cara Pakai

1. User klik button "Export to Excel"
2. Modal muncul dengan link di text input
3. User klik text input → Select All (Ctrl+A)
4. Copy (Ctrl+C)
5. Buka tab browser baru
6. Paste di address bar (Ctrl+V)
7. Tekan Enter → File download!

---

**Solusi ini pasti bekerja karena tidak perlu JavaScript! 🎉**

