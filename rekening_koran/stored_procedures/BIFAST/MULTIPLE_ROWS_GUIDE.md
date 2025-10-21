# SP_BI-FAST_FindBTP_Batch - Multiple Rows Feature

## 🎯 Your Request

> "kayak nya lebih bagus v1 deh, tapi kalau ditemukan 2 btp, tinggal return atau  
> munculkan data 2x, misalkan WIDYAN AUFAR itu memiliki 2 btp, return 2x  
> WIDYAN AUFAR nya, 1 dengan btp apa, persetase berapa bla bla bla, 1 nya  
> lagi berapa juga, gitu"

**Translation:** Simple approach - return multiple rows for same customer when multiple BTPs found

---

## ✅ Solution: Updated SP_BI-FAST_FindBTP_Batch

**One result set, multiple rows per customer when needed**

---

## 📊 Before vs After

### BEFORE (Original v1)

**Input:** WIDYAN AUFAR (has 2 BTPs)

**Output:** 1 row only
```
TransactionID | CustomerName | BTP        | MatchPct | TotalBTPOptions | Message
TRX001       | WIDYAN AUFAR    | 2300009823 | 98.81    | 2              | Found 2 BTP options. Returning BEST.
```

❌ **Problem:** 
- Only shows BEST BTP
- Says "2 options" but doesn't show the 2nd one
- Can't see alternatives

---

### AFTER (Updated v1)

**Input:** WIDYAN AUFAR (has 2 BTPs)

**Output:** 2 rows (same customer, different BTPs)
```
TransactionID | CustomerName | BTP        | MatchPct | OptionNumber | BestFlag | LatestFlag | Label
TRX001       | WIDYAN AUFAR    | 2300009823 | 98.81    | 1           | YES      |            | BEST
TRX001       | WIDYAN AUFAR    | 2300009824 | 95.24    | 2           |          | YES        | LATEST
```

✅ **Solution:**
- Shows ALL BTPs for same customer
- Each BTP gets its own row
- Clear flags (BEST, LATEST)
- Easy to filter or display

---

## 🆕 New Columns

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `LastLineNumber` | INT | Most recent usage line number | 115432 |
| `OptionNumber` | INT | Rank of this BTP (1 = best) | 1, 2, 3... |
| `BestFlag` | VARCHAR | 'YES' if highest match % | 'YES' or '' |
| `LatestFlag` | VARCHAR | 'YES' if most recent | 'YES' or '' |
| `Label` | VARCHAR | Combined indicator | 'BEST + LATEST', 'BEST', 'LATEST' |

---

## 💡 How It Works

### Example: 3 Transactions

**Input JSON:**
```json
[
    {"transaction_id": "T1", "description": "BI-FAST 001 RONNY YULIADY"},
    {"transaction_id": "T2", "description": "BI-FAST 002 WIDYAN AUFAR"},
    {"transaction_id": "T3", "description": "BI-FAST 003 HARDI PUTRA MUHARR"}
]
```

**Assumptions:**
- RONNY YULIADY has 1 BTP
- WIDYAN AUFAR has 2 BTPs
- HARDI PUTRA MUHARR has 1 BTP

**Output: 4 rows total (not 3!)**

```
┌──────┬──────────────────┬────────────┬───────┬────────┬─────────┬───────────┬─────────────────┐
│ TxID │ CustomerName     │ BTP        │ Match%│ Option │ BestFlg │ LatestFlg │ Label           │
├──────┼──────────────────┼────────────┼───────┼────────┼─────────┼───────────┼─────────────────┤
│ T1   │ RONNY YULIADY    │ 2300014094 │ 100.00│ 1      │ YES     │ YES       │ BEST + LATEST   │
├──────┼──────────────────┼────────────┼───────┼────────┼─────────┼───────────┼─────────────────┤
│ T2   │ WIDYAN AUFAR        │ 2300009823 │ 98.81 │ 1      │ YES     │           │ BEST            │ ⬅️ Row 1 for T2
│ T2   │ WIDYAN AUFAR        │ 2300009824 │ 95.24 │ 2      │         │ YES       │ LATEST          │ ⬅️ Row 2 for T2
├──────┼──────────────────┼────────────┼───────┼────────┼─────────┼───────────┼─────────────────┤
│ T3   │ HARDI PUTRA MUHA │ 2300016055 │ 100.00│ 1      │ YES     │ YES       │ BEST + LATEST   │
└──────┴──────────────────┴────────────┴───────┴────────┴─────────┴───────────┴─────────────────┘
```

