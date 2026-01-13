// =====================================================
// Tombol Submit Search - OnSelect Property (Power Automate)
// =====================================================
// Flow: FilterBTPReviewText
// Tujuan: Memanggil Power Automate Flow dengan parameter dari text fields
//         dan menyimpan hasil ke variabel untuk digunakan di Gallery
// =====================================================

// Show loading indicator
Set(varIsLoading, true);

// Call Power Automate Flow
Set(
    varBTPReviewData,
    Flow_FilterBTPReviewText.Run({
        // Parameter: SearchCustomer
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), "", searchCustomerRv.Text),
        
        // Parameter: SearchBatch
        SearchBatch: If(IsBlank(searchBatchRv.Text), "", searchBatchRv.Text),
        
        // Parameter: SearchDescription
        SearchDescription: If(IsBlank(searchDescRv.Text), "", searchDescRv.Text),
        
        // Parameter: SearchBankType
        SearchBankType: If(IsBlank(searchBtRv.Text), "", searchBtRv.Text),
        
        // Parameter: SearchBTP
        SearchBTP: If(IsBlank(searchBtpRv.Text), "", searchBtpRv.Text),
        
        // Parameter: TransactionDate (convert Date ke Text)
        TransactionDate: If(IsBlank(TrxDpRvRk.SelectedDate), "", Text(TrxDpRvRk.SelectedDate)),
        
        // Parameter: UploadedAt (convert Date ke Text)
        UploadedAt: If(IsBlank(UaDpRvRk.SelectedDate), "", Text(UaDpRvRk.SelectedDate))
    }).Data
);

// Hide loading indicator
Set(varIsLoading, false);

// Show success message
Notify(
    "Filter diterapkan: " & CountRows(varBTPReviewData) & " rows",
    NotificationType.Success,
    2000
);

// =====================================================
// CATATAN PENTING:
// =====================================================
// 1. Flow "FilterBTPReviewText" harus sudah dibuat di Power Automate
// 2. Variabel varBTPReviewData harus dideklarasikan di OnStart atau OnVisible screen:
//    Set(varBTPReviewData, []);
// 3. Variabel varIsLoading (optional) untuk loading indicator
// 4. Flow hanya filter text fields, switch/toggle tetap di Power Apps
// 5. Date parameter dikirim sebagai Text (format: "YYYY-MM-DD")
// 6. Empty text fields dikirim sebagai empty string "" (akan di-handle sebagai NULL di SP)
// =====================================================
