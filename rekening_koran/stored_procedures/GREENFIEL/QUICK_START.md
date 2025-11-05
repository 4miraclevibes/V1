# 🚀 GREENFIEL BTP Matching - Quick Start Guide

## ⚡ Quick Setup (5 Minutes)

### Step 1: Ensure Master Data Exists
```sql
-- Ensure table exists with GREENFIEL data
-- Table: [dbo].[MASTER_CUSTOMER_BTP_PATTERN]
-- Records should have: category = 'GREENFIEL' or category = 'NEW'
```

### Step 2: Create Stored Procedure
```sql
-- Run:
SP_GREENFIEL_FindBTP_Batch.sql
```

**Key Feature:** Extracts BTP from description, finds customer_name in master, then returns all BTP options for that customer.

### Step 3: Test
```sql
-- Quick test:
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TEST001",
        "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"
    }
]';

EXEC [dbo].[SP_GREENFIEL_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 0;
```

---

## 🎯 Common Use Cases

### Use Case 1: Batch Import dari File
```sql
-- Import transactions dari file CSV/Excel
-- Convert to JSON format
DECLARE @BatchJSON NVARCHAR(MAX) = N'[
    {"transaction_id": "INV001", "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"},
    {"transaction_id": "INV002", "description": "KR OTOMATIS 0110/FTFVA/WS95011 01660/PT GREENFIEL K00200162181 PlayCorner 2300015906,"},
    ... // more transactions
]';

EXEC [dbo].[SP_GREENFIEL_FindBTP_Batch] 
    @InputJSON = @BatchJSON,
    @Debug = 0;

-- Result: Table with BTP untuk semua transactions
```

### Use Case 2: View ALL BTP Options (Multiple Rows)
```sql
-- If customer has multiple BTPs, returns multiple rows
DECLARE @BatchJSON NVARCHAR(MAX) = N'[
    {"transaction_id": "INV001", "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"}
]';

EXEC [dbo].[SP_GREENFIEL_FindBTP_Batch] 
    @InputJSON = @BatchJSON,
    @Debug = 0;

-- Result: Multiple rows if customer has multiple BTPs
-- TransactionID | CustomerName | BTP        | Option | BestFlag | Label
-- INV001        | CUSTOMER A   | 2300017744 | 1      | YES      | BEST
-- INV001        | CUSTOMER A   | 2300015555 | 2      |          | LATEST
```

### Use Case 3: Get BEST Only (Automation)
```sql
-- Filter untuk automation (ambil BEST option saja)
-- Step 1: Get results
SELECT * 
INTO #Results
FROM (
    EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON = @JSON
) AS Results;

-- Step 2: Filter BEST only
SELECT TransactionID, CustomerName, BTP, MatchPercentage, Status
FROM #Results
WHERE BestFlag = 'YES' OR TotalBTPOptions = 1;

-- Step 3: Cleanup
DROP TABLE #Results;
```

---

## 🔍 How It Works

### Pattern Detection
```
Input: "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"

Split by space:
[0] = "KR"
[1] = "OTOMATIS"
[2] = "3009/FTFVA/WS95051"
[3] = "01660/PT"
[4] = "GREENFIEL"  ← CHECK: Must be exactly 'GREENFIEL'
[5] = "STJ"
...
[12] = "2300017744,"  ← EXTRACT: Last word starting with "23..." (10+ digits)
```

### Processing Flow
1. ✅ Check Array[4] = 'GREENFIEL' (exact match)
2. ✅ Extract BTP = "2300017744"
3. ✅ Search master: `WHERE btp = '2300017744'`
4. ✅ Found customer_name = "CUSTOMER NAME"
5. ✅ Search all BTPs: `WHERE customer_name = 'CUSTOMER NAME' AND (category = 'GREENFIEL' OR category = 'NEW')`
6. ✅ Return all matching BTPs with rankings

---

## 💻 Integration Examples

### C# (.NET)
```csharp
using System;
using System.Data.SqlClient;
using Newtonsoft.Json;

public class GreenfieldService
{
    private string connectionString;
    
    public void ProcessBatch(List<Transaction> transactions)
    {
        // Convert to JSON
        var json = JsonConvert.SerializeObject(transactions.Select(t => new {
            transaction_id = t.Id,
            transaction_date = t.Date.ToString("yyyy-MM-dd"),
            description = t.Description
        }));
        
        using (var conn = new SqlConnection(connectionString))
        {
            conn.Open();
            var cmd = new SqlCommand("SP_GREENFIEL_FindBTP_Batch", conn)
            {
                CommandType = System.Data.CommandType.StoredProcedure
            };
            cmd.Parameters.AddWithValue("@InputJSON", json);
            cmd.Parameters.AddWithValue("@Debug", 0);
            
            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    var txId = reader["TransactionID"].ToString();
                    var customer = reader["CustomerName"].ToString();
                    var btp = reader["BTP"].ToString();
                    var isBest = reader["BestFlag"].ToString() == "YES";
                    
                    // Process best option only
                    if (isBest || reader["TotalBTPOptions"].ToString() == "1")
                    {
                        // Use this BTP
                        Console.WriteLine($"Transaction {txId}: Customer={customer}, BTP={btp}");
                    }
                }
            }
        }
    }
}
```

### Python
```python
import pyodbc
import json

def process_batch(transactions):
    # Convert to JSON
    json_data = json.dumps([
        {
            "transaction_id": t["id"],
            "transaction_date": t["date"],
            "description": t["description"]
        }
        for t in transactions
    ])
    
    # Connect to SQL Server
    conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};'
                          'SERVER=your_server;'
                          'DATABASE=your_db;'
                          'UID=user;PWD=password')
    
    cursor = conn.cursor()
    
    # Execute SP
    cursor.execute("EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON=?, @Debug=0", json_data)
    
    # Get results
    results = []
    for row in cursor.fetchall():
        if row.BestFlag == 'YES' or row.TotalBTPOptions == 1:
            results.append({
                'TransactionID': row.TransactionID,
                'CustomerName': row.CustomerName,
                'BTP': row.BTP,
                'MatchPercentage': row.MatchPercentage,
                'Status': row.Status
            })
    
    return results
```

