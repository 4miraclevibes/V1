-- =====================================================
-- FIX_BIFAST_DATE.sql
-- =====================================================
-- Problem: BIFAST TransactionDate kebalik bulan dan tanggal
-- Root Cause: TRY_CAST tidak explicit format, SQL Server interpret sesuai regional
-- 
-- SEBELUM (line 389):
--   COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate)
--
-- SESUDAH:
--   COALESCE(TRY_CONVERT(DATE, temp.TransactionDate, 103), t.TransactionDate)
--
-- Format 103 = DD/MM/YYYY (British/French)
-- =====================================================

-- =====================================================
-- CARA 1: Patch langsung di SP_MASTER_FindBTP_SaveToReview
-- =====================================================

-- Cari dan replace di bagian BIFAST (sekitar line 389):

-- SEBELUM:
-- temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,

-- SESUDAH:
-- temp.TransactionID, COALESCE(TRY_CONVERT(DATE, temp.TransactionDate, 103), t.TransactionDate) AS TransactionDate, t.Description AS Description,


-- =====================================================
-- CARA 2: Atau ubah cara pass date ke SP_BIFAST (lebih clean)
-- =====================================================

-- SEBELUM (line 356):
-- CONVERT(NVARCHAR(50), TransactionDate, 103) AS transaction_date,  -- Format DD/MM/YYYY

-- SESUDAH:
-- CONVERT(NVARCHAR(50), TransactionDate, 23) AS transaction_date,  -- Format YYYY-MM-DD (ISO)

-- Lalu di INSERT, pakai:
-- COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate)
-- Karena YYYY-MM-DD adalah format universal yang selalu di-parse dengan benar


-- =====================================================
-- VERIFIKASI SETELAH FIX
-- =====================================================

-- Test parsing format DD/MM/YYYY vs YYYY-MM-DD
SELECT 
    '08/10/2024' AS InputString,
    TRY_CAST('08/10/2024' AS DATE) AS TryCast_Ambiguous,  -- Bisa salah!
    TRY_CONVERT(DATE, '08/10/2024', 103) AS TryConvert_103,  -- DD/MM/YYYY - BENAR
    TRY_CONVERT(DATE, '2024-10-08', 23) AS TryConvert_23;  -- YYYY-MM-DD - BENAR

-- Expected result:
-- InputString  | TryCast_Ambiguous | TryConvert_103 | TryConvert_23
-- 08/10/2024   | 2024-08-10 (SALAH)| 2024-10-08     | 2024-10-08
