// =====================================================
// Gallery Items Property - Menggunakan Power Automate Flow
// =====================================================
// Solusi yang lebih fleksibel: Panggil SP via Power Automate
// =====================================================

// =====================================================
// STEP 1: Buat Variable untuk menyimpan hasil Flow
// =====================================================
// Di OnStart atau OnVisible screen:
Set(varBTPReviewData, []);  // Initialize sebagai empty table


// =====================================================
// STEP 2: Buat Button untuk Memanggil Flow
// =====================================================
// Button OnSelect Property (btnLoadData atau btnApplyFilter):
Set(
    varBTPReviewData,
    Flow_FilterBTPReview.Run({
        ShowReview: rkToggleRv.Checked,
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
        SearchBatch: If(IsBlank(searchBatchRv.Text), "", searchBatchRv.Text),
        SearchDescription: If(IsBlank(searchDescRv.Text), "", searchDescRv.Text),
        SearchBankType: If(IsBlank(searchBtRv.Text), "", searchBtRv.Text),
        TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate)),
        UploadedAt: If(IsBlank(UaDpRvRk.SelectedDate), "", Text(UaDpRvRk.SelectedDate)),
        SearchBTP: If(IsBlank(searchBtpRv.Text), "", searchBtpRv.Text),
        ShowDebit: If(rkToggleRvCd.Checked, true, false),
        SortBy: "MatchPercentage",
        SortOrder: "ASC"
    })
);

// Show loading indicator
Set(varIsLoading, true);

// Wait for flow to complete (optional)
Wait(1);

// Hide loading indicator
Set(varIsLoading, false);

// Show success message
Notify(
    "Data loaded: " & CountRows(varBTPReviewData) & " rows",
    NotificationType.Success,
    2000
);


// =====================================================
// STEP 3: Gallery Items Property
// =====================================================
// Items Property Gallery:
varBTPReviewData

// Atau dengan sorting tambahan:
Sort(
    varBTPReviewData,
    MatchPercentage,
    SortOrder.Ascending
)

// Atau dengan limit:
FirstN(
    Sort(
        varBTPReviewData,
        MatchPercentage,
        SortOrder.Ascending
    ),
    200000
)


// =====================================================
// STEP 4: Auto-load saat screen pertama kali dibuka
// =====================================================
// OnVisible Property Screen:
Set(
    varBTPReviewData,
    Flow_FilterBTPReview.Run({
        ShowReview: true,
        SearchCustomer: "",
        SearchBatch: "",
        TransactionDate: "",
        UploadedAt: "",
        ShowDebit: false,
        SortBy: "MatchPercentage",
        SortOrder: "ASC"
    })
);


// =====================================================
// ALTERNATIF: Menggunakan Collection (Lebih Fleksibel)
// =====================================================
// 
// Button OnSelect:
Clear(colBTPReview);
Collect(
    colBTPReview,
    Flow_FilterBTPReview.Run({
        ShowReview: rkToggleRv.Checked,
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
        TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate))
    })
);
//
// Items Property Gallery:
colBTPReview

