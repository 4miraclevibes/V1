# 🚀 Power Apps Integration Guide

Panduan lengkap untuk mengintegrasikan BCA Statement Converter dengan Power Apps.

---

## 🎯 Skenario Penggunaan

### Skenario 1: Upload & Match BTP
1. User upload file HTML rekening koran
2. Convert ke JSON
3. Send ke SQL Server via Flow
4. Tampilkan hasil BTP matching

### Skenario 2: Batch Processing
1. Upload multiple files ke SharePoint
2. Flow process semua files
3. Aggregate results
4. Display summary di Power Apps

### Skenario 3: Real-time Validation
1. User paste transaction description
2. Real-time call ke SP via Flow
3. Show BTP suggestion immediately

---

## 📋 Architecture Overview

```
Power Apps (Frontend)
    ↓
Power Automate Flow (Middleware)
    ↓
Azure Function / Custom API (Parser)
    ↓
SQL Server (Stored Procedures)
    ↓
Return Results
    ↓
Power Apps (Display)
```

---

## 🔧 Setup Guide

### Step 1: Setup SQL Server Connection

1. **Buat SQL Server connector di Power Apps**
   - Masuk ke Power Apps
   - Data → Connections → New Connection
   - Pilih "SQL Server"
   - Input connection details

2. **Test connection dengan query sederhana**
   ```sql
   SELECT TOP 10 * FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN]
   ```

### Step 2: Create Power Automate Flow

#### Flow 1: Parse HTML & Find BTP (Manual Trigger)

**Trigger:** PowerApps (Manual)

**Input Parameters:**
- `HTMLContent` (string) - Content dari file HTML

**Actions:**

1. **Initialize Variable: ParsedJSON**
   - Type: String
   - Value: (akan diisi oleh custom code)

2. **Compose: Parse HTML**
   - Input: 
   ```javascript
   // JavaScript code untuk parse HTML
   // (Bisa menggunakan Azure Function atau inline code)
   ```

3. **SQL Server: Execute Stored Procedure**
   - Procedure: `SP_TRSF_FindBTP_Batch` (atau bank yang sesuai)
   - Parameter `@TransactionsJSON`: Output dari step 2

4. **Response to PowerApps**
   - Return hasil dari SQL query

#### Flow 2: Upload File & Process (Automated)

**Trigger:** When a file is created (SharePoint)

**Actions:**

1. **Get file content**
2. **Parse HTML using Azure Function**
3. **Execute SP for each bank type**
4. **Store results in SharePoint list**
5. **Send notification**

### Step 3: Create Azure Function (HTML Parser)

**Mengapa perlu Azure Function?**
- Power Automate tidak bisa run JavaScript secara native
- Azure Function memberikan environment untuk run `parser.js`

**Setup:**

1. **Create Azure Function App**
   ```bash
   # Via Azure Portal
   - Masuk ke portal.azure.com
   - Create Resource → Function App
   - Runtime: Node.js 18
   - Region: Southeast Asia
   ```

2. **Deploy parser.js ke Azure Function**

   Create `index.js`:
   ```javascript
   const BCAStatementParser = require('./parser');

   module.exports = async function (context, req) {
       context.log('HTML Parser function triggered');

       const htmlContent = req.body.htmlContent;

       if (!htmlContent) {
           context.res = {
               status: 400,
               body: "Please provide htmlContent in request body"
           };
           return;
       }

       try {
           const parser = new BCAStatementParser(htmlContent);
           const result = parser.parse();

           if (result.success) {
               // Format untuk SQL Stored Procedure
               const sqlFormat = parser.getTransactionsForStoredProcedure();

               context.res = {
                   status: 200,
                   body: {
                       success: true,
                       data: result.data,
                       sqlFormat: sqlFormat
                   }
               };
           } else {
               context.res = {
                   status: 500,
                   body: {
                       success: false,
                       error: result.error
                   }
               };
           }
       } catch (error) {
           context.res = {
               status: 500,
               body: {
                   success: false,
                   error: error.message
               }
           };
       }
   };
   ```

