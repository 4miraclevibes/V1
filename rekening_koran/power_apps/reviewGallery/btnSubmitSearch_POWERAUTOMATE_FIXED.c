// =====================================================
// Tombol Submit Search - OnSelect Property (Power Automate) - FIXED VERSION
// =====================================================
// Flow: FilterBTPReview (nama flow di Power Automate)
// Tujuan: Memanggil Power Automate Flow dengan parameter dari text fields
//         dan menyimpan hasil ke variabel untuk digunakan di Gallery
// =====================================================
// Catatan: 
// - Nama flow harus sesuai dengan yang ada di Power Automate
// - Response .data adalah string JSON yang perlu di-parse menjadi Table
// =====================================================

// Show loading indicator
Set(varIsLoading, true);

// Call Power Automate Flow
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

// Extract dan parse data dari response
// Response structure: {success: true, data: "[...JSON string...]", rowcount: 655}
// .data adalah string JSON yang perlu di-parse menjadi Table
// CARA BENAR: Parse dulu dengan ParseJSON, lalu Collect ke collection
If(
    !IsBlank(varFlowResult) && !IsBlank(varFlowResult.data),
    // Step 1: Parse JSON string menjadi Table
    Set(
        varParsedData,
        ParseJSON(varFlowResult.data)
    );
    // Step 2: Clear collection dulu
    Clear(colBTPReviewData);
    // Step 3: Collect parsed data ke collection
    Collect(
        colBTPReviewData,
        varParsedData
    );
    // Step 4: Set variabel dari collection
    Set(varBTPReviewData, colBTPReviewData),
    // Jika tidak ada data, set kosong
    Clear(colBTPReviewData);
    Set(varBTPReviewData, [])
);

// Hide loading indicator
Set(varIsLoading, false);

// Show success message (tanpa CountRows untuk menghindari error)
Notify(
    "Filter diterapkan",
    NotificationType.Success,
    2000
);

// =====================================================
// CATATAN PENTING:
// =====================================================
// 1. Flow "FilterBTPReview" harus sudah dibuat di Power Automate
// 2. Collection colBTPReviewData harus dibuat di OnStart/OnVisible: ClearCollect(colBTPReviewData, []);
// 3. Variabel varParsedData harus dibuat di OnStart/OnVisible: Set(varParsedData, []);
// 4. Variabel varBTPReviewData harus dideklarasikan di OnStart/OnVisible: Set(varBTPReviewData, []);
// 5. Response .data adalah string JSON yang perlu di-parse menjadi Table
// 6. Format: FlowName.Run({parameter1: value1, ...})
//    Response: {success: true, data: "[...JSON string...]", rowcount: 655}
// 7. Parse dengan cara yang benar:
//    - Set(varParsedData, ParseJSON(varFlowResult.data));
//    - Clear(colBTPReviewData);
//    - Collect(colBTPReviewData, varParsedData);
//    - Set(varBTPReviewData, colBTPReviewData);
// 8. Pakai collection di Gallery: Items: colBTPReviewData
// 9. Lihat file POWERAPPS_PARSE_JSON_SOLUSI.md untuk panduan lengkap
// =====================================================
