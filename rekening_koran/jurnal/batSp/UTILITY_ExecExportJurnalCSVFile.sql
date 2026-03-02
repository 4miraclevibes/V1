-- =====================================================
-- UTILITY: Exec SP_EXPORT_JURNAL_CSV_FILE
-- =====================================================
-- Jalankan script ini di SSMS untuk export jurnal ke CSV file
-- Hasil: C:\REKENINGKORAN\jurnal_{timestamp}.csv
--        + batch copy ke network share
-- =====================================================

USE [POWERAPPS]
GO

-- Export semua data jurnal
EXEC [dbo].[SP_EXPORT_JURNAL_CSV_FILE];

-- =====================================================
-- Opsi: Export dengan filter tanggal (uncomment untuk pakai)
-- =====================================================
/*
EXEC [dbo].[SP_EXPORT_JURNAL_CSV_FILE]
    @StartDate = '2025-01-01',
    @EndDate   = '2025-01-31';
*/
