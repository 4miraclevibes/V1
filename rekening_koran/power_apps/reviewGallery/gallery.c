    // Filter untuk user non-FSS (tampilkan semua)
    // Delegation-safe: Gunakan Status column untuk filter
    FirstN(
        Sort(
            If(
                rkToggleRv.Checked,
                // Filter transaksi yang perlu review (NO_MATCH, NO_PATTERN, UNKNOWN_BANK, LOW)
                Filter(
                    BTP_REVIEW,
                    (Status = "NO_MATCH" || 
                    Status = "NO_PATTERN" || 
                    Status = "UNKNOWN_BANK") &&
                    (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
                    (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
                    (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP)
                ),
                Filter(
                    BTP_REVIEW,
                    (Status = "FAIR" ||
                    Status = "GOOD" ||
                    Status = "EXCELLENT") &&
                    (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
                    (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
                    (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP)
                )
            ),
            UploadedAt,
            SortOrder.Descending
        ),
        200000
    )