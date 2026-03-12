-- ═══════════════════════════════════════════════════════════════════════════
-- SP_JURNAL_CreateFromRekeningKoran
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Bisnis proses:
--   Setiap 1 row di MP_REKENING_KORAN (yang isJurnal = 0/NULL dan semua kondisi terpenuhi)
--   → create 2 row di MP_JURNAL. Hanya row yang lolos syarat yang di-update isJurnal = 1.
--
-- Syarat row diproses (semua harus terpenuhi, tidak ada NULL/kurang):
--   - isJurnal = 0 atau NULL (belum di-jurnal)
--   - trx_date IS NOT NULL (untuk document_date, posting_date, value_date, reference)
--   - Amount IS NOT NULL (nominal jurnal)
--   - btp IS NOT NULL dan btp <> '' (untuk baris 2: customer, customer2)
--   - btn IS NOT NULL dan btn <> '' (supaya document_header_text konsisten dari btn)
--   - approved_by = 'digicare@greenfieldsdairy.com'
-- Row yang tidak memenuhi syarat tidak diproses dan isJurnal tetap tidak di-update (tetap 0/NULL).
--
-- no_urut: per (trx_date, AccountName) mulai 0001, 0002, ...
-- reference: {ddmmyyyy}-{no_urut} contoh 26012026-0001
--
-- Baris 1: posting_key '40', customer NULL, account 1113030303/1113030300, customer2 NULL
-- Baris 2: posting_key '15', customer = btp, account NULL, customer2 = btp
--
-- document_header_text: btn max 25 char, logika sama dengan kolom 'text' (desc): trim dulu, lalu potong di space terakhir.
--
-- Prasyarat: MP_REKENING_KORAN punya kolom btn, Amount (jalankan ALTER script bila belum).
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_JURNAL_CreateFromRekeningKoran]
    @StartDate NVARCHAR(50) = NULL,
    @EndDate   NVARCHAR(50) = NULL,
    @Id        BIGINT       = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDateOnly DATE = NULL;
    DECLARE @EndDateOnly   DATE = NULL;
    IF @StartDate IS NOT NULL AND LEN(LTRIM(RTRIM(@StartDate))) > 0
        SET @StartDateOnly = TRY_CAST(LTRIM(RTRIM(@StartDate)) AS DATE);
    IF @EndDate IS NOT NULL AND LEN(LTRIM(RTRIM(@EndDate))) > 0
        SET @EndDateOnly = TRY_CAST(LTRIM(RTRIM(@EndDate)) AS DATE);

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
                created_at,
                ISNULL(AccountNumber, '') AS AccountNumber,
                ISNULL(AccountName, '') AS AccountName,
                ISNULL([btn], '') AS btn,
                LTRIM(RTRIM(ISNULL([btn], ''))) AS btn_trimmed,
                -- Sumber document_header_text: btn dulu, kalau kosong fallback btp → desc → AccountName (row diproses pasti btp ada)
                COALESCE(
                    NULLIF(LTRIM(RTRIM(ISNULL([btn], ''))), ''),
                    NULLIF(LTRIM(RTRIM(ISNULL(btp, ''))), ''),
                    NULLIF(LTRIM(RTRIM(ISNULL([desc], ''))), ''),
                    NULLIF(LTRIM(RTRIM(ISNULL(AccountName, ''))), ''),
                    ''
                ) AS header_source,
                ISNULL(btp, '') AS btp,
                ISNULL([desc], '') AS [desc],
                ISNULL(Amount, 0) AS Amount,
                ISNULL(BankType, '') AS BankType,
                -- no_urut per (trx_date, AccountName), 4 digit
                RIGHT('0000' + CAST(ROW_NUMBER() OVER (PARTITION BY trx_date, ISNULL(AccountName, '') ORDER BY id) AS VARCHAR(4)), 4) AS no_urut
            FROM [dbo].[MP_REKENING_KORAN]
            WHERE (isJurnal = 0 OR isJurnal IS NULL)
              AND (@Id IS NULL OR id = @Id)
              AND trx_date IS NOT NULL
              AND (@StartDateOnly IS NULL OR trx_date >= @StartDateOnly)
              AND (@EndDateOnly IS NULL OR trx_date <= @EndDateOnly)
              AND Amount IS NOT NULL
              AND btp IS NOT NULL
              AND LTRIM(RTRIM(ISNULL(btp, ''))) <> ''
              AND [btn] IS NOT NULL
              AND LTRIM(RTRIM(ISNULL([btn], ''))) <> ''
              AND approved_by = 'bi_jabodetabek@greenfieldsdairy.com'
        ),
        -- document_header_text = header_source (btn → btp → desc → AccountName) max 25 char, logika sama dengan 'text'
        rk_with_headers AS (
            SELECT
                *,
                CASE
                    WHEN LEN(header_source) = 0 THEN ''
                    WHEN LEN(LEFT(header_source, 25)) < 25 THEN LTRIM(RTRIM(LEFT(header_source, 25)))
                    WHEN CHARINDEX(' ', REVERSE(LEFT(header_source, 25))) > 0
                        THEN LTRIM(RTRIM(LEFT(header_source, 25 - CHARINDEX(' ', REVERSE(LEFT(header_source, 25))))))
                    ELSE LTRIM(RTRIM(LEFT(header_source, 25)))
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
            -- Jaminan: document_header_text tidak pernah kosong (row diproses pasti btp ada)
            CASE
                WHEN ISNULL(RTRIM(document_header_text), '') = '' THEN LTRIM(RTRIM(LEFT(ISNULL(btp, ''), 25)))
                ELSE document_header_text
            END AS document_header_text,
            text_50,
            -- reference = ddmmyyyy-HHmmss (jam menit detik tanpa pemisah)
            FORMAT(trx_date, 'ddMMyyyy') + '-' + FORMAT(ISNULL(created_at, GETDATE()), 'HHmmss') AS reference,
            -- company_code, account, profit_center by AccountNumber & BankType (sesuai flow)
            CASE WHEN AccountNumber = '0053061777' THEN 'id93' ELSE 'id92' END AS company_code,
            CASE
                WHEN AccountNumber = '0053061777' AND UPPER(LTRIM(RTRIM(ISNULL(BankType,'')))) = 'VA' THEN '1113030304'
                WHEN AccountNumber = '0053061777' THEN '1113030303'
                ELSE '1113030300'
            END AS account,
            CASE WHEN AccountNumber = '0053061777' THEN '9300DDJT0A' ELSE '9201DQDQ01' END AS profit_center
        INTO #rk_jurnal
        FROM rk_with_headers;

        SET @RowsProcessed = @@ROWCOUNT;

        IF @RowsProcessed = 0
        BEGIN
            PRINT 'Tidak ada row MP_REKENING_KORAN yang memenuhi syarat (isJurnal=0/NULL, trx_date/Amount/btp/btn tidak NULL dan tidak kosong).';
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
PRINT 'Usage: EXEC SP_JURNAL_CreateFromRekeningKoran;';
PRINT '       EXEC SP_JURNAL_CreateFromRekeningKoran @StartDate = ''2026-03-01'', @EndDate = ''2026-03-31'';';
PRINT '       EXEC SP_JURNAL_CreateFromRekeningKoran @Id = 12345;  -- create per 1 baris';
GO
