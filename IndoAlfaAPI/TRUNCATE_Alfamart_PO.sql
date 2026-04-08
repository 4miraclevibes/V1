-- =====================================================
-- Hapus semua data tabel Alfamart PO (Response, Header, Detail)
-- Catatan:
--   Karena ada FOREIGN KEY antar tabel, TRUNCATE langsung tidak bisa.
--   Jadi dipakai DELETE + reseed identity (efeknya mirip TRUNCATE).
-- =====================================================

USE [POWERAPPS];
GO

-- Hapus dari child ke parent (urutan FK)
DELETE FROM [dbo].[Alfamart_PO_Detail];
DELETE FROM [dbo].[Alfamart_PO_Header];
DELETE FROM [dbo].[Alfamart_PO_Response];
GO

-- Reset identity ke 1 lagi
IF OBJECT_ID('dbo.Alfamart_PO_Detail', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.Alfamart_PO_Detail', RESEED, 0);

IF OBJECT_ID('dbo.Alfamart_PO_Header', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.Alfamart_PO_Header', RESEED, 0);

IF OBJECT_ID('dbo.Alfamart_PO_Response', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.Alfamart_PO_Response', RESEED, 0);
GO

PRINT 'Data Alfamart_PO_* sudah dikosongkan dan identity di-reset.';
GO