### Node.js
```javascript
const sql = require('mssql');

async function processBatch(transactions) {
    // Convert to JSON
    const jsonData = JSON.stringify(
        transactions.map(t => ({
            transaction_id: t.id,
            transaction_date: t.date,
            description: t.description
        }))
    );
    
    // Connect to SQL Server
    await sql.connect('mssql://user:password@server/database');
    
    // Execute SP
    const result = await sql.query`
        EXEC SP_GREENFIEL_FindBTP_Batch 
            @InputJSON = ${jsonData},
            @Debug = 0
    `;
    
    // Filter BEST only
    const bestResults = result.recordset.filter(r => 
        r.BestFlag === 'YES' || r.TotalBTPOptions === 1
    );
    
    return bestResults;
}
```

### PowerApps
```powerappsfx
// Button OnSelect
Set(
    jsonData,
    JSON(
        ForAll(
            Gallery1.AllItems,
            {
                transaction_id: Text(Value(ThisItem.ID)),
                transaction_date: Text(ThisItem.Date, "yyyy-mm-dd"),
                description: ThisItem.Description
            }
        )
    )
);

Set(
    results,
    SP_GREENFIEL_FindBTP_Batch.Run(jsonData)
);

// Filter BEST only
ClearCollect(
    BestResults,
    Filter(
        results,
        BestFlag = "YES" || TotalBTPOptions = 1
    )
);
```

---

## 📊 Output Format

### Single BTP (1 row)
```
TransactionID | CustomerName | BTP        | Option | BestFlag | Status
--------------|--------------|------------|--------|----------|----------
TRX001        | CUSTOMER A   | 2300017744 | 1      | YES      | EXCELLENT
```

### Multiple BTPs (2+ rows)
```
TransactionID | CustomerName | BTP        | Option | BestFlag | LatestFlag | Label
--------------|--------------|------------|--------|----------|------------|----------
TRX001        | CUSTOMER A   | 2300017744 | 1      | YES      |            | BEST
TRX001        | CUSTOMER A   | 2300015555 | 2      |          | YES        | LATEST
```

### No Match (1 row)
```
TransactionID | CustomerName | BTP        | Option | Status    | Message
--------------|--------------|------------|--------|-----------|--------------------------
TRX002        | NULL         | NULL       | 0      | NO_MATCH  | BTP "2300019999" not found in master data
```

---

## 🎯 Status Codes

| Status | Match % | Meaning | Action |
|--------|---------|---------|--------|
| `EXCELLENT` | ≥95% | Very high confidence | ✅ Use automatically |
| `GOOD` | 80-94% | High confidence | ✅ Use automatically |
| `FAIR` | 70-79% | Medium confidence | ⚠️ Review manually |
| `LOW` | <70% | Low confidence | ❌ Verify manually |
| `NO_PATTERN` | - | Array[4] ≠ 'GREENFIEL' | ❌ Skip (not GREENFIEL transaction) |
| `NO_BTP` | - | BTP not found in description | ❌ Skip (invalid format) |
| `NO_MATCH` | - | BTP not in master | ❌ Skip (no match) |

---

## 🔧 Debug Mode

### Enable Debug:
```sql
EXEC SP_GREENFIEL_FindBTP_Batch 
    @InputJSON = @JSON,
    @Debug = 1;
```

### Debug Output:
```
=== Input Data ===
RowID | TransactionID | Description
------|---------------|------------
1     | TRX001        | KR OTOMATIS ... 2300017744,

=== Summary Statistics ===
TotalTransactions | TotalRows | FoundBTP | NotFound | MultipleOptions | AvgMatchPercentage
------------------|-----------|----------|----------|-----------------|--------------------
10                | 12        | 10       | 0        | 2               | 98.5

=== Status Breakdown ===
Status    | Count
----------|------
EXCELLENT | 8
GOOD      | 2
NO_MATCH  | 0

=== Transactions with Multiple BTPs ===
TransactionID | CustomerName | TotalBTPOptions
--------------|--------------|-----------------
TRX001        | CUSTOMER A   | 2
```

---

## ✅ Checklist

- [ ] Master table `MASTER_CUSTOMER_BTP_PATTERN` exists
- [ ] Master data has records with `category = 'GREENFIEL'` or `'NEW'`
- [ ] SP `SP_GREENFIEL_FindBTP_Batch` created
- [ ] Test with sample data from `data_sample.txt`
- [ ] Debug mode works (`@Debug = 1`)
- [ ] Integration code ready (C#/Python/Node.js/PowerApps)

---

## 📝 Notes

1. **Pattern is strict**: Array[4] must be exactly 'GREENFIEL' (case-sensitive)
2. **BTP extraction**: Takes the LAST word that starts with "23..." and has at least 10 digits
3. **Two-step lookup**: 
   - Step 1: Find customer_name by BTP
   - Step 2: Find all BTPs by customer_name
4. **Multiple BTPs**: Returns multiple rows when customer has multiple BTPs
5. **Category priority**: Prefers `category = 'GREENFIEL'` over `category = 'NEW'`

---

## 🚀 Next Steps

1. ✅ Read [README.md](README.md) for complete API reference
2. ✅ Test with your data
3. ✅ Integrate into your application
4. ✅ Monitor results and adjust master data as needed

---

**Need help?** See [README.md](README.md) for troubleshooting and detailed documentation.
