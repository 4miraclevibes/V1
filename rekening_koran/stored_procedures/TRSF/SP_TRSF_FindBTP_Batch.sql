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
        TransactionID NVARCHAR(50),  -- Optional identifier dari client
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
    
    -- Process each description
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
    
    -- Helper function variables
    DECLARE @CurrentRowID INT;
    DECLARE @CurrentTransactionID NVARCHAR(50);
    DECLARE @CurrentDescription NVARCHAR(500);
    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @BestBTP NVARCHAR(100);
    DECLARE @BestMatchPct DECIMAL(5,2);
    DECLARE @BestMatchCount INT;
    DECLARE @BestTotalTrans INT;
    DECLARE @TotalOptions INT;
    
    -- Cursor untuk process each description
    DECLARE desc_cursor CURSOR FOR 
        SELECT RowID, TransactionID, Description FROM @Inputs;
    
    OPEN desc_cursor;
    FETCH NEXT FROM desc_cursor INTO @CurrentRowID, @CurrentTransactionID, @CurrentDescription;
    
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
        -- Find BTP dari Master Pattern
        -- =====================================================
        
        SET @BestBTP = NULL;
        SET @BestMatchPct = NULL;
        SET @BestMatchCount = NULL;
        SET @BestTotalTrans = NULL;
        SET @TotalOptions = 0;
        
        IF @CustomerName IS NOT NULL AND LEN(@CustomerName) >= 3
        BEGIN
            -- Find BEST match
            SELECT TOP 1
                @BestBTP = m.btp,
                @BestMatchPct = m.match_percentage,
                @BestMatchCount = m.match_count,
                @BestTotalTrans = m.total_transactions
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
            WHERE m.category = 'TRSF'
                AND UPPER(m.customer_name) = UPPER(@CustomerName)
            ORDER BY 
                m.match_percentage DESC,
                m.total_transactions DESC,
                m.last_line_number DESC;
            
            -- Count total options
            SELECT @TotalOptions = COUNT(*)
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
            WHERE m.category = 'TRSF'
                AND UPPER(m.customer_name) = UPPER(@CustomerName);
        END
        
        -- Insert result
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
    -- Return Results
    -- =====================================================
    
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
            WHEN TotalBTPOptions > 1 THEN 'Found ' + CAST(TotalBTPOptions AS VARCHAR) + ' BTP options. Returning BEST.'
            WHEN Status IN ('EXCELLENT', 'GOOD') THEN 'High confidence match'
            WHEN Status = 'FAIR' THEN 'Medium confidence match'
            WHEN Status = 'LOW' THEN 'Low confidence match - verify manually'
            ELSE 'Match found'
        END AS Message,
        ProcessedAt
    FROM @Results
    ORDER BY RowID;
    
    -- Summary statistics
    IF @Debug = 1
    BEGIN
        PRINT '=== Summary Statistics ===';
        SELECT 
            COUNT(*) AS TotalProcessed,
            SUM(CASE WHEN BTP IS NOT NULL THEN 1 ELSE 0 END) AS FoundBTP,
            SUM(CASE WHEN BTP IS NULL THEN 1 ELSE 0 END) AS NotFound,
            AVG(CASE WHEN BTP IS NOT NULL THEN MatchPercentage ELSE NULL END) AS AvgMatchPercentage
        FROM @Results;
        
        PRINT '=== Status Breakdown ===';
        SELECT Status, COUNT(*) AS Count
        FROM @Results
        GROUP BY Status
        ORDER BY COUNT(*) DESC;
    END
END
GO

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

-- Example 1: Simple batch (2 descriptions)
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": "TRX001",
        "description": "TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY"
    },
    {
        "transaction_id": "TRX002",
        "description": "TRSF FROM BCA 123456789 HARDI PUTRA MUHARR"
    }
]';

EXEC [dbo].[SP_TRSF_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 1;
*/

-- Example 2: Large batch (without transaction_id, will auto-generate)
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"description": "TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY"},
    {"description": "TRSF FROM BCA 123456789 HARDI PUTRA MUHARR"},
    {"description": "TRSF ONLINE PAYMENT 555.00 BROOKLYN BOGA UTAM"},
    {"description": "TRSF ATM 100000 PANCIOUS TIRTA JAY"},
    {"description": "TRSF MOBILE 250000 SUPER NORMAL SISTE"}
]';

EXEC [dbo].[SP_TRSF_FindBTP_Batch] 
    @InputJSON = @JSON,
    @Debug = 0;
*/

-- Example 3: Production format dengan response handling
/*
DECLARE @JSON NVARCHAR(MAX) = N'[
    {"transaction_id": "TRX001", "description": "TRSF E-BANKING CR 0201 455520.00 RONNY YULIADY"},
    {"transaction_id": "TRX002", "description": "TRSF FROM BCA 123456789 HARDI PUTRA MUHARR"}
]';

DECLARE @Results TABLE (
    TransactionID NVARCHAR(50),
    BTP NVARCHAR(100),
    Status NVARCHAR(20),
    Confidence DECIMAL(5,2)
);

INSERT INTO @Results
SELECT TransactionID, BTP, Status, MatchPercentage
FROM [dbo].[SP_TRSF_FindBTP_Batch](@InputJSON, 0);

-- Process results
SELECT * FROM @Results;
*/

