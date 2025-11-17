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

// DEBUG: Pastikan kontrol input benar-benar ada dan mengambil nilai yang benar
// Jika masih error, cek nama kontrol: StartDateInputExport, EndDateInputExport, BtpInputExport

Set(
    varStartDate,
    If(
        !IsBlank(StartDateInputExport.SelectedDate),
        // Format: yyyy-MM-dd (contoh: 2025-01-03)
        Year(StartDateInputExport.SelectedDate) & "-" & 
        Right("0" & Month(StartDateInputExport.SelectedDate), 2) & "-" & 
        Right("0" & Day(StartDateInputExport.SelectedDate), 2),
        ""
    )
);
Set(
    varEndDate,
    If(
        !IsBlank(EndDateInputExport.SelectedDate),
        // Format: yyyy-MM-dd (contoh: 2025-01-31)
        Year(EndDateInputExport.SelectedDate) & "-" & 
        Right("0" & Month(EndDateInputExport.SelectedDate), 2) & "-" & 
        Right("0" & Day(EndDateInputExport.SelectedDate), 2),
        ""
    )
);
Set(
    varBTPFilter,
    If(
        !IsBlank(BtpInputExport.Text) && Len(Trim(BtpInputExport.Text)) > 0,
        // Pastikan mengambil nilai dari Text property, bukan placeholder/label
        Trim(BtpInputExport.Text),
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

