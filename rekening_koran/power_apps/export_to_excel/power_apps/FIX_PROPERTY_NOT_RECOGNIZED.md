# 🔧 Fix: Property Not Recognized di Power Apps

## ❌ Error: `sharePointLink` isn't recognized

**Penyebab:** Power Apps belum recognize property baru dari flow response.

---

## ✅ Solusi: Pakai Property Name dari Body (Lowercase)

Dari output flow, property name di **body** adalah **lowercase**:

```json
"body": {
    "sharepointlink": "https://...",
    "filename": "...",
    "rowcount": 36
}
```

**Power Apps menggunakan property name dari body, bukan title!**

---

## 🔧 Fix Code

### **Update Property Name ke Lowercase**

**SALAH:**
```powerappsfx
varExportResult.sharePointLink  ← Error!
varExportResult.fileName        ← Error!
varExportResult.rowCount        ← Error!
```

**BENAR:**
```powerappsfx
varExportResult.sharepointlink  ← Benar! (lowercase sesuai body)
varExportResult.filename        ← Benar! (lowercase sesuai body)
varExportResult.rowcount        ← Benar! (lowercase sesuai body)
```

---

## ✅ Code yang Sudah Diperbaiki

### **btnDownloadFromSharePoint.c**

```powerappsfx
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

If(
    !IsBlank(varExportResult.sharepointlink),
    Download(varExportResult.sharepointlink);
    Notify("✅ Download started! " & varExportResult.rowcount & " rows.", NotificationType.Success, 3000),
    Notify("❌ Export failed", NotificationType.Error, 3000)
);
```

---

## 🔄 Jika Masih Error: Refresh Power Apps

**Power Apps mungkin perlu di-refresh untuk recognize property baru:**

### **STEP 1: Save Flow di Power Automate**

1. Buka flow di Power Automate
2. **Save** flow (pastikan semua parameter sudah benar)
3. **Test flow manual** → Verify output benar

### **STEP 2: Refresh Power Apps**

1. **Power Apps** → **Data** → **Flows**
2. **Remove flow** `Export_RekeningKoran_ToExcel` (jika ada)
3. **Add flow** → Pilih `Export_RekeningKoran_ToExcel` lagi
4. **Save** Power Apps

### **STEP 3: Check Property Name**

1. **Buka button** → **OnSelect** property
2. **Ketik:** `varExportResult.`
3. **IntelliSense akan muncul** → Lihat property apa saja yang tersedia
4. **Pilih property yang muncul** (biasanya lowercase)

---

## 🧪 Test Property Name

**Cara test property name yang benar:**

1. **Buka button** → **OnSelect** property
2. **Tambah code test:**
   ```powerappsfx
   Set(varExportResult, Export_RekeningKoran_ToExcel.Run());
   Notify(varExportResult.sharepointlink, NotificationType.Information, 5000);
   ```
3. **Save** dan **test button**
4. **Lihat notification** → Jika muncul URL, property name benar!
5. **Jika error** → Coba property name lain (lowercase atau camelCase)

---

## 💡 Tips

**Property name di Power Apps biasanya:**
- **Lowercase** jika property name di body adalah lowercase
- **CamelCase** jika ada title di schema

**Tapi yang paling reliable:**
- **Check IntelliSense** di Power Apps → Ketik `varExportResult.` → Lihat property apa yang muncul
- **Pakai property yang muncul di IntelliSense** (paling pasti benar!)

---

## ✅ Checklist

- [ ] Update property name ke lowercase (`sharepointlink`, `filename`, `rowcount`)
- [ ] Save flow di Power Automate
- [ ] Refresh flow di Power Apps (remove & add lagi)
- [ ] Check IntelliSense di Power Apps → Lihat property yang tersedia
- [ ] Test button → Tidak error
- [ ] Test download → File ter-download

---

## 🔍 Alternative: Check IntelliSense

**Cara paling pasti untuk tahu property name:**

1. **Buka button** → **OnSelect** property
2. **Ketik:** `varExportResult.`
3. **IntelliSense muncul** → Lihat property apa saja yang tersedia
4. **Pakai property yang muncul** (ini yang paling benar!)

**Contoh:**
- Jika muncul `sharepointlink` → Pakai `sharepointlink`
- Jika muncul `sharePointLink` → Pakai `sharePointLink`
- Jika muncul `SharePointLink` → Pakai `SharePointLink`

---

**Check IntelliSense di Power Apps untuk tahu property name yang benar! 🎯**

