# STAGING TABLE - Simple Storage untuk Review

## 📋 Overview

**Database**: `POWERAPPS`  
**Table**: `REKENING_KORAN_STAGING`  
**Main SP**: `SP_MASTER_FindBTP_Batch_ToStaging`

### Purpose
Table biasa (permanent table) yang digunakan untuk **temporary store** hasil dari `SP_MASTER_FindBTP_Batch`. User bisa review di Power Apps sebelum submit ke table final.

### Simple Workflow

```
1. Upload HTML Bank Statement
   ↓
2. Convert to JSON
   ↓
3. Execute SP_MASTER_FindBTP_Batch_ToStaging
   ↓ (auto-save ke REKENING_KORAN_STAGING)
4. Review di Power Apps
   ↓
5. Submit ke Final Table (via Power Apps)
   ↓
6. Delete/archive dari staging table
```

---

## 🗄️ Table Structure

### REKENING_KORAN_STAGING

| Column | Type | Description |
|--------|------|-------------|
| **ID** | INT (PK) | Auto-increment primary key |
| **TransactionID** | INT | Transaction ID dari bank statement |
| **TransactionDate** | NVARCHAR(50) | Tanggal transaksi |
| **Description** | NVARCHAR(MAX) | Description dari bank |
| **CustomerName** | NVARCHAR(200) | Extracted customer name |
| **BTP** | NVARCHAR(50) | Matched BTP |
| **MatchPercentage** | DECIMAL(5,2) | Match confidence |
| **MatchCount** | INT | Jumlah match di master |
| **TotalTransactions** | INT | Total transactions untuk BTP ini |
| **LastLineNumber** | INT | Latest line number |
| **TotalBTPOptions** | INT | Total BTP options found |
| **OptionNumber** | INT | Option number (1, 2, 3...) |
| **BestFlag** | NVARCHAR(10) | 'YES' jika best option |
| **LatestFlag** | NVARCHAR(10) | 'YES' jika latest option |
| **Label** | NVARCHAR(50) | 'BEST', 'LATEST', 'BEST + LATEST' |
| **Status** | NVARCHAR(20) | 'EXCELLENT', 'GOOD', 'FAIR', 'LOW', 'NO_MATCH' |
| **Message** | NVARCHAR(500) | Detail message |
| **BankType** | NVARCHAR(50) | 'TRSF', 'BIFAST', 'MANDIRI', etc. |
| **ProcessedAt** | DATETIME | Waktu processing dari MASTER SP |
| **CreatedAt** | DATETIME | Waktu insert ke staging table |
| **BatchID** | NVARCHAR(50) | Batch identifier |
| **UploadedBy** | NVARCHAR(100) | User yang upload |
| **UploadedAt** | DATETIME | Waktu upload |

---

## 🔧 Stored Procedure

### SP_MASTER_FindBTP_Batch_ToStaging

**Purpose**: Execute MASTER SP dan save hasil ke staging table

**Parameters**:
- `@TransactionsJSON` (NVARCHAR(MAX), required) - JSON array of transactions
- `@BatchID` (NVARCHAR(50), optional) - Custom batch ID, auto-generate jika NULL
- `@UploadedBy` (NVARCHAR(100), optional) - Username/email

**Returns**:
1. Result set dari MASTER SP
2. Summary (BatchID, TotalRowsSaved, Status)

**Example**:
```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "TransactionDate": "08/10/2025", "Description": "..."},
  ...
]';

EXEC SP_MASTER_FindBTP_Batch_ToStaging 
    @TransactionsJSON = @JSON,
    @UploadedBy = 'user@company.com';
```

**Auto-Generated BatchID Format**: `BATCH_YYYYMMDD_HHMMSS`  
Example: `BATCH_20251022_143025`

---

## 🧪 Installation

### Step 1: Create Table
```sql
USE POWERAPPS;
GO
:r CREATE_STAGING_TABLE.sql
```

### Step 2: Create Stored Procedure
```sql
:r SP_MASTER_FindBTP_Batch_ToStaging.sql
```

### Step 3: Test
```sql
:r TEST_STAGING.sql
```

---

## 💡 Usage Examples

### 1. Upload & Save to Staging
```sql
DECLARE @JSON NVARCHAR(MAX) = N'[...]';

EXEC SP_MASTER_FindBTP_Batch_ToStaging 
    @TransactionsJSON = @JSON,
    @UploadedBy = 'user@company.com';
```

### 2. View Data by Batch
```sql
SELECT * 
FROM dbo.REKENING_KORAN_STAGING
WHERE BatchID = 'BATCH_20251022_143025'
ORDER BY TransactionID, OptionNumber;
```

### 3. View Latest Upload
```sql
SELECT TOP 100 *
FROM dbo.REKENING_KORAN_STAGING
ORDER BY UploadedAt DESC;
```

