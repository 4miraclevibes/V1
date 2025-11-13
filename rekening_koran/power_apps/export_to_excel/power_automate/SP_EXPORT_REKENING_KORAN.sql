-- =====================================================
-- SP_EXPORT_REKENING_KORAN
-- =====================================================
-- Purpose: Stored Procedure untuk export data dari VW_MP_REKENING_KORAN
--          Support filter parameters untuk Power Automate
--          Compatible dengan on-premises gateway
--          Exclude credit, include Amount, TransactionType, BankType
-- =====================================================

USE [POWERAPPS]
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_EXPORT_REKENING_KORAN]
    @StartDate NVARCHAR(50) = NULL,
    @EndDate NVARCHAR(50) = NULL,
    @BTP NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Convert string dates to DATETIME (handle NULL)
    DECLARE @StartDateDT DATETIME = NULL;
    DECLARE @EndDateDT DATETIME = NULL;
    
    IF @StartDate IS NOT NULL AND LEN(LTRIM(RTRIM(@StartDate))) > 0
    BEGIN
        SET @StartDateDT = TRY_CAST(@StartDate AS DATETIME);
    END
    
    IF @EndDate IS NOT NULL AND LEN(LTRIM(RTRIM(@EndDate))) > 0
    BEGIN
        SET @EndDateDT = TRY_CAST(@EndDate AS DATETIME);
    END
    
    -- Query dengan filter menggunakan kolom dari VW_MP_REKENING_KORAN
    SELECT 
        [Tanggal Transaksi],
        [Keterangan],
        [Jumlah],
        [DB/CR],
        [Bill To Party],
        [Bank Type]
    FROM [dbo].[VW_MP_REKENING_KORAN]
    WHERE 
        (@StartDateDT IS NULL OR [Tanggal Transaksi] >= @StartDateDT)
        AND (@EndDateDT IS NULL OR [Tanggal Transaksi] <= @EndDateDT)
        AND (@BTP IS NULL OR LEN(LTRIM(RTRIM(@BTP))) = 0 OR [Bill To Party] = @BTP)
    ORDER BY [Tanggal Transaksi] DESC;
    
END
GO

PRINT '✅ SP_EXPORT_REKENING_KORAN created successfully!';
PRINT '';
PRINT 'Usage:';
PRINT '  EXEC SP_EXPORT_REKENING_KORAN;  -- Export semua data';
PRINT '  EXEC SP_EXPORT_REKENING_KORAN @StartDate = ''2025-01-01'', @EndDate = ''2025-01-31'';';
PRINT '  EXEC SP_EXPORT_REKENING_KORAN @BTP = ''2300012345'';';
GO

