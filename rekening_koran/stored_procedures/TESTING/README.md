# Testing Database - rekening_koran_testing

Database testing untuk menyimpan dan menganalisis hasil dari `SP_MASTER_FindBTP_Batch`.

## 📋 Setup Instructions

### Step 1: Create Database
```sql
:r 01_CREATE_DATABASE.sql
```
- Creates database `rekening_koran_testing`
- Drops existing database if exists

### Step 2: Create Tables
```sql
:r 02_CREATE_TABLES.sql
```
- Creates table `BTP_MATCHING_RESULTS`
- Includes indexes for better performance

### Step 3: Create Stored Procedure
```sql
:r 03_CREATE_SP_SAVE_RESULTS.sql
```
- Creates `SP_MASTER_FindBTP_And_Save`
- Executes MASTER SP dan save hasil otomatis

### Step 4: Test
```sql
:r 04_TEST_EXAMPLE.sql
```
- Contoh penggunaan dengan 5 transactions
- Includes utility queries

---

## 🎯 Usage

### Execute dan Save Results

```sql
DECLARE @JSON NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "TransactionDate": "08/10/2025", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE"},
  {"TransactionID": 5, "TransactionDate": "08/10/2025", "Description": "BI-FAST CR TRANSFER   DR 032 PT Kerry Ingredien"}
]';

EXEC rekening_koran_testing.dbo.SP_MASTER_FindBTP_And_Save 
    @TransactionsJSON = @JSON,
    @SourceDatabase = 'POWERAPPS';  -- Ganti dengan database Anda
```

**Parameters:**
- `@TransactionsJSON` - JSON array of transactions (PascalCase: TransactionID, TransactionDate, Description)
- `@SourceDatabase` - Nama database dimana MASTER SP berada (default: 'POWERAPPS')

---

## 📊 Table Structure: BTP_MATCHING_RESULTS

| Column | Type | Description |
|--------|------|-------------|
| **ResultID** | INT (PK) | Auto-increment primary key |
| **TransactionID** | INT | ID dari transaction |
| **TransactionDate** | NVARCHAR(50) | Tanggal transaksi |
| **Description** | NVARCHAR(MAX) | Deskripsi transaksi |
| **CustomerName** | NVARCHAR(200) | Nama customer yang ditemukan |
| **BTP** | NVARCHAR(50) | BTP yang match |
| **MatchPercentage** | DECIMAL(5,2) | Persentase match (0-100) |
| **MatchCount** | INT | Jumlah match di master data |
| **TotalTransactions** | INT | Total transactions di master |
| **LastLineNumber** | INT | Line number terakhir di master CSV |
| **TotalBTPOptions** | INT | Jumlah BTP options yang ditemukan |
| **OptionNumber** | INT | Option number (1, 2, 3...) |
| **BestFlag** | NVARCHAR(10) | 'YES' jika ini BEST option |
| **LatestFlag** | NVARCHAR(10) | 'YES' jika ini LATEST option |
| **Label** | NVARCHAR(50) | 'BEST', 'LATEST', 'BEST + LATEST', or '' |
| **Status** | NVARCHAR(20) | EXCELLENT, GOOD, FAIR, LOW, NO_MATCH, NO_PATTERN |
| **Message** | NVARCHAR(500) | Pesan detail tentang matching |
| **BankType** | NVARCHAR(50) | TRSF, BIFAST, MANDIRI, BNI, CIMB, dll |
| **ProcessedAt** | DATETIME | Kapan MASTER SP memproses |
| **InsertedAt** | DATETIME | Kapan data disimpan ke table (auto) |

**Indexes:**
- `IX_TransactionID` - Fast lookup by TransactionID
- `IX_BankType` - Fast filtering by bank
- `IX_Status` - Fast filtering by status
- `IX_TransactionDate` - Fast filtering by date
- `IX_BTP` - Fast lookup by BTP
- `IX_InsertedAt` - Fast filtering by insertion time

---

## 🔍 Useful Queries

### 1. View Latest Results
```sql
SELECT TOP 10 * 
FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS 
ORDER BY ResultID DESC;
```

### 2. View Results by BankType
```sql
SELECT * 
FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS 
WHERE BankType = 'TRSF';
```

### 3. View Only Successful Matches
```sql
SELECT * 
FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS 
WHERE Status IN ('EXCELLENT', 'GOOD', 'FAIR');
```

