// =====================================================
// Tombol Submit Search - OnSelect Property
// =====================================================
// SP: SP_BTP_REVIEW_FilterText
// Tujuan: Memanggil Stored Procedure dengan parameter dari text fields
//         dan menyimpan hasil ke variabel untuk digunakan di Gallery
// =====================================================

// Set variabel dengan hasil filter dari Stored Procedure
Set(
    varFilteredData,
    SP_BTP_REVIEW_FilterText.Run({
        // Parameter: SearchCustomer
        SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
        
        // Parameter: SearchBatch
        SearchBatch: If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
        
        // Parameter: SearchDescription
        SearchDescription: If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
        
        // Parameter: SearchBankType
        SearchBankType: If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
        
        // Parameter: SearchBTP
        SearchBTP: If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
        
        // Parameter: UploadedAt
        UploadedAt: UaDpRvRk.SelectedDate,
        
        // Parameter: TransactionDate
        TransactionDate: TrxDpRvRk.SelectedDate
    })
);

// Refresh Gallery (optional, jika menggunakan variabel)
// Refresh(galleryReview);

// Notifikasi sukses (optional)
Notify(
    "Filter diterapkan",
    NotificationType.Success,
    2000
);

// =====================================================
// CATATAN PENTING:
// =====================================================
// 1. Function FN_BTP_REVIEW_FilterText harus sudah ditambahkan sebagai Data Source di Power Apps
// 2. Variabel varFilteredData harus dideklarasikan di OnStart atau OnVisible screen
// 3. Di Gallery Items Property, gunakan varFilteredData dan tambahkan filter untuk Status dan TransactionType
// 4. Function hanya filter berdasarkan text fields, switch/toggle tetap di Power Apps
