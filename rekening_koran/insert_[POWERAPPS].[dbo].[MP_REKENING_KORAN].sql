INSERT INTO [POWERAPPS].[dbo].[MP_REKENING_KORAN] (
    [trx_date],
    [created_at],
    [updated_at],
    [credit],
    [btp],
    [desc]
)
SELECT 
    [Tanggal Transaksi] AS [trx_date],
    [created_date] AS [created_at],
    GETDATE() AS [updated_at],
    [Credit] AS [credit],
    [Billto Party] AS [btp],
    [Keterangan] AS [desc]
FROM [AFINDO].[dbo].[FA_Bank_Statement]

