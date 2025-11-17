// Filter untuk user non-FSS (tampilkan semua)
// Delegation-safe: Gunakan range comparison untuk date filter
FirstN(
    Sort(
        If(
            rkToggle.Checked,
            Filter(
                MP_REKENING_KORAN,
                btp = ""
            ),
            Filter(
                MP_REKENING_KORAN,
                (IsBlank(searchBtRk.Text) || searchBtRk.Text in BankType) &&
                // Filter tanggal sementara di-comment karena delegation issue
                // (IsBlank(CdRkDp.SelectedDate) || trx_date >= CdRkDp.SelectedDate) &&
                (IsBlank(searchBtpRk.Text) || searchBtpRk.Text in btp)
            )
        ),
        trx_date,
        SortOrder.Descending
    ),
    4000000
)