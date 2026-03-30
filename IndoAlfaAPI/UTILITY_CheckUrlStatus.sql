-- =====================================================
-- UTILITY_CheckUrlStatus.sql
-- =====================================================
-- Cek URL/API hidup atau mati dari SQL Server.
-- Return: HTTP status code (200 = OK, 0 = timeout/unreachable, dll.)
--
-- Prasyarat:
--   1. xp_cmdshell enabled: EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
--   2. curl ada di server (Windows 10+ biasanya sudah ada)
-- =====================================================

USE [POWERAPPS];
GO

-- Ganti URL ini dengan endpoint yang mau dicek
DECLARE @URL VARCHAR(500) = 'https://b2b-ap.alfamart.co.id';
DECLARE @cmd VARCHAR(1000);
DECLARE @StatusCode VARCHAR(10);

-- Capture output dari curl (hanya HTTP status code)
IF OBJECT_ID('tempdb..#Out') IS NOT NULL DROP TABLE #Out;
CREATE TABLE #Out (line VARCHAR(8000));

SET @cmd = 'curl -s -o NUL -w "%{http_code}" --connect-timeout 5 "' + @URL + '"';
INSERT INTO #Out (line) EXEC master..xp_cmdshell @cmd;

-- Ambil baris yang berisi angka (status code)
SELECT @StatusCode = LTRIM(RTRIM(line))
FROM #Out
WHERE line IS NOT NULL AND LTRIM(RTRIM(line)) <> '' AND line NOT LIKE '%curl%';

-- Jika tidak ketemu (timeout/error), curl kadang return kosong
IF @StatusCode IS NULL OR @StatusCode = ''
    SET @StatusCode = '0';

DROP TABLE #Out;

-- Return status
SELECT 
    @URL AS [URL],
    @StatusCode AS [HTTP_Status],
    CASE 
        WHEN @StatusCode = '200' THEN 'Hidup (OK)'
        WHEN @StatusCode = '0' THEN 'Mati / Timeout / Unreachable'
        WHEN @StatusCode IN ('401','403') THEN 'Hidup tapi Unauthorized/Forbidden'
        WHEN @StatusCode LIKE '[45][0-9][0-9]' THEN 'Hidup tapi Error ' + @StatusCode
        ELSE 'Status: ' + @StatusCode
    END AS [Keterangan];
GO
