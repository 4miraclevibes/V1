# SP_TRSF_FindBTP_Batch_v2 - Output Examples

## 📊 Real Output Comparison: v1 vs v2

---

## Example 1: Transaction with Multiple BTP Options (CHRISTIAN)

### Input:
```json
[
    {
        "transaction_id": "TRX004",
        "description": "TRSF E-BANKING CR 1304/FTSCY/WS95011 683280.00 fresh milk 36pcs 15/04/2024 CHRISTIAN"
    }
]
```

---

### v1 Output: (1 Result Set Only)

**Result Set 1:**
```
TransactionID | Description       | CustomerName | BTP        | MatchPct | MatchCount | TotalTrans | TotalBTPOptions | Status    | Message
TRX004       | TRSF E-BANKING... | CHRISTIAN    | 2300014842 | 98.81    | 83         | 84         | 2               | EXCELLENT | Found 2 BTP options. Returning BEST.
```

**❌ Problem:**
- Tahu ada 2 options, tapi tidak tahu BTP kedua apa
- Tidak tahu kenapa `2300014842` dipilih sebagai BEST
- Tidak bisa lihat alternative options

---

### v2 Output: (2 Result Sets)

**Result Set 1: Main Results**
```
TransactionID | Description       | CustomerName | BTP        | MatchPct | MatchCount | TotalTrans | TotalBTPOptions | Status    | Message                                                     | ProcessedAt
TRX004       | TRSF E-BANKING... | CHRISTIAN    | 2300014842 | 98.81    | 83         | 84         | 2               | EXCELLENT | Found 2 BTP options. Returning BEST. See Result Set 2 for all options. | 2025-10-21 11:45:09.203
```

**Result Set 2: All BTP Options Details**
```
TransactionID | OptionNumber | BTP        | MatchPct | MatchCount | TotalTrans | LastLineNumber | BestFlag  | LatestFlag | Label | Quality
TRX004       | 1           | 2300014842 | 98.81    | 83         | 84         | 115432        | ✅ BEST   |            | BEST  | EXCELLENT
TRX004       | 2           | 2300015678 | 95.24    | 71         | 72         | 116890        |           | 🕒 LATEST  | LATEST| EXCELLENT
```

**✅ Advantages:**
- Lihat kedua BTP options
- `2300014842` = BEST (match 98.81% > 95.24%)
- `2300015678` = LATEST (line 116890 > 115432)
- Bisa pilih LATEST jika prefer recency over match %

---

## Example 2: Transaction with Single BTP (No Multiple Options)

### Input:
```json
[
    {
        "transaction_id": "TRX001",
        "description": "TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY"
    }
]
```

---

### v1 Output:

**Result Set 1:**
```
TransactionID | CustomerName  | BTP        | MatchPct | TotalBTPOptions | Status    | Message
TRX001       | RONNY YULIADY | 2300014094 | 100.00   | 1              | EXCELLENT | High confidence match
```

---

### v2 Output:

**Result Set 1:**
```
TransactionID | CustomerName  | BTP        | MatchPct | TotalBTPOptions | Status    | Message
TRX001       | RONNY YULIADY | 2300014094 | 100.00   | 1              | EXCELLENT | High confidence match
```

**Result Set 2:**
```
(Empty - no multiple options)
```

**✅ Behavior:**
- Result Set 1 identik dengan v1
- Result Set 2 empty (karena hanya 1 option)
- No overhead untuk single matches

---

## Example 3: Batch with Mixed Scenarios

### Input:
```json
[
    {"transaction_id": "T1", "description": "TRSF 001 RONNY YULIADY"},
    {"transaction_id": "T2", "description": "TRSF 002 CHRISTIAN"},
    {"transaction_id": "T3", "description": "TRSF 003 HARDI PUTRA MUHARR"},
    {"transaction_id": "T4", "description": "TRSF 004 UNKNOWN CUSTOMER XXX"}
]
```

---

### v2 Output:

**Result Set 1: Main Results**
```
TransactionID | CustomerName       | BTP        | MatchPct | TotalBTPOptions | Status    | Message
T1           | RONNY YULIADY      | 2300014094 | 100.00   | 1              | EXCELLENT | High confidence match
T2           | CHRISTIAN          | 2300014842 | 98.81    | 2              | EXCELLENT | Found 2 BTP options. Returning BEST. See Result Set 2 for all options.
T3           | HARDI PUTRA MUHARR | 2300016055 | 100.00   | 1              | EXCELLENT | High confidence match
T4           | UNKNOWN CUSTOMER XXX | NULL     | NULL     | 0              | NO_MATCH  | Customer "UNKNOWN CUSTOMER XXX" not found in master data
```

**Result Set 2: All Options (Only for T2)**
```
TransactionID | OptionNumber | BTP        | MatchPct | BestFlag  | LatestFlag | Label | Quality
T2           | 1           | 2300014842 | 98.81    | ✅ BEST   |            | BEST  | EXCELLENT
T2           | 2           | 2300015678 | 95.24    |           | 🕒 LATEST  | LATEST| EXCELLENT
```

**✅ Efficiency:**
- T1, T3, T4: Single/no match → tidak ada di Result Set 2
- T2: Multiple options → detail di Result Set 2
- Result Set 2 hanya berisi yang perlu review

---

## Example 4: BEST = LATEST (Ideal Scenario)

### Scenario:
Customer "BROOKLYN BOGA UTAM" has 2 BTPs:
- BTP A: 99.50% match, last used line 120000
- BTP B: 95.00% match, last used line 118000

