-- =====================================================
-- Test SP_MANDIRI_FindBTP_Batch - DEBUG VERSION
-- =====================================================
-- Purpose: Test extraction logic dan matching untuk debugging
-- Shows: Description, extracted words, customer name, matching results
-- =====================================================

USE POWERAPPS;
GO

-- Test dengan sample data dari MANDIRI_SAMPLE.json
DECLARE @TestJSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": 211,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL KHI"
    },
    {
        "transaction_id": 212,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL KHI"
    },
    {
        "transaction_id": 215,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GLBSD"
    },
    {
        "transaction_id": 216,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL GLC"
    },
    {
        "transaction_id": 217,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GLBSD"
    },
    {
        "transaction_id": 218,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL PURI"
    },
    {
        "transaction_id": 219,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL MOI"
    },
    {
        "transaction_id": 220,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL MOI"
    },
    {
        "transaction_id": 221,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL PURI"
    },
    {
        "transaction_id": 223,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL GLC"
    },
    {
        "transaction_id": 224,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL PIK"
    },
    {
        "transaction_id": 225,
        "transaction_date": "13/11/2025",
        "description": "KR OTOMATIS LLG-MANDIRI MITRA BELANJA ANDA GL PIK"
    }
]';

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST SP_MANDIRI_FindBTP_Batch - DEBUG MODE';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';

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
FROM OPENJSON(@TestJSON)
WITH (
    TransactionID INT '$.transaction_id',
    TransactionDate NVARCHAR(50) '$.transaction_date',
    Description NVARCHAR(MAX) '$.description'
);

-- Process each description dengan debug output
DECLARE @CurrentRowID INT;
DECLARE @CurrentTransactionID INT;
DECLARE @CurrentTransactionDate NVARCHAR(50);
DECLARE @CurrentDescription NVARCHAR(MAX);
DECLARE @CustomerName NVARCHAR(200);
DECLARE @Words TABLE (WordIndex INT, Word NVARCHAR(100));
DECLARE @WordCount INT = 0;

DECLARE desc_cursor CURSOR FOR 
    SELECT RowID, TransactionID, TransactionDate, Description FROM @Inputs;

