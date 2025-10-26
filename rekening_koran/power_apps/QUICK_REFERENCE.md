# ⚡ Power Apps - Quick Reference Card

## **🎯 Core Flow**

```
HTML → JSON → Power Apps → Power Automate → SQL SP → BTP_REVIEW → Review & Approve
```

---

## **📱 Power Apps - Key Formulas**

### **Upload & Process**

```powerappsfx
// Read JSON from attachment
Set(varJSONString, Concat(First(attFileUpload.Attachments), Text(Value)));

// Call Flow
Set(varResult, BTPProcessBankStatement.Run(varJSONString, User().Email));

// Navigate to review
Navigate(ReviewScreen, ScreenTransition.Fade);
```

### **Gallery - Delegation-Safe Filter**

```powerappsfx
// Show only transactions needing review
Filter(
    BTP_REVIEW,
    Status = "NO_MATCH" || 
    Status = "NO_PATTERN" || 
    Status = "UNKNOWN_BANK" || 
    Status = "LOW"
)
```

### **Approve Transaction**

```powerappsfx
Patch(
    BTP_REVIEW,
    LookUp(BTP_REVIEW, ID = ThisItem.ID),
    {
        IsApproved: true,
        ApprovedBy: User().Email,
        ApprovedAt: Now(),
        BTP: txtBTP.Text  // If edited
    }
);
Refresh(BTP_REVIEW);
```

---

## **🔄 Power Automate - Flow Structure**

```
1. Trigger: PowerApps (V2)
   ↓
2. Initialize Variables (BatchID, JSON, User)
   ↓
3. Execute SQL SP: SP_MASTER_FindBTP_SaveToReview
   - @TransactionsJSON
   - @BatchID
   - @UploadedBy
   ↓
4. Parse JSON Results (2 result sets)
   ↓
5. Respond to Power Apps
   - Success: true/false
   - BatchID
   - TotalInput, TotalSaved
   - Message
```

---

## **🗄️ SQL Server - Key Stored Procedure**

```sql
EXEC SP_MASTER_FindBTP_SaveToReview
    @TransactionsJSON = N'[...]',
    @BatchID = 'BATCH_20251024_095440',
    @UploadedBy = 'finance@company.com';
```

**Returns:**
- Result Set 1: All transaction details
- Result Set 2: Batch summary

---

## **📊 Status Values & Colors**

| Status | Color | Meaning | Action |
|--------|-------|---------|--------|
| `EXCELLENT` | 🟢 Green | Perfect match | Auto-approve OK |
| `GOOD` | 🟢 DarkGreen | High confidence | Auto-approve OK |
| `FAIR` | 🟠 Orange | Medium confidence | Quick review |
| `LOW` | 🔴 Red | Low confidence | Manual verify |
| `NO_MATCH` | 🔴 DarkRed | Customer not in master | Add to master |
| `NO_PATTERN` | 🟣 Purple | Name extraction failed | Fix extraction |
| `UNKNOWN_BANK` | ⚪ Gray | Bank not recognized | Categorize |

---

## **🎨 Color Coding Formula**

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

---

## **📝 Notes Auto-Population**

```
NO_PATTERN    → "Customer name tidak ditemukan di description..."
NO_MATCH      → "Customer '[name]' belum ada di master data..."
LOW           → "Match confidence rendah (X%)..."
Multiple BTP  → "Ditemukan X opsi BTP..."
UNKNOWN types → Specific message per type (SETORAN, DB OTOMATIS, etc.)
```

---

## **🔍 Common Filters**

### **Needs Review**
```powerappsfx
Filter(BTP_REVIEW, Status In ["NO_MATCH", "NO_PATTERN", "UNKNOWN_BANK", "LOW"])
```

### **Approved**
```powerappsfx
Filter(BTP_REVIEW, IsApproved = true)
```

### **Pending Approval**
```powerappsfx
Filter(BTP_REVIEW, IsApproved = false)
```

### **Specific Bank**
```powerappsfx
Filter(BTP_REVIEW, BankType = "TRSF")
```

### **By Date Range**
```powerappsfx
Filter(BTP_REVIEW, 
    CreatedAt >= DateValue("2025-10-01") && 
    CreatedAt <= DateValue("2025-10-31")
)
```

