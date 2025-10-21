-- =====================================================
-- SP_MANDIRI_FindBTP_Single
-- =====================================================
-- Purpose: Find BTP dari deskripsi transaksi MANDIRI (Single)
-- Logic: Extract Array[3] + Array[4] (with smart PT/CV)
--        Match dengan master pattern, return BEST match
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_MANDIRI_FindBTP_Single]
    @Description NVARCHAR(500),
    @Debug BIT = 0  -- Set 1 untuk lihat detail proses
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables
    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @Words TABLE (WordIndex INT, Word NVARCHAR(100));
    DECLARE @WordCount INT = 0;
    
    -- =====================================================
    -- STEP 1: Extract Customer Name dari Description
    -- MANDIRI Logic: Array[3] + Array[4] (smart PT/CV)
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
        PRINT '=== DEBUG: Words Split ===';
        SELECT * FROM @Words ORDER BY WordIndex;
        PRINT 'Total words: ' + CAST(@WordCount AS VARCHAR);
    END
    
    -- Extract customer name: Array[3] + Array[4] (with PT/CV smart)
    -- Format: "KR OTOMATIS LLG-MANDIRI [Word4] [Word5] [Word6]..."
    -- C array[3] = SQL WordIndex 4 (because SQL starts from 1, C starts from 0)
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
    
    IF @Debug = 1
    BEGIN
        PRINT '=== DEBUG: Extraction Result ===';
        PRINT 'Extracted Customer Name: ' + ISNULL(@CustomerName, 'NULL');
    END
    
    -- =====================================================
    -- STEP 2: Find BTP dari Master Pattern
    -- =====================================================
    
    DECLARE @Results TABLE (
        BTP NVARCHAR(100),
        CustomerName NVARCHAR(200),
        MatchPercentage DECIMAL(5,2),
        MatchCount INT,
        TotalTransactions INT,
        LastLineNumber INT,
        OptionNumber INT
    );
    
    IF @CustomerName IS NOT NULL AND LEN(@CustomerName) >= 3
    BEGIN
        -- Get ALL matches dengan ranking
        INSERT INTO @Results
        SELECT 
            m.btp,
            m.customer_name,
            m.match_percentage,
            m.match_count,
            m.total_transactions,
            m.last_line_number,
            ROW_NUMBER() OVER (
                ORDER BY 
                    m.match_percentage DESC,
                    m.total_transactions DESC,
                    m.last_line_number DESC
            ) AS OptionNumber
        FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
        WHERE m.category = 'MANDIRI'
            AND UPPER(m.customer_name) = UPPER(@CustomerName);
    END
    
    IF @Debug = 1
    BEGIN
        PRINT '=== DEBUG: Search Results ===';
        SELECT * FROM @Results ORDER BY OptionNumber;
    END
    
    -- =====================================================
    -- STEP 3: Return Results
    -- =====================================================
    
    DECLARE @TotalOptions INT = (SELECT COUNT(*) FROM @Results);
    
    IF @TotalOptions = 0
    BEGIN
        -- No match found
        SELECT 
            @Description AS Description,
            @CustomerName AS CustomerName,
            NULL AS BTP,
            NULL AS MatchPercentage,
            NULL AS MatchCount,
            NULL AS TotalTransactions,
            NULL AS LastLineNumber,
            0 AS TotalBTPOptions,
            NULL AS OptionNumber,
            '' AS BestFlag,
            '' AS LatestFlag,
            '' AS Label,
            CASE 
                WHEN @CustomerName IS NULL THEN 'NO_PATTERN'
                ELSE 'NO_MATCH'
            END AS Status,
            CASE 
                WHEN @CustomerName IS NULL THEN 'Customer name not found in description'
                ELSE 'Customer "' + @CustomerName + '" not found in master data'
            END AS Message;
    END
    ELSE
    BEGIN
        -- Return ALL options dengan flags
        DECLARE @LatestBTP NVARCHAR(100);
        SELECT TOP 1 @LatestBTP = BTP 
        FROM @Results 
        ORDER BY LastLineNumber DESC;
        
        SELECT 
            @Description AS Description,
            r.CustomerName,
            r.BTP,
            r.MatchPercentage,
            r.MatchCount,
            r.TotalTransactions,
            r.LastLineNumber,
            @TotalOptions AS TotalBTPOptions,
            r.OptionNumber,
            CASE WHEN r.OptionNumber = 1 THEN 'YES' ELSE '' END AS BestFlag,
            CASE WHEN r.BTP = @LatestBTP THEN 'YES' ELSE '' END AS LatestFlag,
            CASE 
                WHEN r.OptionNumber = 1 AND r.BTP = @LatestBTP THEN 'BEST + LATEST'
                WHEN r.OptionNumber = 1 THEN 'BEST'
                WHEN r.BTP = @LatestBTP THEN 'LATEST'
                ELSE ''
            END AS Label,
            CASE 
                WHEN r.MatchPercentage >= 95 THEN 'EXCELLENT'
                WHEN r.MatchPercentage >= 80 THEN 'GOOD'
                WHEN r.MatchPercentage >= 70 THEN 'FAIR'
                ELSE 'LOW'
            END AS Status,
            CASE 
                WHEN @TotalOptions > 1 AND r.OptionNumber = 1 THEN 
                    'Found ' + CAST(@TotalOptions AS VARCHAR) + ' BTP options. This is BEST (Option 1 of ' + CAST(@TotalOptions AS VARCHAR) + ')'
                WHEN @TotalOptions > 1 THEN 
                    'Option ' + CAST(r.OptionNumber AS VARCHAR) + ' of ' + CAST(@TotalOptions AS VARCHAR)
                WHEN r.MatchPercentage >= 95 THEN 'High confidence match'
                WHEN r.MatchPercentage >= 70 THEN 'Medium confidence match'
                ELSE 'Low confidence match - verify manually'
            END AS Message
        FROM @Results r
        ORDER BY r.OptionNumber;
    END
END
GO

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

-- Example 1: Simple test (tanpa PT/CV)
/*
EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'KR OTOMATIS LLG-MANDIRI KOPERASI KARYAWAN GREENFIELDS INDONESIA',
    @Debug = 1;

-- Expected: Customer = "KOPERASI KARYAWAN" (2 words)
*/

-- Example 2: With PT prefix
/*
EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'KR OTOMATIS LLG-MANDIRI PT MITRA SELERA GREENFIELDS DAIRY',
    @Debug = 1;

-- Expected: Customer = "PT MITRA SELERA" (3 words)
*/

-- Example 3: With CV prefix
/*
EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'KR OTOMATIS LLG-MANDIRI CV KARYA MANDIRI INDO BUKTI BAYAR',
    @Debug = 1;

-- Expected: Customer = "CV KARYA MANDIRI" (3 words)
*/

-- Example 4: Production usage (no debug)
/*
EXEC [dbo].[SP_MANDIRI_FindBTP_Single] 
    @Description = 'KR OTOMATIS LLG-MANDIRI KOPERASI KARYAWAN TEST',
    @Debug = 0;
*/

