// =====================================================
// Gallery Items Property - Menggunakan Power Automate Flow (Text Filter Only)
// =====================================================
// Flow: FilterBTPReviewText
// SP: SP_BTP_REVIEW_FilterText (hanya filter text fields)
// Switch/Toggle: Tetap di Power Apps (Status dan TransactionType)
// =====================================================

// Items Property Gallery:
FirstN(
    Sort(
        Filter(
            // Pakai variabel hasil dari Flow (sudah difilter berdasarkan text fields)
            varBTPReviewData,
            // Filter Status (switch rkToggleRv) - tetap di Power Apps
            (
                rkToggleRv.Checked && (
                    Status = "NO_MATCH" ||
                    Status = "UNKNOWN_BANK" ||
                    Status = "MISSING" ||
                    Status = "NO_PATTERN"
                )
            ) || (
                !rkToggleRv.Checked && (
                    Status = "FAIR" ||
                    Status = "GOOD" ||
                    Status = "LOW" ||
                    Status = "EXCELLENT"
                )
            ) &&
            IsApproved = false &&
            // Filter TransactionType (switch rkToggleRvCd) - tetap di Power Apps
            (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
        ),
        MatchPercentage,
        SortOrder.Ascending
    ),
    200000
)

// =====================================================
// SETUP REQUIRED:
// =====================================================
// 1. Di OnStart/OnVisible screen:
//    Set(varBTPReviewData, []);
//
// 2. Di tombol Submit Search (OnSelect):
//    Set(
//        varBTPReviewData,
//        Flow_FilterBTPReviewText.Run({
//            SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
//            SearchBatch: If(IsBlank(searchBatchRv.Text), "", searchBatchRv.Text),
//            SearchDescription: If(IsBlank(searchDescRv.Text), "", searchDescRv.Text),
//            SearchBankType: If(IsBlank(searchBtRv.Text), "", searchBtRv.Text),
//            SearchBTP: If(IsBlank(searchBtpRv.Text), "", searchBtpRv.Text),
//            TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate)),
//            UploadedAt: If(IsBlank(UaDpRvRk.SelectedDate), "", Text(UaDpRvRk.SelectedDate))
//        }).Data
//    );
//
// 3. Pastikan Flow "FilterBTPReviewText" sudah dibuat di Power Automate
// 4. Pastikan SP_BTP_REVIEW_FilterText sudah di-execute di SQL Server
// =====================================================