3. **Deploy ke Azure**
   ```bash
   # Via VS Code Azure Functions extension
   # Or via Azure CLI
   func azure functionapp publish <function-app-name>
   ```

4. **Get Function URL**
   - Copy Function URL dari Azure Portal
   - Add ke Power Automate Flow sebagai HTTP action

---

## 🎨 Power Apps Design

### Screen 1: Upload & Select Bank

```javascript
// OnVisible
Set(
    varSelectedBank, 
    Blank()
);
Set(
    varResults,
    Blank()
);

// Gallery: Bank Selection
Items: ["TRSF", "BIFAST", "MANDIRI"]

// OnSelect
Set(varSelectedBank, ThisItem.Value);

// File Upload Control
OnChange: Set(varUploadedFile, Self.SelectedFile)

// Button: Process
OnSelect:
Set(
    varResults,
    FlowProcessHTMLAndFindBTP.Run(
        varUploadedFile.Content,
        varSelectedBank
    )
);
Navigate(ResultsScreen)
```

### Screen 2: Results Display

```javascript
// Gallery: Transaction Results
Items: varResults

// DisplayMode: Show transaction details
Title: ThisItem.Description
Subtitle: "BTP: " & ThisItem.BTP
Label: ThisItem.Label

// Color coding
Fill: Switch(
    ThisItem.Status,
    "EXCELLENT", ColorValue("#d4edda"),
    "GOOD", ColorValue("#cfe2ff"),
    "FAIR", ColorValue("#fff3cd"),
    "LOW", ColorValue("#f8d7da"),
    ColorValue("#f0f0f0")
)
```

### Screen 3: Summary Dashboard

```javascript
// Cards: Summary Statistics
TotalTransactions: CountRows(varResults)
ExcellentMatches: CountIf(varResults, Status = "EXCELLENT")
GoodMatches: CountIf(varResults, Status = "GOOD")
NoMatches: CountIf(varResults, Status = "NO_MATCH")

// Chart: Match Distribution
Items: 
GroupBy(
    varResults,
    "Status",
    "Summary"
)

// Export to Excel Button
OnSelect:
Export(varResults, "BTP_Matching_Results.xlsx")
```

---

## 🔄 Flow Integration Examples

### Example 1: Simple Manual Trigger

**Power Apps:**
```javascript
// Button OnSelect
Set(
    varBTPResults,
    FlowFindBTP.Run(
        JSON(
            Table(
                {TransactionID: 1, Description: txDescription.Text}
            )
        )
    )
);
```

**Flow:**
```
Trigger: PowerApps
↓
Input: TransactionDescription (string)
↓
Compose JSON: 
[
  {
    "TransactionID": 1,
    "Description": "@{triggerBody()['text']}"
  }
]
↓
SQL: Execute SP_TRSF_FindBTP_Batch
Parameter: @TransactionsJSON = outputs('Compose_JSON')
↓
Response to PowerApps: body('Execute_stored_procedure')['ResultSets']['Table1']
```

### Example 2: Batch Upload via SharePoint

**Power Apps:**
```javascript
// Gallery: Uploaded Files
Items: SharePointFiles

// OnSelect: Process File
ForAll(
    SelectedFiles,
    FlowProcessFile.Run(ThisRecord.ID)
)
```

**Flow:**
```
Trigger: When file created (SharePoint)
↓
Get file content
↓
HTTP: Call Azure Function
URL: https://<function-app>.azurewebsites.net/api/ParseHTML
Body: { "htmlContent": "@{body('Get_file_content')}" }
↓
Parse JSON: outputs('HTTP')['body']['sqlFormat']
↓
SQL: Execute SP (bank auto-detected or specified)
↓
Create item in SharePoint Results list
↓
Send email notification
```

---

## 📊 Data Flow Examples

### Format JSON untuk Power Apps

**Input dari HTML:**
```html
<TD>TRSF E-BANKING CR 0810/FTSCY/WS95031 455520.00 ELLA CAROLINE</TD>
```

