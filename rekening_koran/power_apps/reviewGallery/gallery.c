    // Filter untuk user non-FSS (tampilkan semua)
    // Delegation-safe: Gunakan Status column untuk filter
    FirstN(
        Sort(
            If(
                rkToggleRv.Checked,
                // Filter transaksi yang perlu review (NO_MATCH, NO_PATTERN, UNKNOWN_BANK, LOW)
                Filter(
                    BTP_REVIEW,
                    (
                        Status = "NO_MATCH" ||
                        Status = "UNKNOWN_BANK" ||
                        Status = "NO_PATTERN"
                    ) &&
                    IsApproved = false &&
                    (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
                    (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
                    (IsBlank(searchBtRv.Text) || searchBtRv.Text in BankType) &&
                    //(IsBlank(UaDpRvRk.SelectedDate) || DateValue(UploadedAt) = UaDpRvRk.SelectedDate) &&
                    (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP)
                ),
                Filter(
                    BTP_REVIEW,
                    (Status = "FAIR" ||
                    Status = "GOOD" ||
                    Status = "LOW" ||
                    Status = "EXCELLENT") &&
                    IsApproved = false &&
                    (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
                    (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
                    (IsBlank(searchBtRv.Text) || searchBtRv.Text in BankType) &&
                    //(IsBlank(UaDpRvRk.SelectedDate) || DateValue(UploadedAt) = UaDpRvRk.SelectedDate) &&
                    (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP)
                )
            ),
            MatchPercentage,
            SortOrder.Ascending
        ),
        200000
    )