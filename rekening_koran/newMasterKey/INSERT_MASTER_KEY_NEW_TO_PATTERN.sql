-- =====================================================
-- INSERT_MASTER_KEY_NEW_TO_PATTERN.sql
-- =====================================================
-- Purpose: Insert data dari [MASTER KEY NEW] ke [MASTER_CUSTOMER_BTP_PATTERN]
--          HANYA baris yang BELUM ADA di MASTER_CUSTOMER_BTP_PATTERN
--          Compare: (customer_name = BILL_NAME_RK) AND (btp = BILL_RK)
--
-- Source: [POWERAPPS].[dbo].[MASTER KEY NEW]
-- Target: [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
--
-- Default values untuk kolom baru:
--   category = 'NEW'
--   match_count = 100000
--   total_transactions = 100000
--   match_percentage = 100.00
--   last_line_number = 100000
--   created_date = GETDATE()
--   type = 'MT'
-- =====================================================

USE [POWERAPPS];
GO

-- ═══════════════════════════════════════════════════════════════════════
-- Preview: berapa baris yang akan di-insert (belum ada di current)
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'INSERT: MASTER KEY NEW → MASTER_CUSTOMER_BTP_PATTERN (hanya yang belum ada)';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @PreviewCount INT;
SELECT @PreviewCount = COUNT(*)
FROM [POWERAPPS].[dbo].[MASTER KEY NEW] n
WHERE NOT EXISTS (
    SELECT 1
    FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN] p
    WHERE LTRIM(RTRIM(ISNULL(p.customer_name, ''))) = LTRIM(RTRIM(ISNULL(n.BILL_NAME_RK, '')))
      AND LTRIM(RTRIM(ISNULL(p.btp, ''))) = LTRIM(RTRIM(ISNULL(n.BILL_RK, '')))
);

PRINT 'Rows to insert (belum ada di current): ' + CAST(@PreviewCount AS VARCHAR);
PRINT '';

IF @PreviewCount = 0
BEGIN
    PRINT 'Tidak ada data baru. Semua data di MASTER KEY NEW sudah ada di MASTER_CUSTOMER_BTP_PATTERN.';
    RETURN;
END;

-- ═══════════════════════════════════════════════════════════════════════
-- INSERT: hanya baris yang tidak ditemukan (customer_name + btp unik)
-- ═══════════════════════════════════════════════════════════════════════

INSERT INTO [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN] (
    [customer_name],
    [btp],
    [category],
    [match_count],
    [total_transactions],
    [match_percentage],
    [last_line_number],
    [created_date],
    [type]
)
SELECT
    LTRIM(RTRIM(ISNULL(n.BILL_NAME_RK, ''))) AS [customer_name],
    LTRIM(RTRIM(ISNULL(n.BILL_RK, ''))) AS [btp],
    'NEW' AS [category],
    100000 AS [match_count],
    100000 AS [total_transactions],
    100.00 AS [match_percentage],
    100000 AS [last_line_number],
    GETDATE() AS [created_date],
    'MT' AS [type]
FROM [POWERAPPS].[dbo].[MASTER KEY NEW] n
WHERE NOT EXISTS (
    SELECT 1
    FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN] p
    WHERE LTRIM(RTRIM(ISNULL(p.customer_name, ''))) = LTRIM(RTRIM(ISNULL(n.BILL_NAME_RK, '')))
      AND LTRIM(RTRIM(ISNULL(p.btp, ''))) = LTRIM(RTRIM(ISNULL(n.BILL_RK, '')))
)
  AND LTRIM(RTRIM(ISNULL(n.BILL_NAME_RK, ''))) <> ''   -- skip jika kosong
  AND LTRIM(RTRIM(ISNULL(n.BILL_RK, ''))) <> '';      -- skip jika kosong

PRINT '✅ Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows ke MASTER_CUSTOMER_BTP_PATTERN';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Done.';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
