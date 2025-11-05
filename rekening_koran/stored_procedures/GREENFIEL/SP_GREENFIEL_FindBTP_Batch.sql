-- =====================================================
-- SP_GREENFIEL_FindBTP_Batch
-- =====================================================
-- Purpose: Find BTP dari multiple deskripsi GREENFIEL (Batch via JSON)
-- Pattern: Array[4] = 'GREENFIEL' (exact match)
-- Logic: 
--   1. Extract BTP dari array terakhir yang dimulai "23..."
--   2. Cari di master dengan BTP tersebut
--   3. Jika ketemu, gunakan customer_name dari master untuk matching
-- Input: JSON array of descriptions
-- Output: Result set dengan BTP untuk setiap description
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_GREENFIEL_FindBTP_Batch]
    @InputJSON NVARCHAR(MAX),
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Parse JSON input
    DECLARE @Inputs TABLE (
        RowID INT IDENTITY(1,1),
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX)
    );
    
    INSERT INTO @Inputs (TransactionID, TransactionDate, Description)
    SELECT 
        ISNULL(TRY_CAST(TransactionID AS INT), CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT)) AS TransactionID,
        TransactionDate,
        Description
    FROM OPENJSON(@InputJSON)
    WITH (
        TransactionID INT '$.transaction_id',
        TransactionDate NVARCHAR(50) '$.transaction_date',
        Description NVARCHAR(MAX) '$.description'
    );
    
    IF @Debug = 1
    BEGIN
        PRINT '=== Input Data ===';
        SELECT * FROM @Inputs;
    END
    
    -- Process each description
    DECLARE @Results TABLE (
        RowID INT,
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX),
        CustomerName NVARCHAR(200),
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
        DataSource NVARCHAR(50),  -- Flag untuk notes: 'MASTER_CUSTOMER_BTP_PATTERN' atau 'MP_CUSTOMER_NEW'
        ProcessedAt DATETIME DEFAULT GETDATE()
    );
    
        -- Helper function variables
    DECLARE @CurrentRowID INT;
    DECLARE @CurrentTransactionID INT;
    DECLARE @CurrentTransactionDate NVARCHAR(50);
    DECLARE @CurrentDescription NVARCHAR(MAX);
    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @ExtractedBTP NVARCHAR(50);
    DECLARE @BestBTP NVARCHAR(50);
    DECLARE @BestMatchPct DECIMAL(5,2);
    DECLARE @BestMatchCount INT;
    DECLARE @BestTotalTrans INT;
    DECLARE @TotalOptions INT;
    DECLARE @DataSource NVARCHAR(50);  -- Untuk track data source: 'MASTER_CUSTOMER_BTP_PATTERN' atau 'MP_CUSTOMER_NEW'
    
    -- Cursor untuk process each description
    DECLARE desc_cursor CURSOR FOR 
        SELECT RowID, TransactionID, TransactionDate, Description FROM @Inputs;
    
    OPEN desc_cursor;
    FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- =====================================================
        -- Step 1: Check Pattern - Array[4] = 'GREENFIEL'
        -- =====================================================
        
        SET @CustomerName = NULL;
        SET @ExtractedBTP = NULL;
        SET @DataSource = 'MASTER_CUSTOMER_BTP_PATTERN';  -- Reset data source untuk setiap transaction
        
        DECLARE @Words TABLE (WordIndex INT, Word NVARCHAR(100));
        DECLARE @WordCount INT = 0;
        
        -- Split description by space
        DECLARE @Word NVARCHAR(100);
        DECLARE @Pos INT = 1;
        DECLARE @NextPos INT;
        DECLARE @Desc NVARCHAR(500) = LTRIM(RTRIM(@CurrentDescription));
        
        DELETE FROM @Words;
        
        WHILE @Pos <= LEN(@Desc)
        BEGIN
            SET @NextPos = CHARINDEX(' ', @Desc, @Pos);
            
            IF @NextPos = 0
                SET @NextPos = LEN(@Desc) + 1;
            
            SET @Word = SUBSTRING(@Desc, @Pos, @NextPos - @Pos);
            -- Remove trailing comma
            SET @Word = LTRIM(RTRIM(REPLACE(REPLACE(@Word, ',', ''), '.', '')));
            
            IF LEN(@Word) > 0
            BEGIN
                SET @WordCount = @WordCount + 1;
                INSERT INTO @Words (WordIndex, Word) VALUES (@WordCount, @Word);
            END
            
            SET @Pos = @NextPos + 1;
        END
        
        -- Check if Array[4] = 'GREENFIEL'
        -- Note: Array index 4 (zero-based) = WordIndex 5 (one-based)
        -- Format: "KR OTOMATIS [CODE] [CODE] GREENFIEL ..."
        --         [0]         [1]    [2]      [3]        [4]    [5+]
        --         WordIndex: 1       2        3          4      5
        DECLARE @Array4 NVARCHAR(100);
        SELECT @Array4 = Word FROM @Words WHERE WordIndex = 5;  -- Changed from 4 to 5
        
        IF @Debug = 1
        BEGIN
            PRINT 'Debug: WordIndex 5 = ' + ISNULL(@Array4, 'NULL');
            PRINT 'Debug: Total words = ' + CAST(@WordCount AS VARCHAR);
        END
        
        IF @Array4 <> 'GREENFIEL' OR @Array4 IS NULL
        BEGIN
            -- Not a GREENFIEL pattern, skip
            INSERT INTO @Results (
                RowID, TransactionID, TransactionDate, Description,
                CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
                LastLineNumber, TotalBTPOptions, OptionNumber, IsBest, IsLatest,
                Status, DataSource, ProcessedAt
            )
            VALUES (
                @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription,
                NULL, NULL, NULL, NULL, NULL,
                NULL, 0, 0, 0, 0,
                'NO_PATTERN', NULL, GETDATE()
            );
            
            FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
            CONTINUE;
        END
        
        -- =====================================================
        -- Step 2: Extract BTP (array terakhir yang dimulai "23...")
        -- =====================================================
        
        SELECT TOP 1 @ExtractedBTP = Word
        FROM @Words
        WHERE Word LIKE '23%'
           AND LEN(Word) >= 10  -- BTP biasanya minimal 10 digit
        ORDER BY WordIndex DESC;
        
        IF @ExtractedBTP IS NULL
        BEGIN
            -- BTP not found
            INSERT INTO @Results (
                RowID, TransactionID, TransactionDate, Description,
                CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
                LastLineNumber, TotalBTPOptions, OptionNumber, IsBest, IsLatest,
                Status, DataSource, ProcessedAt
            )
            VALUES (
                @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription,
                NULL, NULL, NULL, NULL, NULL,
                NULL, 0, 0, 0, 0,
                'NO_BTP', NULL, GETDATE()
            );
            
            FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
            CONTINUE;
        END
        
        -- =====================================================
        -- Step 3: Cari di master dengan BTP, ambil customer_name
        -- Fallback: Jika tidak ketemu, cari di MP_CUSTOMER_NEW dengan BTP, ambil BTN
        -- =====================================================
        
        DECLARE @CustomerNameFromBTP NVARCHAR(200);
        DECLARE @BTPMatchPct DECIMAL(5,2);
        DECLARE @BTPMatchCount INT;
        DECLARE @BTPTotalTrans INT;
        DECLARE @BTPLastLine INT;
        DECLARE @DataSource NVARCHAR(50) = 'MASTER_CUSTOMER_BTP_PATTERN';  -- Flag untuk notes
        
        -- Step 3a: Cari di MASTER_CUSTOMER_BTP_PATTERN dengan BTP
        SELECT TOP 1 
            @CustomerNameFromBTP = LTRIM(RTRIM(m.customer_name)),
            @BTPMatchPct = m.match_percentage,
            @BTPMatchCount = m.match_count,
            @BTPTotalTrans = m.total_transactions,
            @BTPLastLine = m.last_line_number
        FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
        WHERE m.btp = @ExtractedBTP
        ORDER BY 
            CASE WHEN m.category = 'GREENFIEL' THEN 1 ELSE 2 END,
            m.match_percentage DESC,
            m.total_transactions DESC,
            m.last_line_number DESC;
        
        -- Step 3b: Fallback - Jika tidak ketemu di master, cari di MP_CUSTOMER_NEW dengan BTP, ambil BTN
        IF @CustomerNameFromBTP IS NULL
        BEGIN
            DECLARE @BTNFromMPCustomer NVARCHAR(200);
            
            SELECT TOP 1 
                @BTNFromMPCustomer = LTRIM(RTRIM(c.btn))
            FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] c
            WHERE c.btp = @ExtractedBTP
                AND c.btn IS NOT NULL
                AND LEN(LTRIM(RTRIM(c.btn))) >= 3
            ORDER BY c.created_at DESC;
            
            IF @BTNFromMPCustomer IS NOT NULL
            BEGIN
                -- Ketemu di MP_CUSTOMER_NEW, gunakan BTN sebagai CustomerName
                SET @CustomerNameFromBTP = @BTNFromMPCustomer;
                SET @DataSource = 'MP_CUSTOMER_NEW';  -- Flag untuk notes
                
                -- Set default values untuk metadata (karena tidak ada di MP_CUSTOMER_NEW)
                SET @BTPMatchPct = 100.00;  -- Assume 100% karena exact match by BTP
                SET @BTPMatchCount = 1;
                SET @BTPTotalTrans = 1;
                SET @BTPLastLine = 0;
            END
        END
        
        IF @CustomerNameFromBTP IS NULL
        BEGIN
            -- Customer name not found in master or MP_CUSTOMER_NEW (BTP tidak ada di kedua tempat)
            INSERT INTO @Results (
                RowID, TransactionID, TransactionDate, Description,
                CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
                LastLineNumber, TotalBTPOptions, OptionNumber, IsBest, IsLatest,
                Status, DataSource, ProcessedAt
            )
            VALUES (
                @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription,
                NULL, @ExtractedBTP, NULL, NULL, NULL,
                NULL, 0, 0, 0, 0,
                'NO_MATCH', NULL, GETDATE()
            );
            
            FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
            CONTINUE;
        END
        
        SET @CustomerName = @CustomerNameFromBTP;
        
        -- =====================================================
        -- Step 4: Find ALL BTP Options dari Master Pattern menggunakan customer_name
        -- =====================================================
        
        SET @TotalOptions = 0;
        
        IF @CustomerName IS NOT NULL AND LEN(@CustomerName) >= 3
        BEGIN
            -- Count total options
            SELECT @TotalOptions = COUNT(DISTINCT btp)
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
            WHERE (m.category = 'GREENFIEL' OR m.category = 'NEW')
                AND UPPER(m.customer_name) = UPPER(@CustomerName);
            
            -- Insert ALL BTP options (multiple rows for same customer)
            IF @TotalOptions > 0
            BEGIN
                -- Temp table untuk ranking
                DECLARE @TempOptions TABLE (
                    BTP NVARCHAR(50),
                    MatchPercentage DECIMAL(5,2),
                    MatchCount INT,
                    TotalTransactions INT,
                    LastLineNumber INT,
                    OptionNumber INT
                );
                
                -- Get all options dengan ranking
                INSERT INTO @TempOptions
                SELECT 
                    m.btp,
                    m.match_percentage,
                    m.match_count,
                    m.total_transactions,
                    m.last_line_number,
                    ROW_NUMBER() OVER (
                        ORDER BY 
                            CASE WHEN m.category = 'GREENFIEL' THEN 1 ELSE 2 END,
                            m.match_percentage DESC,
                            m.total_transactions DESC,
                            m.last_line_number DESC
                    ) AS OptionNumber
                FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
                WHERE (m.category = 'GREENFIEL' OR m.category = 'NEW')
                    AND UPPER(m.customer_name) = UPPER(@CustomerName);
                
                -- Insert all options ke @Results
                DECLARE @OptBTP NVARCHAR(50);
                DECLARE @OptMatchPct DECIMAL(5,2);
                DECLARE @OptMatchCount INT;
                DECLARE @OptTotalTrans INT;
                DECLARE @OptLastLine INT;
                DECLARE @OptNumber INT;
                
                DECLARE opt_cursor CURSOR FOR 
                    SELECT BTP, MatchPercentage, MatchCount, TotalTransactions, LastLineNumber, OptionNumber
                    FROM @TempOptions
                    ORDER BY OptionNumber;
                
                OPEN opt_cursor;
                FETCH NEXT FROM opt_cursor INTO @OptBTP, @OptMatchPct, @OptMatchCount, @OptTotalTrans, @OptLastLine, @OptNumber;
                
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Determine status
                    DECLARE @Status NVARCHAR(20) = 'FAIR';
                    IF @OptMatchPct >= 95 SET @Status = 'EXCELLENT';
                    ELSE IF @OptMatchPct >= 80 SET @Status = 'GOOD';
                    ELSE IF @OptMatchPct >= 70 SET @Status = 'FAIR';
                    ELSE SET @Status = 'LOW';
                    
                    INSERT INTO @Results (
                        RowID, TransactionID, TransactionDate, Description,
                        CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
                        LastLineNumber, TotalBTPOptions, OptionNumber, IsBest, IsLatest,
                        Status, DataSource, ProcessedAt
                    )
                    VALUES (
                        @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription,
                        @CustomerName, @OptBTP, @OptMatchPct, @OptMatchCount, @OptTotalTrans,
                        @OptLastLine, @TotalOptions, @OptNumber, 
                        CASE WHEN @OptNumber = 1 THEN 1 ELSE 0 END,  -- Best = Option 1
                        CASE WHEN @OptNumber = 1 AND @OptLastLine = (SELECT MAX(LastLineNumber) FROM @TempOptions) THEN 1 ELSE 0 END,  -- Latest = highest last_line_number
                        @Status, @DataSource, GETDATE()
                    );
                    
                    FETCH NEXT FROM opt_cursor INTO @OptBTP, @OptMatchPct, @OptMatchCount, @OptTotalTrans, @OptLastLine, @OptNumber;
                END
                
                CLOSE opt_cursor;
                DEALLOCATE opt_cursor;
            END
            ELSE
            BEGIN
                -- Customer name found but no BTP in master with category 'GREENFIEL' or 'NEW'
                -- Fallback: Use the extracted BTP as default (since we found customer_name from it)
                DECLARE @FallbackStatus NVARCHAR(20) = 'FAIR';
                IF @BTPMatchPct >= 95 SET @FallbackStatus = 'EXCELLENT';
                ELSE IF @BTPMatchPct >= 80 SET @FallbackStatus = 'GOOD';
                ELSE IF @BTPMatchPct >= 70 SET @FallbackStatus = 'FAIR';
                ELSE SET @FallbackStatus = 'LOW';
                
                INSERT INTO @Results (
                    RowID, TransactionID, TransactionDate, Description,
                    CustomerName, BTP, MatchPercentage, MatchCount, TotalTransactions,
                    LastLineNumber, TotalBTPOptions, OptionNumber, IsBest, IsLatest,
                    Status, DataSource, ProcessedAt
                )
                VALUES (
                    @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription,
                    @CustomerName, @ExtractedBTP, @BTPMatchPct, @BTPMatchCount, @BTPTotalTrans,
                    @BTPLastLine, 1, 1, 1, 1,  -- Single option, so it's both BEST and LATEST
                    @FallbackStatus, @DataSource, GETDATE()
                );
            END
        END
        
        FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
    END
    
    CLOSE desc_cursor;
    DEALLOCATE desc_cursor;
    
    -- =====================================================
    -- Return Results
    -- =====================================================
    
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
            WHEN Status = 'NO_PATTERN' THEN 'GREENFIEL pattern not found (Array[4] must be "GREENFIEL")'
            WHEN Status = 'NO_BTP' THEN 'BTP not found in description (expected array ending with "23...")'
            WHEN Status = 'NO_MATCH' THEN 'BTP "' + ISNULL(@ExtractedBTP, '') + '" not found in master data or customer has no BTP'
            WHEN TotalBTPOptions > 1 AND OptionNumber = 1 THEN 'Found ' + CAST(TotalBTPOptions AS VARCHAR) + ' BTP options. This is BEST (Option ' + CAST(OptionNumber AS VARCHAR) + ' of ' + CAST(TotalBTPOptions AS VARCHAR) + ')' + 
                CASE WHEN DataSource = 'MP_CUSTOMER_NEW' THEN ' [Data source: MP_CUSTOMER_NEW]' ELSE '' END
            WHEN TotalBTPOptions > 1 THEN 'Option ' + CAST(OptionNumber AS VARCHAR) + ' of ' + CAST(TotalBTPOptions AS VARCHAR) + 
                CASE WHEN DataSource = 'MP_CUSTOMER_NEW' THEN ' [Data source: MP_CUSTOMER_NEW]' ELSE '' END
            WHEN Status IN ('EXCELLENT', 'GOOD') THEN 'High confidence match' + 
                CASE WHEN DataSource = 'MP_CUSTOMER_NEW' THEN ' [Data source: MP_CUSTOMER_NEW]' ELSE '' END
            WHEN Status = 'FAIR' THEN 'Medium confidence match' + 
                CASE WHEN DataSource = 'MP_CUSTOMER_NEW' THEN ' [Data source: MP_CUSTOMER_NEW]' ELSE '' END
            WHEN Status = 'LOW' THEN 'Low confidence match - verify manually' + 
                CASE WHEN DataSource = 'MP_CUSTOMER_NEW' THEN ' [Data source: MP_CUSTOMER_NEW]' ELSE '' END
            ELSE 'Match found' + 
                CASE WHEN DataSource = 'MP_CUSTOMER_NEW' THEN ' [Data source: MP_CUSTOMER_NEW]' ELSE '' END
        END AS Message,
        DataSource,
        ProcessedAt
    FROM @Results
    ORDER BY TransactionID, OptionNumber;
    
    -- Summary statistics
    IF @Debug = 1
    BEGIN
        PRINT '=== Summary Statistics ===';
        SELECT 
            COUNT(DISTINCT TransactionID) AS TotalTransactions,
            COUNT(*) AS TotalRows,
            SUM(CASE WHEN BTP IS NOT NULL THEN 1 ELSE 0 END) AS FoundBTP,
            SUM(CASE WHEN BTP IS NULL THEN 1 ELSE 0 END) AS NotFound,
            SUM(CASE WHEN TotalBTPOptions > 1 THEN 1 ELSE 0 END) AS MultipleOptions,
            AVG(CASE WHEN BTP IS NOT NULL THEN MatchPercentage ELSE NULL END) AS AvgMatchPercentage
        FROM @Results;
        
        PRINT '=== Status Breakdown ===';
        SELECT Status, COUNT(*) AS Count
        FROM @Results
        GROUP BY Status
        ORDER BY COUNT(*) DESC;
        
        PRINT '=== Transactions with Multiple BTPs ===';
        SELECT TransactionID, CustomerName, TotalBTPOptions
        FROM @Results
        WHERE TotalBTPOptions > 1
        GROUP BY TransactionID, CustomerName, TotalBTPOptions;
    END
END
GO

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

-- Example 1: Test with sample data
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TRX001",
        "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL STJ IC, 16 SEP 25 INV N9216659 2300017744,"
    },
    {
        "transaction_id": "TRX002",
        "description": "KR OTOMATIS 0110/FTFVA/WS95011 01660/PT GREENFIEL K00200162181 PlayCorner 2300015906,"
    },
    {
        "transaction_id": "TRX003",
        "description": "KR OTOMATIS 3009/FTFVA/WS95051 01660/PT GREENFIEL Boen - Inv 30 Sep Greenfield 2300015551,"
    }
]';

EXEC [dbo].[SP_GREENFIEL_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 1;
*/
