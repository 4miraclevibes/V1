-- ═══════════════════════════════════════════════════════════════════════════
-- SP_MASTER_FindBTP_SaveToReview
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   Process transactions dan LANGSUNG save ke BTP_REVIEW table
--   Solusi untuk nested INSERT-EXEC issue: Insert langsung dari dalam SP
--
-- Parameters:
--   @TransactionsJSON - JSON array of transactions
--   @BatchID - Optional batch identifier (auto-generated if null)
--   @UploadedBy - Optional user identifier
--
-- Returns:
--   Result set dari BTP_REVIEW (yang baru di-insert)
--
-- Example:
--   DECLARE @JSON NVARCHAR(MAX) = N'[
--     {"TransactionID": 1, "TransactionDate": "08/10/2024", "Description": "TRSF E-BANKING..."},
--     {"TransactionID": 2, "TransactionDate": "09/10/2024", "Description": "BI-FAST..."}
--   ]';
--   
--   EXEC SP_MASTER_FindBTP_SaveToReview 
--       @TransactionsJSON = @JSON,
--       @UploadedBy = 'finance@company.com';
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_MASTER_FindBTP_SaveToReview]
    @TransactionsJSON NVARCHAR(MAX),
    @BatchID NVARCHAR(100) = NULL,
    @UploadedBy NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate BatchID if not provided
    IF @BatchID IS NULL
    BEGIN
        SET @BatchID = 'BATCH_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + 
                       REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
    END
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_SaveToReview - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'BatchID: ' + @BatchID;
    IF @UploadedBy IS NOT NULL
        PRINT 'Uploaded By: ' + @UploadedBy;
    PRINT '';
    
    -- Variables
    DECLARE @TotalTransactions INT;
    DECLARE @UploadTime DATETIME = GETDATE();
    
    -- Input transactions
    DECLARE @Transactions TABLE (
        TransactionID INT,
        TransactionDate DATE,
        Description NVARCHAR(MAX),
        BankType NVARCHAR(50),
        BTP NVARCHAR(50),
        CustomerNameFromInput NVARCHAR(200),
        TransactionTime NVARCHAR(50),
        TransactionType NVARCHAR(2),
        Amount DECIMAL(18,2),
        Location NVARCHAR(100),
        Keterangan1 NVARCHAR(200),
        Keterangan2 NVARCHAR(200)
    );
    
    -- Parse JSON dan deteksi bank type (dengan dukungan VA/RPT)
    INSERT INTO @Transactions (
        TransactionID,
        TransactionDate,
        Description,
        BankType,
        BTP,
        CustomerNameFromInput,
        TransactionTime,
        TransactionType,
        Amount,
        Location,
        Keterangan1,
        Keterangan2
    )
    SELECT 
        COALESCE(TransactionID, TransactionIDLower) AS TransactionID,
        -- Convert TransactionDate string ke DATE
        -- Handle format: DD/MM/YY (contoh: '05/11/25' = 5 November 2025), YYYY-MM-DD, ISO format, dll
        CASE
            -- Format DD/MM/YY atau DD/MM/YYYY (contoh: '05/11/25' atau '05/11/2025')
            -- Parse: DD/MM/YY → YYYY-MM-DD
            -- Menggunakan PARSENAME untuk split berdasarkan '/'
            -- PARSENAME membaca dari belakang: posisi 1 = bagian terakhir, posisi 3 = bagian pertama
            WHEN COALESCE(TransactionDate, TransactionDateLower) LIKE '%/%' 
                THEN TRY_CAST(
                    CONCAT(
                        -- Tahun: PARSENAME posisi 1 (bagian terakhir), tambahkan '20' jika 2 digit
                        CASE 
                            WHEN LEN(LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 1)))) = 2 
                            THEN CONCAT('20', LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 1))))
                            ELSE LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 1)))
                        END,
                        '-',
                        -- Bulan: PARSENAME posisi 2 (bagian tengah)
                        RIGHT(CONCAT('0', LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 2)))), 2),
                        '-',
                        -- Tanggal: PARSENAME posisi 3 (bagian pertama)
                        RIGHT(CONCAT('0', LTRIM(RTRIM(PARSENAME(REPLACE(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), '/', '.'), 3)))), 2)
                    )
                    AS DATE)
            -- Format YYYY-MM-DD atau ISO (contoh: '2025-11-05' atau '2025-11-05T00:00:00Z')
            WHEN COALESCE(TransactionDate, TransactionDateLower) LIKE '%-%-%'
                THEN TRY_CAST(LEFT(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))), 10) AS DATE)
            -- Format lainnya, coba parse langsung
            ELSE TRY_CAST(LTRIM(RTRIM(COALESCE(TransactionDate, TransactionDateLower))) AS DATE)
        END AS TransactionDate,
        COALESCE(Description, DescriptionLower) AS Description,
        CASE
            WHEN UPPER(ISNULL(BankTypeInput, '')) = 'VA' OR UPPER(ISNULL(BankTypeInputLower, '')) = 'VA' THEN 'VA'
            WHEN COALESCE(BTPValue, BTPValueLower) IS NOT NULL AND (
                    COALESCE(Description, DescriptionLower) IS NULL OR COALESCE(Description, DescriptionLower) LIKE 'RPT:%' OR LEN(ISNULL(COALESCE(TransactionTimeInput, TransactionTimeLower), '')) > 0
                ) THEN 'VA'
            -- Group 3: Special Logic
            WHEN COALESCE(Description, DescriptionLower, '') LIKE 'TRSF E-BANKING%' OR COALESCE(Description, DescriptionLower, '') LIKE 'TRSF FROM%' THEN 'TRSF'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE 'BI-FAST%' THEN 'BIFAST'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL %' OR COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL,%' OR COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL' THEN 'GREENFIEL'
            -- Group 1
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BNI %' THEN 'BNI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BTPN %' THEN 'BTPN'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MANDIRI %' THEN 'MANDIRI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BRI %' THEN 'BRI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MEGA %' THEN 'MEGA'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-PERMATA %' THEN 'PERMATA'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-DANAMON %' THEN 'DANAMON'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CITIBANK %' THEN 'CITIBANK'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-SINARMAS %' THEN 'SINARMAS'
            -- Group 2
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CIMB NIAGA%' THEN 'CIMB'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MAYBANK INDONE%' THEN 'MAYBANK'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-HSBC INDONESIA%' THEN 'HSBC'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-UOB INDONESIA%' THEN 'UOB'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MUAMALAT INDON%' THEN 'MUAMALAT'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-OCBC NISP%' THEN 'OCBC'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-DBS INDONESIA%' THEN 'DBS'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CAPITAL INDONE%' THEN 'CAPITAL'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-WOORI SAUDARA%' THEN 'WOORI'
            ELSE 'UNKNOWN'
        END as BankType,
        COALESCE(BTPValue, BTPValueLower) AS BTP,
        COALESCE(CustomerNameInput, CustomerNameLower) AS CustomerNameFromInput,
        COALESCE(TransactionTimeInput, TransactionTimeLower) AS TransactionTime,
        CASE 
            WHEN COALESCE(TransactionTypeInput, TransactionTypeLower) IS NULL THEN NULL
            ELSE UPPER(LEFT(LTRIM(RTRIM(COALESCE(TransactionTypeInput, TransactionTypeLower))), 2))
        END AS TransactionType,
        COALESCE(AmountValue, AmountValueLower) AS Amount,
        COALESCE(LocationInput, LocationLower) AS Location,
        COALESCE(Keterangan1Input, Keterangan1Lower) AS Keterangan1,
        COALESCE(Keterangan2Input, Keterangan2Lower) AS Keterangan2
    FROM OPENJSON(@TransactionsJSON)
    WITH (
        TransactionID INT '$.TransactionID',
        TransactionIDLower INT '$.transaction_id',
        TransactionDate NVARCHAR(50) '$.TransactionDate',
        TransactionDateLower NVARCHAR(50) '$.transaction_date',
        Description NVARCHAR(MAX) '$.Description',
        DescriptionLower NVARCHAR(MAX) '$.description',
        BTPValue NVARCHAR(50) '$.BTP',
        BTPValueLower NVARCHAR(50) '$.btp',
        CustomerNameInput NVARCHAR(200) '$.CustomerName',
        CustomerNameLower NVARCHAR(200) '$.customer_name',
        TransactionTimeInput NVARCHAR(50) '$.TransactionTime',
        TransactionTimeLower NVARCHAR(50) '$.transaction_time',
        TransactionTypeInput NVARCHAR(10) '$.TransactionType',
        TransactionTypeLower NVARCHAR(10) '$.transaction_type',
        AmountValue DECIMAL(18,2) '$.Amount',
        AmountValueLower DECIMAL(18,2) '$.amount',
        LocationInput NVARCHAR(100) '$.Location',
        LocationLower NVARCHAR(100) '$.location',
        Keterangan1Input NVARCHAR(200) '$.Keterangan1',
        Keterangan1Lower NVARCHAR(200) '$.keterangan1',
        Keterangan2Input NVARCHAR(200) '$.Keterangan2',
        Keterangan2Lower NVARCHAR(200) '$.keterangan2',
        BankTypeInput NVARCHAR(50) '$.BankType',
        BankTypeInputLower NVARCHAR(50) '$.bank_type'
    );

    -- Fallback parsing untuk format camelCase/lowercase (contoh hasil converter TXT)
    UPDATE t
    SET t.BTP = ISNULL(t.BTP, j.btp),
        t.CustomerNameFromInput = ISNULL(t.CustomerNameFromInput, j.customer_name),
        t.TransactionTime = ISNULL(t.TransactionTime, j.transaction_time),
        t.TransactionType = CASE
            WHEN t.TransactionType IN ('CR', 'DB') THEN t.TransactionType
            WHEN j.transaction_type IS NOT NULL AND UPPER(LEFT(j.transaction_type, 2)) IN ('CR', 'DB')
                THEN UPPER(LEFT(j.transaction_type, 2))
            ELSE t.TransactionType
        END,
        t.Amount = ISNULL(t.Amount, TRY_CAST(j.amount AS DECIMAL(18,2))),
        t.Location = ISNULL(t.Location, j.location),
        t.Keterangan1 = ISNULL(t.Keterangan1, j.keterangan1),
        t.Keterangan2 = ISNULL(t.Keterangan2, j.keterangan2),
        t.BankType = CASE
            WHEN t.BankType = 'UNKNOWN' AND UPPER(ISNULL(j.bank_type, '')) = 'VA' THEN 'VA'
            ELSE t.BankType
        END
    FROM @Transactions t
    CROSS APPLY OPENJSON(@TransactionsJSON)
    WITH (
        TransactionID INT '$.transaction_id',
        btp NVARCHAR(50) '$.btp',
        customer_name NVARCHAR(200) '$.customer_name',
        transaction_time NVARCHAR(50) '$.transaction_time',
        transaction_type NVARCHAR(10) '$.transaction_type',
        amount NVARCHAR(50) '$.amount',
        location NVARCHAR(100) '$.location',
        keterangan1 NVARCHAR(200) '$.keterangan1',
        keterangan2 NVARCHAR(200) '$.keterangan2',
        bank_type NVARCHAR(50) '$.bank_type'
    ) j
    WHERE t.TransactionID = j.TransactionID;

    -- Normalisasi transaction type dan amount defaults
    UPDATE @Transactions
    SET TransactionType = CASE
            WHEN TransactionType IN ('CR', 'DB') THEN TransactionType
            WHEN Amount < 0 THEN 'DB'
            WHEN Amount > 0 THEN 'CR'
            ELSE NULL
        END;

    -- Bentuk description default untuk data VA (RPT) jika kosong
    UPDATE @Transactions
    SET Description = CONCAT(
            'RPT: ', ISNULL(CustomerNameFromInput, '-'),
            ' | ', ISNULL(Keterangan1, '-'),
            ' | ', ISNULL(Keterangan2, '-')
        )
    WHERE BankType = 'VA' AND (
        Description IS NULL OR LTRIM(RTRIM(Description)) = '' OR
        Description NOT LIKE 'RPT:%'
    );
    
    SELECT @TotalTransactions = COUNT(*) FROM @Transactions;
    PRINT 'Total transactions to process: ' + CAST(@TotalTransactions AS VARCHAR);
    PRINT '';
    
    -- Now process each bank type and INSERT directly to BTP_REVIEW
    -- This avoids nested INSERT-EXEC issue!
    
    DECLARE @ProcessedCount INT = 0;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- TRSF
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'TRSF')
    BEGIN
        PRINT '🔄 Processing TRSF...';
        
        DECLARE @TRSF_JSON NVARCHAR(MAX);
        SELECT @TRSF_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'TRSF' FOR JSON PATH
        );
        
        -- Create temp table for TRSF results
        -- Note: SP bank-specific masih mengembalikan TransactionDate sebagai NVARCHAR, jadi kita convert saat INSERT ke BTP_REVIEW
        CREATE TABLE #TRSF_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #TRSF_Temp
        EXEC SP_TRSF_FindBTP_Batch @InputJSON = @TRSF_JSON;
        
        -- Insert directly to BTP_REVIEW (with auto-populate Notes)
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            Amount, TransactionType,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            temp.TransactionID, TRY_CAST(temp.TransactionDate AS DATE), temp.Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'TRSF', temp.ProcessedAt,
            t.Amount,
            CASE WHEN t.TransactionType IN ('CR', 'DB') THEN t.TransactionType ELSE NULL END,
            0,
            CASE
                WHEN temp.Status = 'NO_PATTERN' THEN 'Customer name tidak ditemukan di description - perlu review format extraction'
                WHEN temp.Status = 'NO_MATCH' THEN 'Customer "' + temp.CustomerName + '" belum ada di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN'
                WHEN temp.Status = 'LOW' THEN 'Match confidence rendah (' + CAST(temp.MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN temp.TotalBTPOptions > 1 THEN 'Ditemukan ' + CAST(temp.TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                ELSE NULL
            END,
            GETDATE()
        FROM #TRSF_Temp AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID
        WHERE temp.OptionNumber IS NULL OR temp.OptionNumber = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #TRSF_Temp;
        
        PRINT '✅ TRSF completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- BIFAST
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BIFAST')
    BEGIN
        PRINT '🔄 Processing BIFAST...';
        
        DECLARE @BIFAST_JSON NVARCHAR(MAX);
        SELECT @BIFAST_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'BIFAST' FOR JSON PATH
        );
        
        CREATE TABLE #BIFAST_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BIFAST_Temp
        EXEC SP_BIFAST_FindBTP_Batch @InputJSON = @BIFAST_JSON;
        
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            Amount, TransactionType,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            temp.TransactionID, TRY_CAST(temp.TransactionDate AS DATE), temp.Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'BIFAST', temp.ProcessedAt,
            t.Amount,
            CASE WHEN t.TransactionType IN ('CR', 'DB') THEN t.TransactionType ELSE NULL END,
            0,
            CASE
                WHEN temp.Status = 'NO_PATTERN' THEN 'Customer name tidak ditemukan di description - perlu review format extraction'
                WHEN temp.Status = 'NO_MATCH' THEN 'Customer "' + temp.CustomerName + '" belum ada di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN'
                WHEN temp.Status = 'LOW' THEN 'Match confidence rendah (' + CAST(temp.MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN temp.TotalBTPOptions > 1 THEN 'Ditemukan ' + CAST(temp.TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                ELSE NULL
            END,
            GETDATE()
        FROM #BIFAST_Temp AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID
        WHERE temp.OptionNumber IS NULL OR temp.OptionNumber = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #BIFAST_Temp;
        
        PRINT '✅ BIFAST completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- MANDIRI
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MANDIRI')
    BEGIN
        PRINT '🔄 Processing MANDIRI...';
        
        DECLARE @MANDIRI_JSON NVARCHAR(MAX);
        SELECT @MANDIRI_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'MANDIRI' FOR JSON PATH
        );
        
        CREATE TABLE #MANDIRI_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MANDIRI_Temp
        EXEC SP_MANDIRI_FindBTP_Batch @InputJSON = @MANDIRI_JSON;
        
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            Amount, TransactionType,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            temp.TransactionID, TRY_CAST(temp.TransactionDate AS DATE), temp.Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'MANDIRI', temp.ProcessedAt,
            t.Amount,
            CASE WHEN t.TransactionType IN ('CR', 'DB') THEN t.TransactionType ELSE NULL END,
            0,
            CASE
                WHEN temp.Status = 'NO_PATTERN' THEN 'Customer name tidak ditemukan di description - perlu review format extraction'
                WHEN temp.Status = 'NO_MATCH' THEN 'Customer "' + temp.CustomerName + '" belum ada di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN'
                WHEN temp.Status = 'LOW' THEN 'Match confidence rendah (' + CAST(temp.MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN temp.TotalBTPOptions > 1 THEN 'Ditemukan ' + CAST(temp.TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                ELSE NULL
            END,
            GETDATE()
        FROM #MANDIRI_Temp AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID
        WHERE temp.OptionNumber IS NULL OR temp.OptionNumber = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #MANDIRI_Temp;
        
        PRINT '✅ MANDIRI completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GREENFIEL
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'GREENFIEL')
    BEGIN
        PRINT '🔄 Processing GREENFIEL...';
        
        DECLARE @GREENFIEL_JSON NVARCHAR(MAX);
        SELECT @GREENFIEL_JSON = (
            SELECT TransactionID AS transaction_id, TransactionDate AS transaction_date, Description AS description
            FROM @Transactions WHERE BankType = 'GREENFIEL' FOR JSON PATH
        );
        
        CREATE TABLE #GREENFIEL_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            DataSource NVARCHAR(50),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #GREENFIEL_Temp
        EXEC SP_GREENFIEL_FindBTP_Batch @InputJSON = @GREENFIEL_JSON;
        
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            Amount, TransactionType,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            temp.TransactionID, TRY_CAST(temp.TransactionDate AS DATE), temp.Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'GREENFIEL', temp.ProcessedAt,
            t.Amount,
            CASE WHEN t.TransactionType IN ('CR', 'DB') THEN t.TransactionType ELSE NULL END,
            0,
            CASE
                WHEN temp.Status = 'NO_PATTERN' THEN 'Array[4] bukan "GREENFIEL" - transaksi tidak match dengan pattern GREENFIEL'
                WHEN temp.Status = 'NO_BTP' THEN 'BTP tidak ditemukan di description (expected array ending with "23...")'
                WHEN temp.Status = 'NO_MATCH' THEN 'BTP "' + ISNULL(temp.BTP, '') + '" tidak ditemukan di master data - perlu ditambahkan ke MASTER_CUSTOMER_BTP_PATTERN'
                WHEN temp.Status = 'LOW' THEN 'Match confidence rendah (' + CAST(temp.MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN temp.TotalBTPOptions > 1 AND temp.DataSource = 'MP_CUSTOMER_NEW' THEN 'Ditemukan ' + CAST(temp.TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai [Data source: MP_CUSTOMER_NEW - BTN dari MP_CUSTOMER_NEW]'
                WHEN temp.TotalBTPOptions > 1 THEN 'Ditemukan ' + CAST(temp.TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                WHEN temp.DataSource = 'MP_CUSTOMER_NEW' THEN 'CustomerName ditemukan dari MP_CUSTOMER_NEW (BTN) - BTP tidak ada di MASTER_CUSTOMER_BTP_PATTERN'
                ELSE NULL
            END,
            GETDATE()
        FROM #GREENFIEL_Temp AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID
        WHERE temp.OptionNumber IS NULL OR temp.OptionNumber = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #GREENFIEL_Temp;
        
        PRINT '✅ GREENFIEL completed';
    END

    -- ═══════════════════════════════════════════════════════════════════════
    -- VA (RPT TXT)
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'VA')
    BEGIN
        PRINT '🔄 Processing VA (RPT TXT)...';

        DECLARE @VA_JSON NVARCHAR(MAX);
        SELECT @VA_JSON = (
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                TransactionTime AS transaction_time,
                TransactionType AS transaction_type,
                Description AS description,
                BTP AS btp,
                CustomerNameFromInput AS customer_name,
                Amount AS amount,
                Location AS location,
                Keterangan1 AS keterangan1,
                Keterangan2 AS keterangan2
            FROM @Transactions WHERE BankType = 'VA' FOR JSON PATH
        );

        CREATE TABLE #VA_Temp (
            TransactionID INT,
            TransactionDate NVARCHAR(50), -- SP bank-specific masih mengembalikan NVARCHAR, convert saat INSERT ke BTP_REVIEW
            Description NVARCHAR(MAX),
            CustomerName NVARCHAR(200),
            BTP NVARCHAR(50),
            MatchPercentage DECIMAL(5,2),
            MatchCount INT,
            TotalTransactions INT,
            LastLineNumber INT,
            TotalBTPOptions INT,
            OptionNumber INT,
            BestFlag NVARCHAR(10),
            LatestFlag NVARCHAR(10),
            Label NVARCHAR(50),
            Status NVARCHAR(20),
            Message NVARCHAR(500),
            DataSource NVARCHAR(50),
            OriginalCustomerName NVARCHAR(200),
            TransactionTime NVARCHAR(50),
            Amount DECIMAL(18,2),
            TransactionType NVARCHAR(2),
            Location NVARCHAR(100),
            Keterangan1 NVARCHAR(200),
            Keterangan2 NVARCHAR(200),
            ProcessedAt DATETIME
        );

        INSERT INTO #VA_Temp (
            TransactionID, TransactionDate, Description, CustomerName,
            BTP, MatchPercentage, MatchCount, TotalTransactions, LastLineNumber,
            TotalBTPOptions, OptionNumber, BestFlag, LatestFlag, Label, Status,
            Message, DataSource, OriginalCustomerName, TransactionTime, Amount,
            TransactionType, Location, Keterangan1, Keterangan2, ProcessedAt
        )
        EXEC SP_RPT_FindBTP_Batch @InputJSON = @VA_JSON;

        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            Amount, TransactionType,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID, @UploadedBy, @UploadTime,
            temp.TransactionID, TRY_CAST(temp.TransactionDate AS DATE), temp.Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'VA', temp.ProcessedAt,
            COALESCE(temp.Amount, t.Amount),
            CASE 
                WHEN temp.TransactionType IN ('CR', 'DB') THEN temp.TransactionType
                WHEN t.TransactionType IN ('CR', 'DB') THEN t.TransactionType
                ELSE NULL
            END,
            0,
            CASE
                WHEN temp.Status = 'NO_BTP' THEN 'BTP kosong pada data RPT - periksa file sumber'
                WHEN temp.Status = 'NO_MATCH' THEN 'BTP "' + ISNULL(temp.BTP, '') + '" belum ada di master ataupun MP_CUSTOMER_NEW'
                WHEN temp.Status = 'LOW' THEN 'Match confidence rendah (' + CAST(temp.MatchPercentage AS VARCHAR) + '%) - perlu verifikasi manual'
                WHEN temp.TotalBTPOptions > 1 AND temp.DataSource = 'MP_CUSTOMER_NEW' THEN 'Ada ' + CAST(temp.TotalBTPOptions AS VARCHAR) + ' opsi BTP (BEST dari MP_CUSTOMER_NEW)'
                WHEN temp.TotalBTPOptions > 1 THEN 'Ada ' + CAST(temp.TotalBTPOptions AS VARCHAR) + ' opsi BTP - pilih yang paling sesuai'
                WHEN temp.DataSource = 'MP_CUSTOMER_NEW' THEN 'CustomerName diambil dari MP_CUSTOMER_NEW (BTN)' 
                ELSE NULL
            END
            + ' | RPT Original: ' + ISNULL(temp.OriginalCustomerName, '-')
            + ' / Ket1: ' + ISNULL(temp.Keterangan1, '-')
            + ' / Ket2: ' + ISNULL(temp.Keterangan2, '-')
            + CASE WHEN temp.TransactionTime IS NOT NULL THEN ' / Jam: ' + temp.TransactionTime ELSE '' END
            + CASE WHEN COALESCE(temp.Amount, t.Amount) IS NOT NULL THEN ' / Amount: ' + FORMAT(COALESCE(temp.Amount, t.Amount), 'N2') ELSE '' END
            + CASE WHEN temp.DataSource = 'MP_CUSTOMER_NEW' THEN ' [Data source: MP_CUSTOMER_NEW]' ELSE '' END,
            GETDATE()
        FROM #VA_Temp AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID
        WHERE temp.OptionNumber IS NULL OR temp.OptionNumber = 1;

        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #VA_Temp;

        PRINT '✅ VA (RPT TXT) completed';
    END
    
    -- ... Add other banks as needed (BNI, BTPN, BRI, etc.)
    -- For now, just these 4 banks: TRSF, BIFAST, MANDIRI, GREENFIEL
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Handle UNKNOWN bank types (save all with proper notes)
    -- ═══════════════════════════════════════════════════════════════════════
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'UNKNOWN')
    BEGIN
        PRINT '⚠️  Processing UNKNOWN bank types...';
        
        DECLARE @UnknownCount INT;
        SELECT @UnknownCount = COUNT(*) FROM @Transactions WHERE BankType = 'UNKNOWN';
        
        -- Insert UNKNOWN transactions directly with helpful notes
        INSERT INTO dbo.BTP_REVIEW (
            BatchID, UploadedBy, UploadedAt,
            TransactionID, TransactionDate, Description,
            CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
            LastLineNumber, TotalBTPOptions, OptionNumber, BestFlag, LatestFlag,
            Label, Status, Message, BankType, ProcessedAt,
            Amount, TransactionType,
            IsApproved, Notes, CreatedAt
        )
        SELECT
            @BatchID,
            @UploadedBy,
            @UploadTime,
            TransactionID,
            TransactionDate, -- Sudah DATE dari @Transactions
            Description,
            NULL AS CustomerName,
            NULL AS BTP,
            0.00 AS MatchPercentage,
            0 AS MatchCount,
            0 AS TotalTransactions,
            0 AS LastLineNumber,
            0 AS TotalBTPOptions,
            0 AS OptionNumber,
            '' AS BestFlag,
            '' AS LatestFlag,
            '' AS Label,
            'UNKNOWN_BANK' AS Status,
            'Bank type tidak dikenali - perlu dicek manual atau tambahkan pattern deteksi bank' AS Message,
            'UNKNOWN' AS BankType,
            GETDATE() AS ProcessedAt,
            Amount,
            CASE WHEN TransactionType IN ('CR', 'DB') THEN TransactionType ELSE NULL END,
            0 AS IsApproved,
            CASE 
                WHEN Description LIKE 'SETORAN%' THEN 'Transaksi SETORAN - tidak perlu BTP matching'
                WHEN Description LIKE 'DB OTOMATIS%' THEN 'Transaksi DEBIT - tidak perlu BTP matching'
                WHEN Description LIKE 'SWITCHING%' THEN 'Transaksi SWITCHING - cek apakah perlu ditambahkan ke pattern bank'
                WHEN Description LIKE 'FLAZZ%' THEN 'Transaksi FLAZZ - tidak perlu BTP matching'
                WHEN Description LIKE 'KR OTOMATIS%' THEN 'Transaksi KR OTOMATIS tanpa keyword bank spesifik - cek description untuk identifikasi bank'
                ELSE 'Format transaksi tidak dikenali - perlu review manual untuk identifikasi bank atau kategori'
            END AS Notes,
            GETDATE() AS CreatedAt
        FROM @Transactions
        WHERE BankType = 'UNKNOWN';
        
        SET @ProcessedCount = @ProcessedCount + @UnknownCount;
        
        PRINT '⚠️  UNKNOWN bank types saved: ' + CAST(@UnknownCount AS VARCHAR);
        PRINT '   → These require manual review';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Return results from BTP_REVIEW
    -- ═══════════════════════════════════════════════════════════════════════
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '✅ Processing complete!';
    PRINT 'Total rows saved to BTP_REVIEW: ' + CAST(@ProcessedCount AS VARCHAR);
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT '';
    
    -- Return the saved data
    SELECT
        ID,
        BatchID,
        UploadedBy,
        UploadedAt,
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
        BestFlag,
        LatestFlag,
        Label,
        Status,
        Message,
        BankType,
        ProcessedAt,
        Amount,
        TransactionType,
        IsApproved,
        ApprovedBy,
        ApprovedAt,
        Notes,
        CreatedAt
    FROM dbo.BTP_REVIEW
    WHERE BatchID = @BatchID
    ORDER BY TransactionID, OptionNumber;
    
    -- Summary statistics
    SELECT 
        @BatchID AS BatchID,
        @UploadedBy AS UploadedBy,
        @TotalTransactions AS TotalInput,
        @ProcessedCount AS TotalSaved,
        GETDATE() AS CompletedAt,
        'SUCCESS' AS Status;
        
END;
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ SP_MASTER_FindBTP_SaveToReview created successfully!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Usage:';
PRINT '  EXEC SP_MASTER_FindBTP_SaveToReview';
PRINT '      @TransactionsJSON = N''[...]'',';
PRINT '      @UploadedBy = ''user@company.com'';';
PRINT '';
PRINT 'Features:';
PRINT '  ✅ Process transactions with SP_MASTER logic';
PRINT '  ✅ Save directly to BTP_REVIEW table';
PRINT '  ✅ NO nested INSERT-EXEC issue!';
PRINT '  ✅ Returns saved data + summary';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

