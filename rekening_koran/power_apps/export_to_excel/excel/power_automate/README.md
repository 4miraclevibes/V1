# 📊 Excel Export Flow - Documentation Index

## 🎯 Tujuan

Convert data dari database ke **Excel file (.xlsx)** yang benar-benar bisa dibuka di Excel.

---

## ✅ Urutan flow yang benar (CSV + SharePoint)

Urutan action di Power Automate **harus persis seperti ini** (trigger → SP → CSV → SharePoint → respond):

| # | Action | Keterangan |
|---|--------|------------|
| 1 | **When Power Apps calls a flow (V2)** | Trigger; input opsional: StartDate, EndDate, BTP |
| 2 | **Execute stored procedure (V2)** | Panggil `SP_EXPORT_REKENING_KORAN` |
| 3 | **Parse JSON** | Parse `ResultSets/Table1` dari output SP |
| 4 | **Create CSV table** | Convert ke CSV (UTF-8, comma) |
| 5 | **Compose** | Base64: `base64(body('Create_CSV_table'))` |
| 6 | **Initialize variable** | `varFileName` = RekeningKoran_Export_yyyyMMdd_HHmmss.csv |
| 7 | **Create file** (SharePoint) | Simpan CSV; File Content = `base64ToBinary(body('Compose'))` |
| 8 | **Compose DownloadLink** | Input = `body('Create_file')?['Path']` |
| 9 | **Respond to a Power App or flow** | Output: fileName, sharePointLink, rowCount, status |

**Dokumentasi lengkap flow Rekening Koran (CSV + link):**  
`../../power_automate/SETUP_LENGKAP_DARI_AWAL.md` dan `FLOW_STEPS_SHAREPOINT.md`

Flow **Excel** (jika pakai convert CSV→Excel) dibangun di atas urutan ini; step "Create CSV table" bisa dipakai lalu ditambah konversi ke Excel sebelum "Create file".

---

## 📋 Dua Approach

### **APPROACH 1: CSV → Excel Conversion**

**Flow:** Reuse CSV flow yang sudah ada, lalu convert CSV ke Excel.

**File:** `FLOW_STEPS_CSV_TO_EXCEL.md`

**Flow Steps:**
```
Query → Parse JSON → Create CSV → Convert CSV to Excel → Upload Excel → Return Link
```

**Keuntungan:**
- ✅ Reuse CSV flow yang sudah ada
- ✅ CSV sebagai intermediate step

**Kekurangan:**
- ⚠️ Lebih kompleks (perlu convert CSV)

---

### **APPROACH 2: JSON → Excel Direct (RECOMMENDED!)**

**Flow:** Langsung create Excel dari JSON data, skip CSV.

**File:** `FLOW_STEPS_SIMPLE.md`

**Flow Steps:**
```
Query → Parse JSON → Create Excel → Add Data → Upload Excel → Return Link
```

**Keuntungan:**
- ✅ Lebih simple (tidak perlu CSV)
- ✅ Lebih cepat
- ✅ Lebih reliable

**Kekurangan:**
- ❌ Tidak reuse CSV flow

---

## 🎯 Rekomendasi

**Pakai APPROACH 2 (Simple)** karena:
- ✅ Lebih simple dan cepat
- ✅ Tidak perlu convert CSV
- ✅ Langsung dari JSON ke Excel

**Pakai APPROACH 1** jika:
- Ingin reuse CSV flow yang sudah ada
- Perlu CSV sebagai backup

---

## 📚 Dokumentasi

### **Flow Setup:**
- **`FLOW_STEPS.md`** - Overview dan general flow
- **`FLOW_STEPS_CSV_TO_EXCEL.md`** - CSV → Excel conversion
- **`FLOW_STEPS_SIMPLE.md`** - JSON → Excel direct (RECOMMENDED!)

### **Convert Methods:**
- **`CONVERT_CSV_TO_EXCEL.md`** - 3 cara convert CSV ke Excel

---

## 🚀 Quick Start

1. **Baca:** `FLOW_STEPS_SIMPLE.md` (recommended)
2. **Setup:** Flow di Power Automate sesuai dokumentasi
3. **Test:** Export Excel file

---

**Pilih APPROACH 2 (Simple) untuk setup yang lebih mudah! 📊**

