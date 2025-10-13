# BTP Pattern Matching - Testing Tool

## 📋 Deskripsi

Program testing untuk menguji akurasi pattern matching BTP dari deskripsi transaksi TRSF.
**File-based testing** - tidak perlu database, pakai file SQL langsung sebagai master data.

## 🚀 Cara Menggunakan

### 1. Jalankan Program

```bash
cd rekening_koran
./test_btp_pattern
```

### 2. Pilih Master Data File

Saat program start, pilih file master data:
- **Option 1**: `insert_customer_btp_pattern_70pct.sql` → 2219 patterns (threshold 70%)
- **Option 2**: `insert_customer_btp_pattern.sql` → 2201 patterns (threshold 80%)

### 3. Menu Testing

Program menyediakan 5 opsi testing:

#### ✅ Option 1: Test Manual (Single Input)
- Input 1 deskripsi TRSF secara manual
- Program akan cari pattern dan tampilkan hasil
- Cocok untuk testing case-by-case

**Contoh Input:**
```
TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 GF fresh 2dus 3jan 2024 RONNY YULIADY
```

**Output:**
```
✅ PATTERN FOUND!
BTP                : 2300014094
Customer Name      : RONNY YULIADY
Match Percentage   : 100.00%
Confidence         : 🟢 VERY_HIGH
Recommended Action : Auto-fill without review
```

#### ✅ Option 2: Test Batch 10 Sample
- Ambil 10 transaksi TRSF dari TRSF.csv
- Test semua dan tampilkan hasil
- Quick check untuk lihat akurasi

#### ✅ Option 3: Test Batch 50 Sample
- Ambil 50 transaksi TRSF dari TRSF.csv
- Testing lebih comprehensive

#### ✅ Option 4: Test Batch 100 Sample
- Ambil 100 transaksi TRSF dari TRSF.csv
- Full testing untuk measure akurasi

**Output Batch Testing:**
```
[1] ✅ MATCH
    Original BTP  : 2300014094
    Suggested BTP : 2300014094 (100.0% confidence)
    Customer      : RONNY YULIADY
    
[2] ⚠️ MISMATCH
    Original BTP  : 2300012345
    Suggested BTP : 2300067890 (95.5% confidence)
    Customer      : CUSTOMER X
    
[3] ❌ NO PATTERN
    Original BTP  : 2300099999
    Description   : TRSF ... (no customer name found)

TESTING SUMMARY
═══════════════════════════════════════════
Total Tested       : 100
Pattern Found      : 85 (85.0%)
No Pattern Found   : 15 (15.0%)
```

#### ✅ Option 5: Statistik Master Data
- Tampilkan distribusi quality patterns
- Top 10 customer by transaction volume
- Overview master data yang loaded

## 🎯 Confidence Tier

Program menggunakan tiered confidence system:

| Match % | Tier | Indicator | Recommended Action |
|---------|------|-----------|-------------------|
| ≥95% | VERY_HIGH | 🟢 | Auto-fill without review |
| 90-94% | HIGH | 🔵 | Auto-fill with audit |
| 80-89% | MEDIUM | 🟡 | Suggest with confirmation |
| 70-79% | LOW_MEDIUM | 🟠 | Suggest with validation |
| <70% | LOW | 🔴 | Manual entry |

## 📊 Expected Results

Berdasarkan data analysis sebelumnya:

- **Coverage Rate**: ~40% dari transaksi akan match dengan pattern
- **Accuracy**: 95%+ patterns memiliki match rate ≥95%
- **Perfect Match**: ~94% patterns dengan 100% consistency

## 🔍 Testing Tips

### Test Case 1: Perfect Match
```
Input: TRSF E-BANKING CR 0301/FTSCY/WS95051 1138800.00 inv K002000009320 PT ARYANDA YASA UN
Expected: BTP 2300015194, 100% match
```

### Test Case 2: Multiple Customers in Same BTP
```
Input: TRSF E-BANKING CR 0501/FTSCY/WS95011 911040.00 FM 4dus 3/1 EVELYN YONA
Expected: BTP 2300015307, 100% match untuk EVELYN YONA

Input: TRSF E-BANKING CR 0801/FTSCY/WS95011 683280.00 FM3dus OD2/1 RENITA SUSILO
Expected: BTP 2300015307, 100% match untuk RENITA SUSILO
```

### Test Case 3: No Pattern
```
Input: TRSF E-BANKING CR 0101/FTSCY/WS95051 455520.00
Expected: NO PATTERN FOUND (tidak ada customer name)
```

## 🛠️ Troubleshooting

### Error: "Tidak dapat membuka file"
- Pastikan file SQL ada di folder yang sama dengan program
- Pastikan nama file sesuai: `insert_customer_btp_pattern_70pct.sql` atau `insert_customer_btp_pattern.sql`

### Error: "Tidak dapat membuka TRSF.csv"
- Pastikan file TRSF.csv ada di folder yang sama
- Untuk batch testing (option 2-4)

### Pattern tidak ketemu padahal ada customer name
- Cek apakah customer name di master data (option 5)
- Cek penulisan customer name (harus exact match, case insensitive)
- Mungkin customer name terpotong atau ada typo

## 📁 Files Required

Program membutuhkan file-file ini di folder yang sama:

1. **test_btp_pattern** (executable) - Program utama
2. **insert_customer_btp_pattern_70pct.sql** - Master data 70% threshold
3. **insert_customer_btp_pattern.sql** - Master data 80% threshold
4. **TRSF.csv** - Source data untuk batch testing (optional)

## 🔧 Recompile Program

Jika ada perubahan di source code:

```bash
gcc -o test_btp_pattern test_btp_pattern.c
```

## 📝 Notes

- Program ini **read-only**, tidak mengubah file apapun
- Semua testing dilakukan di memory
- Tidak perlu database atau SQL Server
- Cocok untuk quick testing dan validation
- Kriteria minimal: **2 transaksi** (updated dari 5)

