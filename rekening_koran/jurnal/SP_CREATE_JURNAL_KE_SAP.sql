-- =====================================================
-- SP_CREATE_JURNAL_KE_SAP
-- =====================================================
-- Menggabungkan step create jurnal ke SAP:
--   1. SP_JURNAL_CreateFromRekeningKoran  - buat jurnal dari rekening koran
--   2. SP_EXPORT_JURNAL_CSV_PIPE          - export ke format CSV (pipe)
--   3. TRUNCATE TABLE MP_JURNAL           - kosongkan MP_JURNAL
-- =====================================================

USE [POWERAPPS]
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_CREATE_JURNAL_KE_SAP]
    @StartDate NVARCHAR(50) = NULL,
    @EndDate   NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Create jurnal dari rekening koran
    EXEC [dbo].[SP_JURNAL_CreateFromRekeningKoran];

    -- 2. Export ke CSV (pipe) - result set dikembalikan ke client
    EXEC [dbo].[SP_EXPORT_JURNAL_CSV_PIPE] @StartDate = @StartDate, @EndDate = @EndDate;

    -- 3. Truncate MP_JURNAL
    TRUNCATE TABLE [dbo].[MP_JURNAL];
END
GO

PRINT 'SP_CREATE_JURNAL_KE_SAP created.';
PRINT '';
PRINT 'Usage:';
PRINT '  EXEC SP_CREATE_JURNAL_KE_SAP;';
PRINT '  EXEC SP_CREATE_JURNAL_KE_SAP @StartDate = ''2025-01-01'', @EndDate = ''2025-01-31'';';
PRINT '';
PRINT 'Steps: 1) Create jurnal  2) Export CSV (pipe)  3) Truncate MP_JURNAL';
GO
