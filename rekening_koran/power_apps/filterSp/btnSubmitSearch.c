// =====================================================
// Tombol Submit Search - OnSelect Property
// =====================================================
// Function: FN_BTP_REVIEW_FilterText
// Tujuan: Memanggil Function dengan parameter dari text fields
//         dan menyimpan hasil ke variabel untuk digunakan di Gallery
// =====================================================

// Set variabel dengan hasil filter dari Function
Set(
    varFilteredData,
    FN_BTP_REVIEW_FilterText(
        // Parameter 1: SearchCustomer
        If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
        
        // Parameter 2: SearchBatch
        If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
        
        // Parameter 3: SearchDescription
        If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
        
        // Parameter 4: SearchBankType
        If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
        
        // Parameter 5: SearchBTP
        If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
        
        // Parameter 6: UploadedAt
        UaDpRvRk.SelectedDate,
        
        // Parameter 7: TransactionDate
        TrxDpRvRk.SelectedDate
    )
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
