-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY_ResetJurnalForTesting.sql
-- ═══════════════════════════════════════════════════════════════════════════
-- Untuk testing berulang:
--   1. Set isJurnal di MP_REKENING_KORAN jadi 0 (belum di-jurnal)
--   2. TRUNCATE MP_JURNAL (kosongkan tabel jurnal)
-- Jalankan script ini sebelum menjalankan SP_JURNAL_CreateFromRekeningKoran lagi.
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Reset Jurnal untuk testing...';
PRINT '═══════════════════════════════════════════════════════════════════════';

-- 1. Update isJurnal = 0 di MP_REKENING_KORAN (semua row dianggap belum di-jurnal)
UPDATE [dbo].[MP_REKENING_KORAN]
SET [isJurnal] = 0
WHERE [isJurnal] = 1 OR [isJurnal] IS NULL;

PRINT '1. MP_REKENING_KORAN.isJurnal di-set ke 0: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' row.';

-- 2. Kosongkan MP_JURNAL
TRUNCATE TABLE [dbo].[MP_JURNAL];

PRINT '2. MP_JURNAL di-TRUNCATE (data jurnal dikosongkan).';
PRINT '';
PRINT '✅ Reset selesai. Bisa jalankan SP_JURNAL_CreateFromRekeningKoran lagi.';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
