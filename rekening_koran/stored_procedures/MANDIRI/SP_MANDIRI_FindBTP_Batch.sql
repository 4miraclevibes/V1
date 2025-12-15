-- =====================================================
-- SP_MANDIRI_FindBTP_Batch
-- =====================================================
-- Purpose: Find BTP dari multiple deskripsi MANDIRI (Batch via JSON)
-- Logic: Extract Array[3] + Array[4] (smart PT/CV)
-- Output: Multiple rows untuk customers dengan multiple BTPs
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_MANDIRI_FindBTP_Batch]
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
        ProcessedAt DATETIME DEFAULT GETDATE()
    );
    
    -- Helper function variables
    DECLARE @CurrentRowID INT;
    DECLARE @CurrentTransactionID INT;
    DECLARE @CurrentTransactionDate NVARCHAR(50);
    DECLARE @CurrentDescription NVARCHAR(MAX);
    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @TotalOptions INT;
    
    -- Cursor untuk process each description
    DECLARE desc_cursor CURSOR FOR 
        SELECT RowID, TransactionID, TransactionDate, Description FROM @Inputs;
    
    OPEN desc_cursor;
    FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- =====================================================
        -- Extract Customer Name (MANDIRI Logic)
        -- Array[3] + Array[4] (smart PT/CV)
        -- =====================================================
        
        SET @CustomerName = NULL;
        
        DECLARE @Words TABLE (WordIndex INT, Word NVARCHAR(100));
        DECLARE @WordCount INT = 0;
        
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
            
            IF LEN(@Word) > 0
            BEGIN
                SET @WordCount = @WordCount + 1;
                INSERT INTO @Words (WordIndex, Word) VALUES (@WordCount, @Word);
            END
            
            SET @Pos = @NextPos + 1;
        END
        
        -- Extract Array[3] + Array[4] (with smart PT/CV)
        -- C array[3] = SQL WordIndex 4 (SQL starts from 1, C starts from 0)
        IF @WordCount >= 5
        BEGIN
            DECLARE @Word3 NVARCHAR(100);
            DECLARE @Word4 NVARCHAR(100);
            DECLARE @Word5 NVARCHAR(100);
            
            -- Array[3] in C = WordIndex 4 in SQL
            SELECT @Word3 = Word FROM @Words WHERE WordIndex = 4;
            SELECT @Word4 = Word FROM @Words WHERE WordIndex = 5;
            
            -- Smart PT/CV extraction
            IF @Word3 IN ('PT', 'CV') AND @WordCount >= 6
            BEGIN
                SELECT @Word5 = Word FROM @Words WHERE WordIndex = 6;
                SET @CustomerName = @Word3 + ' ' + @Word4 + ' ' + @Word5;
            END
            ELSE
            BEGIN
                SET @CustomerName = @Word3 + ' ' + @Word4;
            END
        END
        
        -- =====================================================
        -- Find ALL BTP Options dari Master Pattern
        -- =====================================================
        
        SET @TotalOptions = 0;
        
        -- Normalize customer name (remove extra spaces)
        IF @CustomerName IS NOT NULL
        BEGIN
            SET @CustomerName = LTRIM(RTRIM(@CustomerName));
            -- Replace multiple spaces with single space
            WHILE CHARINDEX('  ', @CustomerName) > 0
            BEGIN
                SET @CustomerName = REPLACE(@CustomerName, '  ', ' ');
            END
        END
        
        IF @CustomerName IS NOT NULL AND LEN(@CustomerName) >= 3
        BEGIN
            -- Count total options (with smart partial matching support)
            -- Try exact match first, then substring matching, then word-by-word matching
            SELECT @TotalOptions = COUNT(DISTINCT btp)
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
            WHERE (m.category = 'MANDIRI' OR m.category = 'NEW')
                AND (
                    -- Priority 1: Exact match
                    UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName)))
                    OR
                    -- Priority 2: Master name contained in extracted name (most common case)
                    -- Example: master "MITRA BELANJA ANDA" matches extracted "MITRA BELANJA ANDA GL PIK"
                    UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%'
                    OR
                    -- Priority 3: Extracted name contained in master name
                    -- Example: master "PT MITRA BELANJA ANDA" matches extracted "MITRA BELANJA ANDA"
                    UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%'
                    OR
                    -- Priority 4: Word-by-word matching (at least 2 words match, minimum 3 chars per word)
                    -- Example: master "MITRA BELANJA ANDA" matches extracted "MITRA BELANJA ANDA GL PIK" (3 words match)
                    (
                        SELECT COUNT(*)
                        FROM (
                            SELECT value AS word
                            FROM STRING_SPLIT(UPPER(LTRIM(RTRIM(m.customer_name))), ' ')
                            WHERE LEN(LTRIM(RTRIM(value))) >= 3
                        ) AS master_words
                        WHERE UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + LTRIM(RTRIM(master_words.word)) + '%'
                    ) >= 2
                );
            
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
                
                -- Get all options dengan ranking (prioritize exact match, then partial matches)
                INSERT INTO @TempOptions
                SELECT 
                    m.btp,
                    m.match_percentage,
                    m.match_count,
                    m.total_transactions,
                    m.last_line_number,
                    ROW_NUMBER() OVER (
                        ORDER BY 
                            -- Priority: exact match first, then partial matches, then word-by-word
                            CASE 
                                WHEN UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName))) THEN 1
                                WHEN UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%' THEN 2
                                WHEN UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%' THEN 3
                                WHEN (
                                    SELECT COUNT(*)
                                    FROM (
                                        SELECT value AS word
                                        FROM STRING_SPLIT(UPPER(LTRIM(RTRIM(m.customer_name))), ' ')
                                        WHERE LEN(LTRIM(RTRIM(value))) >= 3
                                    ) AS master_words
                                    WHERE UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + LTRIM(RTRIM(master_words.word)) + '%'
                                ) >= 2 THEN 4
                                ELSE 5
                            END,
                            CASE WHEN m.category = 'MANDIRI' THEN 1 ELSE 2 END,
                            m.match_percentage DESC,
                            m.total_transactions DESC,
                            m.last_line_number DESC
                    ) AS OptionNumber
                FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
                WHERE (m.category = 'MANDIRI' OR m.category = 'NEW')
                    AND (
                        -- Priority 1: Exact match
                        UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName)))
                        OR
                        -- Priority 2: Master name contained in extracted name
                        UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%'
                        OR
                        -- Priority 3: Extracted name contained in master name
                        UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%'
                        OR
                        -- Priority 4: Word-by-word matching (at least 2 words match, minimum 3 chars per word)
                        (
                            SELECT COUNT(*)
                            FROM (
                                SELECT value AS word
                                FROM STRING_SPLIT(UPPER(LTRIM(RTRIM(m.customer_name))), ' ')
                                WHERE LEN(LTRIM(RTRIM(value))) >= 3
                            ) AS master_words
                            WHERE UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + LTRIM(RTRIM(master_words.word)) + '%'
                        ) >= 2
                    );
                
                -- Find LATEST (highest line number)
                DECLARE @LatestBTP NVARCHAR(50);
                SELECT TOP 1 @LatestBTP = BTP
                FROM @TempOptions
                ORDER BY LastLineNumber DESC;
                
                -- Insert ALL options sebagai rows terpisah
                INSERT INTO @Results (
                    RowID, TransactionID, TransactionDate, Description, CustomerName, 
                    BTP, MatchPercentage, MatchCount, TotalTransactions, 
                    LastLineNumber, TotalBTPOptions, OptionNumber, 
                    IsBest, IsLatest, Status
                )
                SELECT 
                    @CurrentRowID,
                    @CurrentTransactionID,
                    @CurrentTransactionDate,
                    @CurrentDescription,
                    @CustomerName,
                    t.BTP,
                    t.MatchPercentage,
                    t.MatchCount,
                    t.TotalTransactions,
                    t.LastLineNumber,
                    @TotalOptions,
                    t.OptionNumber,
                    CASE WHEN t.OptionNumber = 1 THEN 1 ELSE 0 END AS IsBest,
                    CASE WHEN t.BTP = @LatestBTP THEN 1 ELSE 0 END AS IsLatest,
                    CASE 
                        WHEN t.MatchPercentage >= 95 THEN 'EXCELLENT'
                        WHEN t.MatchPercentage >= 80 THEN 'GOOD'
                        WHEN t.MatchPercentage >= 70 THEN 'FAIR'
                        ELSE 'LOW'
                    END
                FROM @TempOptions t
                ORDER BY t.OptionNumber;
                
                DELETE FROM @TempOptions;
            END
            ELSE
            BEGIN
                -- No match found
                INSERT INTO @Results (
                    RowID, TransactionID, TransactionDate, Description, CustomerName, 
                    BTP, MatchPercentage, MatchCount, TotalTransactions, 
                    LastLineNumber, TotalBTPOptions, OptionNumber, 
                    IsBest, IsLatest, Status
                )
                VALUES (
                    @CurrentRowID,
                    @CurrentTransactionID,
                    @CurrentTransactionDate,
                    @CurrentDescription,
                    @CustomerName,
                    NULL, NULL, NULL, NULL, NULL,
                    0, NULL, 0, 0, 'NO_MATCH'
                );
            END
        END
        ELSE
        BEGIN
            -- Customer name not extracted
            INSERT INTO @Results (
                RowID, TransactionID, TransactionDate, Description, CustomerName, 
                BTP, MatchPercentage, MatchCount, TotalTransactions, 
                LastLineNumber, TotalBTPOptions, OptionNumber, 
                IsBest, IsLatest, Status
            )
            VALUES (
                @CurrentRowID,
                @CurrentTransactionID,
                @CurrentTransactionDate,
                    @CurrentDescription,
                @CustomerName,
                NULL, NULL, NULL, NULL, NULL,
                0, NULL, 0, 0, 'NO_PATTERN'
            );
        END;
        
        FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
    END
    
    CLOSE desc_cursor;
    DEALLOCATE desc_cursor;
    
    -- =====================================================
    -- Return Results (ALL BTP OPTIONS as separate rows)
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
            WHEN Status = 'NO_PATTERN' THEN 'Customer name not found in description'
            WHEN Status = 'NO_MATCH' THEN 'Customer "' + CustomerName + '" not found in master data'
            WHEN TotalBTPOptions > 1 AND OptionNumber = 1 THEN 'Found ' + CAST(TotalBTPOptions AS VARCHAR) + ' BTP options. This is BEST (Option ' + CAST(OptionNumber AS VARCHAR) + ' of ' + CAST(TotalBTPOptions AS VARCHAR) + ')'
            WHEN TotalBTPOptions > 1 THEN 'Option ' + CAST(OptionNumber AS VARCHAR) + ' of ' + CAST(TotalBTPOptions AS VARCHAR)
            WHEN Status IN ('EXCELLENT', 'GOOD') THEN 'High confidence match'
            WHEN Status = 'FAIR' THEN 'Medium confidence match'
            WHEN Status = 'LOW' THEN 'Low confidence match - verify manually'
            ELSE 'Match found'
        END AS Message,
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
-- USAGE EXAMPLES (Returns ALL BTP options as multiple rows)
-- =====================================================

