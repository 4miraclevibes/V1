# 📱 Power Apps - Step by Step Implementation Guide

## **Overview: HTML Bank Statement → BTP_REVIEW Table**

```
HTML File (0053061777.html)
    ↓
[HTML to JSON Converter] (JavaScript)
    ↓
JSON File (statement_for_sp.json)
    ↓
[Power Apps - Upload & Process]
    ↓
[Power Automate - Call SQL SP]
    ↓
SQL Server (SP_MASTER_FindBTP_SaveToReview)
    ↓
BTP_REVIEW Table (Finance Review)
    ↓
[Power Apps - Review & Approve]
    ↓
Final Table (Approved Transactions)
```

---

## **🎯 STEP 1: HTML to JSON Conversion**

### **Option A: Manual Conversion (Web-based)**

1. Buka `html_to_json_converter/converter.html` di browser
2. Drag & drop file HTML bank statement (e.g., `0053061777.html`)
3. Click **"Download for Stored Procedure"**
4. Save sebagai `statement_for_sp.json`

### **Option B: Automatic Conversion (if integrated)**

- Upload HTML directly ke Power Apps
- Azure Function converts HTML → JSON
- JSON automatically sent to SP

**For now, gunakan Option A (manual)** untuk testing! ✅

---

## **🎯 STEP 2: Power Apps - Upload Screen**

### **2.1: Create Upload Screen**

**Components Needed:**
1. **AttachmentControl** → Upload JSON file
2. **Button (btnProcess)** → Trigger processing
3. **Label (lblStatus)** → Show status
4. **Gallery (galPreview)** → Preview JSON data (optional)

### **2.2: Button (btnProcess) - OnSelect Code**

```powerappsfx
// Step 1: Read uploaded JSON file
ClearCollect(
    colTransactions,
    JSON(
        First(attFileUpload.Attachments).Value,
        JSONFormat.IncludeBinaryData
    )
);

// Step 2: Prepare data for Power Automate
Set(
    varTransactionsJSON,
    JSON(colTransactions)
);

// Step 3: Show loading message
UpdateContext({locLoading: true});
Set(varStatus, "⏳ Processing " & CountRows(colTransactions) & " transactions...");

// Step 4: Call Power Automate Flow
// (Will be configured in Step 3)
```

**Alternative (Simpler):**
```powerappsfx
// Direct approach - let Power Automate handle JSON
Set(
    varJSONString,
    Concat(
        First(attFileUpload.Attachments),
        Text(Value)
    )
);

// Call Flow
Set(varStatus, "⏳ Sending to database...");
// Flow trigger here (Step 3)
```

---

## **🎯 STEP 3: Power Automate Flow**

### **3.1: Create New Flow**

**Name:** `BTP_ProcessBankStatement`

**Trigger:** `PowerApps (V2)`

**Input Parameters:**
- `TransactionsJSON` (String) - dari Power Apps
- `UploadedBy` (String) - User email

### **3.2: Flow Steps**

#### **Action 1: Initialize Variables**

```
Variable Name: varBatchID
Type: String
Value: concat('BATCH_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'))
```

```
Variable Name: varTransactionsJSON
Type: String
Value: @triggerBody()['text'] (from Power Apps input)
```

```
Variable Name: varUploadedBy
Type: String
Value: @triggerBody()['text_1'] (from Power Apps input)
```

#### **Action 2: Execute SQL Stored Procedure**

**Connection:** SQL Server

**Procedure Name:** `[dbo].[SP_MASTER_FindBTP_SaveToReview]`

**Parameters:**
- `@TransactionsJSON` = `@variables('varTransactionsJSON')`
- `@BatchID` = `@variables('varBatchID')`
- `@UploadedBy` = `@variables('varUploadedBy')`

**Output:** Returns result set + summary

#### **Action 3: Parse JSON (Result Set 1 - Details)**

**Content:** `@body('Execute_stored_procedure')?['ResultSets']?['Table1']`

