# 📱 Power Apps Implementation - Step by Step

Panduan lengkap implementasi Power Apps dengan SQL Stored Procedure untuk BTP matching.

---

## 🎯 Goal

Upload HTML → Parse → Execute SP → Display BTP Results

**Total Time User:** < 1 minute per file!

---

## 🏗️ Architecture Options

### Option 1: Simple (Recommended untuk Start) ⭐

```
┌─────────────────┐
│   Power Apps    │ ← User uploads HTML file
│   (Canvas App)  │
└────────┬────────┘
         │ 1. Upload file content as text
         ↓
┌─────────────────────────┐
│   Power Automate Flow   │
│                         │
│   Steps:                │
│   1. Receive HTML       │
│   2. Call Azure Fn      │ ← parser.js converts HTML → JSON
│   3. Execute SQL SP     │ ← Run SP_TRSF_FindBTP_Batch
│   4. Return results     │
└────────┬────────────────┘
         │ 2. Return BTP results
         ↓
┌─────────────────┐
│   Power Apps    │ ← Display in Gallery
│   (Results)     │
└─────────────────┘
```

**Pros:**
- ✅ Paling mudah di-setup
- ✅ User hanya upload, tunggu, lihat hasil
- ✅ Semua logic di backend

**Cons:**
- ⏳ Butuh deploy Azure Function (one-time)

---

### Option 2: Manual JSON (Fastest Setup, No Azure) 🚀

```
┌─────────────────┐
│   Power Apps    │ 
│                 │
│   User manual:  │
│   1. Convert    │ ← Use converter.html offline
│      HTML→JSON  │
│   2. Paste JSON │ ← Paste statement_for_sp.json
│   3. Click Run  │
└────────┬────────┘
         │ Send JSON string
         ↓
┌─────────────────────────┐
│   Power Automate Flow   │
│                         │
│   Steps:                │
│   1. Receive JSON       │
│   2. Execute SQL SP     │ ← Run SP directly
│   3. Return results     │
└────────┬────────────────┘
         │ Return BTP results
         ↓
┌─────────────────┐
│   Power Apps    │ ← Display in Gallery
│   (Results)     │
└─────────────────┘
```

**Pros:**
- ✅ NO Azure Function needed!
- ✅ Setup dalam 30 menit
- ✅ Bisa langsung testing

**Cons:**
- ⏳ User harus convert manual dulu (tapi cepat kok, 30 detik!)

---

## 📋 Prerequisites

### 1. SQL Server
- ✅ Stored procedures sudah di-deploy:
  - `SP_TRSF_FindBTP_Batch`
  - `SP_BIFAST_FindBTP_Batch`
  - `SP_MANDIRI_FindBTP_Batch`
- ✅ Master data `MASTER_CUSTOMER_BTP_PATTERN` sudah terisi

### 2. Power Platform
- ✅ Power Apps license (atau trial)
- ✅ Power Automate license
- ✅ SQL Server connector access

### 3. (Optional) Azure
- ⏳ Azure Function untuk auto-parse HTML
- ⏳ Hanya jika pilih Option 1

---

## 🚀 IMPLEMENTATION: Option 2 (Fastest!)

Mari kita mulai dengan Option 2 karena paling cepat!

---

### STEP 1: Create Power Automate Flow

#### 1.1 Create New Flow

1. Masuk ke https://make.powerautomate.com/
2. Create → Instant cloud flow
3. Nama: `ExecuteSQLBTPMatching`
4. Trigger: **PowerApps (V2)**
5. Click Create

#### 1.2 Add Input Parameters

**Add Input:**
- Name: `JSONInput`
- Type: Text
- Description: JSON array dari parser

**Add Input:**
- Name: `BankType`
- Type: Text
- Description: TRSF, BIFAST, atau MANDIRI

#### 1.3 Add SQL Server Action

**Action:** SQL Server → Execute stored procedure (V2)

**Configuration:**
```
Server name: [your-sql-server].database.windows.net
Database name: [your-database]
Procedure name: [dbo].[SP_TRSF_FindBTP_Batch]
Parameters:
  @TransactionsJSON: [JSONInput from PowerApps]
```

**IMPORTANT:** Tambahkan 3 actions untuk 3 bank types:

**Action 1: TRSF**
- Condition: `BankType equals 'TRSF'`
- Execute: `SP_TRSF_FindBTP_Batch`

**Action 2: BIFAST**
- Condition: `BankType equals 'BIFAST'`
- Execute: `SP_BIFAST_FindBTP_Batch`

**Action 3: MANDIRI**
- Condition: `BankType equals 'MANDIRI'`
- Execute: `SP_MANDIRI_FindBTP_Batch`

