// =====================================================
// Button: Export to Excel (.xlsx)
// =====================================================
// Export data ke Excel file yang benar-benar bisa dibuka di Excel
// =====================================================

// Call Power Automate Flow
Set(varExportResult, Export_RekeningKoran_ToExcel_XLSX.Run());

// Check result & download Excel file dari SharePoint link
If(
    !IsBlank(varExportResult.sharepointlink),
    // Success - Download Excel file dari SharePoint link
    Download(varExportResult.sharepointlink);
    Notify(
        "✅ Excel file downloaded! " & varExportResult.rowcount & " rows exported.",
        NotificationType.Success,
        3000
    ),
    // Error
    Notify("❌ Export failed. Please try again.", NotificationType.Error, 3000)
);

