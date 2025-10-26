    // Filter untuk user non-FSS (tampilkan semua)
    // Delegation-safe: Gunakan Status column untuk filter
    FirstN(
        Sort(
            If(
                rkToggle_1.Checked,
                // Filter transaksi yang perlu review (NO_MATCH, NO_PATTERN, UNKNOWN_BANK, LOW)
                Filter(
                    BTP_REVIEW,
                    Status = "NO_MATCH" || 
                    Status = "NO_PATTERN" || 
                    Status = "UNKNOWN_BANK" || 
                    Status = "LOW"
                ),
                BTP_REVIEW
            ),
            CreatedAt,
            SortOrder.Descending
        ),
        200000
    )