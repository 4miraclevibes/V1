// Text Input KIRI - Tanggal yang SUDAH di-upload
// Properties:

// Mode:
TextMode.MultiLine

// DisplayMode:
DisplayMode.View

// Default:
"SUDAH UPLOAD (" & varUploadedCount & ")" &
Char(10) &
"─────────────────" &
Char(10) &
Concat(
    colUploadedDates,
    Text(DateValue(Value), "dd/mm/yyyy"),
    Char(10)
)
