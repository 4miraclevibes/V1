# 🚀 Bank Pattern Generator Launcher

Command Center untuk mengelola dan menjalankan semua 20 Bank Pattern Generators dari satu tempat.

## 📋 Quick Start

```bash
cd /Users/balian/Documents/GitHub/V1/rekening_koran/pattern_documentation

# Compile (jika belum)
gcc pattern_launcher.c -o pattern_launcher

# Run
./pattern_launcher
```

## ✨ Features

### 1. 🔍 Test BTP Pattern
- Pilih bank manapun dari 20 banks
- Test pattern matching dengan input description
- Interactive menu untuk manual testing
- Support untuk semua extraction logic

### 2. 📊 Show All Banks
- Daftar lengkap 20 banks
- Grouped by extraction logic:
  - Group 1: Array[3]+[4] (9 banks)
  - Group 2: Array[4]+[5] (9 banks)
  - Group 3: Special Logic (2 banks)
- Pattern count untuk setiap bank

### 3. 🔧 Generate Patterns
- Regenerate patterns untuk bank tertentu
- Konfirmasi sebelum execute (safety feature)
- Auto-compile check
- Update master SQL files

### 4. 📖 Show Documentation
- Quick access ke documentation.txt
- Menampilkan 100 baris pertama
- Overview extraction logic dan statistics

## 🏦 Supported Banks (20)

### Group 1: Array[3] + Array[4]
1. BNI
2. BTPN
3. MANDIRI (131 patterns ⭐)
4. BRI
5. MEGA
6. PERMATA
7. DANAMON
8. CITIBANK
9. SINARMAS

### Group 2: Array[4] + Array[5]
10. CIMB (97 patterns)
11. MAYBANK
12. HSBC
13. UOB
14. MUAMALAT
15. OCBC
16. DBS
17. CAPITAL
18. WOORI

### Group 3: Special Logic
19. TRSF (6900 patterns ⭐⭐⭐)
20. BI-FAST (763 patterns)

## 📖 Documentation

Lihat `LAUNCHER_GUIDE.txt` untuk:
- Detailed user guide
- Troubleshooting
- Examples
- Tips & tricks

## 🎯 Use Cases

### Test Multiple Banks
```
1. Run launcher
2. Select option 1
3. Test bank 3 (MANDIRI)
4. Back to menu
5. Test bank 10 (CIMB)
6. Repeat as needed
```

### Regenerate Specific Bank
```
1. Run launcher
2. Select option 3
3. Choose bank ID
4. Confirm with 'y'
5. Wait for completion
```

### Quick Reference
```
1. Run launcher
2. Select option 2 (View all banks)
   OR
   Select option 4 (View documentation)
```

## 🔧 Requirements

- GCC compiler
- All pattern generators compiled
- CSV files di setiap folder bank

## 📁 File Structure

```
pattern_documentation/
├── pattern_launcher.c          # Source code
├── pattern_launcher            # Executable
├── LAUNCHER_GUIDE.txt         # Detailed guide
├── README_LAUNCHER.md         # This file
└── documentation.txt          # Main docs
```

## 🆘 Troubleshooting

**Executable not found?**
```bash
cd ../pattern_generator_[BANK]
gcc test_btp_pattern.c -o test_btp_pattern_[bank]
```

**Permission denied?**
```bash
chmod +x pattern_launcher
```

**Back to menu not working?**
- Tekan Enter setelah program selesai

## 🎉 Benefits

✅ **Centralized Control** - One tool untuk semua banks
✅ **Quick Testing** - No need to cd ke setiap folder
✅ **Safety** - Konfirmasi sebelum regenerate
✅ **Time Saving** - Batch test multiple banks
✅ **User Friendly** - Clear menu dan instructions

## 📊 Statistics

- **Total Banks**: 20
- **Total Patterns**: ~8,025+
- **Extraction Methods**: 3 groups
- **Total Files**: 120+ files
- **Lines of Code**: 10,000+ lines

## 🔄 Version

**v1.0** (October 20, 2025)
- Initial release
- Support 20 banks
- Full feature set

---

**Created by**: AI Assistant with ❤️
**Date**: October 20, 2025
**Project**: Bank Pattern Generator System

