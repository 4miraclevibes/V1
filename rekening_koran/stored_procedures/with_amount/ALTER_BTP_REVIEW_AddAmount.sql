-- =====================================================
-- ALTER_BTP_REVIEW_AddAmount.sql
-- =====================================================
-- Purpose: Memastikan kolom Amount dan TransactionType ada di BTP_REVIEW
-- Jalankan script ini jika kolom belum ada
-- =====================================================

USE POWERAPPS;
GO

-- Cek dan tambahkan kolom Amount jika belum ada
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'BTP_REVIEW' 
    AND COLUMN_NAME = 'Amount'
)
BEGIN
    ALTER TABLE [dbo].[BTP_REVIEW]
    ADD [Amount] DECIMAL(18,2) NULL;
    
    PRINT '✅ Kolom Amount berhasil ditambahkan';
END
ELSE
BEGIN
    PRINT '✓ Kolom Amount sudah ada';
END
GO

-- Cek dan tambahkan kolom TransactionType jika belum ada
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'BTP_REVIEW' 
    AND COLUMN_NAME = 'TransactionType'
)
BEGIN
    ALTER TABLE [dbo].[BTP_REVIEW]
    ADD [TransactionType] NVARCHAR(2) NULL;
    
    PRINT '✅ Kolom TransactionType berhasil ditambahkan';
END
ELSE
BEGIN
    PRINT '✓ Kolom TransactionType sudah ada';
END
GO

-- Verifikasi struktur tabel
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'BTP_REVIEW'
AND COLUMN_NAME IN ('Amount', 'TransactionType')
ORDER BY ORDINAL_POSITION;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';
PRINT '✅ ALTER_BTP_REVIEW_AddAmount.sql completed!';
PRINT '═══════════════════════════════════════════════════════════════';
GO
