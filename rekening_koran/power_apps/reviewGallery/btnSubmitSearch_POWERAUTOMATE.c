// =====================================================
// Tombol Submit Search - OnSelect Property (Power Automate)
// =====================================================
// Flow: FilterBTPReview (nama flow di Power Automate)
// Tujuan: Memanggil Power Automate Flow dengan parameter dari text fields
//         dan menyimpan hasil ke variabel untuk digunakan di Gallery
// =====================================================
// Catatan: 
// - Nama flow harus sesuai dengan yang ada di Power Automate
// - Response menggunakan lowercase: .data (bukan .Data)
// =====================================================

// Show loading indicator
Set(varIsLoading, true);

// Call Power Automate Flow
// Format: FlowName.Run({parameter1: value1, parameter2: value2})
// Contoh: Export_RekeningKoran_ToExcel.Run({text: varStartDate, text_1: varEndDate})
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
// .data adalah string JSON yang perlu di-parse menjadi Table menggunakan ParseJSON()
Set(
    varBTPReviewData,
    If(
        !IsBlank(varFlowResult) && !IsBlank(varFlowResult.data),
        // Parse JSON string menjadi Table menggunakan ParseJSON()
        ParseJSON(varFlowResult.data),
        []  // Default ke empty table jika tidak ada data
    )
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
// 1. Flow "FilterBTPReview" harus sudah dibuat di Power Automate (cek nama flow yang benar!)
// 2. Variabel varBTPReviewData harus dideklarasikan di OnStart atau OnVisible screen:
//    Set(varBTPReviewData, []);
// 3. Variabel varIsLoading (optional) untuk loading indicator
// 4. Flow hanya filter text fields, switch/toggle tetap di Power Apps
// 5. Date parameter dikirim sebagai Text (format: "YYYY-MM-DD")
// 6. Empty text fields dikirim sebagai empty string "" (akan di-handle sebagai NULL di SP)
// 7. Response menggunakan lowercase: .data (bukan .Data)
// 8. Format: FlowName.Run({parameter1: value1, ...})
//    Response structure: {success: true, data: "[...JSON string...]", rowcount: 655}
//    Extract data dengan: varFlowResult.data (bisa berupa string JSON yang perlu di-parse)
// 9. Parse JSON string menjadi Table menggunakan ParseJSON() function:
//    ParseJSON(varFlowResult.data)
// 10. varBTPReviewData akan menjadi Table yang bisa langsung digunakan di Gallery
// =====================================================
