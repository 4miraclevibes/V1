# 🚀 TRSF BTP Matching - Quick Start Guide

## ⚡ Quick Setup (5 Minutes)

### Step 1: Import Master Data
```sql
-- Run: pattern_generator_TRSF/master_customer_btp_pattern_TRSF_SPLIT.sql
-- This creates and populates MASTER_CUSTOMER_BTP_PATTERN table
-- Total: 6,900 patterns
```

### Step 2: Create Stored Procedures
```sql
-- Run in order:
1. SP_TRSF_FindBTP_Single.sql    -- Single search
2. SP_TRSF_FindBTP_Batch.sql     -- Batch search
```

### Step 3: Test
```sql
-- Quick test:
EXEC [dbo].[SP_TRSF_FindBTP_Single] 
    @Description = 'TRSF E-BANKING 12345 HARDI PUTRA MUHARR';
```

---

## 🎯 Common Use Cases

### Use Case 1: Real-time Transaction Processing
```sql
-- User baru input transaction, cari BTP real-time
EXEC [dbo].[SP_TRSF_FindBTP_Single] 
    @Description = 'TRSF FROM BCA 123456789 100000 RONNY YULIADY',
    @Debug = 0;

-- Result:
-- BTP: 2300016055
-- Customer: RONNY YULIADY
-- Match %: 95.5%
-- Status: EXCELLENT
```

### Use Case 2: Batch Import dari File
```sql
-- Import 100 transactions dari file CSV/Excel
-- Convert to JSON format
DECLARE @BatchJSON NVARCHAR(MAX) = N'[
    {"transaction_id": "INV001", "description": "TRSF 12345 RONNY YULIADY"},
    {"transaction_id": "INV002", "description": "TRSF 67890 HARDI PUTRA MUHARR"},
    ... // 98 more
]';

EXEC [dbo].[SP_TRSF_FindBTP_Batch] 
    @InputJSON = @BatchJSON,
    @Debug = 0;

-- Result: Table with BTP untuk semua 100 transactions
```

### Use Case 3: Nightly Batch Job
```sql
-- Process semua unmatched transactions dari hari ini
DECLARE @UnmatchedJSON NVARCHAR(MAX);

-- 1. Get unmatched transactions
SELECT @UnmatchedJSON = (
    SELECT 
        transaction_id, 
        description
    FROM Transactions
    WHERE transaction_date = CAST(GETDATE() AS DATE)
        AND btp IS NULL
    FOR JSON PATH
);

-- 2. Find BTPs
INSERT INTO #TempResults
EXEC [dbo].[SP_TRSF_FindBTP_Batch] @InputJSON = @UnmatchedJSON;

-- 3. Update original table
UPDATE t
SET t.btp = r.BTP,
    t.customer_name = r.CustomerName,
    t.match_confidence = r.MatchPercentage,
    t.updated_at = GETDATE()
FROM Transactions t
INNER JOIN #TempResults r ON t.transaction_id = r.TransactionID
WHERE r.BTP IS NOT NULL;
```

---

## 📊 JSON Format

### Minimal Format
```json
[
    {"description": "TRSF 12345 CUSTOMER NAME"}
]
```

### Full Format (Recommended)
```json
[
    {
        "transaction_id": "TRX001",
        "description": "TRSF E-BANKING CR 12345 100000 CUSTOMER NAME"
    }
]
```

### Large Batch (Python Example)
```python
import json
import pyodbc

# Prepare data
transactions = [
    {"transaction_id": f"TRX{i:05d}", "description": desc}
    for i, desc in enumerate(transaction_list)
]

# Convert to JSON
json_input = json.dumps(transactions)

# Call SP
cursor.execute("""
    EXEC [dbo].[SP_TRSF_FindBTP_Batch] 
        @InputJSON = ?,
        @Debug = 0
""", json_input)

# Get results
results = cursor.fetchall()
```

---

## 🎨 Integration Examples

