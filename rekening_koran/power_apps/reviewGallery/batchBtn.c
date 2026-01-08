// Button: Tampilkan Total Row
// OnSelect property - Panggil SP untuk hitung total row

// Set loading state
UpdateContext({_isLoadingCount: true});

// Panggil Stored Procedure untuk menghitung total row
Set(
    varTotalRows,
    First(
        '[dbo].[SP_BTP_REVIEW_CountRows]'.Run(
            // @ShowReview - true jika toggle review aktif
            rkToggleRv.Checked,
            
            // Status untuk review mode
            true,  // @IncludeNoMatch
            true,  // @IncludeUnknownBank
            true,  // @IncludeMissing
            true,  // @IncludeNoPattern
            
            // Status untuk approved mode
            true,  // @IncludeFair
            true,  // @IncludeGood
            true,  // @IncludeLow
            true,  // @IncludeExcellent
            
            // @IsApproved
            false,
            
            // Filter text
            If(IsBlank(searchCustomerRv.Text), Blank(), searchCustomerRv.Text),    // @SearchCustomer
            If(IsBlank(searchBatchRv.Text), Blank(), searchBatchRv.Text),          // @SearchBatch
            If(IsBlank(searchDescRv.Text), Blank(), searchDescRv.Text),            // @SearchDescription
            If(IsBlank(searchBtRv.Text), Blank(), searchBtRv.Text),                // @SearchBankType
            If(IsBlank(searchBtpRv.Text), Blank(), searchBtpRv.Text),              // @SearchBTP
            
            // Filter tanggal
            UaDpRvRk.SelectedDate,    // @UploadedAt
            TrxDpRvRk.SelectedDate,   // @TransactionDate
            
            // @ShowDebit - true=DB, false=CR
            rkToggleRvCd.Checked
        )
    ).TotalRows
);

// Tampilkan dialog dengan total row
UpdateContext({_isLoadingCount: false});

Notify(
    "Total data: " & Text(varTotalRows) & " row" & If(varTotalRows > 2000, " (Power Apps hanya menampilkan 2000)", ""),
    If(varTotalRows > 2000, NotificationType.Warning, NotificationType.Information),
    3000
);

