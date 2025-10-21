# 📚 BI-FAST BTP Matching - Documentation Index

## 🚀 Quick Links

| What You Need | File to Read | Description |
|---------------|--------------|-------------|
| **Get started fast** | [QUICK_START.md](QUICK_START.md) | 5-minute setup guide |
| **Multiple rows feature** | [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) | How multiple BTPs return as multiple rows |
| **Full API docs** | [README.md](README.md) | Complete reference |

---

## 📦 Files Overview

### Stored Procedures (SQL)

#### Core SPs
| File | Size | Purpose | Use When |
|------|------|---------|----------|
| [SP_BI-FAST_FindBTP_Single.sql](SP_BI-FAST_FindBTP_Single.sql) | 7.4KB | Single transaction search | Real-time lookup |
| [SP_BI-FAST_FindBTP_Batch.sql](SP_BI-FAST_FindBTP_Batch.sql) | 15KB | Batch search (returns multiple rows for multiple BTPs) | All use cases |

**Key Feature:** When a customer has multiple BTPs, the Batch SP returns multiple rows for the same TransactionID

---

### Test Suites

| File | Size | Tests |
|------|------|-------|
| [Test_SP_BI-FAST.sql](Test_SP_BI-FAST.sql) | 15KB | 9 comprehensive test cases |

---

### Documentation

| File | Size | Content |
|------|------|---------|
| [README.md](README.md) | 6.2KB | Complete API reference, status codes, troubleshooting |
| [QUICK_START.md](QUICK_START.md) | 10KB | 5-minute setup, use cases, integration examples |
| [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) | 16KB | How multiple BTPs work, usage scenarios, client examples |

---

## 🎯 What's the Multiple Rows Feature?

### Your Scenario:
> "WIDYAN AUFAR has 2 BTPs"

### The Solution:

**Output:** 2 rows for same customer
```
TxID | Customer           | BTP        | Match% | Option | BestFlag | Label
T1   | WIDYAN AUFAR | 2300009823 | 98.81  | 1      | YES      | BEST
T1   | WIDYAN AUFAR | 2300009824 | 95.24  | 2      |          | LATEST
```

✅ **Simple:** Same TransactionID, multiple rows = multiple BTPs!

---

## 🔰 For First-Time Users

### Step 1: Start Here
📖 Read: [QUICK_START.md](QUICK_START.md)
- 5-minute deployment
- Import master data
- Create stored procedures
- Run first test

