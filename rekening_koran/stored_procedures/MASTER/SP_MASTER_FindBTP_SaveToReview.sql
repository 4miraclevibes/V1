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
        -- Description SELALU diambil dari input JSON (tidak pernah diubah)
        COALESCE(Description, DescriptionLower) AS Description,
        -- Deteksi BankType dengan urutan yang eksklusif (lebih spesifik dulu)
        CASE
            -- Priority 1: BankType dari input JSON (jika ada, langsung pakai)
            WHEN UPPER(ISNULL(BankTypeInput, '')) = 'VA' OR UPPER(ISNULL(BankTypeInputLower, '')) = 'VA' THEN 'VA'
            -- Priority 2: VA detection berdasarkan BTP dan format RPT
            WHEN COALESCE(BTPValue, BTPValueLower) IS NOT NULL AND (
                    COALESCE(Description, DescriptionLower) IS NULL OR 
                    COALESCE(Description, DescriptionLower) LIKE 'RPT:%' OR 
                    LEN(ISNULL(COALESCE(TransactionTimeInput, TransactionTimeLower), '')) > 0
                ) THEN 'VA'
            -- Priority 3: Special Logic (TRSF dan BIFAST harus di-check sebelum LLG patterns)
            WHEN COALESCE(Description, DescriptionLower, '') LIKE 'TRSF E-BANKING%' OR 
                 COALESCE(Description, DescriptionLower, '') LIKE 'TRSF FROM%' THEN 'TRSF'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE 'BI-FAST%' THEN 'BIFAST'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL %' OR 
                 COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL,%' OR 
                 COALESCE(Description, DescriptionLower, '') LIKE '% GREENFIEL' THEN 'GREENFIEL'
            -- Priority 4: Group 2 (lebih spesifik, harus di-check sebelum Group 1)
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CIMB NIAGA%' THEN 'CIMB'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MAYBANK INDONE%' THEN 'MAYBANK'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-HSBC INDONESIA%' THEN 'HSBC'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-UOB INDONESIA%' THEN 'UOB'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MUAMALAT INDON%' THEN 'MUAMALAT'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-OCBC NISP%' THEN 'OCBC'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-DBS INDONESIA%' THEN 'DBS'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CAPITAL INDONE%' THEN 'CAPITAL'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-WOORI SAUDARA%' THEN 'WOORI'
            -- Priority 5: Group 1 (pattern sederhana)
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BNI %' THEN 'BNI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BTPN %' THEN 'BTPN'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MANDIRI %' THEN 'MANDIRI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-BRI %' THEN 'BRI'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-MEGA %' THEN 'MEGA'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-PERMATA %' THEN 'PERMATA'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-DANAMON %' THEN 'DANAMON'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-CITIBANK %' THEN 'CITIBANK'
            WHEN COALESCE(Description, DescriptionLower, '') LIKE '%LLG-SINARMAS %' THEN 'SINARMAS'
            -- Priority 6: RTGS pattern (untuk CIMB RTGS)
            WHEN COALESCE(Description, DescriptionLower, '') LIKE 'KR OTOMATIS RTGS-PT BANK CIMB%' THEN 'CIMB'
            -- Default: UNKNOWN
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
        -- BankType hanya diubah jika masih UNKNOWN dan ada bank_type dari JSON
        -- JANGAN ubah BankType jika sudah ditentukan sebelumnya!
        t.BankType = CASE
            WHEN t.BankType = 'UNKNOWN' AND UPPER(ISNULL(j.bank_type, '')) = 'VA' THEN 'VA'
            WHEN t.BankType = 'UNKNOWN' AND UPPER(ISNULL(j.bank_type, '')) IN ('TRSF', 'BIFAST', 'GREENFIEL', 'BNI', 'BTPN', 'MANDIRI', 'BRI', 'MEGA', 'PERMATA', 'DANAMON', 'CITIBANK', 'SINARMAS', 'CIMB', 'MAYBANK', 'HSBC', 'UOB', 'MUAMALAT', 'OCBC', 'DBS', 'CAPITAL', 'WOORI') THEN UPPER(ISNULL(j.bank_type, ''))
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

    -- Bentuk description default untuk data VA (RPT) HANYA jika benar-benar kosong
    -- JANGAN ubah Description jika sudah ada dari input JSON!
    UPDATE @Transactions
    SET Description = CONCAT(
            'RPT: ', ISNULL(CustomerNameFromInput, '-'),
            ' | ', ISNULL(Keterangan1, '-'),
            ' | ', ISNULL(Keterangan2, '-')
        )
    WHERE BankType = 'VA' AND (
        Description IS NULL OR LTRIM(RTRIM(Description)) = ''
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
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #TRSF_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'TRSF'
        WHERE temp.rn = 1;
        
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
            SELECT 
                TransactionID AS transaction_id,
                CONVERT(NVARCHAR(50), TransactionDate, 103) AS transaction_date,  -- Format DD/MM/YYYY
                Description AS description
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
        
        -- Debug: Check if SP returned results
        DECLARE @BIFAST_ResultCount INT;
        SELECT @BIFAST_ResultCount = COUNT(*) FROM #BIFAST_Temp;
        PRINT '   BIFAST SP returned ' + CAST(@BIFAST_ResultCount AS VARCHAR) + ' rows';
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY 
                    CASE WHEN OptionNumber IS NULL THEN 0 ELSE OptionNumber END,
                    MatchPercentage DESC, 
                    LastLineNumber DESC
                ) AS rn
            FROM #BIFAST_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'BIFAST'
        WHERE temp.rn = 1;
        
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
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #MANDIRI_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'MANDIRI'
        WHERE temp.rn = 1;
        
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
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #GREENFIEL_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'GREENFIEL'
        WHERE temp.rn = 1;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, 
            -- Description selalu diambil dari input JSON (t.Description) untuk konsistensi dengan semua bank
            -- Meskipun BankType berbeda, Description harus tetap sama dengan input JSON original
            t.Description AS Description,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #VA_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'VA'
        WHERE temp.rn = 1;

        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #VA_Temp;

        PRINT '✅ VA (RPT TXT) completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GROUP 1: Array[3] + Array[4] Banks
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- BNI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BNI')
    BEGIN
        PRINT '🔄 Processing BNI...';
        
        DECLARE @BNI_JSON NVARCHAR(MAX);
        SELECT @BNI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'BNI' FOR JSON PATH
        );
        
        CREATE TABLE #BNI_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BNI_Temp
        EXEC SP_BNI_FindBTP_Batch @TransactionsJSON = @BNI_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'BNI', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #BNI_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'BNI'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #BNI_Temp;
        
        PRINT '✅ BNI completed';
    END
    
    -- BTPN
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BTPN')
    BEGIN
        PRINT '🔄 Processing BTPN...';
        
        DECLARE @BTPN_JSON NVARCHAR(MAX);
        SELECT @BTPN_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'BTPN' FOR JSON PATH
        );
        
        CREATE TABLE #BTPN_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BTPN_Temp
        EXEC SP_BTPN_FindBTP_Batch @TransactionsJSON = @BTPN_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'BTPN', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #BTPN_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'BTPN'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #BTPN_Temp;
        
        PRINT '✅ BTPN completed';
    END
    
    -- BRI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BRI')
    BEGIN
        PRINT '🔄 Processing BRI...';
        
        DECLARE @BRI_JSON NVARCHAR(MAX);
        SELECT @BRI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'BRI' FOR JSON PATH
        );
        
        CREATE TABLE #BRI_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BRI_Temp
        EXEC SP_BRI_FindBTP_Batch @TransactionsJSON = @BRI_JSON;
        
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
            temp.TransactionID, 
            COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate,
            t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'BRI', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #BRI_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'BRI'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #BRI_Temp;
        
        PRINT '✅ BRI completed';
    END
    
    -- MEGA
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MEGA')
    BEGIN
        PRINT '🔄 Processing MEGA...';
        
        DECLARE @MEGA_JSON NVARCHAR(MAX);
        SELECT @MEGA_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'MEGA' FOR JSON PATH
        );
        
        CREATE TABLE #MEGA_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MEGA_Temp
        EXEC SP_MEGA_FindBTP_Batch @TransactionsJSON = @MEGA_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'MEGA', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #MEGA_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'MEGA'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #MEGA_Temp;
        
        PRINT '✅ MEGA completed';
    END
    
    -- PERMATA
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'PERMATA')
    BEGIN
        PRINT '🔄 Processing PERMATA...';
        
        DECLARE @PERMATA_JSON NVARCHAR(MAX);
        SELECT @PERMATA_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'PERMATA' FOR JSON PATH
        );
        
        CREATE TABLE #PERMATA_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #PERMATA_Temp
        EXEC SP_PERMATA_FindBTP_Batch @TransactionsJSON = @PERMATA_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'PERMATA', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #PERMATA_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'PERMATA'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #PERMATA_Temp;
        
        PRINT '✅ PERMATA completed';
    END
    
    -- DANAMON
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'DANAMON')
    BEGIN
        PRINT '🔄 Processing DANAMON...';
        
        DECLARE @DANAMON_JSON NVARCHAR(MAX);
        SELECT @DANAMON_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'DANAMON' FOR JSON PATH
        );
        
        CREATE TABLE #DANAMON_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #DANAMON_Temp
        EXEC SP_DANAMON_FindBTP_Batch @TransactionsJSON = @DANAMON_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'DANAMON', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #DANAMON_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'DANAMON'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #DANAMON_Temp;
        
        PRINT '✅ DANAMON completed';
    END
    
    -- CITIBANK
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CITIBANK')
    BEGIN
        PRINT '🔄 Processing CITIBANK...';
        
        DECLARE @CITIBANK_JSON NVARCHAR(MAX);
        SELECT @CITIBANK_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'CITIBANK' FOR JSON PATH
        );
        
        CREATE TABLE #CITIBANK_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CITIBANK_Temp
        EXEC SP_CITIBANK_FindBTP_Batch @TransactionsJSON = @CITIBANK_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'CITIBANK', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #CITIBANK_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'CITIBANK'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #CITIBANK_Temp;
        
        PRINT '✅ CITIBANK completed';
    END
    
    -- SINARMAS
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'SINARMAS')
    BEGIN
        PRINT '🔄 Processing SINARMAS...';
        
        DECLARE @SINARMAS_JSON NVARCHAR(MAX);
        SELECT @SINARMAS_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'SINARMAS' FOR JSON PATH
        );
        
        CREATE TABLE #SINARMAS_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #SINARMAS_Temp
        EXEC SP_SINARMAS_FindBTP_Batch @TransactionsJSON = @SINARMAS_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'SINARMAS', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #SINARMAS_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'SINARMAS'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #SINARMAS_Temp;
        
        PRINT '✅ SINARMAS completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GROUP 2: Array[4] + Array[5] Banks
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- CIMB
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CIMB')
    BEGIN
        PRINT '🔄 Processing CIMB...';
        
        DECLARE @CIMB_JSON NVARCHAR(MAX);
        SELECT @CIMB_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'CIMB' FOR JSON PATH
        );
        
        CREATE TABLE #CIMB_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CIMB_Temp
        EXEC SP_CIMB_FindBTP_Batch @TransactionsJSON = @CIMB_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'CIMB', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #CIMB_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'CIMB'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #CIMB_Temp;
        
        PRINT '✅ CIMB completed';
    END
    
    -- MAYBANK
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MAYBANK')
    BEGIN
        PRINT '🔄 Processing MAYBANK...';
        
        DECLARE @MAYBANK_JSON NVARCHAR(MAX);
        SELECT @MAYBANK_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'MAYBANK' FOR JSON PATH
        );
        
        CREATE TABLE #MAYBANK_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MAYBANK_Temp
        EXEC SP_MAYBANK_FindBTP_Batch @TransactionsJSON = @MAYBANK_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'MAYBANK', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #MAYBANK_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'MAYBANK'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #MAYBANK_Temp;
        
        PRINT '✅ MAYBANK completed';
    END
    
    -- HSBC
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'HSBC')
    BEGIN
        PRINT '🔄 Processing HSBC...';
        
        DECLARE @HSBC_JSON NVARCHAR(MAX);
        SELECT @HSBC_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'HSBC' FOR JSON PATH
        );
        
        CREATE TABLE #HSBC_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #HSBC_Temp
        EXEC SP_HSBC_FindBTP_Batch @TransactionsJSON = @HSBC_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'HSBC', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #HSBC_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'HSBC'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #HSBC_Temp;
        
        PRINT '✅ HSBC completed';
    END
    
    -- UOB
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'UOB')
    BEGIN
        PRINT '🔄 Processing UOB...';
        
        DECLARE @UOB_JSON NVARCHAR(MAX);
        SELECT @UOB_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'UOB' FOR JSON PATH
        );
        
        CREATE TABLE #UOB_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #UOB_Temp
        EXEC SP_UOB_FindBTP_Batch @TransactionsJSON = @UOB_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'UOB', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #UOB_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'UOB'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #UOB_Temp;
        
        PRINT '✅ UOB completed';
    END
    
    -- MUAMALAT
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MUAMALAT')
    BEGIN
        PRINT '🔄 Processing MUAMALAT...';
        
        DECLARE @MUAMALAT_JSON NVARCHAR(MAX);
        SELECT @MUAMALAT_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'MUAMALAT' FOR JSON PATH
        );
        
        CREATE TABLE #MUAMALAT_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MUAMALAT_Temp
        EXEC SP_MUAMALAT_FindBTP_Batch @TransactionsJSON = @MUAMALAT_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'MUAMALAT', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #MUAMALAT_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'MUAMALAT'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #MUAMALAT_Temp;
        
        PRINT '✅ MUAMALAT completed';
    END
    
    -- OCBC
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'OCBC')
    BEGIN
        PRINT '🔄 Processing OCBC...';
        
        DECLARE @OCBC_JSON NVARCHAR(MAX);
        SELECT @OCBC_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'OCBC' FOR JSON PATH
        );
        
        CREATE TABLE #OCBC_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #OCBC_Temp
        EXEC SP_OCBC_FindBTP_Batch @TransactionsJSON = @OCBC_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'OCBC', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #OCBC_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'OCBC'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #OCBC_Temp;
        
        PRINT '✅ OCBC completed';
    END
    
    -- DBS
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'DBS')
    BEGIN
        PRINT '🔄 Processing DBS...';
        
        DECLARE @DBS_JSON NVARCHAR(MAX);
        SELECT @DBS_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'DBS' FOR JSON PATH
        );
        
        CREATE TABLE #DBS_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #DBS_Temp
        EXEC SP_DBS_FindBTP_Batch @TransactionsJSON = @DBS_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'DBS', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #DBS_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'DBS'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #DBS_Temp;
        
        PRINT '✅ DBS completed';
    END
    
    -- CAPITAL
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CAPITAL')
    BEGIN
        PRINT '🔄 Processing CAPITAL...';
        
        DECLARE @CAPITAL_JSON NVARCHAR(MAX);
        SELECT @CAPITAL_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'CAPITAL' FOR JSON PATH
        );
        
        CREATE TABLE #CAPITAL_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CAPITAL_Temp
        EXEC SP_CAPITAL_FindBTP_Batch @TransactionsJSON = @CAPITAL_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'CAPITAL', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #CAPITAL_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'CAPITAL'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #CAPITAL_Temp;
        
        PRINT '✅ CAPITAL completed';
    END
    
    -- WOORI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'WOORI')
    BEGIN
        PRINT '🔄 Processing WOORI...';
        
        DECLARE @WOORI_JSON NVARCHAR(MAX);
        SELECT @WOORI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions WHERE BankType = 'WOORI' FOR JSON PATH
        );
        
        CREATE TABLE #WOORI_Temp (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #WOORI_Temp
        EXEC SP_WOORI_FindBTP_Batch @TransactionsJSON = @WOORI_JSON;
        
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
            temp.TransactionID, COALESCE(TRY_CAST(temp.TransactionDate AS DATE), t.TransactionDate) AS TransactionDate, t.Description AS Description,
            temp.CustomerName, temp.BTP, temp.MatchPercentage, temp.MatchCount, temp.TotalTransactions,
            temp.LastLineNumber, temp.TotalBTPOptions, temp.OptionNumber, temp.BestFlag, temp.LatestFlag,
            temp.Label, temp.Status, temp.Message, 'WOORI', temp.ProcessedAt,
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
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY OptionNumber, MatchPercentage DESC, LastLineNumber DESC) AS rn
            FROM #WOORI_Temp
            WHERE (OptionNumber IS NULL OR OptionNumber = 1)
        ) AS temp
        INNER JOIN @Transactions AS t ON t.TransactionID = temp.TransactionID AND t.BankType = 'WOORI'
        WHERE temp.rn = 1;
        
        SET @ProcessedCount = @ProcessedCount + @@ROWCOUNT;
        DROP TABLE #WOORI_Temp;
        
        PRINT '✅ WOORI completed';
    END
    
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
    -- Ensure ALL transactions are saved (fallback for missing transactions)
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Insert transaksi yang belum masuk ke BTP_REVIEW
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
        t.TransactionID,
        t.TransactionDate,
        t.Description,
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
        'MISSING' AS Status,
        'Transaksi tidak diproses oleh SP bank-specific - perlu investigasi' AS Message,
        t.BankType,
        GETDATE() AS ProcessedAt,
        t.Amount,
        CASE WHEN t.TransactionType IN ('CR', 'DB') THEN t.TransactionType ELSE NULL END,
        0 AS IsApproved,
        'Transaksi dengan BankType "' + t.BankType + '" tidak masuk ke BTP_REVIEW - kemungkinan SP tidak mengembalikan hasil atau ada error dalam proses' AS Notes,
        GETDATE() AS CreatedAt
    FROM @Transactions AS t
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.BTP_REVIEW AS br
        WHERE br.BatchID = @BatchID
            AND br.TransactionID = t.TransactionID
    );
    
    DECLARE @MissingCount INT = @@ROWCOUNT;
    IF @MissingCount > 0
    BEGIN
        SET @ProcessedCount = @ProcessedCount + @MissingCount;
        PRINT '⚠️  Missing transactions saved: ' + CAST(@MissingCount AS VARCHAR);
        PRINT '   → These were not processed by bank-specific SPs';
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

