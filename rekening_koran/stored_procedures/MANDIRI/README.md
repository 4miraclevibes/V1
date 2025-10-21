# MANDIRI BTP Pattern Matching - Stored Procedures

## 📋 Overview

Stored procedures untuk mencari BTP (Bill To Party) dari deskripsi transaksi MANDIRI berdasarkan customer name pattern matching.

### Logic:
1. **Extract Customer Name**: Ambil ALL CAPS words setelah last number dalam description
2. **Pattern Matching**: Match dengan master data `MASTER_CUSTOMER_BTP_PATTERN`
3. **Best Match Selection**: Return BTP dengan highest match percentage

---

## 📁 Files

| File | Purpose |
|------|---------|
| `SP_MANDIRI_FindBTP_Single.sql` | Single search - 1 description → 1 BTP |
| `SP_MANDIRI_FindBTP_Batch.sql` | Batch search - Multiple descriptions (JSON) → Multiple BTPs |
| `Test_SP_MANDIRI.sql` | Test scripts dengan sample data |
| `README.md` | Documentation (this file) |

---

## 🚀 Installation

### Prerequisites:
1. Table `[dbo].[MASTER_CUSTOMER_BTP_PATTERN]` must exist
2. Table must have column `category` = 'MANDIRI'
3. SQL Server 2016+ (for JSON support)

### Install:
```sql
-- 1. Create table (if not exists)
-- Run: pattern_generator_MANDIRI/master_customer_btp_pattern_MANDIRI_SPLIT.sql

-- 2. Create SP Single
-- Run: SP_MANDIRI_FindBTP_Single.sql

-- 3. Create SP Batch
-- Run: SP_MANDIRI_FindBTP_Batch.sql

-- 4. Test
-- Run: Test_SP_MANDIRI.sql
```

---

## 📖 Usage

### 1. SP_MANDIRI_FindBTP_Single

**Purpose**: Find BTP untuk 1 description

**Parameters**:
- `@Description` (NVARCHAR(500)): Transaction description
- `@Debug` (BIT): 0 = normal, 1 = show debug info

**Returns**:
- Result Set 1: Best match (BTP, CustomerName, MatchPercentage, Status, Message)
- Result Set 2: All options (jika ada multiple matches)

**Example**:
```sql
EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'MANDIRI E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY',
    @Debug = 0;
```

**Output**:
```
BTP          | CustomerName    | MatchPercentage | Status    | Message
-------------|-----------------|-----------------|-----------|------------------
2300016055   | RONNY YULIADY   | 95.5           | EXCELLENT | Single match found
```

---

### 2. SP_MANDIRI_FindBTP_Batch

**Purpose**: Find BTP untuk multiple descriptions (batch processing)

**Parameters**:
- `@InputJSON` (NVARCHAR(MAX)): JSON array of descriptions
- `@Debug` (BIT): 0 = normal, 1 = show debug + statistics

**JSON Format**:
```json
[
    {
        "transaction_id": "TRX001",  // Optional
        "description": "MANDIRI E-BANKING CR 0201 455520.00 RONNY YULIADY"
    },
    {
        "transaction_id": "TRX002",
        "description": "MANDIRI FROM BCA 123456789 HARDI PUTRA MUHARR"
    }
]
```

**Returns**:
- Result set dengan BTP untuk setiap transaction

**Example**:
```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TRX001",
        "description": "MANDIRI E-BANKING CR 0201 455520.00 RONNY YULIADY"
    },
    {
        "transaction_id": "TRX002",
        "description": "MANDIRI FROM BCA 123456789 HARDI PUTRA MUHARR"
    }
]';

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 0;
```

**Output**:
```
TransactionID | Description       | CustomerName      | BTP        | MatchPct | Status    | Message
--------------|-------------------|-------------------|------------|----------|-----------|------------------
TRX001        | MANDIRI E-BANKING... | RONNY YULIADY     | 2300016055 | 95.5     | EXCELLENT | High confidence
TRX002        | MANDIRI FROM BCA...  | HARDI PUTRA MUHARR| 2300016055 | 100.0    | EXCELLENT | High confidence
```

---

## 🎯 Status Codes

| Status | Match % | Meaning |
|--------|---------|---------|
| `EXCELLENT` | ≥95% | Very high confidence |
| `GOOD` | 80-94% | High confidence |
| `FAIR` | 70-79% | Medium confidence |
| `LOW` | <70% | Low confidence - verify manually |
| `NO_MATCH` | - | Customer found but no BTP in master |
| `NO_PATTERN` | - | Customer name not found in description |

---

## 🧪 Testing

### Quick Test:
```sql
-- Test Single
EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'MANDIRI E-BANKING CR 0201 455520.00 RONNY YULIADY',
    @Debug = 1;

-- Test Batch
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "T1", "description": "MANDIRI 12345 RONNY YULIADY"},
    {"transaction_id": "T2", "description": "MANDIRI 67890 HARDI PUTRA MUHARR"}
]';

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] @InputJSON = @JSON, @Debug = 1;
```

### Run Full Test Suite:
```sql
-- See: Test_SP_MANDIRI.sql
```

---

## 📊 Performance

### Single Search:
- **Speed**: <10ms per search
- **Use case**: Real-time transaction processing
- **Limit**: 1 transaction per call

### Batch Search:
- **Speed**: ~5-10ms per transaction (parallel processing)
- **Use case**: Bulk import, nightly batch jobs
- **Recommended**: 100-1000 transactions per batch
- **Limit**: Limited by JSON size (~1000 transactions optimal)

---

## 🔍 Troubleshooting

### Common Issues:

**1. "Customer name not found in description"**
- **Cause**: Description tidak punya ALL CAPS words after last number
- **Solution**: Check description format, ensure ada customer name yang jelas

**2. "Customer not found in master data"**
- **Cause**: Customer name exists tapi tidak ada di master pattern
- **Solution**: Generate patterns lagi atau add manual ke master

**3. "Multiple BTP options found"**
- **Cause**: Customer punya multiple BTPs di master
- **Solution**: SP akan return BEST match (highest %), check All Options untuk alternatives

**4. Low confidence (<70%)**
- **Cause**: Pattern match rendah
- **Solution**: Verify manually, consider updating master data

---

## 🛠️ Maintenance

### Update Master Data:
```sql
-- 1. Regenerate patterns (via C program)
cd pattern_generator_MANDIRI
./generate_patterns_mandiri

-- 2. Truncate existing data
TRUNCATE TABLE [dbo].[MASTER_CUSTOMER_BTP_PATTERN];

-- 3. Import new patterns
-- Run: master_customer_btp_pattern_MANDIRI_SPLIT.sql
```

### Check SP Performance:
```sql
-- Enable statistics
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'MANDIRI 12345 TEST CUSTOMER';
```

---

## 📞 Support

For issues or questions:
1. Check test results in `Test_SP_MANDIRI.sql`
2. Run with `@Debug = 1` untuk detail
3. Verify master data coverage

---

## 📝 Changelog

### Version 1.0 (2025-10-21)
- ✅ Initial release
- ✅ Single search SP
- ✅ Batch search SP with JSON
- ✅ Debug mode
- ✅ Multiple BTP options handling
- ✅ Status codes and confidence levels

