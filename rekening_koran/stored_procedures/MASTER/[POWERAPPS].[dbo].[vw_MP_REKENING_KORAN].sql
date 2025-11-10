CREATE OR ALTER VIEW [POWERAPPS].[dbo].[VW_MP_REKENING_KORAN]
AS
SELECT 
    [id],
    [trx_date],
    [created_at],
    [updated_at],
    [credit],
    [btp],
    [desc],
    [Amount],
    [TransactionType],
    [BankType]
FROM [POWERAPPS].[dbo].[MP_REKENING_KORAN];
GO

