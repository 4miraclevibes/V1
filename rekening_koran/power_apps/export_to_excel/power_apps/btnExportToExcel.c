// =====================================================
// Export to Excel Button - Power Apps Code
// =====================================================
// Purpose: Export data dari VW_REKENING_KORAN ke Excel
// Method: Call Power Automate Flow → Download CSV file
// Security: Credential database hanya di Power Automate
// =====================================================

// Set loading state
Set(varExportLoading, true);
Set(varExportMessage, "⏳ Generating Excel file...");

// Call Power Automate Flow
Set(
    varExportResult,
    Export_RekeningKoran_ToExcel.Run()
);

// Check result
If(
    !IsBlank(varExportResult.fileContent),
    // Success - Download file
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "✅ Export successful! " & 
        varExportResult.rowCount & 
        " rows exported"
    );
    // Download CSV file
    Download(
        varExportResult.fileContent,
        varExportResult.fileName,
        "text/csv"
    ),
    // Error handling
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "❌ Export failed: " & 
        If(
            !IsBlank(varExportResult.error),
            varExportResult.error,
            "Unknown error. Please try again."
        )
    );
    // Show error notification
    Notify(
        varExportMessage,
        NotificationType.Error,
        5000
    )
);

