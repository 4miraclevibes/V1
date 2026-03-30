-- =====================================================
-- UTILITY_CheckOleEnabled.sql
-- =====================================================
-- Cek OLE Automation Procedures aktif atau tidak.
-- Kalau aktif (1) = bisa pakai sp_OACreate / WinHttp di SP untuk hit API.
-- Kalau tidak (0) = pakai cara lain (xp_cmdshell + curl, atau app layer).
-- =====================================================

USE [POWERAPPS];
GO

DECLARE @OleValue INT;

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

SELECT @OleValue = CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = 'Ole Automation Procedures';

SELECT 
    @OleValue AS [Ole_Config_Value],
    CASE WHEN @OleValue = 1 THEN 'Aktif – bisa pakai OLE di SP (sp_OACreate, WinHttp)' 
         ELSE 'Tidak aktif – tidak bisa pakai OLE di SP' 
    END AS [Status];