OPEN desc_cursor;
FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '───────────────────────────────────────────────────────────────────────';
    PRINT 'Transaction ID: ' + CAST(@CurrentTransactionID AS VARCHAR);
    PRINT 'Description: ' + @CurrentDescription;
    PRINT '';
    
    -- Reset variables
    SET @CustomerName = NULL;
    SET @WordCount = 0;
    DELETE FROM @Words;
    
    -- Split description by space
    DECLARE @Word NVARCHAR(100);
    DECLARE @Pos INT = 1;
    DECLARE @NextPos INT;
    DECLARE @Desc NVARCHAR(500) = LTRIM(RTRIM(@CurrentDescription));
    
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
    
    -- Display all words
    PRINT 'All Words:';
    SELECT 
        WordIndex,
        Word,
        CASE 
            WHEN WordIndex = 4 THEN 'Array[3] (WordIndex 4)'
            WHEN WordIndex = 5 THEN 'Array[4] (WordIndex 5)'
            WHEN WordIndex = 6 THEN 'Array[5] (WordIndex 6) - Used if Array[3] = PT/CV'
            ELSE ''
        END AS ArrayPosition
    FROM @Words
    ORDER BY WordIndex;
    PRINT '';
    
    -- Extract Array[3] + Array[4] (with smart PT/CV)
    PRINT 'Extraction Logic:';
    IF @WordCount >= 5
    BEGIN
        DECLARE @Word3 NVARCHAR(100);
        DECLARE @Word4 NVARCHAR(100);
        DECLARE @Word5 NVARCHAR(100);
        
        -- Array[3] in C = WordIndex 4 in SQL
        SELECT @Word3 = Word FROM @Words WHERE WordIndex = 4;
        SELECT @Word4 = Word FROM @Words WHERE WordIndex = 5;
        
        PRINT 'WordIndex 4 (Array[3]): ' + ISNULL(@Word3, 'NULL');
        PRINT 'WordIndex 5 (Array[4]): ' + ISNULL(@Word4, 'NULL');
        
        -- Smart PT/CV extraction
        IF @Word3 IN ('PT', 'CV') AND @WordCount >= 6
        BEGIN
            SELECT @Word5 = Word FROM @Words WHERE WordIndex = 6;
            PRINT 'WordIndex 6 (Array[5]): ' + ISNULL(@Word5, 'NULL');
            PRINT 'Logic: Array[3] = PT/CV, so extract Array[3] + Array[4] + Array[5] (3 words)';
            SET @CustomerName = @Word3 + ' ' + @Word4 + ' ' + @Word5;
        END
        ELSE
        BEGIN
            PRINT 'Logic: Array[3] != PT/CV, so extract Array[3] + Array[4] (2 words)';
            SET @CustomerName = @Word3 + ' ' + @Word4;
        END
    END
    ELSE
    BEGIN
        PRINT 'WordCount < 5, cannot extract customer name';
    END
    
    PRINT '';
    
    -- Normalize customer name
    IF @CustomerName IS NOT NULL
    BEGIN
        SET @CustomerName = LTRIM(RTRIM(@CustomerName));
        WHILE CHARINDEX('  ', @CustomerName) > 0
        BEGIN
            SET @CustomerName = REPLACE(@CustomerName, '  ', ' ');
        END
    END
    
    PRINT 'Extracted Customer Name: ' + ISNULL(@CustomerName, 'NULL');
    PRINT '';
    
    -- Check matching dengan master data
    IF @CustomerName IS NOT NULL AND LEN(@CustomerName) >= 3
    BEGIN
        PRINT 'Matching Results:';
        SELECT 
            m.customer_name AS MasterCustomerName,
            m.btp,
            m.match_percentage,
            m.match_count,
            m.total_transactions,
            CASE 
                WHEN UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName))) THEN 'EXACT MATCH ✓'
                WHEN UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%' THEN 'PARTIAL MATCH (Master in Extracted) ✓'
                WHEN UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%' THEN 'PARTIAL MATCH (Extracted in Master) ✓'
                WHEN (
                    SELECT COUNT(*)
                    FROM (
                        SELECT value AS word
                        FROM STRING_SPLIT(UPPER(LTRIM(RTRIM(m.customer_name))), ' ')
                        WHERE LEN(LTRIM(RTRIM(value))) >= 3
                    ) AS master_words
                    WHERE UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + LTRIM(RTRIM(master_words.word)) + '%'
                ) >= 2 THEN 'WORD-BY-WORD MATCH ✓'
                ELSE 'NO MATCH ✗'
            END AS MatchType,
            CASE 
                WHEN UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName))) THEN 1
                WHEN UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%' THEN 2
                WHEN UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%' THEN 3
                ELSE 4
            END AS MatchPriority
        FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
        WHERE (m.category = 'MANDIRI' OR m.category = 'NEW')
            AND (
                UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName)))
                OR
                UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%'
                OR
                UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%'
                OR
                (
                    SELECT COUNT(*)
                    FROM (
                        SELECT value AS word
                        FROM STRING_SPLIT(UPPER(LTRIM(RTRIM(m.customer_name))), ' ')
                        WHERE LEN(LTRIM(RTRIM(value))) >= 3
                    ) AS master_words
                    WHERE UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + LTRIM(RTRIM(master_words.word)) + '%'
                ) >= 2
            )
        ORDER BY 
            CASE 
                WHEN UPPER(LTRIM(RTRIM(m.customer_name))) = UPPER(LTRIM(RTRIM(@CustomerName))) THEN 1
                WHEN UPPER(LTRIM(RTRIM(@CustomerName))) LIKE '%' + UPPER(LTRIM(RTRIM(m.customer_name))) + '%' THEN 2
                WHEN UPPER(LTRIM(RTRIM(m.customer_name))) LIKE '%' + UPPER(LTRIM(RTRIM(@CustomerName))) + '%' THEN 3
                ELSE 4
            END,
            m.match_percentage DESC,
            m.total_transactions DESC,
            m.last_line_number DESC;
    END
    ELSE
    BEGIN
        PRINT 'Customer Name is NULL or too short (< 3 characters)';
    END
    
    PRINT '';
    PRINT '';
    
    FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
END

CLOSE desc_cursor;
DEALLOCATE desc_cursor;

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'DEBUG TEST COMPLETE';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Test Cases (from MANDIRI_SAMPLE.json):';
PRINT 'All transactions extract: "MITRA BELANJA ANDA" (Array[3] + Array[4])';
PRINT 'Expected: Should match master data "MITRA BELANJA ANDA" via Partial Match';
PRINT '  - Extracted: "MITRA BELANJA ANDA GL KHI" → Match "MITRA BELANJA ANDA" ✓';
PRINT '  - Extracted: "MITRA BELANJA ANDA GLBSD" → Match "MITRA BELANJA ANDA" ✓';
PRINT '  - Extracted: "MITRA BELANJA ANDA GL PIK" → Match "MITRA BELANJA ANDA" ✓';
PRINT '';
GO