#### 1.4 Add Response to PowerApps

**Action:** Respond to PowerApps (V2)

**Add Outputs:**
- Name: `Results`
- Type: Text
- Value: `body('Execute_stored_procedure')` (dari step sebelumnya)

#### 1.5 Save Flow

Save dengan nama: `ExecuteSQLBTPMatching`

---

### STEP 2: Create Power Apps Canvas App

#### 2.1 Create New App

1. Masuk ke https://make.powerapps.com/
2. Create → Canvas app from blank
3. Nama: `BTP Matching Tool`
4. Format: Tablet (atau Phone)

#### 2.2 Add Controls

**Screen 1: Input Screen**

**Control 1: Label (Title)**
```
Text: "🏦 BTP Matching Tool"
Font: Segoe UI, Bold, 24
Align: Center
```

**Control 2: Text Input (JSON Input)**
```
Name: txtJSONInput
HintText: "Paste JSON dari converter.html disini..."
Mode: MultiLine
Height: 300
```

**Control 3: Dropdown (Bank Type)**
```
Name: ddBankType
Items: ["TRSF", "BIFAST", "MANDIRI"]
Default: "TRSF"
```

**Control 4: Button (Execute)**
```
Name: btnExecute
Text: "🔍 Find BTP"
OnSelect: 
    Set(
        varResults,
        ExecuteSQLBTPMatching.Run(
            txtJSONInput.Text,
            ddBankType.Selected.Value
        ).Results
    );
    Navigate(ScreenResults)
```

**Control 5: Label (Instructions)**
```
Text: "
CARA MENGGUNAKAN:
1. Buka converter.html di browser
2. Upload file HTML rekening koran
3. Download 'untuk Stored Procedure'
4. Copy isi file JSON
5. Paste di kotak atas
6. Pilih bank type
7. Klik 'Find BTP'
"
Font: 10
Color: Gray
```

**Screen 2: Results Screen**

**Control 1: Gallery (Results)**
```
Name: galResults
Items: 
    If(
        IsBlank(varResults),
        [],
        ParseJSON(varResults)
    )
Layout: Vertical
```

**Gallery Template:**
```
Title: ThisItem.CustomerName
Subtitle: "BTP: " & ThisItem.BTP
Label1: ThisItem.MatchPercentage & "%"
Label2: ThisItem.Status
Label3: ThisItem.Label

Background Fill:
    Switch(
        ThisItem.Status,
        "EXCELLENT", ColorValue("#d4edda"),
        "GOOD", ColorValue("#cfe2ff"),
        "FAIR", ColorValue("#fff3cd"),
        "LOW", ColorValue("#f8d7da"),
        "NO_MATCH", ColorValue("#f8d7da"),
        ColorValue("#ffffff")
    )
```

**Control 2: Button (Back)**
```
Name: btnBack
Text: "← Back"
OnSelect: Navigate(ScreenInput)
```

**Control 3: Button (Export)**
```
Name: btnExport
Text: "📊 Export to Excel"
OnSelect:
    Export(
        galResults.AllItems,
        "BTP_Results_" & Text(Now(), "yyyymmdd_hhmmss") & ".xlsx"
    )
```

#### 2.3 Connect Flow

1. Di Power Apps Studio
2. Data → Add data → Flows
3. Pilih `ExecuteSQLBTPMatching`
4. Add connection

#### 2.4 Test

1. Buka `statement_for_sp.json` yang sudah ada
2. Copy seluruh content
3. Paste ke `txtJSONInput`
4. Pilih "TRSF" di dropdown
5. Klik "Find BTP"
6. Lihat hasil!

---

## 📊 IMPLEMENTATION: Option 1 (Full Automation)

Untuk implementasi lengkap dengan Azure Function (auto-parse HTML):

### STEP 1: Deploy Azure Function

#### 1.1 Create Function App

```bash
# Via Azure Portal
1. Create Resource → Function App
2. Nama: bca-parser-function
3. Runtime: Node.js 18
4. Region: Southeast Asia
5. Plan: Consumption (pay-per-use)
```

#### 1.2 Deploy parser.js

**Create `index.js` in Azure Function:**

