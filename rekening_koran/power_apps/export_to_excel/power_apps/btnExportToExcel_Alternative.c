// =====================================================
// Export to Excel Button - Alternative Method
// =====================================================
// Jika Launch() masih error, gunakan method ini dengan HTML Text control
// =====================================================

// Set loading state
Set(varExportLoading, true);
Set(varExportMessage, "⏳ Generating file...");

// Call Power Automate Flow
Set(
    varExportResult,
    Export_RekeningKoran_ToExcel.Run()
);

// Check result
If(
    !IsBlank(varExportResult.filecontent),
    // Success - Prepare download
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "✅ Export successful! " & 
        varExportResult.rowcount & 
        " rows exported"
    );
    // Simpan download link ke variable
    Set(
        varDownloadLink,
        "data:text/csv;base64," & varExportResult.filecontent
    );
    // Trigger download dengan HTML Text control
    // (HTML Text control akan auto-trigger download saat OnChange)
    Set(varTriggerDownload, true),
    // Error handling
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "❌ Export failed. Please try again."
    );
    Notify(
        varExportMessage,
        NotificationType.Error,
        5000
    )
);

// =====================================================
// SETUP HTML TEXT CONTROL:
// =====================================================
// 1. Insert → HTML Text control
// 2. Name: htmlDownloadLink
// 3. HTMLText property:
//    If(
//        varTriggerDownload,
//        "<a href='" & varDownloadLink & "' download='" & varExportResult.filename & "'>Download</a><script>document.querySelector('a').click();</script>",
//        ""
//    )
// 4. Reset varTriggerDownload setelah download:
//    Set(varTriggerDownload, false)
// =====================================================

