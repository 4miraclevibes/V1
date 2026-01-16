// Label KIRI - Tanggal yang SUDAH di-upload
// Posisi: sebelah kiri

"SUDAH UPLOAD (" & varUploadedCount & ")" &
Char(10) &
"─────────────────" &
Char(10) &
Concat(
    colUploadedDates,
    Text(DateValue(Value), "dd/mm/yyyy"),
    Char(10)
)
