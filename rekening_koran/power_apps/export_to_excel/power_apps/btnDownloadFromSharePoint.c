// =====================================================
// Button: Download dari SharePoint Link
// =====================================================
// Solusi untuk bypass CSP blob block
// Upload file ke SharePoint via Power Automate
// Download menggunakan Download() function dengan SharePoint link
// =====================================================

// Prepare filter parameters
// Format date untuk SQL Server: yyyy-MM-dd (format ISO yang kompatibel dengan TRY_CAST)
// SP akan handle waktu sendiri (StartDate >= dan EndDate <=)
Set(
    varStartDate,
    If(
        !IsBlank(StartDateInputExport.SelectedDate),
        Text(StartDateInputExport.SelectedDate, "yyyy-MM-dd"),
        ""
    )
);
Set(
    varEndDate,
    If(
        !IsBlank(EndDateInputExport.SelectedDate),
        Text(EndDateInputExport.SelectedDate, "yyyy-MM-dd"),
        ""
    )
);
Set(
    varBTPFilter,
    If(
        !IsBlank(BtpInputExport.Text),
        BtpInputExport.Text,
        ""
    )
);

// Call Power Automate Flow dengan parameter menggunakan format Record
// TROUBLESHOOTING: Jika body masih kosong, berarti Power Apps belum mengenali parameter flow
// Solusi:
// 1. Pastikan flow sudah di-PUBLISH di Power Automate (bukan hanya Save)
// 2. Hapus koneksi flow di Power Apps: File → App settings → Connections → Remove Export_RekeningKoran_ToExcel
// 3. Tambah kembali: Data → Power Automate → Pilih Export_RekeningKoran_ToExcel
// 4. Tutup dan buka kembali Power Apps Studio
// 5. Tunggu beberapa menit untuk sync metadata flow
Set(
    varExportResult,
    Export_RekeningKoran_ToExcel.Run({
        text: varStartDate,
        text_1: varEndDate,
        text_2: varBTPFilter
    })
);

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

