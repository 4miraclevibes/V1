"Total: " & CountIf(BTP_REVIEW, IsApproved = false) &
Char(10) &
"CR: " & CountIf(BTP_REVIEW, IsApproved = false && TransactionType = "CR") &
Char(10) &
"DB: " & CountIf(BTP_REVIEW, IsApproved = false && TransactionType = "DB")