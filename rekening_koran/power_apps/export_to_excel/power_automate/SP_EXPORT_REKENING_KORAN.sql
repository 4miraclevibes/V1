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
    
    -- Convert string dates to DATETIME (handle NULL dan empty string)
    DECLARE @StartDateDT DATETIME = NULL;
    DECLARE @EndDateDT DATETIME = NULL;
    DECLARE @StartDateOnly DATE = NULL;
    DECLARE @EndDateOnly DATE = NULL;
    
    -- Handle StartDate: jika ada, convert ke DATETIME (mulai dari 00:00:00)
    IF @StartDate IS NOT NULL AND LEN(LTRIM(RTRIM(@StartDate))) > 0
    BEGIN
        -- Coba parse langsung sebagai DATETIME
        SET @StartDateDT = TRY_CAST(LTRIM(RTRIM(@StartDate)) AS DATETIME);
        
        -- Jika gagal, coba parse sebagai DATE lalu convert ke DATETIME (00:00:00)
        IF @StartDateDT IS NULL
        BEGIN
            SET @StartDateOnly = TRY_CAST(LTRIM(RTRIM(@StartDate)) AS DATE);
            IF @StartDateOnly IS NOT NULL
            BEGIN
                SET @StartDateDT = CAST(@StartDateOnly AS DATETIME);
            END
        END
    END
    
    -- Handle EndDate: jika ada, convert ke DATETIME (sampai 23:59:59)
    IF @EndDate IS NOT NULL AND LEN(LTRIM(RTRIM(@EndDate))) > 0
    BEGIN
        -- Coba parse langsung sebagai DATETIME
        SET @EndDateDT = TRY_CAST(LTRIM(RTRIM(@EndDate)) AS DATETIME);
        
        -- Jika gagal, coba parse sebagai DATE lalu convert ke DATETIME dengan waktu akhir hari
        IF @EndDateDT IS NULL
        BEGIN
            SET @EndDateOnly = TRY_CAST(LTRIM(RTRIM(@EndDate)) AS DATE);
            IF @EndDateOnly IS NOT NULL
            BEGIN
                -- Set ke akhir hari (23:59:59)
                SET @EndDateDT = DATEADD(SECOND, 86399, CAST(@EndDateOnly AS DATETIME));
            END
        END
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