### 4. Submit to Final Table
```sql
-- Customize sesuai struktur final table anda
INSERT INTO YourFinalTable (
    TransactionDate,
    Description,
    CustomerName,
    BTP,
    BankType,
    CreatedAt
)
SELECT 
    TransactionDate,
    Description,
    CustomerName,
    BTP,
    BankType,
    GETDATE()
FROM dbo.REKENING_KORAN_STAGING
WHERE BatchID = 'BATCH_20251022_143025'
  AND BTP IS NOT NULL;  -- Only matched transactions
```

### 5. Delete After Submit
```sql
-- Delete specific batch
DELETE FROM dbo.REKENING_KORAN_STAGING
WHERE BatchID = 'BATCH_20251022_143025';

-- Or delete old data (older than 7 days)
DELETE FROM dbo.REKENING_KORAN_STAGING
WHERE UploadedAt < DATEADD(DAY, -7, GETDATE());
```

---

## 📱 Power Apps Integration

### Power Automate Flows

**Flow 1: Upload & Process**
- Trigger: PowerApps button
- Action: SQL - Execute `SP_MASTER_FindBTP_Batch_ToStaging`
- Return: Results to Power Apps

**Flow 2: Get Staging Data**
- Trigger: PowerApps screen load
- Action: SQL - SELECT from `REKENING_KORAN_STAGING`
- Return: Data for Gallery display

**Flow 3: Submit to Final**
- Trigger: PowerApps button
- Action 1: SQL - INSERT INTO FinalTable from Staging
- Action 2: SQL - DELETE from Staging (cleanup)

### Power Apps Screens

**Screen 1: Upload**
- Upload HTML file
- Convert to JSON
- Execute SP_MASTER_FindBTP_Batch_ToStaging

**Screen 2: Review (Gallery)**
- Display: Data dari REKENING_KORAN_STAGING
- Show: TransactionDate, Description, CustomerName, BTP, Label (BEST/LATEST)
- Filter: By BatchID, BankType, Date
- Actions: [Submit All] [Submit Selected] [Delete]

**Screen 3: Submit**
- Confirm selected data
- Insert to final table
- Cleanup staging table

---

## 🔍 Useful Queries

### Statistics by Batch
```sql
SELECT 
    BatchID,
    UploadedBy,
    UploadedAt,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT BankType) AS UniqueBanks,
    SUM(CASE WHEN BTP IS NOT NULL THEN 1 ELSE 0 END) AS MatchedRows,
    SUM(CASE WHEN BTP IS NULL THEN 1 ELSE 0 END) AS UnmatchedRows
FROM dbo.REKENING_KORAN_STAGING
GROUP BY BatchID, UploadedBy, UploadedAt
ORDER BY UploadedAt DESC;
```

### Statistics by Bank Type
```sql
SELECT 
    BankType,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT BatchID) AS UniqueBatches,
    AVG(MatchPercentage) AS AvgMatchPercentage
FROM dbo.REKENING_KORAN_STAGING
WHERE BTP IS NOT NULL
GROUP BY BankType
ORDER BY TotalRows DESC;
```

### Find Duplicate Transactions
```sql
SELECT 
    TransactionID,
    TransactionDate,
    Description,
    COUNT(*) AS DuplicateCount
FROM dbo.REKENING_KORAN_STAGING
GROUP BY TransactionID, TransactionDate, Description
HAVING COUNT(*) > 1;
```

### View Best Matches Only
```sql
SELECT *
FROM dbo.REKENING_KORAN_STAGING
WHERE BestFlag = 'YES'
ORDER BY UploadedAt DESC, TransactionID;
```

---

## ⚠️ Important Notes

1. **Table Permanent**: Ini bukan `#temp` table, jadi data tidak auto-delete
2. **Manual Cleanup**: Perlu manual delete/archive data lama
3. **BatchID Auto-Generated**: Jika tidak provide, auto-generate dengan format `BATCH_YYYYMMDD_HHMMSS`
4. **Multiple BTP Options**: Satu transaction bisa punya multiple rows jika ada multiple BTP options
5. **Review Before Submit**: Always review data di staging sebelum submit ke final table

---

## 📂 Files

- `CREATE_STAGING_TABLE.sql` - Create table script
- `SP_MASTER_FindBTP_Batch_ToStaging.sql` - Main stored procedure
- `TEST_STAGING.sql` - Test script
- `STAGING_README.md` - This documentation

---

## ✅ Quick Start Checklist

- [ ] Execute `CREATE_STAGING_TABLE.sql`
- [ ] Execute `SP_MASTER_FindBTP_Batch_ToStaging.sql`
- [ ] Test dengan `TEST_STAGING.sql`
- [ ] Setup Power Automate Flow untuk execute SP
- [ ] Create Power Apps screen untuk display staging data
- [ ] Create Power Apps flow untuk submit to final table
- [ ] Setup cleanup schedule (weekly/monthly)

---

**Version**: 1.0  
**Status**: ✅ Production Ready  
**Database**: POWERAPPS  
**Table**: REKENING_KORAN_STAGING

