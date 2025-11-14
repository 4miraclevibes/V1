// =====================================================
// Export to Excel Button - Power Apps Code
// =====================================================
// Purpose: Export data dari VW_MP_REKENING_KORAN ke CSV/Excel
// Method: Call Power Automate Flow → Download CSV file
// Security: Credential database hanya di Power Automate
// Note: File CSV bisa langsung dibuka di Excel
// =====================================================

// Set loading state
Set(varExportLoading, true);
Set(varExportMessage, "⏳ Generating file...");

// Call Power Automate Flow
Set(
    varExportResult,
    Export_RekeningKoran_ToExcel.Run()
);

// Debug: Show notification untuk check flow result
Notify(
    "Flow result: filecontent blank = " & IsBlank(varExportResult.filecontent) & 
    ", rowcount = " & varExportResult.rowcount,
    NotificationType.Information,
    3000
);

// Check result
If(
    !IsBlank(varExportResult.filecontent),
    // Success - Download file menggunakan Launch dengan data URI
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "✅ Export successful! " & 
        varExportResult.rowcount & 
        " rows exported. Opening file..."
    );
    // Launch data URI - browser akan buka file, user bisa save manual
    Launch("data:text/csv;base64," & varExportResult.filecontent),
    // Error handling
    Set(varExportLoading, false);
    Set(
        varExportMessage,
        "❌ Export failed. filecontent is blank. Check flow run history."
    );
    // Show error notification
    Notify(
        varExportMessage,
        NotificationType.Error,
        5000
    )
);

