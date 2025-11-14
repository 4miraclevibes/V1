# 📋 Setup Tampilkan Link Download (Copy-Paste)

## 🎯 Solusi Paling Sederhana

Tampilkan link di Text Input yang bisa di-copy, lalu user paste di browser baru untuk download.

---

## 🔧 Setup (5 Menit)

### STEP 1: Tambahkan Text Input

1. **Insert** → **Text input**
2. **Name:** `txtDownloadLink`
3. **Default:** 
```powerappsfx
If(varShowLink, varDownloadLink, "")
```
4. **Mode:** Single line
5. **Read-only:** `true` (agar mudah di-select)
6. **Visible:** 
```powerappsfx
varShowLink
```

---

### STEP 2: Tambahkan Label Instruksi

**Label Name:** `lblDownloadInstruction`

**Text:**
```
📥 Copy link di atas → Paste di browser baru → Tekan Enter untuk download
```

**Visible:**
```powerappsfx
varShowLink
```

---

### STEP 3: Tambahkan Button "Copy Link" (Optional)

**Button Name:** `btnCopyLink`

**Text:** "📋 Copy Link"

**OnSelect:**
```powerappsfx
Set(Clipboard.Text, txtDownloadLink.Text);
Notify("✅ Link copied! Paste di browser baru.", NotificationType.Success, 2000);
```

**Visible:**
```powerappsfx
varShowLink
```

---

### STEP 4: Initialize Variable (App OnStart)

```powerappsfx
Set(varShowLink, false);
Set(varDownloadLink, "");
Set(varDownloadFileName, "");
```

---

### STEP 5: Update Button Code

Gunakan code dari `btnExportToExcel_ShowLink.c`:

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.filecontent),
    Set(varDownloadLink, "data:text/csv;base64," & varExportResult.filecontent);
    Set(varDownloadFileName, varExportResult.filename);
    Set(varShowLink, true);
    Notify("✅ Export successful! " & varExportResult.rowcount & " rows. Copy link below.", NotificationType.Success, 5000),
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

---

## ✅ Cara Pakai User

1. Klik button "Export to Excel"
2. Link muncul di text input
3. Klik text input → Select All (Ctrl+A / Cmd+A)
4. Copy (Ctrl+C / Cmd+C)
5. Buka tab browser baru
6. Paste di address bar (Ctrl+V / Cmd+V)
7. Tekan Enter → File download!

**Atau** klik button "Copy Link" → langsung copy ke clipboard.

---

## 🎨 Layout Saran

```
┌─────────────────────────────────┐
│  Button: Export to Excel        │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│  Text Input (link muncul di sini)│
│  [data:text/csv;base64,...]     │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│  📋 Copy Link (button)          │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│  Label: Copy link → Paste → Enter│
└─────────────────────────────────┘
```

---

**Solusi ini pasti bekerja karena tidak perlu JavaScript! 🎉**

