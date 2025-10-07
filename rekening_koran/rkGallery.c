    // Filter untuk user non-FSS (tampilkan semua)
    FirstN(
        Sort(
            If(
                rkToggle.Value,
                Filter(MP_REKENING_KORAN, btp = ""),
                MP_REKENING_KORAN
            ),
            created_at,
            SortOrder.Descending
        ),
        200000
    )