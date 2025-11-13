// =====================================================
// Export to Excel Button - With Filter Parameters
// =====================================================
// Purpose: Export data dengan filter (StartDate, EndDate, BTP)
// =====================================================

// Set loading state
Set(varExportLoading, true);
Set(varExportMessage, "⏳ Generating Excel file...");

// Prepare filter parameters
Set(
    varStartDate,
    If(
        !IsBlank(DatePickerStart.SelectedDate),
        Text(DatePickerStart.SelectedDate, "yyyy-MM-dd"),
        Blank()
    )
);
Set(
    varEndDate,
    If(
        !IsBlank(DatePickerEnd.SelectedDate),
        Text(DatePickerEnd.SelectedDate, "yyyy-MM-dd"),
        Blank()
    )
);
Set(
    varBTPFilter,
    If(
        !IsBlank(TextInputBTP.Text),
        TextInputBTP.Text,
        Blank()
    )
);

// Call Power Automate Flow dengan filter
Set(
    varExportResult,
    Export_RekeningKoran_ToExcel.Run(
        varStartDate,
        varEndDate,
        varBTPFilter
    )
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
        " rows exported" &
        If(
            !IsBlank(varStartDate) || !IsBlank(varEndDate) || !IsBlank(varBTPFilter),
            " (Filtered)",
            ""
        )
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

