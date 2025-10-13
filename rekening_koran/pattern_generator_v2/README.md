# Pattern Generator v2 - CLEAN LOGIC

## Logic Yang Benar

**Cara extract customer name:**
1. Split description by space → array of words
2. Check dari belakang (last word → first word)
3. Find last word yang mengandung angka → save index
4. Customer name = ALL CAPS words SETELAH index tsb (index+1 sampai end)

## Example 1:
```
Description: Z1AL1 ANDRE ISKANDAR
Words: ['Z1AL1', 'ANDRE', 'ISKANDAR']
Index:  [0,      1,       2]

Check dari belakang:
- Index 2 (ISKANDAR) → no number
- Index 1 (ANDRE) → no number  
- Index 0 (Z1AL1) → ADA ANGKA! STOP!

Customer name dimulai dari index 1: ANDRE ISKANDAR ✅
```

## Example 2:
```
Description: WS95051 911040.00 CAFE RSPI SARI PUSPITA PT
Words: ['WS95051', '911040.00', 'CAFE', 'RSPI', 'SARI', 'PUSPITA', 'PT']
Index:  [0,        1,           2,      3,      4,      5,         6]

Check dari belakang:
- Index 6 (PT) → no number
- Index 5 (PUSPITA) → no number
- Index 4 (SARI) → no number
- Index 3 (RSPI) → no number
- Index 2 (CAFE) → no number
- Index 1 (911040.00) → ADA ANGKA! STOP!

Customer name dimulai dari index 2-6: CAFE RSPI SARI PUSPITA PT ✅
```

## Results

- **Total Patterns Generated**: **15,459** (ALL combinations)
- **Coverage (50k samples)**: **89.6%** 🎯
- **Threshold**: NONE (all customer-BTP combinations included)
- **Min Transactions**: 1
- **Output File**: `master_customer_btp_pattern.sql`

### Coverage Test Results

| Test Size | Found | Not Found | Coverage |
|-----------|-------|-----------|----------|
| 50,000 samples | 44,786 | 5,214 | **89.6%** ✅ |

**✅ TARGET 85%+ ACHIEVED!**

## Compile & Run

### 1. Generate Patterns (from TRSF.csv)

```bash
cd /Users/balian/Documents/GitHub/V1/rekening_koran/pattern_generator_v2
gcc -o generate_patterns generate_patterns.c
./generate_patterns
```

### 2. Test BTP Pattern Matching

```bash
cd /Users/balian/Documents/GitHub/V1/rekening_koran/pattern_generator_v2
gcc -o test_btp_pattern test_btp_pattern.c
./test_btp_pattern
```

**Test Options:**
- `1` - Manual input (single test)
- `2` - Test 10 samples
- `3` - Test 50 samples
- `4` - Test 100 samples
- `5` - Test 1,000 samples
- `6` - Test 5,000 samples
- `7` - Test 10,000 samples
- `8` - Test 50,000 samples 🎯 (recommended for accuracy)
- `9` - Show statistics
- `0` - Exit

**Quick Test (50k samples):**
```bash
cd /Users/balian/Documents/GitHub/V1/rekening_koran/pattern_generator_v2
echo "8
0" | ./test_btp_pattern
```

**ATAU gunakan shell script:**
```bash
cd /Users/balian/Documents/GitHub/V1/rekening_koran/pattern_generator_v2
./run_test.sh
```

## Clean Patterns Examples

✅ CLEAN (no numbers in customer name):
- `BROOKLYN BOGA UTAM`
- `PANCIOUS TIRTA JAY`
- `CIRANJANG MAJU TER`
- `RONNY YULIADY`
- `SINAR DIGITAL TERD`

❌ TIDAK ADA LAGI yang seperti ini:
- `WS95031 455520.00 ANDREAS TJITRAHARD`
- `C1JZ1231201162 SUMBER ALFARIA TRI`
- `N7120477 12-JAN-24 MAKAN ENAK BERSAMA`

## Next Steps

1. ✅ Generate patterns dengan logic yang benar
2. ⏳ Test coverage (need to fix test tool)
3. ⏳ Deploy to production

---

**Pattern Generator v2 - Logic yang SIMPLE dan BENAR!** 🎯

