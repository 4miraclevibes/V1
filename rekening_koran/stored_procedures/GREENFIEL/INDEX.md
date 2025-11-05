# 📚 GREENFIEL BTP Matching - Documentation Index

## 🚀 Quick Links

| What You Need | File to Read | Description |
|---------------|--------------|-------------|
| **Get started fast** | [QUICK_START.md](QUICK_START.md) | 5-minute setup guide |
| **Multiple rows feature** | [README.md](README.md) → Multiple BTP Options | How multiple BTPs return as multiple rows |
| **Full API docs** | [README.md](README.md) | Complete reference |

---

## 📦 Files Overview

### Stored Procedures (SQL)

#### Core SPs
| File | Size | Purpose | Use When |
|------|------|---------|----------|
| [SP_GREENFIEL_FindBTP_Batch.sql](SP_GREENFIEL_FindBTP_Batch.sql) | ~15KB | Batch search (returns multiple rows for multiple BTPs) | All use cases |

**Key Feature:** Extracts BTP from description, finds customer_name in master, then returns all BTP options for that customer.

---

### Test Data

| File | Size | Content |
|------|------|---------|
| [data_sample.txt](data_sample.txt) | ~659B | 8 sample transactions for testing |

---

### Documentation

| File | Size | Content |
|------|------|---------|
| [README.md](README.md) | ~8KB | Complete API reference, status codes, troubleshooting |
| [QUICK_START.md](QUICK_START.md) | ~10KB | 5-minute setup, use cases, integration examples |
| [INDEX.md](INDEX.md) | ~5KB | Documentation hub (this file) |

---

## 🎯 What's the Multiple Rows Feature?

### Your Scenario:
> "CUSTOMER A has 2 BTPs"

### The Solution:

**Output:** 2 rows for same customer
```
TxID | Customer     | BTP        | Match% | Option | BestFlag | Label
T1   | CUSTOMER A   | 2300017744 | 100.00 | 1      | YES      | BEST
T1   | CUSTOMER A   | 2300015555 | 95.24  | 2      |          | LATEST
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

### Step 2: Understand How It Works
📖 Read: [README.md](README.md)
- Pattern detection logic
- BTP extraction process
- Customer name lookup
- Multiple BTP options

### Step 3: API Reference
📖 Read: [README.md](README.md)
- Complete API documentation
- All parameters
- Status codes
- Error handling

---

## 🎯 For Specific Use Cases

### Use Case 1: "I want to batch import transactions automatically"
→ Use: `SP_GREENFIEL_FindBTP_Batch` with filter `WHERE BestFlag = 'YES'`  
→ Read: [QUICK_START.md](QUICK_START.md) → Use Case 3

### Use Case 2: "I want to see ALL BTP options for manual review"
→ Use: `SP_GREENFIEL_FindBTP_Batch` (get all rows)  
→ Read: [README.md](README.md) → Multiple BTP Options

### Use Case 3: "How do I handle multiple BTPs in PowerApps?"
→ Read: [QUICK_START.md](QUICK_START.md) → PowerApps Integration

---

## 🔧 For Developers

### Integration Examples
📖 [QUICK_START.md](QUICK_START.md) includes:
- C# (.NET) integration
- Python integration
- Node.js integration
- PowerApps integration
- JSON format examples

### API Reference
📖 [README.md](README.md) includes:
- Complete parameter list
- Return values
- Status codes
- Error handling
- Performance considerations

### Testing
📖 Use sample data:
```sql
-- Test with data_sample.txt
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TEST001",
        "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"
    }
]';

EXEC SP_GREENFIEL_FindBTP_Batch 
    @InputJSON = @JSON,
    @Debug = 1;
