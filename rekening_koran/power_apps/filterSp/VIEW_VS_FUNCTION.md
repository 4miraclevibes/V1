# 🔄 Perbandingan: View vs Function untuk Filtering

## 📊 Overview

Ada **2 opsi** untuk filtering di Power Apps:
1. **View** (`VW_BTP_REVIEW_FilterReady`) - Filter di Power Apps
2. **Function** (`FN_BTP_REVIEW_FilterText`) - Filter di SQL Server

---

## 🆚 Perbandingan

| Aspek | View | Function |
|-------|------|----------|
| **Setup** | ✅ Mudah (tambah sebagai data source) | ⚠️ Perlu tambah sebagai data source |
| **Parameter** | ❌ Tidak bisa | ✅ Bisa |
| **Filter Text** | ⚠️ Di Power Apps (pakai "in" operator) | ✅ Di SQL Server (LIKE) |
| **Delegation** | ⚠️ Bisa delegation warning jika tidak hati-hati | ✅ Delegation-safe |
| **Performance** | ⚡ Baik untuk dataset kecil | ⚡⚡ Lebih baik untuk dataset besar |
| **Fleksibilitas** | ✅ Sangat fleksibel | ⚠️ Terbatas pada parameter |
| **Tombol Submit** | ❌ Tidak perlu (filter langsung) | ✅ Perlu (untuk efisiensi) |
| **Switch/Toggle** | ✅ Tetap di Power Apps | ✅ Tetap di Power Apps |

---

## 🎯 Rekomendasi

### **Pakai View jika:**
- ✅ Dataset tidak terlalu besar (< 50,000 rows)
- ✅ Ingin filter langsung di Gallery tanpa tombol submit
- ✅ Ingin fleksibilitas maksimal untuk filtering
- ✅ Tidak masalah dengan delegation warning (asalkan pakai "in" operator)

### **Pakai Function jika:**
- ✅ Dataset besar (> 50,000 rows)
- ✅ Ingin filter dilakukan di SQL Server (lebih cepat)
- ✅ Tidak masalah dengan tombol submit
- ✅ Ingin menghindari delegation warning sepenuhnya

---

## 📝 Implementasi

### **Opsi 1: View (VW_BTP_REVIEW_FilterReady)**

**Setup:**
1. Tambahkan View sebagai Data Source di Power Apps
2. Langsung pakai di Gallery Items Property
3. Filter text menggunakan "in" operator

**File:**
- `VW_BTP_REVIEW_FilterReady.sql` - View definition
- `galleryWithView.c` - Contoh implementasi

**Keuntungan:**
- Tidak perlu tombol submit
- Filter langsung di Gallery
- Sangat fleksibel

**Kekurangan:**
- Bisa delegation warning jika tidak hati-hati
- Filter dilakukan di Power Apps (lebih lambat untuk dataset besar)

---

### **Opsi 2: Function (FN_BTP_REVIEW_FilterText)**

**Setup:**
1. Tambahkan Function sebagai Data Source di Power Apps
2. Buat tombol Submit Search
3. Simpan hasil filter ke variabel
4. Pakai variabel di Gallery Items Property

**File:**
- `FN_BTP_REVIEW_FilterText.sql` - Function definition
- `galleryWithFunction.c` - Contoh implementasi
- `btnSubmitSearch.c` - Contoh tombol Submit

**Keuntungan:**
- Filter dilakukan di SQL Server (lebih cepat)
- Delegation-safe
- Lebih efisien untuk dataset besar

**Kekurangan:**
- Perlu tombol submit
- Kurang fleksibel (terbatas pada parameter)

---

## 💡 Saran

**Untuk kasus Anda (ada tombol submit search):**

**Rekomendasi: Pakai Function** karena:
1. ✅ Sudah ada tombol submit search
2. ✅ Filter text dilakukan di SQL Server (lebih cepat)
3. ✅ Delegation-safe
4. ✅ Switch/toggle tetap di Power Apps (sesuai kebutuhan)

**Implementasi:**
- Gunakan `FN_BTP_REVIEW_FilterText` sebagai data source
- Isi tombol Submit Search dengan code dari `btnSubmitSearch.c`
- Update Gallery Items Property dengan code dari `galleryWithFunction.c`

---

## 🔗 File Terkait

### **View:**
- `VW_BTP_REVIEW_FilterReady.sql`
- `galleryWithView.c`

### **Function:**
- `FN_BTP_REVIEW_FilterText.sql`
- `galleryWithFunction.c`
- `btnSubmitSearch.c`
- `FUNCTION_USAGE_GUIDE.md`
