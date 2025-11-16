# 🔧 Fix Property Name di Power Apps - V2

## ❌ Error: `sharepointlink` isn't recognized

**Penyebab:** Power Apps menggunakan **title** dari schema, bukan property name!

---

## ✅ Property Name yang Benar

Dari output flow schema:
- Property name: `sharepointlink` (lowercase)
- **Title:** `sharePointLink` (camelCase) ← INI YANG DIPAKAI DI POWER APPS!

**Power Apps menggunakan TITLE, bukan property name!**

| Property di Schema | Title | Property di Power Apps |
|-------------------|-------|------------------------|
| `sharepointlink` | `sharePointLink` | `sharePointLink` ✅ |
| `filename` | `fileName` | `fileName` ✅ |
| `rowcount` | `rowCount` | `rowCount` ✅ |
| `status` | `status` | `status` ✅ |

---

## 🔧 Fix Code

### **btnGenerateLink.c**

**SALAH:**
```powerappsfx
varExportResult.sharepointlink  ← Error!
varExportResult.filename        ← Error!
varExportResult.rowcount       ← Error!
```

**BENAR:**
```powerappsfx
varExportResult.sharePointLink  ← Benar! (camelCase sesuai title)
varExportResult.fileName        ← Benar! (camelCase sesuai title)
varExportResult.rowCount        ← Benar! (camelCase sesuai title)
```

---

### **btnDownloadFromSharePoint.c**

**SALAH:**
```powerappsfx
varExportResult.sharepointlink  ← Error!
varExportResult.rowcount        ← Error!
```

**BENAR:**
```powerappsfx
varExportResult.sharePointLink  ← Benar! (camelCase sesuai title)
varExportResult.rowCount        ← Benar! (camelCase sesuai title)
```

---

## ✅ Code yang Sudah Diperbaiki

### **btnGenerateLink.c**

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.sharePointLink),
    Set(varSharePointLink, varExportResult.sharePointLink);
    Set(varDownloadFileName, varExportResult.fileName);
    Set(varLinkReady, true);
    Notify("✅ File ready! " & varExportResult.rowCount & " rows.", NotificationType.Success, 3000),
    Set(varLinkReady, false);
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

---

### **btnDownloadFromSharePoint.c**

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

## 🧪 Test

1. **Update code** dengan property name camelCase sesuai title
2. **Save** Power Apps
3. **Test button** → Harusnya tidak error lagi
4. **Check download** → File harus ter-download

---

## 💡 Tips

**Cara check property name yang benar:**

1. **Buka flow di Power Automate**
2. **Buka action "Respond to PowerApps"**
3. **Lihat parameter yang di-add:**
   - **Name:** Property name di schema (lowercase)
   - **Title:** Property name di Power Apps (camelCase)
4. **Power Apps menggunakan TITLE, bukan Name!**

**Contoh:**
- Parameter Name: `sharepointlink` (lowercase)
- Parameter Title: `sharePointLink` (camelCase)
- **Power Apps pakai:** `sharePointLink` (sesuai title)

---

## ✅ Checklist

- [x] Update `sharepointlink` → `sharePointLink` (camelCase sesuai title)
- [x] Update `filename` → `fileName` (camelCase sesuai title)
- [x] Update `rowcount` → `rowCount` (camelCase sesuai title)
- [ ] Test button → Tidak error
- [ ] Test download → File ter-download

---

**Power Apps menggunakan TITLE dari schema, bukan property name! 🎯**

