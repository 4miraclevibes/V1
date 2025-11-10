CREATE OR ALTER VIEW [dbo].[VW_MP_REKENING_KORAN]
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
FROM [dbo].[MP_REKENING_KORAN];
GO