**Schema:**
```json
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "ID": {"type": "integer"},
            "BatchID": {"type": "string"},
            "TransactionID": {"type": "integer"},
            "TransactionDate": {"type": "string"},
            "Description": {"type": "string"},
            "CustomerName": {"type": "string"},
            "BTP": {"type": "string"},
            "MatchPercentage": {"type": "number"},
            "Status": {"type": "string"},
            "Message": {"type": "string"},
            "BankType": {"type": "string"},
            "Notes": {"type": "string"},
            "IsApproved": {"type": "boolean"}
        }
    }
}
```

#### **Action 4: Parse JSON (Result Set 2 - Summary)**

**Content:** `@body('Execute_stored_procedure')?['ResultSets']?['Table2']`

**Schema:**
```json
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "BatchID": {"type": "string"},
            "UploadedBy": {"type": "string"},
            "TotalInput": {"type": "integer"},
            "TotalSaved": {"type": "integer"},
            "CompletedAt": {"type": "string"},
            "Status": {"type": "string"}
        }
    }
}
```

#### **Action 5: Respond to Power Apps**

**Response Body:**
```json
{
    "Success": true,
    "BatchID": "@{variables('varBatchID')}",
    "TotalInput": "@{first(body('Parse_JSON_Summary'))?['TotalInput']}",
    "TotalSaved": "@{first(body('Parse_JSON_Summary'))?['TotalSaved']}",
    "Message": "Successfully processed @{first(body('Parse_JSON_Summary'))?['TotalSaved']} transactions"
}
```

---

## **🎯 STEP 4: Power Apps - Process & Show Results**

### **4.1: Button (btnProcess) - Complete OnSelect Code**

```powerappsfx
// Step 1: Prepare JSON from uploaded file
Set(
    varJSONString,
    Concat(
        First(attFileUpload.Attachments),
        Text(Value)
    )
);

// Step 2: Show loading
UpdateContext({locLoading: true});
Set(varStatus, "⏳ Processing...");

// Step 3: Call Power Automate Flow
Set(
    varFlowResult,
    BTPProcessBankStatement.Run(
        varJSONString,                  // TransactionsJSON
        User().Email                    // UploadedBy
    )
);

// Step 4: Handle response
If(
    varFlowResult.Success,
    // Success
    Set(varStatus, "✅ " & varFlowResult.Message);
    Set(varBatchID, varFlowResult.BatchID);
    Navigate(ReviewScreen, ScreenTransition.Fade),
    // Error
    Set(varStatus, "❌ Error: " & varFlowResult.Message)
);

UpdateContext({locLoading: false});
```

### **4.2: Status Label - Text Property**

```powerappsfx
If(
    locLoading,
    "⏳ Processing " & CountRows(colTransactions) & " transactions...",
    varStatus
)
```

---

## **🎯 STEP 5: Power Apps - Review Screen**

### **5.1: Components**

1. **Gallery (galReview)** - Show BTP_REVIEW data
2. **Toggle (tglFilterNeedsReview)** - Filter problematic transactions
3. **Dropdown (ddFilterStatus)** - Filter by Status
4. **Button (btnApprove)** - Approve selected transaction
5. **TextInput (txtBTP)** - Edit BTP if needed
6. **Label (lblNotes)** - Show Notes/guidance

### **5.2: Gallery (galReview) - Items Property**

**Using existing code from `btpFilterBtn.c`:**

```powerappsfx
// Delegation-safe: Gunakan Status column untuk filter
FirstN(
    Sort(
        If(
            tglFilterNeedsReview.Value,
            // Filter transaksi yang perlu review (NO_MATCH, NO_PATTERN, UNKNOWN_BANK, LOW)
            Filter(
                BTP_REVIEW,
                Status = "NO_MATCH" || 
                Status = "NO_PATTERN" || 
                Status = "UNKNOWN_BANK" || 
                Status = "LOW"
            ),
            BTP_REVIEW
        ),
        CreatedAt,
        SortOrder.Descending
    ),
    200000
)
```