---

## **📊 Statistics Formulas**

```powerappsfx
// Total transactions
CountRows(BTP_REVIEW)

// Needs review
CountRows(Filter(BTP_REVIEW, Status In ["NO_MATCH", "NO_PATTERN", "UNKNOWN_BANK", "LOW"]))

// Approved count
CountRows(Filter(BTP_REVIEW, IsApproved = true))

// Average match percentage
Average(Filter(BTP_REVIEW, !IsBlank(MatchPercentage)), MatchPercentage)

// By bank type
GroupBy(BTP_REVIEW, "BankType", "Count")
```

---

## **⚠️ Delegation Best Practices**

### **✅ DO:**
```powerappsfx
// Use simple comparisons
Filter(BTP_REVIEW, Status = "NO_MATCH")

// Use OR with ||
Filter(BTP_REVIEW, Status = "NO_MATCH" || Status = "LOW")

// Use In for multiple values
Filter(BTP_REVIEW, Status In ["NO_MATCH", "LOW"])
```

### **❌ DON'T:**
```powerappsfx
// Avoid IsBlank on SQL columns
Filter(BTP_REVIEW, IsBlank(BTP))  ❌

// Avoid complex functions
Filter(BTP_REVIEW, Left(CustomerName, 2) = "PT")  ❌

// Avoid nested Filters
Filter(Filter(BTP_REVIEW, ...), ...)  ❌
```

### **🔧 WORKAROUND:**
```powerappsfx
// Instead of IsBlank(BTP), use Status
Filter(BTP_REVIEW, Status In ["NO_MATCH", "NO_PATTERN", "UNKNOWN_BANK"])
```

---

## **🚀 Performance Tips**

1. **Limit data with FirstN**
   ```powerappsfx
   FirstN(Sort(BTP_REVIEW, CreatedAt, Descending), 500)
   ```

2. **Use specific filters**
   ```powerappsfx
   // Good ✅
   Filter(BTP_REVIEW, BatchID = "BATCH_20251024_095440")
   
   // Bad ❌
   Filter(BTP_REVIEW, true)  // Gets everything
   ```

3. **Cache frequently used data**
   ```powerappsfx
   // On Screen Visible
   ClearCollect(colRecentBatches, FirstN(BTP_REVIEW, 1000));
   ```

4. **Use Concurrent for multiple queries**
   ```powerappsfx
   Concurrent(
       Set(varTotal, CountRows(BTP_REVIEW)),
       Set(varNeedsReview, CountRows(Filter(BTP_REVIEW, Status = "NO_MATCH"))),
       Set(varApproved, CountRows(Filter(BTP_REVIEW, IsApproved = true)))
   );
   ```

---

## **🐛 Common Issues & Solutions**

### **Issue: Delegation Warning**
**Solution:** Use Status column instead of IsBlank(BTP)

### **Issue: Flow Timeout**
**Solution:** 
- Process in batches (max 1000 transactions per call)
- Increase Flow timeout in settings
- Use async pattern

### **Issue: Gallery Not Refreshing**
**Solution:**
```powerappsfx
Refresh(BTP_REVIEW);
// or
Reset(galReview);
```

### **Issue: NULL vs Empty String**
**Solution:**
```powerappsfx
// Don't compare with ""
If(BTP = "", ..., ...)  ❌

// Use Status instead
If(Status = "NO_MATCH", ..., ...)  ✅
```

---

## **📞 Support Resources**

- **Full Guide:** `power_apps/STEP_BY_STEP_GUIDE.md`
- **Notes Guide:** `stored_procedures/MASTER/NOTES_COLUMN_GUIDE.md`
- **Gallery Filter:** `power_apps/reviewGallery/btpFilterBtn.c`
- **Test Data:** `html_to_json_converter/examples/test_200_rows.json`

---

**Quick Start:**
1. Deploy SQL SP
2. Create Power Automate Flow
3. Build Power Apps screens (Upload → Review → Dashboard)
4. Test with `test_200_rows.json`
5. Deploy to production!

**Estimated Setup Time:** 2-3 hours ⚡

