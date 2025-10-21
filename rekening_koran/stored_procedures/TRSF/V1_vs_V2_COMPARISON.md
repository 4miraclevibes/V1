# SP_TRSF_FindBTP_Batch: v1 vs v2 Comparison

## 📊 Overview

Kedua versi SP ini melakukan hal yang sama: **Find BTP dari deskripsi TRSF**.  
Perbedaan utama adalah **output format** ketika ada **multiple BTP options**.

---

## 🔄 Version Comparison

### v1 (Original) - Simple Output

**File:** `SP_TRSF_FindBTP_Batch.sql`

#### Output:
- **1 Result Set** only
- Returns **BEST BTP** untuk setiap transaction
- Column `TotalBTPOptions` menunjukkan jumlah options (tapi tidak detail)

#### Example Result:
```
TransactionID | CustomerName  | BTP        | MatchPct | TotalBTPOptions | Message
TRX004       | CHRISTIAN     | 2300014842 | 98.81    | 2              | Found 2 BTP options. Returning BEST.
```

**Limitation:**  
❌ Tidak tahu BTP options lainnya apa saja  
❌ Tidak tahu flag BEST vs LATEST  
❌ Harus query manual untuk lihat alternatives

---

### v2 (Enhanced) - Detailed Output

**File:** `SP_TRSF_FindBTP_Batch_v2.sql`

#### Output:
- **2 Result Sets**
  - **Set 1:** Main results (sama seperti v1, tapi message lebih detail)
  - **Set 2:** ALL BTP options untuk yang multiple matches

#### Example Results:

**Result Set 1:** (Main Results)
```
TransactionID | CustomerName  | BTP        | MatchPct | TotalBTPOptions | Message
TRX004       | CHRISTIAN     | 2300014842 | 98.81    | 2              | Found 2 BTP options. Returning BEST. See Result Set 2 for all options.
```

**Result Set 2:** (All Options Details)
```
TransactionID | OptionNumber | BTP        | MatchPct | BestFlag   | LatestFlag | Label      | Quality
TRX004       | 1           | 2300014842 | 98.81    | ✅ BEST    |            | BEST       | EXCELLENT
TRX004       | 2           | 2300015678 | 95.24    |            | 🕒 LATEST  | LATEST     | EXCELLENT
```

**Advantages:**  
✅ Lihat semua BTP options  
✅ Flag indicators (BEST, LATEST)  
✅ Dapat override pilihan BEST jika perlu  
✅ Mirip output C code

---

## 🎯 When to Use Which Version?

### Use v1 (SP_TRSF_FindBTP_Batch) if:

✅ **Simple automation** - Just need best match  
✅ **Import batch** - Trust algorithm choice  
✅ **Performance critical** - Less overhead  
✅ **Single result set** - Easier to consume in code

**Use Case Examples:**
- Automatic daily import from bank statements
- Real-time API integration
- Simple PowerApps gallery display

---

### Use v2 (SP_TRSF_FindBTP_Batch_v2) if:

✅ **Manual review needed** - Want to see alternatives  
✅ **Override capability** - User can choose different BTP  
✅ **Transparency** - Show why BEST was chosen  
✅ **Similar to C code** - Match existing behavior

**Use Case Examples:**
- Manual reconciliation interface
- Verification/audit screens
- Training/debugging
- PowerApps dropdown with options

---

## 🔧 API Comparison

### v1 Usage:
```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "T1", "description": "TRSF 12345 CHRISTIAN"}
]';

EXEC SP_TRSF_FindBTP_Batch @InputJSON = @JSON;

-- Returns: 1 result set (main results)
```

### v2 Usage:
```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "T1", "description": "TRSF 12345 CHRISTIAN"}
]';

EXEC SP_TRSF_FindBTP_Batch_v2 @InputJSON = @JSON;

-- Returns: 2 result sets
--   Set 1: Main results (same as v1 structure)
--   Set 2: All options (only for multiple matches)
```

---

## 📋 Output Schema Comparison

### Result Set 1 (Main Results)

**Same structure for both versions:**

