// Button: Hitung Total Row (OnSelect)

Set(
    varCount,
    First(
        '[dbo].[SP_BTP_REVIEW_CountDynamic]'.Run(
            searchBatchRv.Text,        // @SearchBatch
            TrxDpRvRk.SelectedDate     // @TransactionDate
        )
    )
);

Notify(
    "Total: " & varCount.TotalRows & 
    " | CR: " & varCount.TotalCR & 
    " | DB: " & varCount.TotalDB,
    NotificationType.Information,
    3000
);
