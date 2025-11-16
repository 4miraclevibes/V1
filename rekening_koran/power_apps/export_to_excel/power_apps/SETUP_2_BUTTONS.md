# 🎯 Setup 2 Buttons: Generate Link → Download

## ✅ Solusi dengan 2 Button

**Button 1:** Generate link dari flow  
**Button 2:** Download file menggunakan link yang sudah di-generate

---

## 🔧 Setup

### STEP 1: Button 1 - Generate Link

**Button Name:** `btnGenerateLink`

**Text:** "📊 Generate Export Link"

**OnSelect:** (Gunakan code dari `btnGenerateLink.c`)

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.filecontent),
    Set(varDownloadData, varExportResult.filecontent);
    Set(varDownloadFileName, varExportResult.filename);
    Set(varDownloadLink, "data:text/csv;base64," & varExportResult.filecontent);
    Set(varLinkReady, true);
    Notify("✅ Link ready! Click Download button.", NotificationType.Success, 3000),
    Set(varLinkReady, false);
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

---

### STEP 2: Button 2 - Download File

**Button Name:** `btnDownloadFile` atau `getFileBtn`

**Text:** "📥 Download File"

**OnSelect:** (Gunakan code dari `getFileBtn.c`)

```powerappsfx
If(
    varLinkReady && !IsBlank(varDownloadData),
    Set(varTriggerDownload, false);
    Set(varTriggerDownload, true);
    Notify("📥 Download started...", NotificationType.Information, 2000),
    Notify("❌ No file ready. Generate link first.", NotificationType.Warning, 3000)
);
```

**Enabled:** 
```powerappsfx
varLinkReady
```

---

### STEP 3: HTML Text Control (untuk download)

**Name:** `htmlAutoDownload`

**HTMLText Property:**
```powerappsfx
If(
    varTriggerDownload && !IsBlank(varDownloadData),
    "<a id='autoDownload' href='data:text/csv;base64," & varDownloadData & "' download='" & varDownloadFileName & "'></a><script>var link=document.getElementById('autoDownload');if(link){link.click();}</script>",
    ""
)
```

---

### STEP 4: Initialize Variables (App OnStart)

```powerappsfx
Set(varLinkReady, false);
Set(varTriggerDownload, false);
Set(varDownloadData, "");
Set(varDownloadFileName, "");
Set(varDownloadLink, "");
```

---

## ✅ Cara Pakai

1. Klik **Button 1** "Generate Export Link"
   - Flow dipanggil
   - Link di-generate dan disimpan
   - Notification: "Link ready!"

2. Klik **Button 2** "Download File"
   - HTML Text control trigger download
   - File langsung ter-download ke folder Downloads

---

## 🎨 Layout Saran

```
┌─────────────────────────────┐
│  Button 1: Generate Link    │
└─────────────────────────────┘
              ↓
┌─────────────────────────────┐
│  Button 2: Download File    │
│  (Enabled jika link ready)  │
└─────────────────────────────┘
```

---

**Solusi ini memisahkan generate link dan download, lebih jelas untuk user! 🎉**

