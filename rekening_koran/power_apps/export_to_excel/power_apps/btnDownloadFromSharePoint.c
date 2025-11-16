// =====================================================
// Button: Download dari SharePoint Link
// =====================================================
// Solusi untuk bypass CSP blob block
// Upload file ke SharePoint via Power Automate
// Download menggunakan Download() function dengan SharePoint link
// =====================================================

// Call Power Automate Flow
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

// Check result & download dari SharePoint link
// Note: Property name sesuai dengan output flow body (lowercase)
If(
    !IsBlank(varExportResult.sharepointlink),
    // Success - Download dari SharePoint link
    Download(varExportResult.sharepointlink);
    Notify(
        "✅ Download started! " & varExportResult.rowcount & " rows exported.",
        NotificationType.Success,
        3000
    ),
    // Error
    Notify("❌ Export failed. Please try again.", NotificationType.Error, 3000)
);

