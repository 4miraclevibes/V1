// Text Input KANAN - Tanggal yang BELUM di-upload
// Properties:

// Mode:
TextMode.MultiLine

// DisplayMode:
DisplayMode.View

// Default:
"BELUM UPLOAD (" & varMissingCount & ")" &
Char(10) &
"─────────────────" &
Char(10) &
Concat(
    colMissingDates,
    Text(Value, "dd/mm/yyyy"),
    Char(10)
)