| Column            | Type           | Description                          |
|-------------------|----------------|--------------------------------------|
| TransactionID     | NVARCHAR(50)   | Your transaction reference           |
| Description       | NVARCHAR(500)  | Original description                 |
| CustomerName      | NVARCHAR(200)  | Extracted customer name              |
| BTP               | NVARCHAR(100)  | Best matching BTP code               |
| MatchPercentage   | DECIMAL(5,2)   | Match quality (%)                    |
| MatchCount        | INT            | Successful match count               |
| TotalTransactions | INT            | Total transactions for this BTP      |
| TotalBTPOptions   | INT            | Number of BTP options found          |
| Status            | NVARCHAR(20)   | EXCELLENT/GOOD/FAIR/LOW/NO_MATCH     |
| Message           | NVARCHAR(500)  | Descriptive message                  |
| ProcessedAt       | DATETIME       | Processing timestamp                 |

**Message Difference:**
- **v1:** `"Found 2 BTP options. Returning BEST."`
- **v2:** `"Found 2 BTP options. Returning BEST. See Result Set 2 for all options."`

---

### Result Set 2 (All Options) - v2 ONLY

**Only exists in v2, only populated when `TotalBTPOptions > 1`:**

| Column            | Type           | Description                          |
|-------------------|----------------|--------------------------------------|
| TransactionID     | NVARCHAR(50)   | Reference to Result Set 1            |
| OptionNumber      | INT            | Rank (1 = BEST)                      |
| BTP               | NVARCHAR(100)  | BTP code for this option             |
| MatchPercentage   | DECIMAL(5,2)   | Match quality (%)                    |
| MatchCount        | INT            | Usage count                          |
| TotalTransactions | INT            | Total transactions                   |
| LastLineNumber    | INT            | Most recent usage line number        |
| BestFlag          | NVARCHAR(10)   | "✅ BEST" or empty                   |
| LatestFlag        | NVARCHAR(10)   | "🕒 LATEST" or empty                 |
| Label             | NVARCHAR(50)   | "BEST + LATEST" / "BEST" / "LATEST" / "" |
| Quality           | NVARCHAR(20)   | EXCELLENT/GOOD/FAIR/LOW              |

---

## 🎯 Flag Interpretation (v2)

### BestFlag: ✅ BEST
- Highest `MatchPercentage`
- **Algorithm recommendation**
- Returned in Result Set 1

### LatestFlag: 🕒 LATEST
- Highest `LastLineNumber` (most recent usage)
- May not be BEST if match % is lower
- **Recency indicator**

### Label Combinations:

| Label          | Meaning                                           | Confidence |
|----------------|---------------------------------------------------|------------|
| BEST + LATEST  | Same BTP has highest match % AND most recent      | ⭐⭐⭐     |
| BEST           | Highest match %, but older BTP exists             | ⭐⭐       |
| LATEST         | Most recent, but lower match %                    | ⭐         |
| (empty)        | Alternative option, neither best nor latest       | ⭐         |

---

## 💻 Code Integration Examples

### C# - Consuming v1 (Simple)

```csharp
using (var connection = new SqlConnection(connectionString))
{
    var command = new SqlCommand("SP_TRSF_FindBTP_Batch", connection);
    command.CommandType = CommandType.StoredProcedure;
    command.Parameters.AddWithValue("@InputJSON", json);
    
    connection.Open();
    var reader = command.ExecuteReader();
    
    while (reader.Read())
    {
        var result = new {
            TransactionID = reader["TransactionID"].ToString(),
            BTP = reader["BTP"].ToString(),
            Status = reader["Status"].ToString()
        };
        
        // Process main result only
        Console.WriteLine($"{result.TransactionID}: {result.BTP} ({result.Status})");
    }
}
```

---

### C# - Consuming v2 (With Options)

