# 🔧 Fix Property Name di Power Apps

## ❌ Error: `sharePointLink` isn't recognized

**Penyebab:** Property name di Power Apps harus lowercase sesuai dengan output flow.

---

## ✅ Property Name yang Benar

Dari output flow, property name adalah **lowercase**:

| Property di Flow | Property di Power Apps |
|------------------|------------------------|
| `sharepointlink` | `sharepointlink` ✅ |
| `filename` | `filename` ✅ |
| `rowcount` | `rowcount` ✅ |
| `status` | `status` ✅ |

**❌ JANGAN pakai:**
- `sharePointLink` (camelCase)
- `fileName` (camelCase)
- `rowCount` (camelCase)

**✅ PAKAI:**
- `sharepointlink` (lowercase)
- `filename` (lowercase)
- `rowcount` (lowercase)

---

## 🔧 Fix Code

### **Button Code (btnDownloadFromSharePoint.c)**

**SALAH:**
```powerappsfx
varExportResult.sharePointLink  ← Error!
```

**BENAR:**
```powerappsfx
varExportResult.sharepointlink  ← Benar!
```

---

### **Button Code (btnGenerateLink.c)**

**SALAH:**
```powerappsfx
varExportResult.sharePointLink  ← Error!
```

**BENAR:**
```powerappsfx
varExportResult.sharepointlink  ← Benar!
```

---

## ✅ Code yang Sudah Diperbaiki

### **btnDownloadFromSharePoint.c**

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.sharepointlink),
    Download(varExportResult.sharepointlink);
    Notify("✅ Download started!", NotificationType.Success, 3000),
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

---

### **btnGenerateLink.c**

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.sharepointlink),
    Set(varSharePointLink, varExportResult.sharepointlink);
    Set(varDownloadFileName, varExportResult.filename);
    Set(varLinkReady, true);
    Notify("✅ File ready!", NotificationType.Success, 3000),
    Set(varLinkReady, false);
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

---

## 🧪 Test

1. **Update code** dengan property name lowercase
2. **Save** Power Apps
3. **Test button** → Harusnya tidak error lagi
4. **Check download** → File harus ter-download

---

## 💡 Tips

**Cara check property name yang benar:**

1. **Run flow manual** di Power Automate
2. **Lihat output** di "Respond to PowerApps"
3. **Property name** di output adalah yang harus dipakai di Power Apps
4. **Biasanya lowercase** untuk property name di Power Apps

---

## ✅ Checklist

- [ ] Update `sharePointLink` → `sharepointlink` (lowercase)
- [ ] Update `fileName` → `filename` (lowercase)
- [ ] Update `rowCount` → `rowcount` (lowercase)
- [ ] Test button → Tidak error
- [ ] Test download → File ter-download

---

**Property name harus lowercase sesuai output flow! 🎯**

