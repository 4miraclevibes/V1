-- ═══════════════════════════════════════════════════════════════════════════
-- SP_JURNAL_CreateFromRekeningKoran
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Bisnis proses:
--   Setiap 1 row di MP_REKENING_KORAN (yang isJurnal = 0/NULL) → create 2 row di MP_JURNAL.
--   Kedua baris punya no_urut yang sama (per trx_date + AccountName).
--   Setelah insert, MP_REKENING_KORAN.isJurnal di-update jadi 1.
--
-- no_urut: per (trx_date, AccountName) mulai 0001, 0002, ...
-- reference: {ddmmyyyy}-{no_urut} contoh 26012026-0001
--
-- Baris 1: posting_key '40', customer NULL, account 1113030303/1113030300, customer2 NULL
-- Baris 2: posting_key '15', customer = btp, account NULL, customer2 = btp
--
-- Prasyarat: MP_REKENING_KORAN punya kolom btn, Amount (jalankan ALTER script bila belum).
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_JURNAL_CreateFromRekeningKoran]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsProcessed INT = 0;
    DECLARE @RowsInserted INT = 0;

    BEGIN TRY
        -- ═══════════════════════════════════════════════════════════════════
        -- Temp: row rekening koran yang belum di-jurnal, dengan no_urut
        -- ═══════════════════════════════════════════════════════════════════
        ;WITH rk AS (
            SELECT
                id,
                trx_date,
                ISNULL(AccountNumber, '') AS AccountNumber,
                ISNULL(AccountName, '') AS AccountName,
                ISNULL(btn, '') AS btn,
                ISNULL(btp, '') AS btp,
                ISNULL([desc], '') AS [desc],
                ISNULL(Amount, 0) AS Amount,
                -- no_urut per (trx_date, AccountName), 4 digit
                RIGHT('0000' + CAST(ROW_NUMBER() OVER (PARTITION BY trx_date, ISNULL(AccountName, '') ORDER BY id) AS VARCHAR(4)), 4) AS no_urut
            FROM [dbo].[MP_REKENING_KORAN]
            WHERE (isJurnal = 0 OR isJurnal IS NULL)
        ),
        -- Helper: document_header_text = btn max 25 char, potong di space terakhir
        rk_with_headers AS (
            SELECT
                *,
                CASE
                    WHEN LEN(LEFT(btn, 25)) < 25 THEN LTRIM(RTRIM(LEFT(btn, 25)))
                    WHEN CHARINDEX(' ', REVERSE(LEFT(btn, 25))) > 0
                        THEN LTRIM(RTRIM(LEFT(btn, 25 - CHARINDEX(' ', REVERSE(LEFT(btn, 25))))))
                    ELSE LTRIM(RTRIM(LEFT(btn, 25)))
                END AS document_header_text,
                -- text = desc 50 char dari belakang, potong di space terakhir
                CASE
                    WHEN LEN(RIGHT([desc], 50)) < 50 THEN LTRIM(RTRIM(RIGHT([desc], 50)))
                    WHEN CHARINDEX(' ', REVERSE(RIGHT([desc], 50))) > 0
                        THEN LTRIM(RTRIM(RIGHT([desc], 50 - CHARINDEX(' ', REVERSE(RIGHT([desc], 50))))))
                    ELSE LTRIM(RTRIM(RIGHT([desc], 50)))
                END AS text_50
            FROM rk
        )
        SELECT
            id,
            trx_date,
            AccountNumber,
            AccountName,
            btn,
            btp,
            [desc],
            Amount,
            no_urut,
            document_header_text,
            text_50,
            -- reference = ddmmyyyy-no_urut
            FORMAT(trx_date, 'ddMMyyyy') + '-' + no_urut AS reference,
            -- company_code, account, profit_center by AccountNumber
            CASE WHEN AccountNumber = '0053061777' THEN 'id93' ELSE 'id92' END AS company_code,
            CASE WHEN AccountNumber = '0053061777' THEN '1113030303' ELSE '1113030300' END AS account,
            CASE WHEN AccountNumber = '0053061777' THEN '9300DDJT0A' ELSE '9201DQDQ01' END AS profit_center
        INTO #rk_jurnal
        FROM rk_with_headers;

        SET @RowsProcessed = @@ROWCOUNT;

        IF @RowsProcessed = 0
        BEGIN
            PRINT 'Tidak ada row MP_REKENING_KORAN yang belum di-jurnal (isJurnal = 0/NULL).';
            RETURN;
        END;

        -- ═══════════════════════════════════════════════════════════════════
        -- Insert baris 1 (posting_key 40, customer NULL, account isi, customer2 NULL)
        -- ═══════════════════════════════════════════════════════════════════
        INSERT INTO [dbo].[MP_JURNAL] (
            no_urut, row_line, source_rk_id,
            document_date, document_type, company_code, posting_date, currency, country_grouping,
            reference, material, document_header_text, posting_key, customer, account, special,
            amount, value_date, assignment, text, profit_center, cost_center, order_no, tax_code,
            customer2, sales_organization, reason_code
        )
        SELECT
            no_urut, 1, id,
            trx_date, 'DZ', company_code, trx_date, 'IDR', NULL,
            reference, NULL, document_header_text, '40', NULL, account, NULL,
            amount, trx_date, '3000', text_50, profit_center, NULL, NULL, NULL,
            NULL, NULL, NULL
        FROM #rk_jurnal;

        SET @RowsInserted = @@ROWCOUNT;

        -- ═══════════════════════════════════════════════════════════════════
        -- Insert baris 2 (posting_key 15, customer = btp, account NULL, customer2 = btp)
        -- ═══════════════════════════════════════════════════════════════════
        INSERT INTO [dbo].[MP_JURNAL] (
            no_urut, row_line, source_rk_id,
            document_date, document_type, company_code, posting_date, currency, country_grouping,
            reference, material, document_header_text, posting_key, customer, account, special,
            amount, value_date, assignment, text, profit_center, cost_center, order_no, tax_code,
            customer2, sales_organization, reason_code
        )
        SELECT
            no_urut, 2, id,
            trx_date, 'DZ', company_code, trx_date, 'IDR', NULL,
            reference, NULL, document_header_text, '15', btp, NULL, NULL,
            amount, trx_date, '3000', text_50, profit_center, NULL, NULL, NULL,
            btp, NULL, NULL
        FROM #rk_jurnal;

        SET @RowsInserted = @RowsInserted + @@ROWCOUNT;

        -- ═══════════════════════════════════════════════════════════════════
        -- Update MP_REKENING_KORAN.isJurnal = 1 untuk row yang sudah di-jurnal
        -- ═══════════════════════════════════════════════════════════════════
        UPDATE rk
        SET rk.isJurnal = 1
        FROM [dbo].[MP_REKENING_KORAN] rk
        INNER JOIN #rk_jurnal j ON j.id = rk.id;

        PRINT 'Jurnal dibuat: ' + CAST(@RowsProcessed AS VARCHAR) + ' row RK → ' + CAST(@RowsInserted AS VARCHAR) + ' row jurnal. isJurnal di-update.';
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error: ' + @msg;
        RAISERROR(@msg, 16, 1);
    END CATCH;
END;
GO

PRINT 'SP_JURNAL_CreateFromRekeningKoran created.';
GO
