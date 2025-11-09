-- =====================================================
-- SP_RPT_FindBTP_Batch
-- =====================================================
-- Purpose : Memproses data RPT (file TXT) untuk mencari BTP dan CustomerName
--            menggunakan MASTER_CUSTOMER_BTP_PATTERN dengan fallback ke MP_CUSTOMER_NEW
-- Input   : JSON array (hasil converter TXT) dengan kolom:
--           transaction_id, transaction_date, transaction_time, btp,
--           customer_name, amount, location, keterangan1, keterangan2
-- Output  : Result set seragam dengan SP bank lain (Match info + metadata)
-- Pattern : Tidak perlu parsing description. BTP langsung tersedia dari file RPT
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_RPT_FindBTP_Batch]
    @InputJSON NVARCHAR(MAX),
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- ══════════════════════════════════════════════════
    -- STEP 1. Parse JSON input
    -- ══════════════════════════════════════════════════
    DECLARE @Inputs TABLE (
        RowID INT IDENTITY(1,1),
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        TransactionTime NVARCHAR(50),
        Description NVARCHAR(MAX),
        TransactionType NVARCHAR(2),
        BTP NVARCHAR(50),
        OriginalCustomerName NVARCHAR(200),
        Amount DECIMAL(18,2),
        Location NVARCHAR(100),
        Keterangan1 NVARCHAR(200),
        Keterangan2 NVARCHAR(200)
    );

    INSERT INTO @Inputs (
        TransactionID,
        TransactionDate,
        TransactionTime,
        Description,
        TransactionType,
        BTP,
        OriginalCustomerName,
        Amount,
        Location,
        Keterangan1,
        Keterangan2
    )
    SELECT
        ISNULL(TRY_CAST([transaction_id] AS INT),
               CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT)) AS TransactionID,
        LTRIM(RTRIM([transaction_date])) AS TransactionDate,
        LTRIM(RTRIM([transaction_time])) AS TransactionTime,
        NULLIF(LTRIM(RTRIM([description])), '') AS Description,
        NULLIF(UPPER(LEFT(LTRIM(RTRIM([transaction_type])), 2)), '') AS TransactionType,
        NULLIF(LTRIM(RTRIM([btp])), '') AS BTP,
        NULLIF(LTRIM(RTRIM([customer_name])), '') AS OriginalCustomerName,
        TRY_CAST([amount] AS DECIMAL(18,2)) AS Amount,
        NULLIF(LTRIM(RTRIM([location])), '') AS Location,
        NULLIF(LTRIM(RTRIM([keterangan1])), '') AS Keterangan1,
        NULLIF(LTRIM(RTRIM([keterangan2])), '') AS Keterangan2
    FROM OPENJSON(@InputJSON)
    WITH (
        [transaction_id] NVARCHAR(50) '$.transaction_id',
        [transaction_date] NVARCHAR(50) '$.transaction_date',
        [transaction_time] NVARCHAR(50) '$.transaction_time',
        [description] NVARCHAR(MAX) '$.description',
        [btp] NVARCHAR(50) '$.btp',
        [customer_name] NVARCHAR(200) '$.customer_name',
        [amount] NVARCHAR(50) '$.amount',
        [transaction_type] NVARCHAR(10) '$.transaction_type',
        [location] NVARCHAR(100) '$.location',
        [keterangan1] NVARCHAR(200) '$.keterangan1',
        [keterangan2] NVARCHAR(200) '$.keterangan2'
    );

    IF @Debug = 1
    BEGIN
        PRINT '=== RAW INPUT (RPT) ===';
        SELECT * FROM @Inputs;
    END

    -- Normalisasi transaction type (default CR jika amount positif)
    UPDATE @Inputs
    SET TransactionType = CASE
            WHEN TransactionType IN ('CR', 'DB') THEN TransactionType
            WHEN Amount < 0 THEN 'DB'
            WHEN Amount >= 0 THEN 'CR'
            ELSE NULL
        END;

    -- Default terakhir: jika tetap NULL, pakai CR
    UPDATE @Inputs
    SET TransactionType = 'CR'
    WHERE TransactionType IS NULL;

    -- Pastikan description terisi (untuk BTP_REVIEW)
    UPDATE @Inputs
    SET Description = CONCAT(
            'RPT: ',
            ISNULL(OriginalCustomerName, '-'),
            ' | ',
            ISNULL(Keterangan1, '-'),
            ' | ',
            ISNULL(Keterangan2, '-')
        )
    WHERE Description IS NULL;

    -- ══════════════════════════════════════════════════
    -- STEP 2. Siapkan tabel hasil
    -- ══════════════════════════════════════════════════
    DECLARE @Results TABLE (
        RowID INT,
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        TransactionTime NVARCHAR(50),
        Description NVARCHAR(MAX),
        CustomerName NVARCHAR(200),
        OriginalCustomerName NVARCHAR(200),
        BTP NVARCHAR(50),
        MatchPercentage DECIMAL(5,2),
        MatchCount INT,
        TotalTransactions INT,
        LastLineNumber INT,
        TotalBTPOptions INT,
        OptionNumber INT,
        IsBest BIT,
        IsLatest BIT,
        Status NVARCHAR(20),
        DataSource NVARCHAR(50),
        Amount DECIMAL(18,2),
        Location NVARCHAR(100),
        Keterangan1 NVARCHAR(200),
        Keterangan2 NVARCHAR(200),
        TransactionType NVARCHAR(2),
        ProcessedAt DATETIME DEFAULT GETDATE()
    );

    -- ══════════════════════════════════════════════════
    -- STEP 3. Cursor untuk memproses tiap baris RPT
    -- ══════════════════════════════════════════════════
    DECLARE @RowID INT;
    DECLARE @TransactionID INT;
    DECLARE @TransactionDate NVARCHAR(50);
    DECLARE @TransactionTime NVARCHAR(50);
    DECLARE @Description NVARCHAR(MAX);
    DECLARE @TransactionType NVARCHAR(2);
    DECLARE @BTP NVARCHAR(50);
    DECLARE @OriginalCustomer NVARCHAR(200);
    DECLARE @Amount DECIMAL(18,2);
    DECLARE @Location NVARCHAR(100);
    DECLARE @Keterangan1 NVARCHAR(200);
    DECLARE @Keterangan2 NVARCHAR(200);

    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @DataSource NVARCHAR(50);

    DECLARE @BTPMatchPct DECIMAL(5,2);
    DECLARE @BTPMatchCount INT;
    DECLARE @BTPTotalTrans INT;
    DECLARE @BTPLastLine INT;

    DECLARE @TotalOptions INT;

    DECLARE rpt_cursor CURSOR FOR
        SELECT RowID, TransactionID, TransactionDate, TransactionTime, Description,
               TransactionType, BTP, OriginalCustomerName, Amount, Location, Keterangan1, Keterangan2
        FROM @Inputs
        ORDER BY RowID;

    OPEN rpt_cursor;
    FETCH NEXT FROM rpt_cursor INTO @RowID, @TransactionID, @TransactionDate, @TransactionTime,
        @Description, @TransactionType, @BTP, @OriginalCustomer, @Amount, @Location, @Keterangan1, @Keterangan2;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @CustomerName = NULL;
        SET @DataSource = 'MASTER_CUSTOMER_BTP_PATTERN';
        SET @BTPMatchPct = NULL;
        SET @BTPMatchCount = NULL;
        SET @BTPTotalTrans = NULL;
        SET @BTPLastLine = NULL;
        SET @TotalOptions = 0;
        SET @TransactionType = CASE
            WHEN @TransactionType IN ('CR', 'DB') THEN @TransactionType
            WHEN @Amount < 0 THEN 'DB'
            WHEN @Amount >= 0 THEN 'CR'
            ELSE NULL
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'Processing RowID = ' + CAST(@RowID AS VARCHAR) +
                  ', BTP = ' + ISNULL(@BTP, 'NULL');
        END

        -- 3a. Validasi BTP
        IF @BTP IS NULL OR LEN(@BTP) < 5
        BEGIN
            INSERT INTO @Results (
                RowID, TransactionID, TransactionDate, TransactionTime, Description,
                CustomerName, OriginalCustomerName, BTP, MatchPercentage, MatchCount,
                TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
                IsBest, IsLatest, Status, DataSource, Amount, Location,
                Keterangan1, Keterangan2, TransactionType, ProcessedAt
            )
            VALUES (
                @RowID, @TransactionID, @TransactionDate, @TransactionTime, @Description,
                NULL, @OriginalCustomer, NULL, NULL, NULL,
                NULL, NULL, 0, 0,
                0, 0, 'NO_BTP', NULL, @Amount, @Location,
                @Keterangan1, @Keterangan2, @TransactionType, GETDATE()
            );

            FETCH NEXT FROM rpt_cursor INTO @RowID, @TransactionID, @TransactionDate, @TransactionTime,
                @Description, @TransactionType, @BTP, @OriginalCustomer, @Amount, @Location, @Keterangan1, @Keterangan2;
            CONTINUE;
        END

        -- 3b. Cari BTP di MASTER_CUSTOMER_BTP_PATTERN
        SELECT TOP 1
            @CustomerName = LTRIM(RTRIM(m.customer_name)),
            @BTPMatchPct = m.match_percentage,
            @BTPMatchCount = m.match_count,
            @BTPTotalTrans = m.total_transactions,
            @BTPLastLine = m.last_line_number
        FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
        WHERE m.btp = @BTP
        ORDER BY
            CASE WHEN m.category = 'VA' THEN 1
                 WHEN m.category = 'TRSF' THEN 2
                 WHEN m.category = 'NEW' THEN 3
                 ELSE 4 END,
            m.match_percentage DESC,
            m.total_transactions DESC,
            m.last_line_number DESC;

        -- 3c. Jika tidak ketemu di master, fallback ke MP_CUSTOMER_NEW
        IF @CustomerName IS NULL
        BEGIN
            DECLARE @CustomerFromMP NVARCHAR(200);
            SELECT TOP 1
                @CustomerFromMP = LTRIM(RTRIM(c.btn))
            FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] c
            WHERE c.btp = @BTP
                AND c.btn IS NOT NULL
                AND LEN(LTRIM(RTRIM(c.btn))) >= 3
            ORDER BY c.created_at DESC;

            IF @CustomerFromMP IS NOT NULL
            BEGIN
                SET @CustomerName = @CustomerFromMP;
                SET @DataSource = 'MP_CUSTOMER_NEW';
                SET @BTPMatchPct = 100.00;
                SET @BTPMatchCount = 1;
                SET @BTPTotalTrans = 1;
                SET @BTPLastLine = 0;
            END
        END

        IF @CustomerName IS NULL
        BEGIN
            -- BTP tidak ada di master maupun MP_CUSTOMER_NEW
            INSERT INTO @Results (
                RowID, TransactionID, TransactionDate, TransactionTime, Description,
                CustomerName, OriginalCustomerName, BTP, MatchPercentage, MatchCount,
                TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
                IsBest, IsLatest, Status, DataSource, Amount, Location,
                Keterangan1, Keterangan2, TransactionType, ProcessedAt
            )
            VALUES (
                @RowID, @TransactionID, @TransactionDate, @TransactionTime, @Description,
                NULL, @OriginalCustomer, @BTP, NULL, NULL,
                NULL, NULL, 0, 0,
                0, 0, 'NO_MATCH', NULL, @Amount, @Location,
                @Keterangan1, @Keterangan2, @TransactionType, GETDATE()
            );

            FETCH NEXT FROM rpt_cursor INTO @RowID, @TransactionID, @TransactionDate, @TransactionTime,
                @Description, @TransactionType, @BTP, @OriginalCustomer, @Amount, @Location, @Keterangan1, @Keterangan2;
            CONTINUE;
        END

        -- 3d. Hitung informasi tambahan & tentukan hasil akhir (1 row per transaksi)
        DECLARE @LatestLastLine INT = NULL;
        DECLARE @LatestFlag BIT = 0;

        SET @TotalOptions = 0;

        IF @CustomerName IS NOT NULL AND @DataSource = 'MASTER_CUSTOMER_BTP_PATTERN'
        BEGIN
            SELECT 
                @TotalOptions = COUNT(DISTINCT m.btp),
                @LatestLastLine = MAX(m.last_line_number)
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
            WHERE (m.category = 'VA' OR m.category = 'TRSF' OR m.category = 'NEW')
              AND UPPER(m.customer_name) = UPPER(@CustomerName);

            IF @TotalOptions IS NULL SET @TotalOptions = 0;
            IF @BTPLastLine IS NOT NULL AND @LatestLastLine IS NOT NULL AND @BTPLastLine = @LatestLastLine
                SET @LatestFlag = 1;
        END
        ELSE
        BEGIN
            SET @TotalOptions = CASE WHEN @CustomerName IS NOT NULL THEN 1 ELSE 0 END;
            SET @LatestFlag = 1;
        END

        DECLARE @Status NVARCHAR(20);
        IF @BTPMatchPct >= 95 SET @Status = 'EXCELLENT';
        ELSE IF @BTPMatchPct >= 80 SET @Status = 'GOOD';
        ELSE IF @BTPMatchPct >= 70 SET @Status = 'FAIR';
        ELSE IF @BTPMatchPct IS NULL SET @Status = 'LOW';
        ELSE SET @Status = 'LOW';

        INSERT INTO @Results (
            RowID, TransactionID, TransactionDate, TransactionTime, Description,
            CustomerName, OriginalCustomerName, BTP, MatchPercentage, MatchCount,
            TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
            IsBest, IsLatest, Status, DataSource, Amount, Location,
            Keterangan1, Keterangan2, TransactionType, ProcessedAt
        )
        VALUES (
            @RowID, @TransactionID, @TransactionDate, @TransactionTime, @Description,
            @CustomerName, @OriginalCustomer, @BTP,
            ISNULL(@BTPMatchPct, 100.00),
            ISNULL(@BTPMatchCount, 1),
            ISNULL(@BTPTotalTrans, 1),
            ISNULL(@BTPLastLine, 0),
            @TotalOptions,
            1,
            1,
            CASE WHEN @LatestFlag = 1 THEN 1 ELSE 0 END,
            @Status,
            @DataSource,
            @Amount,
            @Location,
            @Keterangan1,
            @Keterangan2,
            @TransactionType,
            GETDATE()
        );

        FETCH NEXT FROM rpt_cursor INTO @RowID, @TransactionID, @TransactionDate, @TransactionTime,
            @Description, @TransactionType, @BTP, @OriginalCustomer, @Amount, @Location, @Keterangan1, @Keterangan2;
    END

    CLOSE rpt_cursor;
    DEALLOCATE rpt_cursor;

    -- ══════════════════════════════════════════════════
    -- STEP 4. Return hasil
    -- ══════════════════════════════════════════════════
    SELECT
        TransactionID,
        TransactionDate,
        Description,
        CustomerName,
        BTP,
        MatchPercentage,
        MatchCount,
        TotalTransactions,
        LastLineNumber,
        TotalBTPOptions,
        OptionNumber,
        CASE WHEN IsBest = 1 THEN 'YES' ELSE '' END AS BestFlag,
        CASE WHEN IsLatest = 1 THEN 'YES' ELSE '' END AS LatestFlag,
        CASE
            WHEN IsBest = 1 AND IsLatest = 1 THEN 'BEST + LATEST'
            WHEN IsBest = 1 THEN 'BEST'
            WHEN IsLatest = 1 THEN 'LATEST'
            ELSE ''
        END AS Label,
        Status,
        CASE
            WHEN Status = 'NO_BTP' THEN 'BTP tidak ditemukan di data RPT'
            WHEN Status = 'NO_MATCH' THEN 'BTP "' + ISNULL(BTP, '') + '" tidak ditemukan di MASTER ataupun MP_CUSTOMER_NEW'
            WHEN TotalBTPOptions > 1 AND OptionNumber = 1 THEN 'Ditemukan ' + CAST(TotalBTPOptions AS VARCHAR) + ' opsi BTP (BEST)'
            WHEN TotalBTPOptions > 1 THEN 'Opsi ' + CAST(OptionNumber AS VARCHAR) + ' dari ' + CAST(TotalBTPOptions AS VARCHAR)
            WHEN Status IN ('EXCELLENT', 'GOOD') THEN 'High confidence match'
            WHEN Status = 'FAIR' THEN 'Medium confidence match'
            WHEN Status = 'LOW' THEN 'Low confidence match - perlu verifikasi manual'
            ELSE 'Match ditemukan'
        END AS Message,
        DataSource,
        OriginalCustomerName,
        TransactionTime,
        Amount,
        TransactionType,
        Location,
        Keterangan1,
        Keterangan2,
        ProcessedAt
    FROM @Results
    ORDER BY TransactionID, OptionNumber;

    IF @Debug = 1
    BEGIN
        PRINT '=== RPT Summary ===';
        SELECT
            COUNT(DISTINCT TransactionID) AS TotalTransactions,
            COUNT(*) AS TotalRows,
            SUM(CASE WHEN BTP IS NOT NULL THEN 1 ELSE 0 END) AS RowsWithBTP,
            SUM(CASE WHEN Status = 'NO_MATCH' THEN 1 ELSE 0 END) AS NoMatchCount,
            SUM(CASE WHEN TotalBTPOptions > 1 THEN 1 ELSE 0 END) AS MultipleOptions
        FROM @Results;
    END
END
GO

/* ======================================================================
   TEST BLOCK
   Cara pakai:
     1. Buka converter.html → tab TXT/RPT → upload file → Copy JSON untuk SP.
     2. Ganti isi @JSON di bawah dengan hasil copy tersebut.
     3. Jalankan block ini di SSMS untuk melihat output langsung dari SP.
====================================================================== */

-- DECLARE @JSON NVARCHAR(MAX) = N'[
--     {
--         "transaction_id": 1,
--         "transaction_date": "05/11/25",
--         "transaction_time": "06:11:44",
--         "btp": "2300016953",
--         "customer_name": "PT  ERA KOPI AND",
--         "amount": 463270.00,
--         "location": "9508N",
--         "keterangan1": "-",
--         "keterangan2": "-",
--         "description": "RPT: PT  ERA KOPI AND | - | -",
--         "bank_type": "VA"
--     }
-- ]';

-- EXEC [dbo].[SP_RPT_FindBTP_Batch]
--     @InputJSON = @JSON,
--     @Debug = 1;


