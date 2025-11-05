# GREENFIEL BTP Pattern Matching - Stored Procedures

## 📋 Overview

Stored procedures untuk mencari BTP (Bill To Party) dari deskripsi transaksi GREENFIEL berdasarkan BTP extraction dan customer name matching.

### Logic:
1. **Pattern Detection**: Check jika Array[4] = 'GREENFIEL' (exact match)
2. **Extract BTP**: Ambil array terakhir yang dimulai dengan "23..." (minimal 10 digit)
3. **Find Customer Name**: Cari di master data dengan BTP yang diextract
4. **Pattern Matching**: Gunakan customer_name dari master untuk mencari semua BTP options
5. **Best Match Selection**: Return BTP dengan highest match percentage

---

## 📁 Files

| File | Purpose |
|------|---------|
| `SP_GREENFIEL_FindBTP_Batch.sql` | Batch search - Multiple descriptions (JSON) → Multiple BTPs |
| `data_sample.txt` | Sample data untuk testing |
| `README.md` | Documentation (this file) |

---

## 🚀 Installation

### Prerequisites:
1. Table `[dbo].[MASTER_CUSTOMER_BTP_PATTERN]` must exist
2. Table must have records with `category` = 'GREENFIEL' or 'NEW'
3. SQL Server 2016+ (for JSON support)

### Install:
```sql
-- 1. Ensure master table exists
-- Table: [dbo].[MASTER_CUSTOMER_BTP_PATTERN]

-- 2. Create SP Batch
-- Run: SP_GREENFIEL_FindBTP_Batch.sql

-- 3. Test
-- Use sample data from data_sample.txt
```

---

## 📖 Usage

### SP_GREENFIEL_FindBTP_Batch

**Purpose**: Find BTP untuk multiple descriptions (batch processing)

**Parameters**:
- `@InputJSON` (NVARCHAR(MAX)): JSON array of descriptions
- `@Debug` (BIT): 0 = normal, 1 = show debug + statistics

**JSON Format**:
```json
[
    {
        "transaction_id": "TRX001",
        "transaction_date": "2025-01-15",
        "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"
    },
    {
        "transaction_id": "TRX002",
        "description": "KR OTOMATIS 0110/FTFVA/WS95011 01660/PT GREENFIEL K00200162181 PlayCorner 2300015906,"
    }
]
```

**Returns**:
- Result set dengan BTP untuk setiap transaction
- Multiple rows jika customer memiliki multiple BTPs

**Example**:
```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TRX001",
        "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"
    },
    {
        "transaction_id": "TRX002",
        "description": "KR OTOMATIS 0110/FTFVA/WS95011 01660/PT GREENFIEL K00200162181 PlayCorner 2300015906,"
    }
]';

EXEC [dbo].[SP_GREENFIEL_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 1;
```

**Output**:
```
TransactionID | Description              | CustomerName | BTP        | MatchPct | Status    | Message
--------------|--------------------------|--------------|------------|----------|-----------|------------------
TRX001        | KR OTOMATIS ... 2300017  | CUSTOMER A   | 2300017744 | 100.00   | EXCELLENT | High confidence match
TRX002        | KR OTOMATIS ... 2300015  | CUSTOMER B   | 2300015906 | 100.00   | EXCELLENT | High confidence match
```

---

## 🎯 Pattern Detection

### Format:
```
KR OTOMATIS [CODE] [CODE] [CODE] GREENFIEL [TEXT...] 23XXXXXXXXXX
          [0]      [1]    [2]      [3]       [4]      [5+]      [LAST]
```

### Rules:
1. **Array[4] must be 'GREENFIEL'** (exact match, case-sensitive)
2. **BTP is the last array element** that starts with "23..." (minimal 10 digits)
3. If pattern not matched → Status: `NO_PATTERN`
4. If BTP not found → Status: `NO_BTP`

### Example Analysis:
```
Input: "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"

Split by space:
[0] = "KR"
[1] = "OTOMATIS"
[2] = "3009/FTFVA/WS95051"
[3] = "01660/PT"
[4] = "GREENFIEL"  ← Pattern matched!
[5] = "STJ"
[6] = "IC,"
[7] = "16"
[8] = "SEP"
[9] = "25"
[10] = "INV"
[11] = "N9216659"
[12] = "2300017744,"  ← BTP extracted! (starts with "23", 10 digits)

Process:
1. Check Array[4] = 'GREENFIEL' ✅
2. Extract BTP = "2300017744"
3. Search master: WHERE btp = '2300017744'
4. Found customer_name = "CUSTOMER NAME"
5. Search all BTPs: WHERE customer_name = 'CUSTOMER NAME' AND (category = 'GREENFIEL' OR category = 'NEW')
6. Return all matching BTPs with rankings
```

---

## 🎯 Status Codes

| Status | Meaning |
|--------|---------|
| `EXCELLENT` | Match percentage ≥95% - Very high confidence |
| `GOOD` | Match percentage 80-94% - High confidence |
| `FAIR` | Match percentage 70-79% - Medium confidence |
| `LOW` | Match percentage <70% - Low confidence, verify manually |
| `NO_PATTERN` | Array[4] is not 'GREENFIEL' - Pattern not matched |
| `NO_BTP` | BTP not found in description (no word starting with "23...") |
| `NO_MATCH` | BTP not found in master data OR customer has no BTP options |