### 4. View Failed Matches
```sql
SELECT * 
FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS 
WHERE Status IN ('NO_MATCH', 'NO_PATTERN');
```

### 5. Summary by BankType
```sql
SELECT 
    BankType,
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT TransactionID) AS UniqueTransactions,
    SUM(CASE WHEN Status NOT IN ('NO_MATCH', 'NO_PATTERN') THEN 1 ELSE 0 END) AS MatchedRecords,
    AVG(CASE WHEN Status NOT IN ('NO_MATCH', 'NO_PATTERN') THEN MatchPercentage ELSE NULL END) AS AvgMatchPercentage
FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS
GROUP BY BankType
ORDER BY BankType;
```

### 6. View Results by Date Range
```sql
SELECT * 
FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS 
WHERE TransactionDate BETWEEN '01/10/2025' AND '31/10/2025';
```

### 7. View Multiple BTP Options
```sql
SELECT * 
FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS 
WHERE TotalBTPOptions > 1
ORDER BY TransactionID, OptionNumber;
```

### 8. Performance Statistics
```sql
SELECT 
    COUNT(*) AS TotalTests,
    COUNT(DISTINCT TransactionID) AS UniqueTransactions,
    SUM(CASE WHEN Status IN ('EXCELLENT', 'GOOD') THEN 1 ELSE 0 END) AS HighConfidence,
    SUM(CASE WHEN Status = 'FAIR' THEN 1 ELSE 0 END) AS MediumConfidence,
    SUM(CASE WHEN Status = 'LOW' THEN 1 ELSE 0 END) AS LowConfidence,
    SUM(CASE WHEN Status = 'NO_MATCH' THEN 1 ELSE 0 END) AS NoMatch,
    SUM(CASE WHEN Status = 'NO_PATTERN' THEN 1 ELSE 0 END) AS NoPattern
FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS;
```

### 9. Clear All Test Data
```sql
TRUNCATE TABLE rekening_koran_testing.dbo.BTP_MATCHING_RESULTS;
```

---

## ✅ Benefits

1. **Automated Testing**: Execute dan save hasil otomatis
2. **Historical Data**: Semua test results tersimpan dengan timestamp
3. **Performance Analysis**: Analyze match rates per bank
4. **Debugging**: Easy to identify failed matches
5. **Reporting**: Generate reports dari saved data
6. **Comparison**: Compare results across different test runs

---

## 🎯 Workflow

```
1. Upload HTML → Parser → JSON
           ↓
2. JSON → SP_MASTER_FindBTP_And_Save
           ↓
3. Execute MASTER SP (from main database)
           ↓
4. Save results → rekening_koran_testing.BTP_MATCHING_RESULTS
           ↓
5. Analyze results via SQL queries
```

---

## 📁 Files

- `01_CREATE_DATABASE.sql` - Create database
- `02_CREATE_TABLES.sql` - Create tables
- `03_CREATE_SP_SAVE_RESULTS.sql` - Create SP untuk save results
- `04_TEST_EXAMPLE.sql` - Example test cases
- `README.md` - This file

---

## ⚠️ Important Notes

1. **Database Name**: Pastikan main database name benar di parameter `@SourceDatabase`
2. **Permissions**: User harus punya permission untuk execute SP di main database
3. **Storage**: Table akan grow seiring testing, truncate secara berkala jika perlu
4. **Indexes**: Sudah include indexes untuk performance, tapi bisa ditambah sesuai kebutuhan
5. **Backup**: Consider backup table sebelum truncate jika data penting

---

## 🚀 Quick Start

```sql
-- 1. Setup (one time)
:r 01_CREATE_DATABASE.sql
:r 02_CREATE_TABLES.sql
:r 03_CREATE_SP_SAVE_RESULTS.sql

-- 2. Test dengan sample JSON
DECLARE @JSON NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "TransactionDate": "08/10/2025", "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE"}
]';

EXEC rekening_koran_testing.dbo.SP_MASTER_FindBTP_And_Save 
    @TransactionsJSON = @JSON,
    @SourceDatabase = 'POWERAPPS';

-- 3. View results
SELECT TOP 10 * FROM rekening_koran_testing.dbo.BTP_MATCHING_RESULTS ORDER BY ResultID DESC;
```

**Done!** ✅

