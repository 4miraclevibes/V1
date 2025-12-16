// =====================================================
// Button: Reset Filter
// =====================================================
// Purpose: Reset semua filter ke kondisi awal
// =====================================================

// Reset semua variable filter
Set(varFilterTransactionDate, Blank());
Set(varFilterUploadedAt, Blank());
Set(varSearchCustomer, "");
Set(varSearchBatch, "");
Set(varSearchDescription, "");
Set(varSearchBankType, "");
Set(varSearchBTP, "");
Set(varShowReview, true);  // Default: show review
Set(varShowDebit, Blank());

// Reset semua controls
Reset(TrxDpRvRk);
Reset(UaDpRvRk);
Reset(searchCustomerRv);
Reset(searchBatchRv);
Reset(searchDescRv);
Reset(searchBtRv);
Reset(searchBtpRv);
Reset(rkToggleRv);
Reset(rkToggleRvCd);

// Refresh data source (show all data)
Refresh(SP_BTP_REVIEW_FilterComplete);

// Atau jika menggunakan Power Automate Flow:
// Set(
//     varFilteredData,
//     Flow_FilterBTPReview.Run(
//         Blank(),  // TransactionDate
//         Blank(),  // UploadedAt
//         "",       // SearchCustomer
//         "",       // SearchBatch
//         "",       // SearchDescription
//         "",       // SearchBankType
//         "",       // SearchBTP
//         true,     // ShowReview
//         Blank()   // ShowDebit
//     )
// );

// Success message
Set(varFilterMessage, "🔄 Filter reset");
Notify(
    varFilterMessage,
    NotificationType.Success,
    2000
);

