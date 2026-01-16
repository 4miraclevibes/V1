// =====================================================
// SOLUSI PALING SIMPLE - Copy Paste Langsung!
// =====================================================
// Flow: FilterBTPReview
// =====================================================

// STEP 1: Di OnStart/OnVisible screen, tambahkan ini:
ClearCollect(colBTPReviewData, []);
Set(varParsedData, []);
Set(varBTPReviewData, []);

// STEP 2: Di Button OnSelect, copy paste ini:
Set(varIsLoading, true);

Set(
    varFlowResult,
    FilterBTPReview.Run({
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
        SearchBatch: If(IsBlank(searchBatchRv.Text), "", searchBatchRv.Text),
        SearchDescription: If(IsBlank(searchDescRv.Text), "", searchDescRv.Text),
        SearchBankType: If(IsBlank(searchBtRv.Text), "", searchBtRv.Text),
        SearchBTP: If(IsBlank(searchBtpRv.Text), "", searchBtpRv.Text),
        TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate)),
        UploadedAt: If(IsBlank(UaDpRvRk.SelectedDate), "", Text(UaDpRvRk.SelectedDate))
    })
);

If(
    !IsBlank(varFlowResult) && !IsBlank(varFlowResult.data),
    Set(varParsedData, ParseJSON(varFlowResult.data));
    Clear(colBTPReviewData);
    Collect(colBTPReviewData, varParsedData);
    Set(varBTPReviewData, colBTPReviewData),
    Clear(colBTPReviewData);
    Set(varBTPReviewData, [])
);

Set(varIsLoading, false);
Notify("Filter diterapkan", NotificationType.Success, 2000);

// STEP 3: Di Gallery Items property, ketik ini:
colBTPReviewData

// SELESAI! 🎉