### Example 1: C# / .NET
```csharp
using System.Data.SqlClient;
using Newtonsoft.Json;

public class BTPMatcher
{
    public async Task<List<BTPResult>> FindBTPsBatch(List<Transaction> transactions)
    {
        var json = JsonConvert.SerializeObject(transactions.Select(t => new {
            transaction_id = t.Id,
            description = t.Description
        }));
        
        using (var conn = new SqlConnection(connectionString))
        using (var cmd = new SqlCommand("[dbo].[SP_TRSF_FindBTP_Batch]", conn))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@InputJSON", json);
            cmd.Parameters.AddWithValue("@Debug", 0);
            
            await conn.OpenAsync();
            var reader = await cmd.ExecuteReaderAsync();
            
            var results = new List<BTPResult>();
            while (await reader.ReadAsync())
            {
                results.Add(new BTPResult {
                    TransactionId = reader["TransactionID"].ToString(),
                    BTP = reader["BTP"].ToString(),
                    CustomerName = reader["CustomerName"].ToString(),
                    MatchPercentage = Convert.ToDecimal(reader["MatchPercentage"]),
                    Status = reader["Status"].ToString()
                });
            }
            
            return results;
        }
    }
}
```

### Example 2: Python
```python
import pyodbc
import json

def find_btps_batch(transactions):
    """
    transactions: List of dicts with 'transaction_id' and 'description'
    """
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    
    # Prepare JSON
    json_input = json.dumps(transactions)
    
    # Execute SP
    cursor.execute("""
        EXEC [dbo].[SP_TRSF_FindBTP_Batch] 
            @InputJSON = ?,
            @Debug = 0
    """, json_input)
    
    # Fetch results
    columns = [column[0] for column in cursor.description]
    results = []
    
    for row in cursor.fetchall():
        results.append(dict(zip(columns, row)))
    
    return results

# Usage
transactions = [
    {"transaction_id": "T1", "description": "TRSF 12345 RONNY YULIADY"},
    {"transaction_id": "T2", "description": "TRSF 67890 HARDI PUTRA"}
]

results = find_btps_batch(transactions)
for r in results:
    print(f"{r['TransactionID']}: {r['BTP']} ({r['Status']})")
```

### Example 3: Node.js
```javascript
const sql = require('mssql');

async function findBTPsBatch(transactions) {
    const pool = await sql.connect(config);
    
    const jsonInput = JSON.stringify(transactions);
    
    const result = await pool.request()
        .input('InputJSON', sql.NVarChar(sql.MAX), jsonInput)
        .input('Debug', sql.Bit, 0)
        .execute('[dbo].[SP_TRSF_FindBTP_Batch]');
    
    return result.recordset;
}

// Usage
const transactions = [
    {transaction_id: 'T1', description: 'TRSF 12345 RONNY YULIADY'},
    {transaction_id: 'T2', description: 'TRSF 67890 HARDI PUTRA'}
];

const results = await findBTPsBatch(transactions);
results.forEach(r => {
    console.log(`${r.TransactionID}: ${r.BTP} (${r.Status})`);
});
```

---

## ⚠️ Important Notes

### Batch Size Recommendations
- **Small batches** (1-100): Best for real-time processing
- **Medium batches** (100-1000): Optimal for scheduled jobs
- **Large batches** (1000+): Split into multiple calls

### JSON Size Limits
- SQL Server JSON limit: ~2GB
- Practical limit: ~10,000 transactions per batch
- Recommended: 500-1000 transactions per batch

### Performance Tips
1. Use batch SP for multiple transactions (faster than loop)
2. Add index on `category` column if not exists
3. Consider pagination for very large datasets
4. Monitor execution time with `SET STATISTICS TIME ON`

---

## 🐛 Troubleshooting

### Problem: "Invalid JSON"
```sql
-- Test your JSON format:
SELECT * FROM OPENJSON(@YourJSON);

-- Should return rows without errors
```

### Problem: Slow Performance
```sql
-- Check master data size
SELECT COUNT(*) FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] 
WHERE category = 'TRSF';

-- Add index if missing
CREATE INDEX IX_Category ON [dbo].[MASTER_CUSTOMER_BTP_PATTERN] (category);
```

### Problem: No Results
```sql
-- Verify master data exists
SELECT TOP 10 * FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] 
WHERE category = 'TRSF';

-- Test with debug mode
EXEC [dbo].[SP_TRSF_FindBTP_Single] 
    @Description = 'Your description',
    @Debug = 1;
```

---

## 📞 Need Help?

1. **Check documentation**: `README.md`
2. **Run tests**: `Test_SP_TRSF.sql`
3. **Enable debug mode**: `@Debug = 1`
4. **Verify master data**: Check `MASTER_CUSTOMER_BTP_PATTERN` table

---

## ✅ Checklist

- [ ] Master data imported (6,900 patterns)
- [ ] SP_TRSF_FindBTP_Single created
- [ ] SP_TRSF_FindBTP_Batch created
- [ ] Test script executed successfully
- [ ] Integration code ready
- [ ] Ready for production! 🚀