### **5.3: Gallery Template - Display Fields**

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ 🏦 [BankType]  |  📅 [TransactionDate]  |  🔢 [TrxID]  │
│ Description: [First 60 chars...]                        │
│ 👤 Customer: [CustomerName]                             │
│ 💳 BTP: [BTP]  |  📊 Match: [MatchPercentage]%         │
│ 🚦 Status: [Status]  |  🏷️ [Label]                     │
│ 📝 Notes: [Notes]                                       │
│                              [✅ Approve]  [✏️ Edit]   │
└─────────────────────────────────────────────────────────┘
```

**Label (lblDescription) - Text:**
```powerappsfx
Left(ThisItem.Description, 60) & If(Len(ThisItem.Description) > 60, "...", "")
```

**Label (lblStatus) - Text:**
```powerappsfx
ThisItem.Status
```

**Label (lblStatus) - Color:**
```powerappsfx
Switch(
    ThisItem.Status,
    "EXCELLENT", Color.Green,
    "GOOD", Color.DarkGreen,
    "FAIR", Color.Orange,
    "LOW", Color.Red,
    "NO_MATCH", Color.DarkRed,
    "NO_PATTERN", Color.Purple,
    "UNKNOWN_BANK", Color.Gray,
    Color.Black
)
```

**Label (lblNotes) - Text:**
```powerappsfx
If(
    !IsBlank(ThisItem.Notes),
    "📝 " & ThisItem.Notes,
    ""
)
```

**Label (lblNotes) - Visible:**
```powerappsfx
!IsBlank(ThisItem.Notes)
```

### **5.4: Button (btnApprove) - OnSelect**

```powerappsfx
// Update BTP_REVIEW table
Patch(
    BTP_REVIEW,
    LookUp(BTP_REVIEW, ID = ThisItem.ID),
    {
        IsApproved: true,
        ApprovedBy: User().Email,
        ApprovedAt: Now(),
        BTP: If(
            !IsBlank(txtBTP.Text),
            txtBTP.Text,  // Use edited BTP
            ThisItem.BTP  // Use original BTP
        ),
        Notes: ThisItem.Notes & " | Approved by " & User().Email & " at " & Text(Now(), "yyyy-mm-dd hh:mm:ss")
    }
);

// Show notification
Notify("✅ Transaction approved!", NotificationType.Success);