```

---

## ❓ FAQ Quick Links

### Q: How does GREENFIEL pattern work?
→ [README.md](README.md) → Pattern Detection

### Q: How does BTP extraction work?
→ [README.md](README.md) → Pattern Detection → Example Analysis

### Q: What do the flags mean?
→ [README.md](README.md) → Multiple BTP Options

### Q: How to setup in 5 minutes?
→ [QUICK_START.md](QUICK_START.md)

### Q: How to get BEST BTP only for automation?
→ [QUICK_START.md](QUICK_START.md) → Use Case 3

### Q: Can I see all BTP options?
→ Yes! [README.md](README.md) → Multiple BTP Options

---

## 📊 Feature Summary

| Feature | GREENFIEL Batch |
|---------|-----------------|
| **Input** | Multiple (JSON) |
| **Output** | Multiple rows (1+ per transaction) |
| **Multiple BTPs** | Multiple rows for same TransactionID |
| **Show ALL options** | ✅ Yes (all rows) |
| **BEST flag** | ✅ Yes |
| **LATEST flag** | ✅ Yes |
| **Debug mode** | ✅ Yes |
| **Use for** | All scenarios |

---

## 🎓 Learning Path

### Beginner (New to GREENFIEL)
1. [QUICK_START.md](QUICK_START.md) - Setup and run
2. [README.md](README.md) - Understand pattern detection

### Intermediate (Ready to integrate)
1. [QUICK_START.md](QUICK_START.md) - Integration examples
2. [README.md](README.md) - API reference
3. [QUICK_START.md](QUICK_START.md) - Use cases

### Advanced (Optimization)
1. [README.md](README.md) - Troubleshooting
2. Test with your own data

---

## 📚 Documentation Stats

| Type | Files | Total Size |
|------|-------|------------|
| Stored Procedures | 1 | ~15KB |
| Test Data | 1 | ~659B |
| Documentation | 3 | ~23KB |
| **Total** | **5** | **~39KB** |

---

## ✅ What You Get

✅ **1 Stored Procedure** (Batch)  
✅ **1 Test Data File** (8 sample transactions)  
✅ **3 Documentation Files** (23KB of docs!)  
✅ **Multiple Rows Feature** (See all BTPs)  
✅ **BEST + LATEST Flags** (Easy filtering)  
✅ **Integration Examples** (C#, Python, Node.js, PowerApps)  
✅ **Real Examples** (Sample data included)  

---

## 🚀 Quick Deploy (Copy-Paste)

```sql
-- 1. Ensure master table exists
-- Table: [dbo].[MASTER_CUSTOMER_BTP_PATTERN]
-- Records with: category = 'GREENFIEL' or 'NEW'

-- 2. Create stored procedure
:r SP_GREENFIEL_FindBTP_Batch.sql

-- 3. Test
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TEST001",
        "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"
    }
]';

EXEC SP_GREENFIEL_FindBTP_Batch 
    @InputJSON = @JSON,
    @Debug = 1;

-- 4. Use!
EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON = @YourJSON;
```

---

## 💡 Pro Tips

1. **Start with QUICK_START.md** - Best overview
2. **Understand pattern detection** - Array[4] must be exactly 'GREENFIEL'
3. **Filter for BEST only** - Use `WHERE BestFlag = 'YES'` for automation
4. **See all options** - Just run SP without filter for manual review
5. **Use debug mode** - Set `@Debug = 1` to see detailed statistics

---

## 📞 File Selection Guide

**I want to:**
- **Setup quickly** → [QUICK_START.md](QUICK_START.md)
- **Understand pattern detection** → [README.md](README.md) → Pattern Detection
- **Read API docs** → [README.md](README.md)
- **Deploy batch SP** → [SP_GREENFIEL_FindBTP_Batch.sql](SP_GREENFIEL_FindBTP_Batch.sql)
- **Test with sample data** → [data_sample.txt](data_sample.txt)

---

## 🔍 How GREENFIEL Works (Quick Overview)

1. **Pattern Check**: Array[4] = 'GREENFIEL'? ✅
2. **Extract BTP**: Last word starting with "23..." (10+ digits)
3. **Find Customer**: Search master by BTP → get customer_name
4. **Find All BTPs**: Search master by customer_name → get all BTP options
5. **Return Results**: All BTPs ranked by priority

**Key Difference from other banks:**
- Other banks: Extract customer_name → Find BTPs
- GREENFIEL: Extract BTP → Find customer_name → Find all BTPs

---

**🎯 Simple solution: Extract BTP first, then find customer, then find all BTPs!**

**Need help?** All questions are answered in these 3 documentation files!
