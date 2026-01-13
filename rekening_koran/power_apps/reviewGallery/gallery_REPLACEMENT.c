// =====================================================
// REPLACEMENT untuk gallery.c - Menggunakan SP dengan Parameter
// =====================================================
// Copy-paste ini ke Items property gallery Anda
// =====================================================

// =====================================================
// FORMAT PALING SEDERHANA - Hanya Memanggil Data (Coba ini dulu!) ⭐
// =====================================================
// Items Property Gallery:
With(
    {
        result: POWERAPPS3.dboSPBTPREVIEWFilterComplete({})
    },
    result.ResultSets.Table1
)

// =====================================================
// FORMAT LENGKAP - Dengan Filter dan Sort (Gunakan setelah format sederhana berhasil)
// =====================================================
// Items Property Gallery:
With(
    {
        result: POWERAPPS3.dboSPBTPREVIEWFilterComplete({
            // Filter Status (review vs approved)
            ShowReview: rkToggleRv.Checked,
            
            // Filter Search Text
            SearchCustomer: If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),
            SearchBatch: If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
            SearchDescription: If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),
            SearchBankType: If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),
            SearchBTP: If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),
            
            // Filter Date
            TransactionDate: TrxDpRvRk.SelectedDate,
            UploadedAt: UaDpRvRk.SelectedDate,
            
            // Filter Transaction Type
            ShowDebit: If(rkToggleRvCd.Checked, true, Blank()),  // true = DB only, Blank = CR/All
            
            // Sorting
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
// PENJELASAN PARAMETER:
// =====================================================
//
// ShowReview: 
//   - true = tampilkan yang perlu review (NO_MATCH, NO_PATTERN, dll)
//   - false = tampilkan yang approved (FAIR, GOOD, EXCELLENT, dll)
//
// SearchCustomer, SearchBatch, dll:
//   - IsBlank(...) ? Blank() : ... = kirim NULL ke SP jika kosong
//   - Power Apps Blank() = SQL NULL
//
// TransactionDate, UploadedAt:
//   - Langsung kirim SelectedDate (bisa Blank() jika tidak dipilih)
//
// ShowDebit:
//   - true = hanya DB (Debit)
//   - false atau Blank() = CR atau semua
//
// SortBy, SortOrder:
//   - SortBy: "MatchPercentage", "CreatedAt", atau "TransactionDate"
//   - SortOrder: "ASC" atau "DESC"

