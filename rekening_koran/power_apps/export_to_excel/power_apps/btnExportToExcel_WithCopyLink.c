// =====================================================
// Export to Excel Button - WITH COPY LINK
// =====================================================
// Solusi: Tampilkan link/data yang bisa di-copy manual
// User bisa copy link dan paste di browser untuk download
// =====================================================

// Call Power Automate Flow
Set(varExportResult, Export_RekeningKoran_ToExcel.Run());

// Check result
If(
    !IsBlank(varExportResult.filecontent),
    // Success - Simpan data dan tampilkan link untuk copy
    Set(varDownloadData, varExportResult.filecontent);
    Set(varDownloadFileName, varExportResult.filename);
    Set(
        varDownloadLink,
        "data:text/csv;base64," & varExportResult.filecontent
    );
    // Tampilkan modal dengan link yang bisa di-copy
    Set(varShowDownloadModal, true);
    Notify(
        "✅ Export successful! " & varExportResult.rowcount & " rows. Click link below to download.",
        NotificationType.Success,
        5000
    ),
    // Error
    Notify("❌ Export failed", NotificationType.Error, 3000)
);

