-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY_ExecCreateJurnal.sql
-- ═══════════════════════════════════════════════════════════════════════════
-- Jalankan SP untuk membuat jurnal dari rekening koran.
-- Hanya row MP_REKENING_KORAN dengan isJurnal = 0/NULL yang diproses.
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Exec: SP_JURNAL_CreateFromRekeningKoran';
PRINT '═══════════════════════════════════════════════════════════════════════';

EXEC [dbo].[SP_JURNAL_CreateFromRekeningKoran];

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Selesai.';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
