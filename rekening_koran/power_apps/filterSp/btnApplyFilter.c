// =====================================================
// Button: Apply Filter
// =====================================================
// Purpose: Mengumpulkan semua nilai filter dan memanggil stored procedure
// =====================================================

// Set loading state
Set(varIsFiltering, true);
Set(varFilterMessage, "⏳ Applying filter...");

// Simpan semua nilai filter ke variable
Set(varFilterTransactionDate, TrxDpRvRk.SelectedDate);
Set(varFilterUploadedAt, UaDpRvRk.SelectedDate);
Set(varSearchCustomer, searchCustomerRv.Text);
Set(varSearchBatch, searchBatchRv.Text);
Set(varSearchDescription, searchDescRv.Text);
Set(varSearchBankType, searchBtRv.Text);
Set(varSearchBTP, searchBtpRv.Text);
Set(varShowReview, rkToggleRv.Checked);
Set(varShowDebit, If(rkToggleRvCd.Checked, true, false));

// OPSI 1: Jika menggunakan SP sebagai Data Source langsung
Refresh(SP_BTP_REVIEW_FilterComplete);

// OPSI 2: Jika menggunakan Power Automate Flow
// Set(
//     varFilteredData,
//     Flow_FilterBTPReview.Run(
//         varFilterTransactionDate,
//         varFilterUploadedAt,
//         varSearchCustomer,
//         varSearchBatch,
//         varSearchDescription,
//         varSearchBankType,
//         varSearchBTP,
//         varShowReview,
//         varShowDebit
//     )
// );

// Reset loading state
Set(varIsFiltering, false);

// Success message
Set(
    varFilterMessage,
    "✅ Filter applied" &
    If(
        !IsBlank(varFilterTransactionDate) || 
        !IsBlank(varFilterUploadedAt) || 
        !IsBlank(varSearchCustomer) ||
        !IsBlank(varSearchBatch),
        " (" & 
        If(!IsBlank(varFilterTransactionDate), "Date, ", "") &
        If(!IsBlank(varSearchCustomer), "Customer, ", "") &
        If(!IsBlank(varSearchBatch), "Batch, ", "") &
        "...)",
        ""
    )
);

// Show notification
Notify(
    varFilterMessage,
    NotificationType.Success,
    2000
);

