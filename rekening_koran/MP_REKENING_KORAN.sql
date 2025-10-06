CREATE TABLE [MP_REKENING_KORAN] (
    [id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [trx_date] DATE NOT NULL,
    [created_at] DATETIME NOT NULL,
    [updated_at] DATETIME NOT NULL,
    [credit] DECIMAL(18,2) NOT NULL,
    [btp] VARCHAR(255) NOT NULL,
    [keterangan] VARCHAR(255) NOT NULL,
);
 