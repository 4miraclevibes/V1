// =====================================================
// Gallery Items Property - Menggunakan SP_BTP_REVIEW_FilterText
// =====================================================
// SP: SP_BTP_REVIEW_FilterText (hanya filter text fields)
// Switch/Toggle: Tetap di Power Apps (Status dan TransactionType)
// =====================================================
// SETUP:
// 1. Tambahkan SP_BTP_REVIEW_FilterText sebagai Data Source di Power Apps
// 2. Di OnStart/OnVisible screen: Set(varFilteredData, []);
// 3. Di tombol Submit Search: Panggil SP dan simpan ke varFilteredData
// 4. Di Gallery Items: Pakai varFilteredData + filter Status dan TransactionType
// =====================================================

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
