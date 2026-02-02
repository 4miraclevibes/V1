-- ═══════════════════════════════════════════════════════════════════════════
-- MP_JURNAL - Tabel Jurnal (2 baris per 1 baris MP_REKENING_KORAN)
-- ═══════════════════════════════════════════════════════════════════════════
-- Sumber: MP_REKENING_KORAN. Setiap 1 row rekening koran → 2 row jurnal
-- (baris pertama posting_key 40, baris kedua posting_key 15)
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

IF OBJECT_ID('dbo.MP_JURNAL', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[MP_JURNAL];
    PRINT 'Dropped existing MP_JURNAL';
END
GO

CREATE TABLE [dbo].[MP_JURNAL] (
    [id]                BIGINT IDENTITY(1,1) NOT NULL,
    [no_urut]           NVARCHAR(4) NULL,           -- 0001, 0002, ... per (trx_date, AccountName)
    [row_line]          TINYINT NOT NULL,           -- 1 = baris pertama, 2 = baris kedua
    [source_rk_id]      BIGINT NULL,                -- FK ke MP_REKENING_KORAN.id (traceability)

    [document_date]     DATE NULL,
    [document_type]     NVARCHAR(10) NULL,          -- DEFAULT 'DZ'
    [company_code]      NVARCHAR(20) NULL,          -- 'id93' / 'id92' by AccountNumber
    [posting_date]      DATE NULL,
    [currency]          NVARCHAR(5) NULL,           -- 'IDR'
    [country_grouping]  NVARCHAR(50) NULL,
    [reference]         NVARCHAR(30) NULL,          -- ddmmyyyy-0001 format
    [material]          NVARCHAR(50) NULL,
    [document_header_text] NVARCHAR(25) NULL,       -- btn max 25 char (potong di space)
    [posting_key]       NVARCHAR(5) NULL,           -- '40' baris 1, '15' baris 2
    [customer]          NVARCHAR(255) NULL,         -- NULL baris 1, btp baris 2
    [account]           NVARCHAR(20) NULL,          -- 1113030303/1113030300 baris 1, NULL baris 2
    [special]           NVARCHAR(50) NULL,
    [amount]            DECIMAL(18,2) NULL,
    [value_date]        DATE NULL,
    [assignment]        NVARCHAR(20) NULL,          -- '3000'
    [text]              NVARCHAR(50) NULL,          -- desc 50 char dari belakang (potong di space)
    [profit_center]     NVARCHAR(20) NULL,         -- by AccountNumber
    [cost_center]       NVARCHAR(50) NULL,
    [order_no]          NVARCHAR(50) NULL,          -- "order" reserved, pakai order_no
    [tax_code]          NVARCHAR(20) NULL,
    [customer2]         NVARCHAR(255) NULL,         -- NULL baris 1, btp baris 2
    [sales_organization] NVARCHAR(50) NULL,
    [reason_code]       NVARCHAR(20) NULL,

    [created_at]        DATETIME NULL DEFAULT GETDATE(),

    CONSTRAINT PK_MP_JURNAL PRIMARY KEY CLUSTERED ([id])
);
GO

CREATE INDEX IX_MP_JURNAL_source_rk_id ON [dbo].[MP_JURNAL]([source_rk_id]);
CREATE INDEX IX_MP_JURNAL_reference ON [dbo].[MP_JURNAL]([reference]);
GO

PRINT 'MP_JURNAL table created.';
GO
