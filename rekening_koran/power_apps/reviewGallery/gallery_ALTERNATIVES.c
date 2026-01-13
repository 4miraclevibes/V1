// =====================================================
// ALTERNATIF Format untuk Gallery Items Property
// =====================================================
// Coba satu per satu jika format pertama tidak bekerja
// =====================================================

// =====================================================
// OPSI 1: Dengan With() - Sama seperti loginBtn.c ⭐
// =====================================================
With(
    {
        result: POWERAPPS3.dboSPBTPREVIEWFilterComplete({
            ShowReview: rkToggleRv.Checked,
            SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
            SearchBatch: If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
            TransactionDate: TrxDpRvRk.SelectedDate,
            UploadedAt: UaDpRvRk.SelectedDate,
            ShowDebit: If(rkToggleRvCd.Checked, true, Blank()),
            SortBy: "MatchPercentage",
            SortOrder: "ASC"
        })
    },
    FirstN(
        Sort(
            result.ResultSets.Table1,
            MatchPercentage,
            SortOrder.Ascending
        ),
        200000
    )
)


// =====================================================
// OPSI 2: Jika Table1 tidak dikenali, coba tanpa ResultSets
// =====================================================
With(
    {
        result: POWERAPPS3.dboSPBTPREVIEWFilterComplete({
            ShowReview: rkToggleRv.Checked,
            SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
            TransactionDate: TrxDpRvRk.SelectedDate,
            SortBy: "MatchPercentage",
            SortOrder: "ASC"
        })
    },
    FirstN(
        Sort(
            result,  // Coba langsung result tanpa .ResultSets.Table1
            MatchPercentage,
            SortOrder.Ascending
        ),
        200000
    )
)


// =====================================================
// OPSI 3: Jika MatchPercentage tidak dikenali, gunakan nama kolom dengan bracket
// =====================================================
With(
    {
        result: POWERAPPS3.dboSPBTPREVIEWFilterComplete({
            ShowReview: rkToggleRv.Checked,
            SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
            TransactionDate: TrxDpRvRk.SelectedDate,
            SortBy: "MatchPercentage",
            SortOrder: "ASC"
        })
    },
    FirstN(
        Sort(
            result.ResultSets.Table1,
            result.ResultSets.Table1.MatchPercentage,  // Coba dengan full path
            SortOrder.Ascending
        ),
        200000
    )
)


// =====================================================
// OPSI 4: Jika masih error, coba tanpa Sort di Power Apps (sort sudah di SP)
// =====================================================
With(
    {
        result: POWERAPPS3.dboSPBTPREVIEWFilterComplete({
            ShowReview: rkToggleRv.Checked,
            SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
            TransactionDate: TrxDpRvRk.SelectedDate,
            SortBy: "MatchPercentage",  // Sort sudah di SP
            SortOrder: "ASC"
        })
    },
    FirstN(
        result.ResultSets.Table1,  // Langsung pakai hasil dari SP (sudah sorted)
        200000
    )
)


// =====================================================
// OPSI 5: Debug - Cek struktur hasil SP
// =====================================================
// Gunakan ini di OnSelect button untuk debug:
With(
    {
        result: POWERAPPS3.dboSPBTPREVIEWFilterComplete({
            ShowReview: rkToggleRv.Checked,
            TransactionDate: TrxDpRvRk.SelectedDate
        })
    },
    // Cek struktur result
    Notify(
        "Result type: " & Type(result) & 
        " | Has ResultSets: " & If(IsBlank(result.ResultSets), "No", "Yes") &
        " | Table1 count: " & CountRows(result.ResultSets.Table1),
        NotificationType.Information,
        5000
    )
)


// =====================================================
// CATATAN PENTING:
// =====================================================
// 1. Table1 adalah nama default untuk result set pertama dari SP
// 2. Jika SP mengembalikan multiple result sets, bisa Table1, Table2, dll
// 3. MatchPercentage harus sesuai dengan nama kolom di SP
// 4. Jika kolom tidak dikenali, coba:
//    - result.ResultSets.Table1["MatchPercentage"] (dengan bracket)
//    - Atau cek nama kolom di SP (case-sensitive)
// 5. Jika masih error, gunakan OPSI 4 (sort sudah di SP, tidak perlu sort lagi di Power Apps)

