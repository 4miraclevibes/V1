// =====================================================
// Variables untuk Filter BTP_REVIEW
// =====================================================
// Tambahkan ini di OnStart atau OnVisible screen
// =====================================================

// Filter variables
Set(varFilterTransactionDate, Blank());
Set(varFilterUploadedAt, Blank());
Set(varSearchCustomer, "");
Set(varSearchBatch, "");
Set(varSearchDescription, "");
Set(varSearchBankType, "");
Set(varSearchBTP, "");
Set(varShowReview, true);  // true = show review, false = show approved
Set(varShowDebit, Blank());  // Blank = all, true = DB only, false = CR only

// UI state variables
Set(varIsFiltering, false);
Set(varFilterMessage, "");
Set(varFilteredData, []);  // Jika menggunakan collection/flow result

// Filter summary (optional - untuk menampilkan filter aktif)
Set(
    varActiveFilters,
    Concat(
        [
            If(!IsBlank(varFilterTransactionDate), "TransactionDate", Blank()),
            If(!IsBlank(varFilterUploadedAt), "UploadedAt", Blank()),
            If(!IsBlank(varSearchCustomer), "Customer", Blank()),
            If(!IsBlank(varSearchBatch), "Batch", Blank()),
            If(!IsBlank(varSearchDescription), "Description", Blank()),
            If(!IsBlank(varSearchBankType), "BankType", Blank()),
            If(!IsBlank(varSearchBTP), "BTP", Blank())
        ],
        ", "
    )
);

