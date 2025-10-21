-- =====================================================
-- SP_TRSF_FindBTP_Single
-- =====================================================
-- Purpose: Find BTP dari deskripsi transaksi TRSF (Single)
-- Logic: Extract customer name (ALL CAPS setelah last number)
--        Match dengan master pattern, return BEST match
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_TRSF_FindBTP_Single]
    @Description NVARCHAR(500),
    @Debug BIT = 0  -- Set 1 untuk lihat detail proses
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables
    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @Words TABLE (WordIndex INT, Word NVARCHAR(100));
    DECLARE @LastNumberIndex INT = -1;
    DECLARE @WordCount INT = 0;
    
    -- =====================================================
    -- STEP 1: Extract Customer Name dari Description
    -- =====================================================
    
    -- Split description by space
    DECLARE @Word NVARCHAR(100);
    DECLARE @Pos INT = 1;
    DECLARE @NextPos INT;
    DECLARE @Desc NVARCHAR(500) = LTRIM(RTRIM(@Description));
    
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
    
    IF @Debug = 1
    BEGIN
        PRINT '=== STEP 1: Split Words ===';
        SELECT * FROM @Words ORDER BY WordIndex;
    END
    
    -- Find last word with number
    SELECT TOP 1 @LastNumberIndex = WordIndex
    FROM @Words
    WHERE Word LIKE '%[0-9]%'
    ORDER BY WordIndex DESC;
    
    IF @Debug = 1
        PRINT 'Last number index: ' + ISNULL(CAST(@LastNumberIndex AS VARCHAR), 'NULL');
    
    -- Extract ALL CAPS words after last number
    IF @LastNumberIndex IS NOT NULL AND @LastNumberIndex < @WordCount
    BEGIN
        -- Build customer name from ALL CAPS words
        DECLARE @TempName NVARCHAR(200) = '';
        DECLARE @SkipMonths TABLE (Month NVARCHAR(20));
        
        -- Skip month prefixes
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
            AND Word = UPPER(Word)  -- ALL CAPS check
            AND Word COLLATE Latin1_General_BIN NOT LIKE '%[a-z]%'  -- No lowercase
            AND LEN(Word) >= 2  -- Minimal 2 chars
            AND NOT EXISTS (SELECT 1 FROM @SkipMonths WHERE Month = Word)  -- Skip months
        ORDER BY WordIndex;
        
        SET @CustomerName = @TempName;
    END
    
    IF @Debug = 1
        PRINT 'Extracted customer name: ' + ISNULL(@CustomerName, 'NULL');
    
    -- =====================================================
    -- STEP 2: Find BTP dari Master Pattern
    -- =====================================================
    
    IF @CustomerName IS NULL OR LEN(@CustomerName) < 3
    BEGIN
        -- No valid customer name found
        SELECT 
            NULL AS BTP,
            NULL AS CustomerName,
            NULL AS MatchPercentage,
            NULL AS MatchCount,
            NULL AS TotalTransactions,
            0 AS TotalMatches,
            'NO_PATTERN' AS Status,
            'Customer name not found in description' AS Message;
        RETURN;
    END
    
    -- Find ALL matching patterns
    DECLARE @Matches TABLE (
        BTP NVARCHAR(100),
        CustomerName NVARCHAR(200),
        MatchPercentage DECIMAL(5,2),
        MatchCount INT,
        TotalTransactions INT,
        LastLineNumber INT,
        Rank INT
    );
    
    INSERT INTO @Matches
    SELECT 
        m.btp,
        m.customer_name,
        m.match_percentage,
        m.match_count,
        m.total_transactions,
        m.last_line_number,
        ROW_NUMBER() OVER (
            ORDER BY 
                m.match_percentage DESC,  -- Highest match % first
                m.total_transactions DESC, -- Most transactions
                m.last_line_number DESC    -- Most recent
        ) AS Rank
    FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
    WHERE m.category = 'TRSF'
        AND UPPER(m.customer_name) = UPPER(@CustomerName);
    
    DECLARE @TotalMatches INT = (SELECT COUNT(*) FROM @Matches);
    
    IF @Debug = 1
    BEGIN
        PRINT '=== STEP 2: Matching Results ===';
        PRINT 'Total matches found: ' + CAST(@TotalMatches AS VARCHAR);
        SELECT * FROM @Matches ORDER BY Rank;
    END
    
    -- =====================================================
    -- STEP 3: Return Results
    -- =====================================================
    
    IF @TotalMatches = 0
    BEGIN
        -- No match found
        SELECT 
            NULL AS BTP,
            @CustomerName AS CustomerName,
            NULL AS MatchPercentage,
            NULL AS MatchCount,
            NULL AS TotalTransactions,
            0 AS TotalMatches,
            'NO_MATCH' AS Status,
            'Customer "' + @CustomerName + '" not found in master data' AS Message;
    END
    ELSE
    BEGIN
        -- Return BEST match + all options
        SELECT 
            BTP,
            CustomerName,
            MatchPercentage,
            MatchCount,
            TotalTransactions,
            @TotalMatches AS TotalMatches,
            CASE 
                WHEN MatchPercentage >= 95 THEN 'EXCELLENT'
                WHEN MatchPercentage >= 80 THEN 'GOOD'
                WHEN MatchPercentage >= 70 THEN 'FAIR'
                ELSE 'LOW'
            END AS Status,
            CASE 
                WHEN @TotalMatches > 1 
                THEN 'Found ' + CAST(@TotalMatches AS VARCHAR) + ' BTP options. Returning BEST match.'
                ELSE 'Single match found.'
            END AS Message
        FROM @Matches
        WHERE Rank = 1;  -- BEST match only
        
        -- Return all options if multiple matches
        IF @TotalMatches > 1
        BEGIN
            SELECT 
                Rank AS OptionNumber,
                BTP,
                MatchPercentage,
                MatchCount,
                TotalTransactions,
                LastLineNumber,
                CASE WHEN Rank = 1 THEN 'BEST' ELSE '' END AS Label
            FROM @Matches
            ORDER BY Rank;
        END
    END
END
GO

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

-- Example 1: Simple test
/*
EXEC [dbo].[SP_TRSF_FindBTP_Single] 
    @Description = 'TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY',
    @Debug = 0;
*/

-- Example 2: With debug mode
/*
EXEC [dbo].[SP_TRSF_FindBTP_Single] 
    @Description = 'TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY',
    @Debug = 1;
*/

-- Example 3: Multiple BTP options
/*
EXEC [dbo].[SP_TRSF_FindBTP_Single] 
    @Description = 'TRSF FROM BCA 123456789 HARDI PUTRA MUHARR',
    @Debug = 0;
*/

