-- =====================================================
-- CONTOH CARA EXECUTE SP_BTP_REVIEW_FilterComplete
-- =====================================================

-- =====================================================
-- CONTOH 1: Execute dengan semua parameter default
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]

-- =====================================================
-- CONTOH 2: Execute dengan beberapa parameter (menggunakan parameter name)
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 0,
    @ShowReview = 1,
    @SearchCustomer = 'PT ABC',
    @SortBy = 'CreatedAt',
    @SortOrder = 'DESC'

-- =====================================================
-- CONTOH 3: Filter berdasarkan customer name
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 0,
    @SearchCustomer = 'Customer Name'

-- =====================================================
-- CONTOH 4: Filter berdasarkan batch ID
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 0,
    @SearchBatch = 'BATCH001'

-- =====================================================
-- CONTOH 5: Filter berdasarkan tanggal transaksi
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 0,
    @TransactionDate = '2024-01-15'

-- =====================================================
-- CONTOH 6: Filter hanya Debit (DB)
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 0,
    @ShowDebit = 1

-- =====================================================
-- CONTOH 7: Filter hanya Credit (CR)
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 0,
    @ShowDebit = 0

-- =====================================================
-- CONTOH 8: Filter approved records dengan status tertentu
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 1,
    @ShowReview = 0,
    @IncludeGood = 1,
    @IncludeExcellent = 1,
    @IncludeFair = 0,
    @IncludeLow = 0

-- =====================================================
-- CONTOH 9: Filter dengan multiple search criteria
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 0,
    @SearchCustomer = 'ABC',
    @SearchBatch = 'BATCH',
    @SearchDescription = 'Payment',
    @SearchBankType = 'BCA',
    @TransactionDate = '2024-01-15',
    @ShowDebit = 1,
    @SortBy = 'TransactionDate',
    @SortOrder = 'DESC'

-- =====================================================
-- CONTOH 10: Filter review status tertentu saja
-- =====================================================
EXEC [dbo].[SP_BTP_REVIEW_FilterComplete]
    @IsApproved = 0,
    @ShowReview = 1,
    @IncludeNoMatch = 1,
    @IncludeUnknownBank = 0,
    @IncludeMissing = 0,
    @IncludeNoPattern = 0

-- =====================================================
-- CATATAN:
-- =====================================================
-- 1. Semua parameter bisa diisi atau dibiarkan NULL/default
-- 2. Parameter @IsApproved harus diisi (tidak ada default, tapi default value = 0)
-- 3. Hasil akan ditampilkan sebagai result set dengan semua kolom dari BTP_REVIEW
-- 4. Untuk melihat hasil, jalankan di SQL Server Management Studio (SSMS) atau Azure Data Studio
-- 5. Hasil bisa langsung dilihat di tab "Results" setelah execute
-- =====================================================

