# 📚 Examples - Export to Excel

## 🎯 Use Cases

### Example 1: Simple Export (All Data)

**Power Apps Button:**
```powerappsfx
Set(varResult, Export_RekeningKoran_ToExcel.Run());
Download(varResult.fileContent, varResult.fileName, "text/csv");
```

**Result:** Export semua data dari view

---

### Example 2: Export dengan Filter Date Range

**Power Apps:**
```powerappsfx
Set(
    varResult,
    Export_RekeningKoran_ToExcel.Run(
        Text(DatePickerStart.SelectedDate, "yyyy-MM-dd"),
        Text(DatePickerEnd.SelectedDate, "yyyy-MM-dd"),
        Blank()
    )
);
Download(varResult.fileContent, varResult.fileName, "text/csv");
```

**Power Automate SQL Query:**
```sql
DECLARE @StartDate DATETIME = TRY_CAST('@{triggerBody()?['StartDate']}' AS DATETIME);
DECLARE @EndDate DATETIME = TRY_CAST('@{triggerBody()?['EndDate']}' AS DATETIME);

SELECT * FROM VW_REKENING_KORAN
WHERE 
    (@StartDate IS NULL OR trx_date >= @StartDate)
    AND (@EndDate IS NULL OR trx_date <= @EndDate)
ORDER BY id DESC
```

---

### Example 3: Export dengan Filter BTP

**Power Apps:**
```powerappsfx
Set(
    varResult,
    Export_RekeningKoran_ToExcel.Run(
        Blank(),
        Blank(),
        TextInputBTP.Text
    )
);
Download(varResult.fileContent, varResult.fileName, "text/csv");
```

---

### Example 4: Export dengan Loading Indicator

**Power Apps:**
```powerappsfx
// Show loading
Set(varExportLoading, true);
Set(varExportMessage, "⏳ Exporting...");

// Export
Set(varResult, Export_RekeningKoran_ToExcel.Run());

// Hide loading
Set(varExportLoading, false);

// Check result
If(
    !IsBlank(varResult.fileContent),
    Set(varExportMessage, "✅ Export successful!");
    Download(varResult.fileContent, varResult.fileName, "text/csv"),
    Set(varExportMessage, "❌ Export failed!");
    Notify("Export failed", NotificationType.Error)
);
```

**Label Text:**
```powerappsfx
If(varExportLoading, "⏳ Exporting...", varExportMessage)
```

---

### Example 5: Export Multiple Views

**Flow 1: Export Rekening Koran**
```powerappsfx
Set(varResult, Export_RekeningKoran_ToExcel.Run());
Download(varResult.fileContent, varResult.fileName, "text/csv");
```

**Flow 2: Export BTP Review**
```powerappsfx
Set(varResult, Export_BTPReview_ToExcel.Run());
Download(varResult.fileContent, varResult.fileName, "text/csv");
```

**Flow 3: Export Customer Master**
```powerappsfx
Set(varResult, Export_CustomerMaster_ToExcel.Run());
Download(varResult.fileContent, varResult.fileName, "text/csv");
```

---

### Example 6: Export dengan Error Handling

**Power Apps:**
```powerappsfx
// Try export
Set(varResult, Export_RekeningKoran_ToExcel.Run());

// Check status
If(
    varResult.status = "success",
    // Success
    Set(varExportMessage, "✅ Export successful!");
    Download(varResult.fileContent, varResult.fileName, "text/csv"),
    // Error
    Set(varExportMessage, "❌ Export failed: " & varResult.error);
    Notify(varExportMessage, NotificationType.Error, 5000)
);
```

**Power Automate Flow (with error handling):**
```
1. Execute SQL Query
   → Configure run after: is successful, has failed
   
2. If successful:
   → Parse JSON
   → Create CSV
   → Respond with success
   
3. If failed:
   → Compose error message
   → Respond with error status
```

---

### Example 7: Export dengan Progress Bar

**Power Apps:**
```powerappsfx
// Initialize progress
Set(varExportProgress, 0);

// Export
Set(varResult, Export_RekeningKoran_ToExcel.Run());

// Update progress
Set(varExportProgress, 50);

// Process result
If(!IsBlank(varResult.fileContent),
    Set(varExportProgress, 100);
    Download(varResult.fileContent, varResult.fileName, "text/csv")
);
```

**Progress Bar Value:**
```powerappsfx
varExportProgress / 100
```

---

### Example 8: Export ke SharePoint (Alternative)

**Power Automate Flow:**
```
1. Execute SQL Query
2. Parse JSON
3. Create CSV
4. Create file in SharePoint
5. Return file URL
```

**Power Apps:**
```powerappsfx
Set(varResult, Export_RekeningKoran_ToSharePoint.Run());
Launch(varResult.fileUrl);
```

---

### Example 9: Batch Export (Multiple Files)

**Power Apps:**
```powerappsfx
// Export Rekening Koran
Set(varRK, Export_RekeningKoran_ToExcel.Run());
Download(varRK.fileContent, varRK.fileName, "text/csv");

// Wait 1 second
Set(varWait, 1);

// Export BTP Review
Set(varBTP, Export_BTPReview_ToExcel.Run());
Download(varBTP.fileContent, varBTP.fileName, "text/csv");
```

---

### Example 10: Export dengan Custom Format

**Power Automate Flow:**
```
1. Execute SQL Query
2. Parse JSON
3. Apply to each row:
   → Format date: formatDateTime(item()['trx_date'], 'dd/MM/yyyy')
   → Format number: formatNumber(item()['credit'], 'N2')
4. Create CSV
5. Convert to Base64
6. Respond
```

---

## 🔧 Advanced Examples

### Export dengan Pagination

**Power Automate Flow:**
```sql
-- Get total count
SELECT COUNT(*) as TotalRows FROM VW_REKENING_KORAN

-- Get page 1 (first 1000 rows)
SELECT TOP 1000 * FROM VW_REKENING_KORAN ORDER BY id DESC

-- Get page 2 (next 1000 rows)
SELECT * FROM VW_REKENING_KORAN 
WHERE id < (SELECT MIN(id) FROM (SELECT TOP 1000 id FROM VW_REKENING_KORAN ORDER BY id DESC) AS t)
ORDER BY id DESC
```

---

### Export dengan Custom Columns

**Power Automate SQL Query:**
```sql
SELECT 
    [id] AS 'ID',
    FORMAT([trx_date], 'dd/MM/yyyy') AS 'Transaction Date',
    FORMAT([created_at], 'dd/MM/yyyy HH:mm') AS 'Created At',
    FORMAT([credit], 'N2') AS 'Credit Amount',
    [btp] AS 'BTP Code',
    [desc] AS 'Description'
FROM VW_REKENING_KORAN
ORDER BY [id] DESC
```

---

## 📝 Notes

1. **File Format:**
   - CSV: Simple, universal support
   - Excel: Better formatting, but more complex

2. **Performance:**
   - Small data (<1000 rows): Fast
   - Medium data (1000-10000 rows): Acceptable
   - Large data (>10000 rows): Consider pagination

3. **Security:**
   - Always use Power Automate (no direct DB connection)
   - Credential hanya di Power Automate
   - User tidak pernah lihat SQL credentials

---

**Need more examples?** → Check [README.md](./README.md) untuk detail lengkap!

