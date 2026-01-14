// Label Text - Tampilkan total dari collection
// Tidak hit database lagi

"Total: " & First(colBtpCount).TotalRows &
Char(10) &
"CR: " & First(colBtpCount).TotalCR &
Char(10) &
"DB: " & First(colBtpCount).TotalDB
