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
                        Status = "MISSING" ||
                        //Status = "LOW" ||
                        Status = "NO_PATTERN"
                    ) &&
                    IsApproved = false &&
                    (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
                    (IsBlank(searchBatchRv.Text) || searchBatchRv.Text in BatchID) &&
                    (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
                    (IsBlank(searchBtRv.Text) || searchBtRv.Text in BankType) &&
                    (IsBlank(UaDpRvRk.SelectedDate) || DateValue(UploadedAt) = UaDpRvRk.SelectedDate) &&
                    (IsBlank(TrxDpRvRk.SelectedDate) || DateValue(TransactionDate) = TrxDpRvRk.SelectedDate) &&
                    (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP) &&
                    (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
                ),
                Filter(
                    BTP_REVIEW,
                    (Status = "FAIR" ||
                    Status = "GOOD" ||
                    Status = "LOW" ||
                    //Status = "MISSING" ||
                    Status = "EXCELLENT") &&
                    IsApproved = false &&
                    (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
                    (IsBlank(searchBatchRv.Text) || searchBatchRv.Text in BatchID) &&
                    (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
                    (IsBlank(searchBtRv.Text) || searchBtRv.Text in BankType) &&
                    (IsBlank(UaDpRvRk.SelectedDate) || DateValue(UploadedAt) = UaDpRvRk.SelectedDate) &&
                    (IsBlank(TrxDpRvRk.SelectedDate) || DateValue(TransactionDate) = TrxDpRvRk.SelectedDate) &&
                    (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP) &&
                    (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
                )
            ),
            MatchPercentage,
            SortOrder.Ascending
        ),
        200000
    )