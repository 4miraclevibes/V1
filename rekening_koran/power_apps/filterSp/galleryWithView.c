// =====================================================
// Gallery Items Property - Menggunakan View + Filter di Power Apps
// =====================================================
// View: VW_BTP_REVIEW_FilterReady
// Filter: Text fields menggunakan "in" operator (delegation-safe)
// Switch/Toggle: Status dan TransactionType tetap di Power Apps
// =====================================================
// CATATAN: 
// - View tidak bisa menerima parameter, jadi filter dilakukan di Power Apps
// - Gunakan "in" operator untuk text filtering (delegation-safe)
// - Switch/toggle tetap di Power Apps
// =====================================================

FirstN(
    Sort(
        If(
            rkToggleRv.Checked,
            // Filter transaksi yang perlu review (NO_MATCH, NO_PATTERN, UNKNOWN_BANK, MISSING)
            Filter(
                VW_BTP_REVIEW_FilterReady,
                (
                    Status = "NO_MATCH" ||
                    Status = "UNKNOWN_BANK" ||
                    Status = "MISSING" ||
                    Status = "NO_PATTERN"
                ) &&
                IsApproved = false &&
                // Text filtering menggunakan "in" operator (delegation-safe)
                (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
                (IsBlank(searchBatchRv.Text) || searchBatchRv.Text in BatchID) &&
                (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
                (IsBlank(searchBtRv.Text) || searchBtRv.Text in BankType) &&
                (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP) &&
                // Date filtering menggunakan helper column
                (IsBlank(UaDpRvRk.SelectedDate) || UploadedAtDate = UaDpRvRk.SelectedDate) &&
                (IsBlank(TrxDpRvRk.SelectedDate) || TransactionDateOnly = TrxDpRvRk.SelectedDate) &&
                // TransactionType filter (switch rkToggleRvCd)
                (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
            ),
            // Filter transaksi yang sudah approved (FAIR, GOOD, LOW, EXCELLENT)
            Filter(
                VW_BTP_REVIEW_FilterReady,
                (
                    Status = "FAIR" ||
                    Status = "GOOD" ||
                    Status = "LOW" ||
                    Status = "EXCELLENT"
                ) &&
                IsApproved = false &&
                // Text filtering menggunakan "in" operator (delegation-safe)
                (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
                (IsBlank(searchBatchRv.Text) || searchBatchRv.Text in BatchID) &&
                (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
                (IsBlank(searchBtRv.Text) || searchBtRv.Text in BankType) &&
                (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP) &&
                // Date filtering menggunakan helper column
                (IsBlank(UaDpRvRk.SelectedDate) || UploadedAtDate = UaDpRvRk.SelectedDate) &&
                (IsBlank(TrxDpRvRk.SelectedDate) || TransactionDateOnly = TrxDpRvRk.SelectedDate) &&
                // TransactionType filter (switch rkToggleRvCd)
                (rkToggleRvCd.Checked && TransactionType = "DB" || !rkToggleRvCd.Checked && TransactionType = "CR")
            )
        ),
        MatchPercentage,
        SortOrder.Ascending
    ),
    200000
)

// =====================================================
// CATATAN PENTING:
// =====================================================
// 1. View VW_BTP_REVIEW_FilterReady harus ditambahkan sebagai Data Source di Power Apps
// 2. Filter text menggunakan "in" operator untuk menghindari delegation warning
// 3. Switch/toggle (rkToggleRv, rkToggleRvCd) tetap di Power Apps
// 4. Tombol Submit Search tidak diperlukan karena filter langsung di Gallery
// 5. Jika ingin pakai tombol Submit, bisa simpan hasil filter ke variabel
