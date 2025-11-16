// =====================================================
// Button 1: Generate SharePoint Link
// =====================================================
// Upload file ke SharePoint via flow, simpan SharePoint link
// =====================================================

// Call Power Automate Flow
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

// Check result & simpan SharePoint link
If(
    !IsBlank(varExportResult.sharePointLink),
    // Success - Simpan SharePoint link untuk download
    Set(varSharePointLink, varExportResult.sharePointLink);
    Set(varDownloadFileName, varExportResult.fileName);
    Set(varLinkReady, true);
    Notify(
        "✅ File ready! " & varExportResult.rowCount & " rows. Click Download button.",
        NotificationType.Success,
        3000
    ),
    // Error
    Set(varLinkReady, false);
    Notify("❌ Export failed", NotificationType.Error, 3000)
);

