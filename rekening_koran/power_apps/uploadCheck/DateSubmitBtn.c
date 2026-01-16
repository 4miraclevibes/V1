// DateSubmitBtn OnSelect
// Cek tanggal mana saja yang sudah/belum di-upload dalam range DateFrom - DateTo

// 1. Simpan distinct trx_date yang sudah ada dalam range
ClearCollect(
    colUploadedDates,
    Sort(
        Distinct(
            Filter(
                colRk,
                DateValue(trx_date) >= DateFrom.SelectedDate &&
                DateValue(trx_date) <= DateTo.SelectedDate
            ),
            trx_date
        ),
        Value,
        SortOrder.Ascending
    )
);

// 2. Generate semua tanggal dalam range
ClearCollect(
    colAllDates,
    ForAll(
        Sequence(
            DateDiff(DateFrom.SelectedDate, DateTo.SelectedDate, TimeUnit.Days) + 1,
            0,
            1
        ),
        DateAdd(DateFrom.SelectedDate, Value, TimeUnit.Days)
    )
);

// 3. Filter tanggal yang BELUM di-upload
ClearCollect(
    colMissingDates,
    Filter(
        colAllDates,
        !(Value in colUploadedDates.Value)
    )
);

// 4. Simpan text untuk tanggal yang SUDAH di-upload
Set(
    varUploadedDatesText,
    If(
        CountRows(colUploadedDates) > 0,
        "Sudah di-upload (" & CountRows(colUploadedDates) & "):" &
        Char(10) &
        Concat(
            colUploadedDates,
            Text(DateValue(Value), "dd/mm/yyyy"),
            Char(10)
        ),
        "Tidak ada data dalam range"
    )
);

// 5. Simpan text untuk tanggal yang BELUM di-upload
Set(
    varMissingDatesText,
    If(
        CountRows(colMissingDates) > 0,
        "Belum di-upload (" & CountRows(colMissingDates) & "):" &
        Char(10) &
        Concat(
            colMissingDates,
            Text(Value, "dd/mm/yyyy"),
            Char(10)
        ),
        "Semua tanggal sudah di-upload!"
    )
);

// 6. Set count
Set(varUploadedCount, CountRows(colUploadedDates));
Set(varMissingCount, CountRows(colMissingDates));