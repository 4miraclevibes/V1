// =====================================================
// Gallery Items Property - Menggunakan SP dengan Parameter
// =====================================================
// Ganti Items property di gallery dengan salah satu opsi di bawah
// =====================================================

// =====================================================
// OPSI 1: SP dengan Parameter Langsung (Recommended) ⭐
// =====================================================
// 
// Items Property:
POWERAPPS3.dboSP_BTP_REVIEW_FilterComplete({
    ShowReview: rkToggleRv.Checked,
    SearchCustomer: searchCustomerRv.Text,
    SearchBatch: searchBatchRv.Text,
    SearchDescription: searchDescRv.Text,
    SearchBankType: searchBtRv.Text,
    TransactionDate: TrxDpRvRk.SelectedDate,
    UploadedAt: UaDpRvRk.SelectedDate,
    SearchBTP: searchBtpRv.Text,
    ShowDebit: If(rkToggleRvCd.Checked, true, Blank()),
    SortBy: "MatchPercentage",
    SortOrder: "ASC"
}).ResultSets.Table1

// =====================================================
// OPSI 2: SP dengan Variable (TIDAK DISARANKAN untuk SP dengan parameter)
// =====================================================
// 
// CATATAN: Untuk SP dengan parameter, HARUS langsung kirim parameter saat dipanggil
// Format yang benar adalah OPSI 1 (langsung dengan parameter)
//
// Jika ingin pakai variable, gunakan With() seperti di loginBtn.c:
// Items Property:
With(
    {
        result: POWERAPPS3.dboSP_BTP_REVIEW_FilterComplete({
            ShowReview: rkToggleRv.Checked,
            SearchCustomer: varSearchCustomer,
            TransactionDate: varFilterTransactionDate,
            // ... parameter lainnya dari variable
        })
    },
    result.ResultSets.Table1
)


// =====================================================
// OPSI 3: SP dengan Parameter + Filter Tambahan
// =====================================================
//
// Items Property:
Filter(
    POWERAPPS3.dboSP_BTP_REVIEW_FilterComplete({
        ShowReview: rkToggleRv.Checked,
        SearchCustomer: searchCustomerRv.Text,
        SearchBatch: searchBatchRv.Text,
        TransactionDate: TrxDpRvRk.SelectedDate,
        UploadedAt: UaDpRvRk.SelectedDate,
        ShowDebit: If(rkToggleRvCd.Checked, true, Blank())
    }).ResultSets.Table1,
    IsApproved = false  // Filter tambahan yang delegation-safe
)


// =====================================================
// OPSI 4: SP dengan Parameter + Sort
// =====================================================
//
// Items Property:
Sort(
    POWERAPPS3.dboSP_BTP_REVIEW_FilterComplete({
        ShowReview: rkToggleRv.Checked,
        SearchCustomer: searchCustomerRv.Text,
        TransactionDate: TrxDpRvRk.SelectedDate,
        SortBy: "MatchPercentage",
        SortOrder: "ASC"
    }).ResultSets.Table1,
    MatchPercentage,
    SortOrder.Ascending
)


// =====================================================
// OPSI 5: SP dengan Parameter + FirstN (Limit)
// =====================================================
//
// Items Property:
FirstN(
    POWERAPPS3.dboSP_BTP_REVIEW_FilterComplete({
        ShowReview: rkToggleRv.Checked,
        SearchCustomer: searchCustomerRv.Text,
        TransactionDate: TrxDpRvRk.SelectedDate,
        SortBy: "MatchPercentage",
        SortOrder: "ASC"
    }).ResultSets.Table1,
    200000  // Max 200k rows
)


// =====================================================
// Mapping Parameter SP ke Control Power Apps
// =====================================================
//
// SP Parameter          →  Power Apps Control/Variable
// ──────────────────────────────────────────────────────
// @ShowReview            →  rkToggleRv.Checked
// @SearchCustomer        →  searchCustomerRv.Text
// @SearchBatch           →  searchBatchRv.Text
// @SearchDescription     →  searchDescRv.Text
// @SearchBankType        →  searchBtRv.Text
// @TransactionDate       →  TrxDpRvRk.SelectedDate
// @UploadedAt            →  UaDpRvRk.SelectedDate
// @SearchBTP             →  searchBtpRv.Text
// @ShowDebit             →  rkToggleRvCd.Checked (true = DB, false/Blank = CR/All)
// @SortBy                →  "MatchPercentage" atau "CreatedAt" atau "TransactionDate"
// @SortOrder             →  "ASC" atau "DESC"
// @IsApproved            →  false (default)
// @IncludeNoMatch        →  1 (default)
// @IncludeUnknownBank    →  1 (default)
// @IncludeMissing        →  1 (default)
// @IncludeNoPattern      →  1 (default)
// @IncludeFair           →  1 (default)
// @IncludeGood           →  1 (default)
// @IncludeLow            →  1 (default)
// @IncludeExcellent      →  1 (default)


// =====================================================
// Contoh Lengkap untuk Replace gallery.c
// =====================================================
//
// Items Property (ganti semua filter lama dengan ini):
FirstN(
    Sort(
        POWERAPPS3.dboSP_BTP_REVIEW_FilterComplete({
            ShowReview: rkToggleRv.Checked,
            SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
            SearchBatch: If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
            SearchDescription: If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
            SearchBankType: If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
            TransactionDate: TrxDpRvRk.SelectedDate,
            UploadedAt: UaDpRvRk.SelectedDate,
            SearchBTP: If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
            ShowDebit: If(rkToggleRvCd.Checked, true, Blank()),
            SortBy: "MatchPercentage",
            SortOrder: "ASC"
        }).ResultSets.Table1,
        MatchPercentage,
        SortOrder.Ascending
    ),
    200000
)

