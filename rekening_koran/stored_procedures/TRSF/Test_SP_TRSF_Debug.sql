-- =====================================================
-- Test SP_TRSF_FindBTP_Batch - DEBUG VERSION
-- =====================================================
-- Purpose: Test extraction logic dan matching untuk debugging
-- Shows: Description, extracted words, last number index, customer name, matching results
-- =====================================================

USE POWERAPPS;
GO

-- Test dengan sample data dari TRSF_SAMPLE.json
DECLARE @TestJSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": 313,
        "transaction_date": "13/11/2025",
        "description": "TRSF E-BANKING CR 1311/FTSCY/WS95011 683280.00 N9239026 22Sep25 Domu BSD FRANKI SEPTINUS"
    },
    {
        "transaction_id": 314,
        "transaction_date": "13/11/2025",
        "description": "TRSF E-BANKING CR 1311/FTSCY/WS95011 911040.00 N9255646 26Sep25 Domu BSD FRANKI SEPTINUS"
    }
]';

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'TEST SP_TRSF_FindBTP_Batch - DEBUG MODE';
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
DECLARE @LastNumberIndex INT = -1;
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
    SET @LastNumberIndex = -1;
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
            WHEN Word LIKE '%[0-9]%' THEN 'HAS NUMBER'
            ELSE 'NO NUMBER'
        END AS HasNumber,
        CASE 
            WHEN Word COLLATE Latin1_General_BIN NOT LIKE '%[a-z]%' THEN 'ALL CAPS'
            ELSE 'MIXED CASE'
        END AS CaseType
    FROM @Words
    ORDER BY WordIndex;
    PRINT '';
    
    -- Find last word with number
    SELECT TOP 1 @LastNumberIndex = WordIndex
    FROM @Words
    WHERE Word LIKE '%[0-9]%'
    ORDER BY WordIndex DESC;
    
    PRINT 'Last Number Index: ' + ISNULL(CAST(@LastNumberIndex AS VARCHAR), 'NULL');
    PRINT '';
    
    -- Extract ALL CAPS words after last number
    IF @LastNumberIndex IS NOT NULL AND @LastNumberIndex < @WordCount
    BEGIN
        DECLARE @TempName NVARCHAR(200) = '';
        DECLARE @SkipMonths TABLE (Month NVARCHAR(20));
        
        DELETE FROM @SkipMonths;
        INSERT INTO @SkipMonths VALUES 
            ('JAN'),('JANUARI'),('FEB'),('FEBRUARI'),('MAR'),('MARET'),
            ('APR'),('APRIL'),('MAY'),('MEI'),('JUN'),('JUNI'),
            ('JUL'),('JULI'),('AUG'),('AGT'),('AGUSTUS'),
            ('SEP'),('SEPT'),('SEPTEMBER'),('OCT'),('OKT'),('OKTOBER'),
            ('NOV'),('NOVEMBER'),('DEC'),('DES'),('DESEMBER');
        
        -- Show words after last number
        PRINT 'Words After Last Number:';
        SELECT 
            WordIndex,
            Word,
            CASE 
                WHEN Word COLLATE Latin1_General_BIN NOT LIKE '%[a-z]%' THEN 'ALL CAPS ✓'
                ELSE 'MIXED CASE ✗'
            END AS CaseType,
            CASE 
                WHEN EXISTS (SELECT 1 FROM @SkipMonths WHERE Month = Word) THEN 'MONTH ✗'
                WHEN LEN(Word) < 2 THEN 'TOO SHORT ✗'
                WHEN Word COLLATE Latin1_General_BIN NOT LIKE '%[a-z]%' THEN 'INCLUDED ✓'
                ELSE 'EXCLUDED ✗'
            END AS Status
        FROM @Words
        WHERE WordIndex > @LastNumberIndex
        ORDER BY WordIndex;
        PRINT '';
        
        -- Extract customer name
        SELECT @TempName = @TempName + 
            CASE 
                WHEN LEN(@TempName) > 0 THEN ' ' + Word 
                ELSE Word 
            END
        FROM @Words w
        WHERE WordIndex > @LastNumberIndex
            AND Word COLLATE Latin1_General_BIN NOT LIKE '%[a-z]%'
            AND LEN(Word) >= 2
            AND NOT EXISTS (SELECT 1 FROM @SkipMonths WHERE Month = Word)
        ORDER BY WordIndex;
        
        SET @CustomerName = LTRIM(RTRIM(@TempName));
        
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
                END AS MatchType
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
            WHERE (m.category = 'TRSF' OR m.category = 'NEW')
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
    END
    ELSE
    BEGIN
        PRINT 'No valid last number found or no words after last number';
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
GO