```javascript
const BCAStatementParser = require('./parser');

module.exports = async function (context, req) {
    context.log('BCA Parser triggered');

    const htmlContent = req.body.htmlContent;

    if (!htmlContent) {
        context.res = {
            status: 400,
            body: { error: "htmlContent is required" }
        };
        return;
    }

    try {
        const parser = new BCAStatementParser(htmlContent);
        const result = parser.parse();

        if (result.success) {
            const sqlFormat = parser.getTransactionsForStoredProcedure();
            
            // Detect bank type dari transaksi
            let bankType = 'TRSF'; // default
            if (sqlFormat.length > 0) {
                const firstDesc = sqlFormat[0].Description;
                if (firstDesc.includes('BI-FAST')) {
                    bankType = 'BIFAST';
                } else if (firstDesc.includes('LLG-MANDIRI')) {
                    bankType = 'MANDIRI';
                }
            }

            context.res = {
                status: 200,
                body: {
                    success: true,
                    sqlFormat: JSON.stringify(sqlFormat),
                    bankType: bankType,
                    transactionCount: sqlFormat.length,
                    accountInfo: result.data.accountInfo
                }
            };
        } else {
            context.res = {
                status: 500,
                body: { error: result.error }
            };
        }
    } catch (error) {
        context.res = {
            status: 500,
            body: { error: error.message }
        };
    }
};
```

#### 1.3 Upload Files

1. Upload `parser.js` ke Function App
2. Upload `index.js` ke Function App
3. Test via Azure Portal → Test/Run

#### 1.4 Get Function URL

1. Function → Get Function URL
2. Copy URL (dengan access key)
3. Simpan untuk digunakan di Flow

---

### STEP 2: Update Power Automate Flow

**Modify Flow untuk include Azure Function:**

```
Trigger: PowerApps (V2)
    ↓
Input: HTMLContent (text)
    ↓
Action: HTTP (Call Azure Function)
    URI: [Function URL]
    Method: POST
    Headers: 
        Content-Type: application/json
    Body:
        {
            "htmlContent": "@{triggerBody()['text']}"
        }
    ↓
Parse JSON (dari response Azure Function)
    ↓
Condition: Check success
    ↓
If Yes:
    Execute SQL SP berdasarkan bankType
    Return results
    ↓
If No:
    Return error message
```

---

### STEP 3: Update Power Apps

**Modify Input Screen:**

**Remove txtJSONInput, add:**

**Control: Attachments (File Upload)**
```
Name: attHTMLFile
Accept: .html
```

**Button OnSelect:**
```
Set(
    varResults,
    ExecuteSQLBTPMatching.Run(
        First(attHTMLFile.Attachments).Value
    ).Results
);
Navigate(ScreenResults)
```

**Lebih simple untuk user!** Tinggal upload HTML file, done!

---

## 🧪 Testing Guide

### Test Flow (Manual)

1. Masuk ke Flow → Test
2. Trigger: Manual
3. Input JSON:
```json
[
  {"TransactionID": 1, "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"}
]
```
4. Input BankType: `TRSF`
5. Run
6. Check output

### Test Power Apps

**Test Case 1: Single Transaction**
```json
[{"TransactionID": 1, "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"}]
```

**Expected:**
- CustomerName: ELLA CAROLINE
- BTP found
- Status: EXCELLENT

**Test Case 2: Multiple Transactions**
- Use full `statement_for_sp.json` (43 transactions)
- Expected: 43 results

**Test Case 3: No Match**
```json
[{"TransactionID": 99, "Description": "TRSF E-BANKING CR 0810/FTSCY/WS95051 455520.00 CUSTOMER BARU TIDAK ADA"}]
```

**Expected:**
- Status: NO_MATCH
- Message: Customer not found

---

## 📊 Sample Flow JSON (Import Ready)

Saya bisa buatkan Flow JSON yang bisa langsung di-import! Tapi karena setiap environment berbeda (SQL connection string, dll), lebih baik dibuat manual mengikuti step di atas.

---

## 🎨 Power Apps Design Tips

### Color Coding untuk Status

```javascript
// Gallery background color
Switch(
    ThisItem.Status,
    "EXCELLENT", RGBA(212, 237, 218, 1),
    "GOOD", RGBA(207, 226, 255, 1),
    "FAIR", RGBA(255, 243, 205, 1),
    "LOW", RGBA(248, 215, 218, 1),
    "NO_MATCH", RGBA(248, 215, 218, 1),
    RGBA(255, 255, 255, 1)
)
```

### Icon untuk BestFlag & LatestFlag

```javascript
// Icon visibility
If(
    ThisItem.BestFlag = "YES",
    true,
    false
)

// Icon: Icon.Crown (for BEST)
// Icon: Icon.Star (for LATEST)
```

### Loading Indicator

```javascript
// Add Spinner control
Visible: 
    ExecuteSQLBTPMatching.Run.InProgress

// Show di atas button saat processing
```

---

## 🚀 Deployment Checklist

### SQL Server
- [ ] Stored procedures deployed
- [ ] Master data populated
- [ ] Test SPs manually in SSMS
- [ ] SQL Server connector configured in Power Platform