-- Example 1: Simple test (tanpa PT/CV)
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TRX001",
        "description": "KR OTOMATIS LLG-MANDIRI KOPERASI KARYAWAN GREENFIELDS INDONESIA"
    }
]';

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 1;

-- Expected: Customer = "KOPERASI KARYAWAN" (2 words)
*/

-- Example 2: Batch dengan PT/CV prefix
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "T1", "description": "KR OTOMATIS LLG-MANDIRI KOPERASI KARYAWAN TEST"},
    {"transaction_id": "T2", "description": "KR OTOMATIS LLG-MANDIRI PT MITRA SELERA GREENFIELDS"},
    {"transaction_id": "T3", "description": "KR OTOMATIS LLG-MANDIRI CV KARYA MANDIRI INDO"}
]';

EXEC [dbo].[SP_MANDIRI_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 0;

-- Expected:
-- T1: Customer = "KOPERASI KARYAWAN" (2 words)
-- T2: Customer = "PT MITRA SELERA" (3 words)
-- T3: Customer = "CV KARYA MANDIRI" (3 words)
*/

-- Example 3: Filter for BEST options only
/*
DECLARE @JSON NVARCHAR(MAX) = N'[...]';

SELECT TransactionID, CustomerName, BTP, MatchPercentage, Label
FROM [dbo].[SP_MANDIRI_FindBTP_Batch](@JSON, 0)
WHERE BestFlag = 'YES';
*/

