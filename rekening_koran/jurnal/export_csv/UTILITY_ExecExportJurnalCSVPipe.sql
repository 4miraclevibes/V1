-- =====================================================
-- UTILITY: Exec SP_EXPORT_JURNAL_CSV_PIPE
-- =====================================================
-- Jalankan script ini di SSMS untuk export jurnal ke format CSV (pipe separator)
-- Hasil: 1 row, 1 column CSVContent. Copy & paste ke file .csv atau .psv
-- =====================================================

USE [POWERAPPS]
GO

-- Export semua data jurnal
EXEC [dbo].[SP_EXPORT_JURNAL_CSV_PIPE];

-- =====================================================
-- Opsi: Export dengan filter tanggal (uncomment untuk pakai)
-- =====================================================
/*
EXEC [dbo].[SP_EXPORT_JURNAL_CSV_PIPE]
    @StartDate = '2025-01-01',
    @EndDate   = '2025-01-31';
*/