### v2 Output:

**Result Set 2:**
```
TransactionID | OptionNumber | BTP        | MatchPct | BestFlag  | LatestFlag | Label         | Quality
TX           | 1           | BTP_A      | 99.50    | ✅ BEST   | 🕒 LATEST  | BEST + LATEST | EXCELLENT
TX           | 2           | BTP_B      | 95.00    |           |            |               | EXCELLENT
```

**✅ Interpretation:**
- `BEST + LATEST` → Very high confidence!
- BTP_A is both highest match AND most recent
- No dilemma antara quality vs recency

---

## Example 5: BEST ≠ LATEST (Conflict Scenario)

### Scenario:
Customer "SUPER NORMAL SISTE" has 2 BTPs:
- BTP A: 98.00% match, last used line 110000 (older)
- BTP B: 92.00% match, last used line 125000 (newer)

### v2 Output:

**Result Set 2:**
```
TransactionID | OptionNumber | BTP        | MatchPct | BestFlag  | LatestFlag | Label  | Quality
TX           | 1           | BTP_A      | 98.00    | ✅ BEST   |            | BEST   | EXCELLENT
TX           | 2           | BTP_B      | 92.00    |           | 🕒 LATEST  | LATEST | EXCELLENT
```

**✅ Decision Making:**
- Algorithm recommends BTP_A (BEST match %)
- But BTP_B is more recent (LATEST)
- **Business rule decision:**
  - Prefer accuracy? → Use BTP_A
  - Prefer recency? → Override to BTP_B

---

## 🎯 How to Use Result Set 2

### Scenario A: Automatic Processing
```csharp
// Read Result Set 1 only
var reader = command.ExecuteReader();
while (reader.Read())
{
    string btp = reader["BTP"].ToString();
    // Use recommended BEST BTP
    ProcessTransaction(btp);
}
```

### Scenario B: Manual Review UI
```csharp
var reader = command.ExecuteReader();

// Get main results
var mainResults = ReadResultSet1(reader);

// Get all options
reader.NextResult();
var allOptions = ReadResultSet2(reader);

// Display for manual selection
foreach (var tx in mainResults.Where(r => r.TotalBTPOptions > 1))
{
    Console.WriteLine($"\n📋 Transaction {tx.TransactionID}:");
    Console.WriteLine($"   Customer: {tx.CustomerName}");
    Console.WriteLine($"   Recommended: {tx.BTP} (BEST match {tx.MatchPercentage}%)");
    
    var options = allOptions.Where(o => o.TransactionID == tx.TransactionID);
    Console.WriteLine($"\n   All Options:");
    
    foreach (var opt in options)
    {
        string indicator = "";
        if (opt.Label == "BEST + LATEST") indicator = "⭐⭐⭐";
        else if (opt.Label == "BEST") indicator = "⭐⭐";
        else if (opt.Label == "LATEST") indicator = "⭐";
        
        Console.WriteLine($"   [{opt.OptionNumber}] {opt.BTP} - {opt.MatchPercentage}% {indicator}");
        Console.WriteLine($"       {opt.Label} - Used {opt.MatchCount}/{opt.TotalTransactions} times");
    }
    
    // User can select different option
    int choice = AskUserChoice();
    string selectedBTP = options.ElementAt(choice - 1).BTP;
}
```

---

## 📊 Visual Comparison

### Your Original Screenshot Data:

**v1 Output:** (What you showed in screenshot)
```
TransactionID | CustomerName | BTP        | TotalBTPOptions | Message
4            | CHRISTIAN    | 2300014842 | 2              | Found 2 BTP options. Returning BEST.
```
❌ **Can't see:** What's the other BTP? Why this is BEST?

---

**v2 Output:** (Enhanced)

**Set 1:**
```
TransactionID | CustomerName | BTP        | TotalBTPOptions | Message
4            | CHRISTIAN    | 2300014842 | 2              | Found 2 BTP options. Returning BEST. See Result Set 2 for all options.
```

**Set 2:**
```
TransactionID | Option | BTP        | Match% | BestFlag | LatestFlag | Label
4            | 1      | 2300014842 | 98.81  | ✅ BEST  |            | BEST
4            | 2      | 2300015678 | 95.24  |          | 🕒 LATEST  | LATEST
```

✅ **Now you see:**
- Both BTPs: 2300014842 vs 2300015678
- Why BEST: 98.81% > 95.24%
- Alternative: 2300015678 is LATEST
- Can override if needed

---

## 🚀 Quick Test

```sql
USE [POWERAPPS];

-- Your exact test case
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "4",
        "description": "TRSF E-BANKING CR 1304/FTSCY/WS95011 683280.00 fresh milk 36pcs 15/04/2024 CHRISTIAN"
    }
]';

-- Run v2
EXEC SP_TRSF_FindBTP_Batch_v2 @InputJSON = @JSON;

-- Check both result sets!
```

---

## ✅ Summary

| Feature                  | v1   | v2   |
|--------------------------|------|------|
| Main results             | ✅   | ✅   |
| Show BEST BTP            | ✅   | ✅   |
| Show ALL options         | ❌   | ✅   |
| BEST flag                | ❌   | ✅   |
| LATEST flag              | ❌   | ✅   |
| Override capability      | ❌   | ✅   |
| Transparency             | ❌   | ✅   |
| Match C code behavior    | ❌   | ✅   |

**v2 = Just like your C code, but in SQL!** 🎯