// Refresh gallery
Refresh(BTP_REVIEW);
```

### **5.5: TextInput (txtBTP) - Default Property**

```powerappsfx
ThisItem.BTP
```

**Visible:**
```powerappsfx
// Show only if BTP is blank or status requires manual input
IsBlank(ThisItem.BTP) || 
ThisItem.Status = "NO_MATCH" || 
ThisItem.Status = "LOW"
```

---

## **🎯 STEP 6: Power Apps - Statistics Dashboard**

### **6.1: Components**

1. **Label (lblTotalTransactions)** - Total count
2. **Label (lblNeedsReview)** - Count needs review
3. **Label (lblApproved)** - Count approved
4. **Chart (chrtByBankType)** - Distribution by bank
5. **Chart (chrtByStatus)** - Distribution by status

### **6.2: Label (lblTotalTransactions) - Text**

```powerappsfx
"Total: " & CountRows(BTP_REVIEW)
```

### **6.3: Label (lblNeedsReview) - Text**

```powerappsfx
"⚠️ Needs Review: " & CountRows(
    Filter(
        BTP_REVIEW,
        Status = "NO_MATCH" || 
        Status = "NO_PATTERN" || 
        Status = "UNKNOWN_BANK" || 
        Status = "LOW"
    )
)
```

### **6.4: Label (lblApproved) - Text**

```powerappsfx
"✅ Approved: " & CountRows(Filter(BTP_REVIEW, IsApproved = true))
```

### **6.5: Chart (chrtByBankType) - Items**

```powerappsfx
GroupBy(BTP_REVIEW, "BankType", "Count")
```

---

## **🎯 STEP 7: Testing Flow**

### **Test Scenario 1: Small Dataset (10 transactions)**

1. Prepare test JSON with 10 transactions
2. Upload via Power Apps
3. Click "Process"
4. Verify:
   - ✅ Flow runs successfully
   - ✅ Data appears in BTP_REVIEW
   - ✅ Notes are populated
   - ✅ Status is correct

### **Test Scenario 2: Medium Dataset (200 transactions)**

Use `test_200_rows.json` from earlier:
1. Upload `test_200_rows.json`
2. Process
3. Verify:
   - ✅ All 200 rows saved (TotalInput = TotalSaved = 200)
   - ✅ UNKNOWN transactions have Notes
   - ✅ Filter toggle works
   - ✅ No delegation warnings

### **Test Scenario 3: Full Dataset (12,000+ transactions)**

Use full `statement_for_sp.json`:
1. Upload file
2. Process (may take longer)
3. Verify:
   - ✅ Performance is acceptable
   - ✅ Gallery loads without timeout
   - ✅ Delegation still works

---

## **🎯 STEP 8: Error Handling**

### **8.1: Power Automate - Error Actions**

After each action, add **Configure run after** → **has failed**:

```json
{
    "Success": false,
    "Message": "Error: @{outputs('Execute_stored_procedure')?['body']?['message']}",
    "ErrorDetails": "@{result('Execute_stored_procedure')}"
}
```

### **8.2: Power Apps - Error Display**

```powerappsfx
If(
    !varFlowResult.Success,
    Notify(
        "❌ Error: " & varFlowResult.Message,
        NotificationType.Error,
        5000
    );
    Set(varStatus, "❌ " & varFlowResult.Message)
)
```

---

## **🎯 STEP 9: Deployment Checklist**

### **SQL Server:**
- [ ] Deploy `SP_MASTER_FindBTP_SaveToReview.sql`
- [ ] Create `BTP_REVIEW` table
- [ ] Test SP with sample JSON
- [ ] Verify all 20 banks are processed
- [ ] Check Notes auto-population

### **Power Automate:**
- [ ] Create Flow `BTP_ProcessBankStatement`
- [ ] Test connection to SQL Server
- [ ] Test with 10 transactions
- [ ] Test with 200 transactions
- [ ] Verify error handling

### **Power Apps:**
- [ ] Create Upload Screen
- [ ] Create Review Screen
- [ ] Create Dashboard Screen
- [ ] Test file upload
- [ ] Test Flow trigger
- [ ] Test Gallery filters
- [ ] Test Approve functionality
- [ ] Verify delegation warnings are resolved

---

## **📊 Expected Results**

### **For 200 transactions test:**

```
BatchID: BATCH_20251024_095440
UploadedBy: finance@company.com
TotalInput: 200
TotalSaved: 200  ✅

Breakdown:
- TRSF: ~91 transactions
- BIFAST: ~16 transactions
- MANDIRI: ~0 transactions (in this sample)
- UNKNOWN: ~73 transactions (with smart Notes)
- Other banks: ~20 transactions
```

### **Notes populated for:**
- NO_MATCH: "Customer '[name]' belum ada di master data..."
- NO_PATTERN: "Customer name tidak ditemukan..."
- UNKNOWN_BANK: Specific message per transaction type
- LOW: "Match confidence rendah..."
- Multiple BTP: "Ditemukan X opsi BTP..."

---

## **🔗 Related Files**

- HTML Converter: `html_to_json_converter/converter.html`
- Test Data: `html_to_json_converter/examples/test_200_rows.json`
- Full Data: `html_to_json_converter/examples/statement_for_sp.json`
- SP: `stored_procedures/MASTER/SP_MASTER_FindBTP_SaveToReview.sql`
- Gallery Filter: `power_apps/reviewGallery/btpFilterBtn.c`
- Notes Guide: `stored_procedures/MASTER/NOTES_COLUMN_GUIDE.md`

---

**Last Updated:** 2025-10-24  
**Status:** ✅ Ready for Implementation  
**Next:** Start with STEP 2 - Create Power Apps Upload Screen

