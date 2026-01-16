// Label Text - Count dinamis berdasarkan search/filter
// Filter collection dengan kondisi search yang aktif

With(
    {
        filtered: Filter(
            colBtpReview,
            IsApproved = false &&
            (IsBlank(searchCustomerRv.Text) || searchCustomerRv.Text in CustomerName) &&
            (IsBlank(searchBatchRv.Text) || searchBatchRv.Text in BatchID) &&
            (IsBlank(searchDescRv.Text) || searchDescRv.Text in Description) &&
            (IsBlank(searchBtRv.Text) || searchBtRv.Text in BankType) &&
            (IsBlank(UaDpRvRk.SelectedDate) || DateValue(UploadedAt) = UaDpRvRk.SelectedDate) &&
            (IsBlank(TrxDpRvRkF.SelectedDate) || DateValue(TransactionDate) >= TrxDpRvRkF.SelectedDate) &&
            (IsBlank(TrxDpRvRkL.SelectedDate) || DateValue(TransactionDate) <= TrxDpRvRkL.SelectedDate) &&
            (IsBlank(searchBtpRv.Text) || searchBtpRv.Text in BTP)
        )
    },
    "Total: " & CountRows(filtered) & " | " & Text(Sum(filtered, Amount), "#,##0") &
    Char(10) &
    "CR: " & CountIf(filtered, TransactionType = "CR") & " | " & Text(Sum(Filter(filtered, TransactionType = "CR"), Amount), "#,##0") &
    Char(10) &
    "DB: " & CountIf(filtered, TransactionType = "DB") & " | " & Text(Sum(Filter(filtered, TransactionType = "DB"), Amount), "#,##0")
)
