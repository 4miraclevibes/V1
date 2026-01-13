// =====================================================
// Gallery Items Property - Menggunakan Stored Procedure untuk Text Filtering
// =====================================================
// SP: SP_BTP_REVIEW_FilterText
// Parameter: Hanya text fields (CustomerName, BatchID, Description, BankType, BTP, UploadedAt, TransactionDate)
// Switch/Toggle: Tetap di Power Apps (Status dan TransactionType)
// =====================================================

// Variabel untuk menyimpan hasil filter dari SP
// Set di tombol Submit Search:
// Set(varFilteredData, SP_BTP_REVIEW_FilterText.Run({
//     SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
//     SearchBatch: If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
//     SearchDescription: If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
//     SearchBankType: If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
//     SearchBTP: If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
//     UploadedAt: UaDpRvRk.SelectedDate,
//     TransactionDate: TrxDpRvRk.SelectedDate
// }));

// Items Property Gallery:
FirstN(
    Sort(
        Filter(
            // Pakai variabel hasil dari SP (sudah difilter berdasarkan text fields)
            varFilteredData,
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
// CATATAN PENTING:
// =====================================================
// 1. SP_BTP_REVIEW_FilterText harus ditambahkan sebagai Data Source di Power Apps
// 2. Variabel varFilteredData harus dideklarasikan di OnStart atau OnVisible screen:
//    Set(varFilteredData, []);
// 3. Di tombol Submit Search, panggil SP dan simpan ke variabel
// 4. Switch/toggle (rkToggleRv, rkToggleRvCd) tetap di Power Apps
// 5. SP hanya filter text fields, Status dan TransactionType tetap di Power Apps