**Key Points:**
- T1: 1 row (1 BTP)
- T2: 2 rows (2 BTPs) ⭐ Same TransactionID, different BTPs!
- T3: 1 row (1 BTP)
- **Total: 4 rows**

---

## 🎯 Usage Scenarios

### Scenario 1: Display ALL Options (Manual Review)

```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "1", "description": "BI-FAST 12345 WIDYAN AUFAR"}
]';

-- Get all rows
SELECT 
    TransactionID,
    CustomerName,
    BTP,
    MatchPercentage,
    OptionNumber,
    BestFlag,
    LatestFlag,
    Label
FROM [dbo].[SP_BI-FAST_FindBTP_Batch](@JSON, 0)
ORDER BY TransactionID, OptionNumber;

-- Result: Shows ALL BTP options
-- User can pick from the list
```

---

### Scenario 2: Get BEST Only (Automation)

```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "1", "description": "BI-FAST 12345 WIDYAN AUFAR"}
]';

-- Filter for BEST only
SELECT 
    TransactionID,
    BTP,
    MatchPercentage,
    Label
FROM [dbo].[SP_BI-FAST_FindBTP_Batch](@JSON, 0)
WHERE BestFlag = 'YES';

-- Result: Only 1 row per transaction (BEST BTP)
```

---

### Scenario 3: Identify Transactions with Multiple BTPs

```sql
DECLARE @JSON NVARCHAR(MAX) = N'[...]';

-- Get transactions with multiple options
SELECT DISTINCT
    TransactionID,
    CustomerName,
    TotalBTPOptions
FROM [dbo].[SP_BI-FAST_FindBTP_Batch](@JSON, 0)
WHERE TotalBTPOptions > 1;

-- Result: List of transactions needing manual review
```

---

### Scenario 4: PowerApps Gallery Display

```sql
-- Show in gallery with ALL options
SELECT 
    TransactionID,
    CustomerName,
    BTP,
    MatchPercentage,
    CASE 
        WHEN BestFlag = 'YES' THEN '⭐ ' + BTP + ' (Recommended)'
        WHEN LatestFlag = 'YES' THEN '🕒 ' + BTP + ' (Latest)'
        ELSE BTP
    END AS DisplayText,
    OptionNumber
FROM [dbo].[SP_BI-FAST_FindBTP_Batch](@JSON, 0)
ORDER BY TransactionID, OptionNumber;

-- Gallery will show:
-- WIDYAN AUFAR
--   ⭐ 2300009823 (Recommended)
--   🕒 2300009824 (Latest)
```

---

## 📊 Label Meanings

| Label | Meaning | Action |
|-------|---------|--------|
| `BEST + LATEST` | Same BTP has highest match % AND most recent | ✅ Use it! Very confident |
| `BEST` | Highest match %, but not most recent | ⭐ Recommended (accuracy) |
| `LATEST` | Most recent, but lower match % | 🕒 Consider (recency) |
| (empty) | Alternative option | Lower priority |

---

## 🔄 Comparison with v2 Approach

### v2 Approach (2 Result Sets)
```sql
EXEC SP_BI-FAST_FindBTP_Batch_v2 @InputJSON = @JSON;

-- Result Set 1: Main results (1 row per transaction)
-- Result Set 2: All options (multiple rows for those with multiple BTPs)
```

**Pros:**
- Main results stay clean (1 row per transaction)
- Options separated

**Cons:**
- 2 result sets to handle
- More complex client code
- Need to join/match result sets

---

### v1 Updated Approach (Multiple Rows in 1 Result Set)
```sql
EXEC SP_BI-FAST_FindBTP_Batch @InputJSON = @JSON;

-- Single result set
-- Multiple rows for transactions with multiple BTPs
```

**Pros:**
- ✅ Simple: Single result set
- ✅ Flexible: Filter as needed
- ✅ Clear: More rows = more options
- ✅ Easy client code

**Cons:**
- Row count ≠ transaction count (need to count DISTINCT)

---

## 💻 Client Code Examples

### C# - Display ALL Options

```csharp
var command = new SqlCommand("SP_BI-FAST_FindBTP_Batch", connection);
command.CommandType = CommandType.StoredProcedure;
command.Parameters.AddWithValue("@InputJSON", json);

var reader = command.ExecuteReader();

var grouped = new Dictionary<string, List<BTPOption>>();

while (reader.Read())
{
    var txId = reader["TransactionID"].ToString();
    var option = new BTPOption
    {
        BTP = reader["BTP"].ToString(),
        MatchPercentage = (decimal)reader["MatchPercentage"],
        OptionNumber = (int)reader["OptionNumber"],
        Label = reader["Label"].ToString()
    };
    
    if (!grouped.ContainsKey(txId))
        grouped[txId] = new List<BTPOption>();
    
    grouped[txId].Add(option);
}

// Display grouped by transaction
foreach (var tx in grouped)
{
    Console.WriteLine($"\nTransaction: {tx.Key}");
    foreach (var opt in tx.Value)
    {
        Console.WriteLine($"  [{opt.OptionNumber}] {opt.BTP} " +
                         $"({opt.MatchPercentage}%) {opt.Label}");
    }
}
```

