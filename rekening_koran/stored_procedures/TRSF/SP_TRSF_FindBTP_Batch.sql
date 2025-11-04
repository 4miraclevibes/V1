-- =====================================================
-- SP_TRSF_FindBTP_Batch
-- =====================================================
-- Purpose: Find BTP dari multiple deskripsi TRSF (Batch via JSON)
-- Input: JSON array of descriptions
-- Output: Result set dengan BTP untuk setiap description
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_TRSF_FindBTP_Batch]
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
    DECLARE @BestBTP NVARCHAR(50);
    DECLARE @BestMatchPct DECIMAL(5,2);
    DECLARE @BestMatchCount INT;
    DECLARE @BestTotalTrans INT;
    DECLARE @TotalOptions INT;
    
    -- Cursor untuk process each description
    DECLARE desc_cursor CURSOR FOR 
        SELECT RowID, TransactionID, TransactionDate, Description FROM @Inputs;
    
    OPEN desc_cursor;
    FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- =====================================================
        -- Extract Customer Name (same logic as single SP)
        -- =====================================================
        
        SET @CustomerName = NULL;
        
        DECLARE @Words TABLE (WordIndex INT, Word NVARCHAR(100));
        DECLARE @LastNumberIndex INT = -1;
        DECLARE @WordCount INT = 0;
        
        -- Split description by space
        DECLARE @Word NVARCHAR(100);
        DECLARE @Pos INT = 1;
        DECLARE @NextPos INT;
        DECLARE @Desc NVARCHAR(500) = LTRIM(RTRIM(@CurrentDescription));
        
        DELETE FROM @Words;  -- Clear untuk setiap iterasi
        
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
        
        -- Find last word with number
        SELECT TOP 1 @LastNumberIndex = WordIndex
        FROM @Words
        WHERE Word LIKE '%[0-9]%'
        ORDER BY WordIndex DESC;
        
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
            
            SELECT @TempName = @TempName + 
                CASE 
                    WHEN LEN(@TempName) > 0 THEN ' ' + Word 
                    ELSE Word 
                END
            FROM @Words w
            WHERE WordIndex > @LastNumberIndex
                AND Word = UPPER(Word)
                AND Word COLLATE Latin1_General_BIN NOT LIKE '%[a-z]%'
                AND LEN(Word) >= 2
                AND NOT EXISTS (SELECT 1 FROM @SkipMonths WHERE Month = Word)
            ORDER BY WordIndex;
            
            SET @CustomerName = @TempName;
        END
        
        -- =====================================================
        -- Find ALL BTP Options dari Master Pattern
        -- =====================================================
        
        SET @TotalOptions = 0;
        
        IF @CustomerName IS NOT NULL AND LEN(@CustomerName) >= 3
        BEGIN
            -- Count total options
            SELECT @TotalOptions = COUNT(DISTINCT btp)
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
            WHERE (m.category = 'TRSF' OR m.category = 'NEW')
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
                            CASE WHEN m.category = 'TRSF' THEN 1 ELSE 2 END,
                            m.match_percentage DESC,
                            m.total_transactions DESC,
                            m.last_line_number DESC
                    ) AS OptionNumber
                FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
                WHERE (m.category = 'TRSF' OR m.category = 'NEW')
                    AND UPPER(m.customer_name) = UPPER(@CustomerName);
                
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

-- Example 1: Simple test with customer having multiple BTPs
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TRX001",
        "description": "TRSF E-BANKING CR 1304/FTSCY/WS95011 683280.00 fresh milk 36pcs 15/04/2024 CHRISTIAN"
    },
    {
        "transaction_id": "TRX002",
        "description": "TRSF FROM BCA 123456789 HARDI PUTRA MUHARR"
    }
]';

EXEC [dbo].[SP_TRSF_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 1;

-- Expected Output:
-- TRX001 will return 2 ROWS (CHRISTIAN has 2 BTPs):
--   Row 1: BTP 2300014842, 98.81%, BestFlag='YES', Label='BEST'
--   Row 2: BTP 2300015678, 95.24%, LatestFlag='YES', Label='LATEST'
-- TRX002 will return 1 ROW (HARDI PUTRA MUHARR has 1 BTP)
*/

-- Example 2: Large batch showing multiple options behavior
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "T1", "description": "TRSF E-BANKING CR 0201 455520.00 RONNY YULIADY"},
    {"transaction_id": "T2", "description": "TRSF FROM BCA 123456789 CHRISTIAN"},
    {"transaction_id": "T3", "description": "TRSF ONLINE PAYMENT 555.00 BROOKLYN BOGA UTAM"},
    {"transaction_id": "T4", "description": "TRSF ATM 100000 PANCIOUS TIRTA JAY"}
]';

EXEC [dbo].[SP_TRSF_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 0;

-- If T2 (CHRISTIAN) has 2 BTPs, output will be:
-- T1: 1 row
-- T2: 2 rows (Option 1 and Option 2)
-- T3: 1 row
-- T4: 1 row
-- Total: 5 rows (not 4)
*/

-- Example 3: Filter for BEST options only
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "TX1", "description": "TRSF 12345 CHRISTIAN"},
    {"transaction_id": "TX2", "description": "TRSF 67890 RONNY YULIADY"}
]';

-- Get all options
SELECT * 
INTO #AllResults
FROM [dbo].[SP_TRSF_FindBTP_Batch](@JSON, 0);

-- Filter: BEST options only (for automation)
SELECT TransactionID, CustomerName, BTP, MatchPercentage, Label
FROM #AllResults
WHERE BestFlag = 'YES' OR TotalBTPOptions = 1;

-- View: ALL options (for manual review)
SELECT TransactionID, CustomerName, BTP, MatchPercentage, OptionNumber, Label
FROM #AllResults
ORDER BY TransactionID, OptionNumber;

DROP TABLE #AllResults;
*/

-- Example 4: Count how many transactions have multiple BTP options
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"description": "TRSF 001 CUSTOMER A"},
    {"description": "TRSF 002 CUSTOMER B"},
    {"description": "TRSF 003 CUSTOMER C"}
]';

SELECT 
    COUNT(DISTINCT TransactionID) AS TotalTransactions,
    SUM(CASE WHEN TotalBTPOptions > 1 THEN 1 ELSE 0 END) AS TransWithMultipleBTPs
FROM [dbo].[SP_TRSF_FindBTP_Batch](@JSON, 0);
*/