**Output dari Parser (SQL Format):**
```json
{
  "TransactionID": 1,
  "Description": "TRSF E-BANKING CR 0810/FTSCY/WS95031 455520.00 ELLA CAROLINE"
}
```

**Output dari Stored Procedure:**
```json
{
  "TransactionID": 1,
  "Description": "TRSF E-BANKING CR 0810/FTSCY/WS95031 455520.00 ELLA CAROLINE",
  "CustomerName": "ELLA CAROLINE",
  "BTP": "2300014094",
  "MatchPercentage": 100.00,
  "Status": "EXCELLENT",
  "Label": "BEST"
}
```

**Display di Power Apps:**
```javascript
// Gallery Item
Title1.Text: ThisItem.Description
Subtitle1.Text: "Customer: " & ThisItem.CustomerName
Label1.Text: "BTP: " & ThisItem.BTP
Label2.Text: ThisItem.MatchPercentage & "%"
Label3.Text: ThisItem.Label

// Color indicator
Rectangle1.Fill: Switch(
    ThisItem.Status,
    "EXCELLENT", Color.Green,
    "GOOD", Color.Blue,
    Color.Gray
)
```

---

## 🎯 Best Practices

### Performance Optimization

1. **Batch transactions**
   - Jangan process 1-1 transaction
   - Group dalam batches of 50-100

2. **Cache results**
   - Store hasil matching di Collection
   - Refresh only when needed

3. **Async processing**
   - Untuk files besar, gunakan Flow background processing
   - Show progress indicator di Power Apps

### Error Handling

```javascript
// Power Apps
If(
    IsError(FlowProcessFile),
    Notify("Error processing file: " & FlowProcessFile.Error, NotificationType.Error),
    Notify("File processed successfully!", NotificationType.Success)
);
```

### Security

1. **File validation**
   - Validate file extension (.html only)
   - Check file size (max 5MB)
   - Scan for malicious content

2. **SQL Injection prevention**
   - Always use Stored Procedures
   - Never concatenate SQL strings
   - Validate input parameters

---

## 🧪 Testing Guide

### Test Scenario 1: Single Transaction

**Input:**
```
HTML dengan 1 transaksi TRSF
```

**Expected:**
- Parsing success
- BTP found
- Status = EXCELLENT
- Match percentage = 100%

### Test Scenario 2: Multiple Banks

**Input:**
```
HTML dengan mix: TRSF, BI-FAST, MANDIRI
```

**Expected:**
- Auto-detect bank per transaction
- Route to correct SP
- All matches found

### Test Scenario 3: No Match

**Input:**
```
Transaction dengan customer name tidak di master
```

**Expected:**
- Status = NO_MATCH
- Message = "Customer not found"
- Show suggestion untuk add new customer

---

## 📞 Troubleshooting

### Issue: Flow timeout

**Solusi:**
- Break large files into smaller chunks
- Use async processing
- Increase Flow timeout settings

### Issue: JSON parsing error

**Solusi:**
- Validate JSON with jsonlint.com
- Check for special characters
- Escape single quotes properly

### Issue: SP returns empty

**Solusi:**
- Check category filter in SP
- Verify master data exists
- Test SP directly in SSMS

---

## 🎉 Complete Example

### End-to-End Flow

1. **User uploads `0053061777.html`**
2. **Power Apps sends to Flow**
3. **Flow calls Azure Function**
4. **Azure Function parses HTML → JSON**
5. **Flow sends JSON to SQL**
6. **SQL runs `SP_TRSF_FindBTP_Batch`**
7. **SQL returns 43 matched transactions**
8. **Flow sends results back to Power Apps**
9. **Power Apps displays in Gallery**
10. **User can export to Excel**

---

## 📚 Additional Resources

- [Power Apps Documentation](https://docs.microsoft.com/en-us/powerapps/)
- [Power Automate Documentation](https://docs.microsoft.com/en-us/power-automate/)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)

---

**Version:** 1.0.0  
**Last Updated:** October 21, 2025  
**Status:** ✅ Ready for Implementation

