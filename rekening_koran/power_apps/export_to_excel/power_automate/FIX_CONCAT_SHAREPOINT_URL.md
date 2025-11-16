# 🔧 Fix Concat untuk SharePoint URL

## 📋 URL SharePoint yang Diberikan

```
https://greenfieldsdairy.sharepoint.com/sites/dairy/Power%20Apps/Forms/AllItems.aspx?id=%2Fsites%2Fdairy%2FPower%20Apps%2FCustomer%20Profile%2FRK%5FEXPORT&viewid=92f91e3c%2D83ea%2D464e%2Da23b%2D37b83d134c5e
```

**Dari URL ini, base URL yang benar adalah:**
```
https://greenfieldsdairy.sharepoint.com/sites/dairy
```

---

## ✅ Expression yang Benar untuk "Compose DownloadLink"

### **Option 1: Simple Concat (PALING MUDAH)**

**Expression:**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy',
    body('Create_file')?['Path']
)
```

**Hasil:**
```
https://greenfieldsdairy.sharepoint.com/sites/dairy/Power Apps/Customer Profile/RK_EXPORT/RekeningKoran_Export_20251114_083257.csv
```

**Cara pakai:**
1. Buka action "Compose DownloadLink"
2. Klik icon **fx**
3. Ketik expression di atas
4. Klik **OK**

---

### **Option 2: Download Link dengan Format SharePoint (LEBIH RELIABLE)**

**Expression:**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy/_layouts/15/download.aspx?SourceUrl=',
    encodeUriComponent(concat('https://greenfieldsdairy.sharepoint.com/sites/dairy', body('Create_file')?['Path'])),
    '&download=1'
)
```

**Hasil:**
```
https://greenfieldsdairy.sharepoint.com/sites/dairy/_layouts/15/download.aspx?SourceUrl=https%3A%2F%2Fgreenfieldsdairy.sharepoint.com%2Fsites%2Fdairy%2FPower%20Apps%2FCustomer%20Profile%2FRK_EXPORT%2FRekeningKoran_Export_20251114_083257.csv&download=1
```

**Keuntungan:**
- Format khusus SharePoint untuk download langsung
- Lebih reliable untuk auto-download di Power Apps

**Cara pakai:**
1. Buka action "Compose DownloadLink"
2. Klik icon **fx**
3. Ketik expression di atas
4. Klik **OK**

---

## 🎯 Rekomendasi

**Pakai Option 1** (Simple Concat) karena:
- ✅ Lebih sederhana
- ✅ Power Apps `Download()` function bisa langsung pakai
- ✅ URL lebih clean

**Pakai Option 2** (Download Link Format) jika:
- Option 1 tidak bekerja
- Perlu format khusus SharePoint untuk download

---

## 🔧 Step-by-Step Fix

### **STEP 1: Buka Action "Compose DownloadLink"**

1. Scroll ke action **"Compose DownloadLink"** di flow
2. Klik action tersebut

---

### **STEP 2: Update Input Expression**

**Current (Relative Path):**
```
body('Create_file')?['Path']
```

**Update ke (Full URL - Option 1):**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy',
    body('Create_file')?['Path']
)
```

**Atau (Download Link Format - Option 2):**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy/_layouts/15/download.aspx?SourceUrl=',
    encodeUriComponent(concat('https://greenfieldsdairy.sharepoint.com/sites/dairy', body('Create_file')?['Path'])),
    '&download=1'
)
```

---

### **STEP 3: Save Flow**

1. Klik **Save** di Power Automate
2. Test flow manual untuk verify URL benar

---

## 🧪 Test URL

**Setelah fix, test URL di browser:**

1. **Run flow manual**
2. **Copy `sharePointLink` dari output**
3. **Paste di browser baru**
4. **Check apakah file ter-download langsung**

**Contoh URL yang dihasilkan:**
```
https://greenfieldsdairy.sharepoint.com/sites/dairy/Power Apps/Customer Profile/RK_EXPORT/RekeningKoran_Export_20251114_083257.csv
```

---

## ✅ Checklist

- [ ] Buka action "Compose DownloadLink"
- [ ] Update Input expression dengan Option 1 atau Option 2
- [ ] Base URL: `https://greenfieldsdairy.sharepoint.com/sites/dairy`
- [ ] Path dari Create file: `/Power Apps/Customer Profile/RK_EXPORT/filename.csv`
- [ ] Save flow
- [ ] Test flow manual → Verify URL benar
- [ ] Test di browser → File bisa di-download

---

## 💡 Tips

**Jika SharePoint site berbeda:**
- Ganti `greenfieldsdairy.sharepoint.com` dengan SharePoint site kamu
- Ganti `dairy` dengan nama site kamu
- Format: `https://[company].sharepoint.com/sites/[siteName]`

**Contoh untuk site lain:**
```
concat(
    'https://yourcompany.sharepoint.com/sites/YourSite',
    body('Create_file')?['Path']
)
```

---

## 🎯 Summary

**Expression yang Benar:**
```
concat(
    'https://greenfieldsdairy.sharepoint.com/sites/dairy',
    body('Create_file')?['Path']
)
```

**Hasil:**
- Full SharePoint URL untuk download
- Bisa langsung dipakai di Power Apps `Download()` function

---

**Pakai Option 1 (Simple Concat) - Paling mudah dan reliable! 🎯**

