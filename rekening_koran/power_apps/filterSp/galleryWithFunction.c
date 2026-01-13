// =====================================================
// Gallery Items Property - Menggunakan Table-Valued Function
// =====================================================
// Function: FN_BTP_REVIEW_FilterText
// Parameter: Hanya text fields (CustomerName, BatchID, Description, BankType, BTP, UploadedAt, TransactionDate)
// Switch/Toggle: Tetap di Power Apps (Status dan TransactionType)
// =====================================================

// Variabel untuk menyimpan hasil filter
// Set di tombol Submit Search:
// Set(varFilteredData, FN_BTP_REVIEW_FilterText(
//     searchCustomerRv.Text,
//     searchBatchRv.Text,
//     searchDescRv.Text,
//     searchBtRv.Text,
//     searchBtpRv.Text,
//     UaDpRvRk.SelectedDate,
//     TrxDpRvRk.SelectedDate
// ));

// Items Property Gallery:
FirstN(
    Sort(
        Filter(
            // Panggil Function dengan parameter dari text fields
            FN_BTP_REVIEW_FilterText(
                If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
                If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
                If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
                If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
                If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
                UaDpRvRk.SelectedDate,
                TrxDpRvRk.SelectedDate
            ),
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
// ALTERNATIF: Menggunakan Variabel (Lebih Efisien)
// =====================================================
// Di tombol Submit Search (OnSelect):
/*
Set(
    varFilteredData,
    FN_BTP_REVIEW_FilterText(
        If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
        If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
        If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
        If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
        If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
        UaDpRvRk.SelectedDate,
        TrxDpRvRk.SelectedDate
    )
);
*/

// Items Property Gallery (menggunakan variabel):
/*
FirstN(
    Sort(
        Filter(
            varFilteredData,
            // Filter Status (switch rkToggleRv)
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
            // Filter TransactionType (switch rkToggleRvCd)
            (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
        ),
        MatchPercentage,
        SortOrder.Ascending
    ),
    200000
)
*/