### Step 2: Understand Multiple Rows
📖 Read: [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md)
- How it works
- Real examples
- Usage scenarios
- Client code (C#, Python, PowerApps)

### Step 3: API Reference
📖 Read: [README.md](README.md)
- Complete API documentation
- All parameters
- Status codes
- Error handling

---

## 🎯 For Specific Use Cases

### Use Case 1: "I want to batch import transactions automatically"
→ Use: `SP_BI-FAST_FindBTP_Batch` with filter `WHERE BestFlag = 'YES'`  
→ Read: [QUICK_START.md](QUICK_START.md) → Use Case 2

### Use Case 2: "I want to see ALL BTP options for manual review"
→ Use: `SP_BI-FAST_FindBTP_Batch` (get all rows)  
→ Read: [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) → Scenario 1

### Use Case 3: "I need real-time single transaction lookup"
→ Use: `SP_BI-FAST_FindBTP_Single`  
→ Read: [README.md](README.md) → Single Search API

### Use Case 4: "How do I handle multiple BTPs in PowerApps?"
→ Read: [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) → PowerApps Implementation

---

## 🔧 For Developers

### Integration Examples
📖 [QUICK_START.md](QUICK_START.md) includes:
- C# (.NET) integration
- Python integration
- Node.js integration
- JSON format examples

📖 [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) includes:
- Handling multiple rows in C#
- Pandas DataFrame processing
- PowerApps gallery grouping

### API Reference
📖 [README.md](README.md) includes:
- Complete parameter list
- Return values
- Status codes
- Error handling
- Performance considerations

### Testing
📖 Run tests:
```sql
-- Test both SPs
:r Test_SP_BI-FAST.sql
```

---

## ❓ FAQ Quick Links

### Q: How do multiple BTPs work?
→ [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) → How It Works

### Q: What do the flags mean?
→ [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) → Label Meanings

### Q: How to setup in 5 minutes?
→ [QUICK_START.md](QUICK_START.md)

### Q: How to get BEST BTP only for automation?
→ [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) → Scenario 2

### Q: Can I see all BTP options?
→ Yes! [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) → Scenario 1

---

## 📊 Feature Summary

| Feature | Single | Batch |
|---------|--------|-------|
| **Input** | 1 description | Multiple (JSON) |
| **Output** | Single result | Multiple rows (1+ per transaction) |
| **Multiple BTPs** | N/A | Multiple rows for same TransactionID |
| **Show ALL options** | N/A | ✅ Yes (all rows) |
| **BEST flag** | N/A | ✅ Yes |
| **LATEST flag** | N/A | ✅ Yes |
| **Debug mode** | ✅ | ✅ |
| **Use for** | Real-time | All scenarios |

---

## 🎓 Learning Path

### Beginner (New to BI-FAST)
1. [QUICK_START.md](QUICK_START.md) - Setup and run
2. [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) - Understand multiple rows

### Intermediate (Ready to integrate)
1. [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md) - Usage scenarios
2. [README.md](README.md) - API reference
3. [QUICK_START.md](QUICK_START.md) - Integration code

### Advanced (Optimization)
1. [README.md](README.md) - Performance tuning
2. Test files - Benchmark your use case

---

## 📚 Documentation Stats

| Type | Files | Total Size |
|------|-------|------------|
| Stored Procedures | 2 | 22.4KB |
| Test Suites | 1 | 15KB |
| Documentation | 3 | ~32KB |
| **Total** | **6** | **~70KB** |

---

## ✅ What You Get

✅ **2 Stored Procedures** (Single, Batch)  
✅ **1 Test Suite** (Comprehensive testing)  
✅ **3 Documentation Files** (32KB of docs!)  
✅ **Multiple Rows Feature** (See all BTPs)  
✅ **BEST + LATEST Flags** (Easy filtering)  
✅ **Integration Examples** (C#, Python, Node.js, PowerApps)  
✅ **Real Examples** (Your exact use case)  

---

## 🚀 Quick Deploy (Copy-Paste)

```sql
-- 1. Import master data (one time)
:r ../../pattern_generator_BI-FAST/master_customer_btp_pattern_BI-FAST_SPLIT.sql

-- 2. Create stored procedures
:r SP_BI-FAST_FindBTP_Single.sql
:r SP_BI-FAST_FindBTP_Batch.sql

-- 3. Test
:r Test_SP_BI-FAST.sql

-- 4. Use!
EXEC SP_BI-FAST_FindBTP_Batch @InputJSON = N'[
    {"transaction_id": "1", "description": "BI-FAST 12345 CUSTOMER NAME"}
]';
```

---

## 💡 Pro Tips

1. **Start with QUICK_START.md** - Best overview
2. **Understand multiple rows** - Read MULTIPLE_ROWS_GUIDE.md
3. **Filter for BEST only** - Use `WHERE BestFlag = 'YES'` for automation
4. **See all options** - Just run SP without filter for manual review
5. **Run tests first** - Verify before production

---

## 📞 File Selection Guide

**I want to:**
- **Setup quickly** → [QUICK_START.md](QUICK_START.md)
- **Understand multiple rows** → [MULTIPLE_ROWS_GUIDE.md](MULTIPLE_ROWS_GUIDE.md)
- **Read API docs** → [README.md](README.md)
- **Deploy batch SP** → [SP_BI-FAST_FindBTP_Batch.sql](SP_BI-FAST_FindBTP_Batch.sql)
- **Test everything** → [Test_SP_BI-FAST.sql](Test_SP_BI-FAST.sql)

---

**🎯 Simple solution: Multiple rows for multiple BTPs!**

**Need help?** All questions are answered in these 6 files!
