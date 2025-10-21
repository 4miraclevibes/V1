-- =====================================================
-- SP_TRSF_FindBTP_Batch_v2
-- =====================================================
-- Purpose: Find BTP dari multiple deskripsi TRSF (Batch via JSON)
-- Version 2: Returns ALL BTP OPTIONS untuk multiple matches
-- Similar to C code behavior
-- =====================================================

CREATE OR ALTER PROCEDURE [dbo].[SP_TRSF_FindBTP_Batch_v2]
    @InputJSON NVARCHAR(MAX),
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Parse JSON input
    DECLARE @Inputs TABLE (
        RowID INT IDENTITY(1,1),
        TransactionID NVARCHAR(50),
        Description NVARCHAR(500)
    );
    
    INSERT INTO @Inputs (TransactionID, Description)
    SELECT 
        ISNULL(TransactionID, CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS NVARCHAR(50))) AS TransactionID,
        Description
    FROM OPENJSON(@InputJSON)
    WITH (
        TransactionID NVARCHAR(50) '$.transaction_id',
        Description NVARCHAR(500) '$.description'
    );
    
    IF @Debug = 1
    BEGIN
        PRINT '=== Input Data ===';
        SELECT * FROM @Inputs;
    END
    
    -- Main results
    DECLARE @Results TABLE (
        RowID INT,
        TransactionID NVARCHAR(50),
        Description NVARCHAR(500),
        CustomerName NVARCHAR(200),
        BTP NVARCHAR(100),
        MatchPercentage DECIMAL(5,2),
        MatchCount INT,
        TotalTransactions INT,
        TotalBTPOptions INT,
        Status NVARCHAR(20),
        ProcessedAt DATETIME DEFAULT GETDATE()
    );
    
    -- ALL BTP Options (for multiple matches)
    DECLARE @AllOptions TABLE (
        TransactionID NVARCHAR(50),
        OptionNumber INT,
        BTP NVARCHAR(100),
        MatchPercentage DECIMAL(5,2),
        MatchCount INT,
        TotalTransactions INT,
        LastLineNumber INT,
        IsLatest BIT,
        IsBest BIT,
        Label NVARCHAR(50)
    );
    
    -- Process each description
    DECLARE @CurrentRowID INT;
    DECLARE @CurrentTransactionID NVARCHAR(50);
    DECLARE @CurrentDescription NVARCHAR(500);
    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @BestBTP NVARCHAR(100);
    DECLARE @BestMatchPct DECIMAL(5,2);
    DECLARE @BestMatchCount INT;
    DECLARE @BestTotalTrans INT;
    DECLARE @TotalOptions INT;
    
    DECLARE desc_cursor CURSOR FOR 
        SELECT RowID, TransactionID, Description FROM @Inputs;
    
    OPEN desc_cursor;
    FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentDescription;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- =====================================================
        -- Extract Customer Name (same logic as v1)
        -- =====================================================
        
        SET @CustomerName = NULL;
        
        DECLARE @Words TABLE (WordIndex INT, Word NVARCHAR(100));
        DECLARE @LastNumberIndex INT = -1;
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
        
        SELECT TOP 1 @LastNumberIndex = WordIndex
        FROM @Words
        WHERE Word LIKE '%[0-9]%'
        ORDER BY WordIndex DESC;
        
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
        -- Find ALL BTP Options + Store Details
        -- =====================================================
        
        SET @BestBTP = NULL;
        SET @BestMatchPct = NULL;
        SET @BestMatchCount = NULL;
        SET @BestTotalTrans = NULL;
        SET @TotalOptions = 0;
        
        IF @CustomerName IS NOT NULL AND LEN(@CustomerName) >= 3
        BEGIN
            -- Temp table untuk semua options
            DECLARE @TempOptions TABLE (
                BTP NVARCHAR(100),
                MatchPercentage DECIMAL(5,2),
                MatchCount INT,
                TotalTransactions INT,
                LastLineNumber INT,
                OptionNumber INT
            );
            
            -- Get ALL matches sorted
            INSERT INTO @TempOptions
            SELECT 
                m.btp,
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
            WHERE m.category = 'TRSF'
                AND UPPER(m.customer_name) = UPPER(@CustomerName);
            
            SET @TotalOptions = @@ROWCOUNT;
            
            -- Get BEST match
            SELECT TOP 1
                @BestBTP = BTP,
                @BestMatchPct = MatchPercentage,
                @BestMatchCount = MatchCount,
                @BestTotalTrans = TotalTransactions
            FROM @TempOptions
            WHERE OptionNumber = 1;
            
            -- If multiple options, store ALL details
            IF @TotalOptions > 1
            BEGIN
                -- Find latest BTP (highest line number)
                DECLARE @LatestBTP NVARCHAR(100);
                SELECT TOP 1 @LatestBTP = BTP
                FROM @TempOptions
                ORDER BY LastLineNumber DESC;
                
                -- Insert ALL options dengan labels
                INSERT INTO @AllOptions (
                    TransactionID, OptionNumber, BTP, MatchPercentage,
                    MatchCount, TotalTransactions, LastLineNumber,
                    IsLatest, IsBest, Label
                )
                SELECT 
                    @CurrentTransactionID,
                    OptionNumber,
                    BTP,
                    MatchPercentage,
                    MatchCount,
                    TotalTransactions,
                    LastLineNumber,
                    CASE WHEN BTP = @LatestBTP THEN 1 ELSE 0 END AS IsLatest,
                    CASE WHEN OptionNumber = 1 THEN 1 ELSE 0 END AS IsBest,
                    CASE 
                        WHEN OptionNumber = 1 AND BTP = @LatestBTP THEN 'BEST + LATEST'
                        WHEN OptionNumber = 1 THEN 'BEST'
                        WHEN BTP = @LatestBTP THEN 'LATEST'
                        ELSE ''
                    END AS Label
                FROM @TempOptions
                ORDER BY OptionNumber;
            END
            
            DELETE FROM @TempOptions;
        END
        
        -- Insert main result
        INSERT INTO @Results (
            RowID, TransactionID, Description, CustomerName, 
            BTP, MatchPercentage, MatchCount, TotalTransactions, 
            TotalBTPOptions, Status
        )
        VALUES (
            @CurrentRowID,
            @CurrentTransactionID,
            @CurrentDescription,
            @CustomerName,
            @BestBTP,
            @BestMatchPct,
            @BestMatchCount,
            @BestTotalTrans,
            @TotalOptions,
            CASE 
                WHEN @BestBTP IS NULL AND @CustomerName IS NULL THEN 'NO_PATTERN'
                WHEN @BestBTP IS NULL THEN 'NO_MATCH'
                WHEN @BestMatchPct >= 95 THEN 'EXCELLENT'
                WHEN @BestMatchPct >= 80 THEN 'GOOD'
                WHEN @BestMatchPct >= 70 THEN 'FAIR'
                ELSE 'LOW'
            END
        );
        
        FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentDescription;
    END
    
    CLOSE desc_cursor;
    DEALLOCATE desc_cursor;
    
    -- =====================================================
    -- Return Results (2 Result Sets)
    -- =====================================================
    
    -- Result Set 1: Main Results
    SELECT 
        TransactionID,
        Description,
        CustomerName,
        BTP,
        MatchPercentage,
        MatchCount,
        TotalTransactions,
        TotalBTPOptions,
        Status,
        CASE 
            WHEN Status = 'NO_PATTERN' THEN 'Customer name not found in description'
            WHEN Status = 'NO_MATCH' THEN 'Customer "' + CustomerName + '" not found in master data'
            WHEN TotalBTPOptions > 1 THEN 'Found ' + CAST(TotalBTPOptions AS VARCHAR) + ' BTP options. Returning BEST. See Result Set 2 for all options.'
            WHEN Status IN ('EXCELLENT', 'GOOD') THEN 'High confidence match'
            WHEN Status = 'FAIR' THEN 'Medium confidence match'
            WHEN Status = 'LOW' THEN 'Low confidence match - verify manually'
            ELSE 'Match found'
        END AS Message,
        ProcessedAt
    FROM @Results
    ORDER BY RowID;
    
    -- Result Set 2: ALL BTP Options (only for multiple matches)
    IF EXISTS (SELECT 1 FROM @AllOptions)
    BEGIN
        SELECT 
            TransactionID,
            OptionNumber,
            BTP,
            MatchPercentage,
            MatchCount,
            TotalTransactions,
            LastLineNumber,
            CASE 
                WHEN IsBest = 1 THEN '✅ BEST'
                ELSE '  '
            END AS BestFlag,
            CASE 
                WHEN IsLatest = 1 THEN '🕒 LATEST'
                ELSE ''
            END AS LatestFlag,
            Label,
            CASE 
                WHEN MatchPercentage >= 95 THEN 'EXCELLENT'
                WHEN MatchPercentage >= 80 THEN 'GOOD'
                WHEN MatchPercentage >= 70 THEN 'FAIR'
                ELSE 'LOW'
            END AS Quality
        FROM @AllOptions
        ORDER BY TransactionID, OptionNumber;
    END
    ELSE
    BEGIN
        -- Empty result set dengan struktur yang sama
        SELECT 
            CAST(NULL AS NVARCHAR(50)) AS TransactionID,
            CAST(NULL AS INT) AS OptionNumber,
            CAST(NULL AS NVARCHAR(100)) AS BTP,
            CAST(NULL AS DECIMAL(5,2)) AS MatchPercentage,
            CAST(NULL AS INT) AS MatchCount,
            CAST(NULL AS INT) AS TotalTransactions,
            CAST(NULL AS INT) AS LastLineNumber,
            CAST(NULL AS NVARCHAR(10)) AS BestFlag,
            CAST(NULL AS NVARCHAR(10)) AS LatestFlag,
            CAST(NULL AS NVARCHAR(50)) AS Label,
            CAST(NULL AS NVARCHAR(20)) AS Quality
        WHERE 1 = 0;  -- Always empty
    END
    
    -- Summary statistics (if debug)
    IF @Debug = 1
    BEGIN
        PRINT '=== Summary Statistics ===';
        SELECT 
            COUNT(*) AS TotalProcessed,
            SUM(CASE WHEN BTP IS NOT NULL THEN 1 ELSE 0 END) AS FoundBTP,
            SUM(CASE WHEN BTP IS NULL THEN 1 ELSE 0 END) AS NotFound,
            SUM(CASE WHEN TotalBTPOptions > 1 THEN 1 ELSE 0 END) AS MultipleOptions,
            AVG(CASE WHEN BTP IS NOT NULL THEN MatchPercentage ELSE NULL END) AS AvgMatchPercentage
        FROM @Results;
    END
END
GO

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

-- Example 1: Simple test with multiple matches
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

EXEC [dbo].[SP_TRSF_FindBTP_Batch_v2] 
    @InputJSON = @JSON,
    @Debug = 0;

-- Result Set 1: Main results (BEST BTP untuk setiap transaction)
-- Result Set 2: ALL OPTIONS (untuk transactions dengan multiple BTPs)
--   Columns: TransactionID, OptionNumber, BTP, MatchPercentage, 
--            BestFlag, LatestFlag, Label, Quality
*/

-- Example 2: View all options details
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "T1", "description": "TRSF 12345 CHRISTIAN"},
    {"transaction_id": "T2", "description": "TRSF 67890 RONNY YULIADY"}
]';

EXEC [dbo].[SP_TRSF_FindBTP_Batch_v2] @InputJSON = @JSON;

-- Check Result Set 2 untuk lihat ALL BTP options
-- Flag indicators:
--   ✅ BEST     = Highest match percentage (recommended)
--   🕒 LATEST   = Most recently used BTP
--   BEST + LATEST = Same BTP is both best and latest
*/

