// =====================================================
// Gallery Items Property - Menggunakan Stored Procedure
// =====================================================
// Ganti Items property di gallery dengan salah satu opsi di bawah
// =====================================================

// =====================================================
// OPSI 1: SP sebagai Data Source (Paling Mudah) ⭐
// =====================================================
// 
// Prerequisites:
// 1. Tambahkan SP_BTP_REVIEW_FilterComplete sebagai data source di Power Apps
// 2. SP akan otomatis menggunakan parameter dari variable yang sudah diset
//
// Items Property:
SP_BTP_REVIEW_FilterComplete

// Catatan: Parameter SP akan diambil dari variable:
// - @TransactionDate = varFilterTransactionDate
// - @UploadedAt = varFilterUploadedAt
// - @SearchCustomer = varSearchCustomer
// - dll (sesuai dengan parameter SP)


// =====================================================
// OPSI 2: Melalui Power Automate Flow
// =====================================================
//
// Items Property:
varFilteredData
//
// Flow akan dipanggil dari btnApplyFilter dengan semua parameter


// =====================================================
// OPSI 3: Collection (Jika perlu manipulasi data)
// =====================================================
//
// Items Property:
colFilteredBTPReview
//
// Di btnApplyFilter, setelah memanggil SP/Flow:
// Clear(colFilteredBTPReview);
// Collect(colFilteredBTPReview, varFilteredData);


// =====================================================
// OPSI 4: Hybrid - Filter di Power Apps setelah SP
// =====================================================
//
// Items Property:
Filter(
    SP_BTP_REVIEW_FilterComplete,
    // Filter tambahan di Power Apps (delegation-safe)
    Status <> "EXCELLENT" || MatchPercentage < 100
)
//
// Catatan: Filter tambahan harus delegation-safe (menggunakan kolom yang ter-index)


// =====================================================
// Contoh Lengkap dengan Sorting
// =====================================================
//
// Items Property:
Sort(
    SP_BTP_REVIEW_FilterComplete,
    MatchPercentage,
    SortOrder.Ascending
)


// =====================================================
// Contoh dengan FirstN (Limit Results)
// =====================================================
//
// Items Property:
FirstN(
    Sort(
        SP_BTP_REVIEW_FilterComplete,
        MatchPercentage,
        SortOrder.Ascending
    ),
    200000  // Max 200k rows
)

