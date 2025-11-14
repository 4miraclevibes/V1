// =====================================================
// Export to Excel Button - FINAL VERSION
// =====================================================
// Solusi paling sederhana untuk auto-download
// =====================================================

// Call Power Automate Flow
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

// Check result & trigger download
If(
    !IsBlank(varExportResult.filecontent),
    // Success - Set variables untuk HTML Text control
    Set(varDownloadData, varExportResult.filecontent);
    Set(varDownloadFileName, varExportResult.filename);
    // Toggle untuk trigger HTML Text control
    Set(varTriggerDownload, false);
    Set(varTriggerDownload, true);
    Notify("✅ Download started! " & varExportResult.rowcount & " rows", NotificationType.Success, 2000),
    // Error
    Notify("❌ Export failed", NotificationType.Error, 3000)
);

