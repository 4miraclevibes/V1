// =====================================================
// Export to Excel Button - SHOW LINK VERSION
// =====================================================
// Solusi sederhana: Tampilkan link yang bisa di-copy
// User copy link → paste di browser → download
// =====================================================

// Call Power Automate Flow
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

// Check result
If(
    !IsBlank(varExportResult.filecontent),
    // Success - Simpan link untuk ditampilkan
    Set(
        varDownloadLink,
        "data:text/csv;base64," & varExportResult.filecontent
    );
    Set(varDownloadFileName, varExportResult.filename);
    Set(varShowLink, true);
    Notify(
        "✅ Export successful! " & varExportResult.rowcount & " rows. Copy link below.",
        NotificationType.Success,
        5000
    ),
    // Error
    Notify("❌ Export failed", NotificationType.Error, 3000)
);

