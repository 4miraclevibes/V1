-- =====================================================
-- CREATE TABLE Alfamart PO Response (dari API B2B Auto Download)
-- =====================================================
-- Struktur mengikuti response PO-PurchaseOrderOle.json
-- =====================================================

USE [POWERAPPS];
GO

-- 1. Response (satu row per panggilan API)
IF OBJECT_ID('dbo.Alfamart_PO_Response', 'U') IS NOT NULL DROP TABLE [dbo].[Alfamart_PO_Response];
CREATE TABLE [dbo].[Alfamart_PO_Response] (
    [id]            BIGINT IDENTITY(1,1) NOT NULL,
    [status_code]   INT NULL,
    [status]        VARCHAR(10) NULL,
    [message]       NVARCHAR(500) NULL,
    [response_at]   DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT [PK_Alfamart_PO_Response] PRIMARY KEY CLUSTERED ([id])
);
GO

-- 2. Header (satu row per PO di result[], plus kolom trailer)
IF OBJECT_ID('dbo.Alfamart_PO_Header', 'U') IS NOT NULL DROP TABLE [dbo].[Alfamart_PO_Header];
CREATE TABLE [dbo].[Alfamart_PO_Header] (
    [id]              BIGINT IDENTITY(1,1) NOT NULL,
    [response_id]      BIGINT NOT NULL,
    [result_index]     INT NOT NULL,
    -- header
    [rec_tag]          VARCHAR(20) NULL,
    [po_no]            VARCHAR(50) NULL,
    [po_date]          VARCHAR(20) NULL,
    [exp_date]         VARCHAR(20) NULL,
    [proc_date]        VARCHAR(20) NULL,
    [dlv_code]         VARCHAR(20) NULL,
    [dlv_name]         NVARCHAR(200) NULL,
    [dlv_town]         NVARCHAR(100) NULL,
    [sup_code]         VARCHAR(100) NULL,
    [sup_name]         NVARCHAR(200) NULL,
    [sup_add]          NVARCHAR(500) NULL,
    [sup_phone]        VARCHAR(50) NULL,
    [sup_fax]          VARCHAR(50) NULL,
    -- trl (trailer)
    [trl_rec_tag]      VARCHAR(20) NULL,
    [tot_purchase]     BIGINT NULL,
    [tot_disc]         BIGINT NULL,
    [tot_aft_disc]     BIGINT NULL,
    [tot_ppn]          BIGINT NULL,
    [tot_aft_ppn]      BIGINT NULL,
    [total_fpp]        BIGINT NULL,
    [amount_in_words]  NVARCHAR(500) NULL,
    [contact]          VARCHAR(50) NULL,
    [supp_accno]       VARCHAR(50) NULL,
    [supp_accnm]       NVARCHAR(200) NULL,
    [supp_bank]        VARCHAR(50) NULL,
    [barcode_in]       VARCHAR(50) NULL,
    CONSTRAINT [PK_Alfamart_PO_Header] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_Alfamart_PO_Header_Response] FOREIGN KEY ([response_id]) REFERENCES [dbo].[Alfamart_PO_Response]([id])
);
GO

-- 3. Detail (satu row per line di detail[])
IF OBJECT_ID('dbo.Alfamart_PO_Detail', 'U') IS NOT NULL DROP TABLE [dbo].[Alfamart_PO_Detail];
CREATE TABLE [dbo].[Alfamart_PO_Detail] (
    [id]       BIGINT IDENTITY(1,1) NOT NULL,
    [header_id] BIGINT NOT NULL,
    [rec_tag]   VARCHAR(20) NULL,
    [desc]      NVARCHAR(500) NULL,
    [qty_crt]   INT NULL,
    [qty_pcs]   INT NULL,
    [plu]       BIGINT NULL,
    [barcode]   VARCHAR(50) NULL,
    [price]     DECIMAL(18,2) NULL,
    [uom]       VARCHAR(20) NULL,
    [cnv]       VARCHAR(20) NULL,
    [disc_a]    VARCHAR(20) NULL,
    [remark]    NVARCHAR(200) NULL,
    [net]       DECIMAL(18,2) NULL,
    [ppnbm]     DECIMAL(18,2) NULL,
    [total]     BIGINT NULL,
    [plu_b]     BIGINT NULL,
    [qty_b]     INT NULL,
    [price_b]   DECIMAL(18,2) NULL,
    [disc_b]    VARCHAR(20) NULL,
    CONSTRAINT [PK_Alfamart_PO_Detail] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_Alfamart_PO_Detail_Header] FOREIGN KEY ([header_id]) REFERENCES [dbo].[Alfamart_PO_Header]([id])
);
GO

CREATE NONCLUSTERED INDEX [IX_Alfamart_PO_Header_response_id] ON [dbo].[Alfamart_PO_Header]([response_id]);
CREATE NONCLUSTERED INDEX [IX_Alfamart_PO_Detail_header_id]   ON [dbo].[Alfamart_PO_Detail]([header_id]);
GO

PRINT 'Alfamart_PO_Response, Alfamart_PO_Header, Alfamart_PO_Detail created.';
GO