---

### C# - Get BEST Only (Simple)

```csharp
var command = new SqlCommand("SP_BI-FAST_FindBTP_Batch", connection);
command.CommandType = CommandType.StoredProcedure;
command.Parameters.AddWithValue("@InputJSON", json);

var reader = command.ExecuteReader();

while (reader.Read())
{
    // Only process BEST
    if (reader["BestFlag"].ToString() == "YES")
    {
        var result = new {
            TransactionID = reader["TransactionID"].ToString(),
            BTP = reader["BTP"].ToString(),
            Confidence = (decimal)reader["MatchPercentage"]
        };
        
        ProcessTransaction(result);
    }
}
```

---

### Python - Pandas DataFrame

```python
import pandas as pd
import pyodbc

conn = pyodbc.connect(connection_string)

# Get all results
df = pd.read_sql(
    "EXEC SP_BI-FAST_FindBTP_Batch @InputJSON = ?", 
    conn, 
    params=[json_input]
)

# View all options
print(df[['TransactionID', 'CustomerName', 'BTP', 
          'MatchPercentage', 'OptionNumber', 'Label']])

# Filter: BEST only
best_df = df[df['BestFlag'] == 'YES']

# Count transactions with multiple BTPs
multi_btp = df[df['TotalBTPOptions'] > 1]['TransactionID'].nunique()
print(f"Transactions with multiple BTPs: {multi_btp}")
```

---

## 🎨 PowerApps Implementation

### Gallery ItemsSource

```javascript
// Call SP and store in collection
ClearCollect(
    colBTPResults,
    SP_BI-FAST_FindBTP_Batch.Run({InputJSON: JSON(colTransactions)})
);

// Group by TransactionID
GroupBy(
    colBTPResults,
    "TransactionID",
    "Options"
)
```

### Display in Gallery

```javascript
// Header: Transaction ID
ThisItem.TransactionID

// Child gallery: Show all BTP options
Options

// For each option:
If(
    BestFlag = "YES",
    "⭐ " & BTP & " (Recommended)",
    If(
        LatestFlag = "YES",
        "🕒 " & BTP & " (Latest)",
        BTP
    )
)
```

---

## 📈 Performance Notes

### Row Count Impact

- **Input:** 100 transactions
- **Scenario A:** All have 1 BTP → **Output:** 100 rows
- **Scenario B:** 20 have 2 BTPs → **Output:** 120 rows (100 + 20 extra)
- **Scenario C:** 10 have 3 BTPs → **Output:** 120 rows (100 + 20 extra)

**Performance:** Minimal impact, extra rows only when multiple BTPs exist

---

## ✅ Summary

### What Changed

**Before:**
- 1 transaction → 1 row (even if multiple BTPs)
- TotalBTPOptions shows count but not details

**After:**
- 1 transaction → N rows (N = number of BTPs)
- Each row shows full BTP details
- Flags indicate BEST/LATEST

### Benefits

✅ **Simple:** Single result set (no v2 complexity)  
✅ **Flexible:** Filter/group as needed  
✅ **Clear:** Multiple rows = multiple BTPs  
✅ **Complete:** All BTP options visible  
✅ **Filterable:** Easy to get BEST only  

### Use Cases

1. **Manual Review:** Show all rows
2. **Automation:** Filter `BestFlag = 'YES'`
3. **PowerApps:** Group by TransactionID
4. **Reports:** Count DISTINCT TransactionID

---

## 🚀 Quick Test

```sql
USE [POWERAPPS];

DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "TEST", 
     "description": "BI-FAST E-BANKING CR 1304 683280.00 fresh milk WIDYAN AUFAR"}
]';

EXEC SP_BI-FAST_FindBTP_Batch @InputJSON = @JSON, @Debug = 1;

-- Expected: 2 rows if WIDYAN AUFAR has 2 BTPs
-- Row 1: Option 1, BestFlag='YES'
-- Row 2: Option 2, LatestFlag='YES'
```

---

**Perfect match to your request!** 🎉

Multiple rows for same customer = Simple and clear! ✅

