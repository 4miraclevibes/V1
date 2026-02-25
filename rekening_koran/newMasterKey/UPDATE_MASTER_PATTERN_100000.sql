-- =====================================================
-- UPDATE_MASTER_PATTERN_100000.sql
-- =====================================================
-- Purpose: Update data di MASTER_CUSTOMER_BTP_PATTERN yang sebelumnya
--          di-insert dengan nilai 100, 100, 100, 100 (kecuali match_percentage)
--          → Ubah menjadi 100000, 100000, 100.00, 100000
--
-- Target: Baris dengan category='NEW', match_count=100, total_transactions=100,
--         match_percentage=100.00, last_line_number=100 (dari INSERT sebelumnya)
-- =====================================================

USE [POWERAPPS];
GO

-- ═══════════════════════════════════════════════════════════════════════
-- Preview: berapa baris yang akan di-update
-- ═══════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'UPDATE: MASTER_CUSTOMER_BTP_PATTERN (100 → 100000)';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

DECLARE @UpdateCount INT;
SELECT @UpdateCount = COUNT(*)
FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
WHERE [category] = 'NEW'
  AND [match_count] = 100
  AND [total_transactions] = 100
  AND [match_percentage] = 100.00
  AND [last_line_number] = 100;

PRINT 'Rows to update (kondisi: category=NEW, match_count=100, total_transactions=100, last_line_number=100): ' + CAST(@UpdateCount AS VARCHAR);
PRINT '';

IF @UpdateCount = 0
BEGIN
    PRINT 'Tidak ada baris yang memenuhi kondisi.';
    RETURN;
END;

-- ═══════════════════════════════════════════════════════════════════════
-- UPDATE: 100 → 100000 (kecuali match_percentage tetap 100.00)
-- ═══════════════════════════════════════════════════════════════════════

UPDATE [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]
SET [match_count] = 100000,
    [total_transactions] = 100000,
    [last_line_number] = 100000
WHERE [category] = 'NEW'
  AND [match_count] = 100
  AND [total_transactions] = 100
  AND [match_percentage] = 100.00
  AND [last_line_number] = 100;

PRINT '✅ Updated ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '   - match_count: 100 → 100000';
PRINT '   - total_transactions: 100 → 100000';
PRINT '   - last_line_number: 100 → 100000';
PRINT '   - match_percentage: tetap 100.00';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Done.';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