### Azure Function (Optional, for Option 1)
- [ ] Function App created
- [ ] parser.js uploaded
- [ ] index.js uploaded
- [ ] Function tested via Azure Portal
- [ ] Function URL copied

### Power Automate
- [ ] Flow created
- [ ] SQL connection added
- [ ] Test flow manually
- [ ] Error handling added
- [ ] Flow published

### Power Apps
- [ ] Canvas app created
- [ ] Screens designed
- [ ] Flow connected
- [ ] Test with sample data
- [ ] User acceptance testing
- [ ] App published
- [ ] Share with users

---

## 📱 User Guide (for End Users)

### Option 2: Manual JSON (Simple)

**Step 1: Convert HTML to JSON**
1. Buka `converter.html` di browser
2. Drag & drop file HTML rekening koran
3. Klik "Download untuk Stored Procedure"
4. File `statement_for_sp.json` akan ter-download

**Step 2: Use Power Apps**
1. Buka Power Apps "BTP Matching Tool"
2. Open `statement_for_sp.json` dengan Notepad
3. Copy semua content (Ctrl+A, Ctrl+C)
4. Paste di kotak input di Power Apps
5. Pilih bank type (TRSF/BIFAST/MANDIRI)
6. Klik "Find BTP"
7. Tunggu 2-5 detik
8. Lihat hasil!

**Total Time:** ~1 minute

---

### Option 1: Full Auto (Advanced)

**Step 1: Upload HTML**
1. Buka Power Apps "BTP Matching Tool"
2. Click "Upload File"
3. Pilih file HTML rekening koran
4. Click "Process"
5. Tunggu 5-10 detik
6. Lihat hasil!

**Total Time:** ~30 seconds

---

## 💡 Advanced Features (Optional)

### 1. History Tracking

**Add to Flow:**
- Store hasil matching ke SharePoint list
- Include: Timestamp, User, File name, Results

### 2. Batch Processing

**Multiple Files:**
- Upload multiple HTML files
- Process sequentially
- Aggregate results

### 3. Notification

**Send Email:**
- After processing complete
- Include summary statistics
- Attach Excel export

### 4. Analytics Dashboard

**Power BI:**
- Connect to SharePoint history list
- Show metrics:
  - Total transactions processed
  - Match rate (%)
  - Top customers
  - Bank distribution

---

## 🐛 Troubleshooting

### "Flow timeout"
**Problem:** Processing takes > 2 minutes  
**Solution:** 
- Break into smaller batches (<100 transactions)
- Increase Flow timeout settings

### "SQL connection failed"
**Problem:** Can't connect to SQL Server  
**Solution:**
- Check firewall rules (allow Azure services)
- Verify connection string
- Test connection in Power Automate

### "Invalid JSON"
**Problem:** JSON format error  
**Solution:**
- Validate JSON at jsonlint.com
- Ensure copied complete JSON (including `[` and `]`)
- Check for special characters

### "No results returned"
**Problem:** SP returns empty  
**Solution:**
- Check master data exists
- Verify category filter in SP
- Test SP directly in SSMS with same JSON

---

## 📊 Performance Benchmarks

| Transactions | Flow Time | Total User Time |
|--------------|-----------|-----------------|
| 10           | ~2 sec    | ~30 sec         |
| 50           | ~5 sec    | ~1 min          |
| 100          | ~10 sec   | ~1.5 min        |
| 500          | ~30 sec   | ~2 min          |

**Note:** User time includes HTML→JSON conversion (Option 2)

---

## 🎉 Summary

### Option 2 (Recommended untuk Start) ⭐

**Pros:**
- ✅ Setup cepat (30 menit)
- ✅ No Azure Function needed
- ✅ Langsung bisa testing
- ✅ User workflow simple

**Cons:**
- ⏳ User harus convert HTML dulu (30 detik)

**Best for:** Quick start, testing, proof of concept

---

### Option 1 (Full Automation)

**Pros:**
- ✅ User tinggal upload HTML
- ✅ Fully automated
- ✅ Professional solution

**Cons:**
- ⏳ Butuh Azure Function setup
- ⏳ Lebih kompleks

**Best for:** Production deployment, many users

---

## 🚀 Rekomendasi

**MULAI DENGAN OPTION 2!**

1. ✅ Setup Flow (15 menit)
2. ✅ Setup Power Apps (15 menit)
3. ✅ Test dengan `statement_for_sp.json` yang sudah ada
4. ✅ User acceptance testing
5. ✅ Jika approved, upgrade ke Option 1 (add Azure Function)

**Total Time to Production:** 1-2 hours untuk Option 2!

---

**Version:** 1.0.0  
**Last Updated:** October 21, 2025  
**Status:** ✅ Implementation Ready

