// Label KANAN - Tanggal yang BELUM di-upload
// Posisi: sebelah kanan

"BELUM UPLOAD (" & varMissingCount & ")" &
Char(10) &
"─────────────────" &
Char(10) &
Concat(
    colMissingDates,
    Text(Value, "dd/mm/yyyy"),
    Char(10)
)
