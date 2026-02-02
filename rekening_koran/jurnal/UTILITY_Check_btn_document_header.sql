-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY_Check_btn_document_header.sql
-- ═══════════════════════════════════════════════════════════════════════════
-- Cek isi kolom btn, btp, [desc], AccountName di row yang akan diproses jurnal
-- (isJurnal=0/NULL, trx_date & Amount & btp terisi).
-- Jalankan untuk memastikan kolom mana yang terisi dan apakah [btn] ada di tabel.
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

-- Cek apakah kolom [btn] ada di MP_REKENING_KORAN
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'MP_REKENING_KORAN' AND COLUMN_NAME = 'btn'
)
BEGIN
    PRINT 'Kolom [btn] TIDAK ADA di MP_REKENING_KORAN. Jalankan ALTER_ADD_BTN_APPROVED_BY.sql dulu.';
END
ELSE
BEGIN
    PRINT 'Kolom [btn] ada. Sample data (row yang akan diproses):';
    PRINT '';

    SELECT TOP 20
        id,
        trx_date,
        [btn]           AS btn_value,
        LEN([btn])      AS btn_len,
        btp             AS btp_value,
        LEFT([desc], 40) AS desc_preview,
        AccountName
    FROM [dbo].[MP_REKENING_KORAN]
    WHERE (isJurnal = 0 OR isJurnal IS NULL)
      AND trx_date IS NOT NULL
      AND Amount IS NOT NULL
      AND btp IS NOT NULL
      AND LTRIM(RTRIM(ISNULL(btp, ''))) <> ''
    ORDER BY id;
END
GO
