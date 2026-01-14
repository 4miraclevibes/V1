// Button: Hitung Total Row (OnSelect)
// Pakai SP - gunakan setelah connector sudah sync

Set(
    rvResult,
    POWERAPPS4.dboSPBTPREVIEWCountDynamic({
        SearchBatch: If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),
        TransactionDate: If(IsBlank(TrxDpRvRkF.SelectedDate), Blank(), TrxDpRvRkF.SelectedDate)
    })
);

If(
    CountRows(rvResult.ResultSets.Table1) > 0,
    Set(rvTotalRows, First(rvResult.ResultSets.Table1).TotalRows);
    Set(rvTotalCR, First(rvResult.ResultSets.Table1).TotalCR);
    Set(rvTotalDB, First(rvResult.ResultSets.Table1).TotalDB);
    Notify(
        "Total: " & rvTotalRows & 
        " | CR: " & rvTotalCR & 
        " | DB: " & rvTotalDB,
        NotificationType.Information,
        3000
    ),
    Notify(
        "Tidak ada data",
        NotificationType.Warning
    )
);