```csharp
using (var connection = new SqlConnection(connectionString))
{
    var command = new SqlCommand("SP_TRSF_FindBTP_Batch_v2", connection);
    command.CommandType = CommandType.StoredProcedure;
    command.Parameters.AddWithValue("@InputJSON", json);
    
    connection.Open();
    var reader = command.ExecuteReader();
    
    // Result Set 1: Main results
    var mainResults = new List<MainResult>();
    while (reader.Read())
    {
        mainResults.Add(new MainResult {
            TransactionID = reader["TransactionID"].ToString(),
            BTP = reader["BTP"].ToString(),
            TotalBTPOptions = (int)reader["TotalBTPOptions"]
        });
    }
    
    // Result Set 2: All options
    reader.NextResult();
    var allOptions = new List<BTPOption>();
    while (reader.Read())
    {
        allOptions.Add(new BTPOption {
            TransactionID = reader["TransactionID"].ToString(),
            OptionNumber = (int)reader["OptionNumber"],
            BTP = reader["BTP"].ToString(),
            Label = reader["Label"].ToString()
        });
    }
    
    // Display options for manual selection
    foreach (var main in mainResults.Where(r => r.TotalBTPOptions > 1))
    {
        Console.WriteLine($"\nTransaction {main.TransactionID}:");
        foreach (var opt in allOptions.Where(o => o.TransactionID == main.TransactionID))
        {
            Console.WriteLine($"  {opt.OptionNumber}. {opt.BTP} ({opt.Label})");
        }
    }
}
```

---

## 📊 Performance Comparison

| Aspect                | v1                  | v2                  |
|-----------------------|---------------------|---------------------|
| **Execution Time**    | Faster (baseline)   | ~5-10% slower       |
| **Memory Usage**      | Lower               | Higher (2 sets)     |
| **Network Transfer**  | Smaller             | Larger (2 sets)     |
| **Complexity**        | Simple              | More complex        |
| **Overhead**          | Minimal             | Additional temp tables |

**Recommendation:**  
- Use **v1** for high-volume automatic processing
- Use **v2** for manual review and transparency

---

## 🔄 Migration Guide

### From v1 to v2:

**✅ Backwards Compatible:**
- Result Set 1 has same structure (just enhanced message)
- Existing code reading Result Set 1 will work unchanged

**⚠️ Code Changes Needed If:**
- You want to consume Result Set 2 (all options)
- You need to handle multiple result sets in your client code

**Example Migration:**

```csharp
// Old code (v1)
var reader = command.ExecuteReader();
while (reader.Read()) { /* process */ }

// New code (v2) - Backwards compatible
var reader = command.ExecuteReader();
while (reader.Read()) { /* process Result Set 1 */ }

// Optional: Read Result Set 2
reader.NextResult();
while (reader.Read()) { /* process all options */ }
```

---

## 🎯 Decision Matrix

| Your Requirement                          | Use v1 | Use v2 |
|-------------------------------------------|:------:|:------:|
| Automatic batch import                    | ✅     |        |
| Trust algorithm to choose BEST            | ✅     | ✅     |
| Need to see alternative BTPs              |        | ✅     |
| Manual review/override UI                 |        | ✅     |
| Want BEST vs LATEST flags                 |        | ✅     |
| Simple integration                        | ✅     |        |
| Match C code behavior                     |        | ✅     |
| Performance critical                      | ✅     |        |
| Audit/transparency required               |        | ✅     |

---

## 📝 Summary

**v1 = Simple & Fast**  
- 1 result set
- Best match only
- Perfect for automation

**v2 = Detailed & Transparent**  
- 2 result sets
- All options visible
- Perfect for manual review

**Both are valid choices!** Pick based on your use case.

---

## 🚀 Quick Start

### Test Both Versions:

```sql
-- Test data with multiple options
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "TEST", "description": "TRSF 12345 CHRISTIAN"}
]';

-- v1 output
EXEC SP_TRSF_FindBTP_Batch @InputJSON = @JSON;

-- v2 output
EXEC SP_TRSF_FindBTP_Batch_v2 @InputJSON = @JSON;
```

### See the Difference:
```sql
-- Run comparison test
:r Test_SP_TRSF_v2.sql
```

---

**Questions?** Check:
- `README.md` - Full documentation
- `QUICK_START.md` - Integration examples
- `Test_SP_TRSF.sql` - v1 tests
- `Test_SP_TRSF_v2.sql` - v2 tests