---

## 🔍 Multiple BTP Options

When a customer has multiple BTPs in master data, the SP returns multiple rows for the same TransactionID.

### Output Format:
```
TransactionID | CustomerName | BTP        | Option | BestFlag | LatestFlag | Label
--------------|--------------|------------|--------|----------|------------|----------
TRX001        | CUSTOMER A   | 2300017744 | 1      | YES      |            | BEST
TRX001        | CUSTOMER A   | 2300015555 | 2      |          | YES        | LATEST
```

### Filtering:
```sql
-- Get BEST option only (for automation)
SELECT * FROM (
    EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON = @JSON
) WHERE BestFlag = 'YES' OR TotalBTPOptions = 1;

-- Get ALL options (for manual review)
EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON = @JSON;
```

---

## 📊 Return Columns

| Column | Type | Description |
|--------|------|-------------|
| `TransactionID` | INT | Transaction ID from input |
| `TransactionDate` | NVARCHAR(50) | Transaction date from input |
| `Description` | NVARCHAR(MAX) | Original description |
| `CustomerName` | NVARCHAR(200) | Customer name from master (found via BTP) |
| `BTP` | NVARCHAR(50) | BTP code |
| `MatchPercentage` | DECIMAL(5,2) | Match confidence (0-100) |
| `MatchCount` | INT | Number of matches in master |
| `TotalTransactions` | INT | Total transactions in master |
| `LastLineNumber` | INT | Last line number in master |
| `TotalBTPOptions` | INT | Total BTP options for this customer |
| `OptionNumber` | INT | Option ranking (1 = best) |
| `BestFlag` | NVARCHAR(10) | 'YES' if this is the best option |
| `LatestFlag` | NVARCHAR(10) | 'YES' if this is the latest BTP |
| `Label` | NVARCHAR(50) | 'BEST', 'LATEST', 'BEST + LATEST', or '' |
| `Status` | NVARCHAR(20) | Status code (see above) |
| `Message` | NVARCHAR(500) | Human-readable message |
| `ProcessedAt` | DATETIME | Processing timestamp |

---

## 💡 Common Use Cases

### Use Case 1: Batch Import
```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "1", "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"},
    {"transaction_id": "2", "description": "KR OTOMATIS 0110/FTFVA/WS95011 01660/PT GREENFIEL K00200162181 PlayCorner 2300015906,"}
]';

EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON = @JSON;
```

### Use Case 2: Get BEST Only (Automation)
```sql
-- Insert results to temp table
SELECT * 
INTO #Results
FROM (
    EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON = @JSON
) AS Results;

-- Filter BEST only
SELECT TransactionID, CustomerName, BTP, MatchPercentage, Status
FROM #Results
WHERE BestFlag = 'YES' OR TotalBTPOptions = 1;

DROP TABLE #Results;
```

### Use Case 3: Debug Mode
```sql
EXEC SP_GREENFIEL_FindBTP_Batch 
    @InputJSON = @JSON,
    @Debug = 1;

-- Shows:
-- - Input data
-- - Summary statistics
-- - Status breakdown
-- - Transactions with multiple BTPs
```

---

## 🔧 Troubleshooting

### Issue: Status = 'NO_PATTERN'
**Cause**: Array[4] is not exactly 'GREENFIEL'  
**Solution**: Check description format. Array[4] must be exactly 'GREENFIEL' (case-sensitive)

### Issue: Status = 'NO_BTP'
**Cause**: No word in description starts with "23..." and has at least 10 digits  
**Solution**: Verify BTP format. BTP should be at the end of description and start with "23..."

### Issue: Status = 'NO_MATCH'
**Cause**: BTP not found in master OR customer has no BTP options  
**Solution**: 
1. Check if BTP exists in `MASTER_CUSTOMER_BTP_PATTERN`
2. Check if customer has BTP with `category = 'GREENFIEL'` or `category = 'NEW'`

### Issue: Multiple rows for same transaction
**Behavior**: This is normal! Customer has multiple BTPs  
**Solution**: Use `WHERE BestFlag = 'YES'` to get best option only

---

## 📝 Notes

1. **Pattern is strict**: Array[4] must be exactly 'GREENFIEL' (case-sensitive)
2. **BTP extraction**: Only takes the LAST word that starts with "23..." and has at least 10 digits
3. **Master lookup**: First searches by BTP to find customer_name, then searches by customer_name for all BTP options
4. **Category priority**: Prefers `category = 'GREENFIEL'` over `category = 'NEW'`
5. **Multiple BTPs**: Returns multiple rows when customer has multiple BTPs in master

---

## 🧪 Testing

### Sample Data
See `data_sample.txt` for sample transactions.

### Quick Test
```sql
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

## 📚 Related Documentation

- Master Table: `[dbo].[MASTER_CUSTOMER_BTP_PATTERN]`
- Category: `'GREENFIEL'` or `'NEW'`
- See other bank SPs for different extraction logic

---

**Author**: Generated October 2025  
**Version**: 1.0.0
