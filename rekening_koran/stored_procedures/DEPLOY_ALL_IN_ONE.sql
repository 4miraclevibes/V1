-- ═══════════════════════════════════════════════════════════════════════════
-- ALL-IN-ONE DEPLOYMENT SCRIPT
-- ═══════════════════════════════════════════════════════════════════════════
--
-- This file contains ALL 5 stored procedures in one file.
-- Just copy-paste this entire file to SQL Server and execute!
--
-- Procedures included:
--   1. SP_TRSF_FindBTP_Batch
--   2. SP_BIFAST_FindBTP_Batch
--   3. SP_MANDIRI_FindBTP_Batch
--   4. SP_MASTER_FindBTP_Batch (NOW WITH ALL 20 BANKS!)
--   5. SP_MASTER_FindBTP_Batch_ToStaging
--
-- Database: POWERAPPS
-- Version: v2.2.0 (ALL 20 BANKS COMPLETE!)
-- Date: 2025-10-22
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'DEPLOYING ALL 5 STORED PROCEDURES...';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
GO


-- ═══════════════════════════════════════════════════════════════════════════
-- 1. TRSF
-- ═══════════════════════════════════════════════════════════════════════════

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
            WHERE m.category = 'TRSF'
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
                            m.match_percentage DESC,
                            m.total_transactions DESC,
                            m.last_line_number DESC
                    ) AS OptionNumber
                FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
                WHERE m.category = 'TRSF'
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
GO

PRINT '✅ TRSF deployed!';
PRINT '';
GO


-- ═══════════════════════════════════════════════════════════════════════════
-- 2. BIFAST
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR ALTER PROCEDURE [dbo].[SP_BIFAST_FindBTP_Batch]
    @InputJSON NVARCHAR(MAX),
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Parse JSON input
    DECLARE @Inputs TABLE (
        RowID INT IDENTITY(1,1),
        TransactionID INT,  -- Optional identifier dari client
        TransactionDate NVARCHAR(50),  -- Transaction date from statement
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
            WHERE m.category = 'BIFAST'
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
                            m.match_percentage DESC,
                            m.total_transactions DESC,
                            m.last_line_number DESC
                    ) AS OptionNumber
                FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
                WHERE m.category = 'BIFAST'
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
GO

PRINT '✅ BIFAST deployed!';
PRINT '';
GO


-- ═══════════════════════════════════════════════════════════════════════════
-- 3. MANDIRI
-- ═══════════════════════════════════════════════════════════════════════════

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
        
        IF @CustomerName IS NOT NULL AND LEN(@CustomerName) >= 3
        BEGIN
            -- Count total options
            SELECT @TotalOptions = COUNT(DISTINCT btp)
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
            WHERE m.category = 'MANDIRI'
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
                            m.match_percentage DESC,
                            m.total_transactions DESC,
                            m.last_line_number DESC
                    ) AS OptionNumber
                FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
                WHERE m.category = 'MANDIRI'
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
GO

PRINT '✅ MANDIRI deployed!';
PRINT '';
GO


-- ═══════════════════════════════════════════════════════════════════════════
-- 4. MASTER
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR ALTER PROCEDURE [dbo].[SP_MASTER_FindBTP_Batch]
    @TransactionsJSON NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_Batch - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Variables
    -- ═══════════════════════════════════════════════════════════════════════
    
    DECLARE @TotalTransactions INT;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Temp Tables
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Input transactions
    DECLARE @Transactions TABLE (
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX),
        BankType NVARCHAR(50)
    );
    
    -- Results from all banks
    DECLARE @AllResults TABLE (
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
        BestFlag NVARCHAR(10),
        LatestFlag NVARCHAR(10),
        Label NVARCHAR(50),
        Status NVARCHAR(20),
        Message NVARCHAR(500),
        BankType NVARCHAR(50),
        ProcessedAt DATETIME
    );
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Step 1: Parse JSON and detect bank type for each transaction
    -- ═══════════════════════════════════════════════════════════════════════
    
    INSERT INTO @Transactions (TransactionID, TransactionDate, Description, BankType)
    SELECT 
        TransactionID,
        TransactionDate,
        Description,
        CASE
            -- Group 3: Special Logic (TRSF & BI-FAST)
            WHEN Description LIKE 'TRSF E-BANKING%' OR Description LIKE 'TRSF FROM%' THEN 'TRSF'
            WHEN Description LIKE 'BI-FAST%' THEN 'BIFAST'
            
            -- Group 1: Array[3] + Array[4]
            WHEN Description LIKE '%LLG-BNI %' THEN 'BNI'
            WHEN Description LIKE '%LLG-BTPN %' THEN 'BTPN'
            WHEN Description LIKE '%LLG-MANDIRI %' THEN 'MANDIRI'
            WHEN Description LIKE '%LLG-BRI %' THEN 'BRI'
            WHEN Description LIKE '%LLG-MEGA %' THEN 'MEGA'
            WHEN Description LIKE '%LLG-PERMATA %' THEN 'PERMATA'
            WHEN Description LIKE '%LLG-DANAMON %' THEN 'DANAMON'
            WHEN Description LIKE '%LLG-CITIBANK %' THEN 'CITIBANK'
            WHEN Description LIKE '%LLG-SINARMAS %' THEN 'SINARMAS'
            
            -- Group 2: Array[4] + Array[5] (with special words)
            WHEN Description LIKE '%LLG-CIMB NIAGA%' THEN 'CIMB'
            WHEN Description LIKE '%LLG-MAYBANK INDONE%' THEN 'MAYBANK'
            WHEN Description LIKE '%LLG-HSBC INDONESIA%' THEN 'HSBC'
            WHEN Description LIKE '%LLG-UOB INDONESIA%' THEN 'UOB'
            WHEN Description LIKE '%LLG-MUAMALAT INDON%' THEN 'MUAMALAT'
            WHEN Description LIKE '%LLG-OCBC NISP%' THEN 'OCBC'
            WHEN Description LIKE '%LLG-DBS INDONESIA%' THEN 'DBS'
            WHEN Description LIKE '%LLG-CAPITAL INDONE%' THEN 'CAPITAL'
            WHEN Description LIKE '%LLG-WOORI SAUDARA%' THEN 'WOORI'
            
            ELSE 'UNKNOWN'
        END as BankType
    FROM OPENJSON(@TransactionsJSON)
    WITH (
        TransactionID INT '$.TransactionID',
        TransactionDate NVARCHAR(50) '$.TransactionDate',
        Description NVARCHAR(MAX) '$.Description'
    );
    
    SELECT @TotalTransactions = COUNT(*) FROM @Transactions;
    
    PRINT 'Total transactions to process: ' + CAST(@TotalTransactions AS VARCHAR);
    PRINT '';
    
    -- Show bank type distribution
    PRINT 'Bank Type Distribution:';
    PRINT '─────────────────────────────────────────────────────────────────────';
    
    SELECT 
        BankType,
        COUNT(*) as TransactionCount
    FROM @Transactions
    GROUP BY BankType
    ORDER BY COUNT(*) DESC;
    
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Step 2: Process each bank type separately
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- TRSF
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'TRSF')
    BEGIN
        PRINT '🔄 Processing TRSF transactions...';
        
        DECLARE @TRSF_JSON NVARCHAR(MAX);
        SELECT @TRSF_JSON = (
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
            FROM @Transactions
            WHERE BankType = 'TRSF'
            FOR JSON PATH
        );
        
        CREATE TABLE #TRSF_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #TRSF_Results
        EXEC SP_TRSF_FindBTP_Batch @InputJSON = @TRSF_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'TRSF' AS BankType, ProcessedAt
        FROM #TRSF_Results;
        
        DROP TABLE #TRSF_Results;
        
        PRINT '✅ TRSF completed';
    END
    
    -- BIFAST
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BIFAST')
    BEGIN
        PRINT '🔄 Processing BIFAST transactions...';
        
        DECLARE @BIFAST_JSON NVARCHAR(MAX);
        SELECT @BIFAST_JSON = (
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
            FROM @Transactions
            WHERE BankType = 'BIFAST'
            FOR JSON PATH
        );
        
        CREATE TABLE #BIFAST_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BIFAST_Results
        EXEC SP_BIFAST_FindBTP_Batch @InputJSON = @BIFAST_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'BIFAST' AS BankType, ProcessedAt
        FROM #BIFAST_Results;
        
        DROP TABLE #BIFAST_Results;
        
        PRINT '✅ BIFAST completed';
    END
    
    -- MANDIRI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MANDIRI')
    BEGIN
        PRINT '🔄 Processing MANDIRI transactions...';
        
        DECLARE @MANDIRI_JSON NVARCHAR(MAX);
        SELECT @MANDIRI_JSON = (
            SELECT 
                TransactionID AS transaction_id,
                TransactionDate AS transaction_date,
                Description AS description
            FROM @Transactions
            WHERE BankType = 'MANDIRI'
            FOR JSON PATH
        );
        
        CREATE TABLE #MANDIRI_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MANDIRI_Results
        EXEC SP_MANDIRI_FindBTP_Batch @InputJSON = @MANDIRI_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'MANDIRI' AS BankType, ProcessedAt
        FROM #MANDIRI_Results;
        
        DROP TABLE #MANDIRI_Results;
        
        PRINT '✅ MANDIRI completed';
    END
    
    -- BNI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BNI')
    BEGIN
        PRINT '🔄 Processing BNI transactions...';
        
        DECLARE @BNI_JSON NVARCHAR(MAX);
        SELECT @BNI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'BNI'
            FOR JSON PATH
        );
        
        CREATE TABLE #BNI_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BNI_Results
        EXEC SP_BNI_FindBTP_Batch @TransactionsJSON = @BNI_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'BNI' AS BankType, ProcessedAt
        FROM #BNI_Results;
        
        DROP TABLE #BNI_Results;
        
        PRINT '✅ BNI completed';
    END
    
    -- BTPN
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BTPN')
    BEGIN
        PRINT '🔄 Processing BTPN transactions...';
        
        DECLARE @BTPN_JSON NVARCHAR(MAX);
        SELECT @BTPN_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'BTPN'
            FOR JSON PATH
        );
        
        CREATE TABLE #BTPN_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BTPN_Results
        EXEC SP_BTPN_FindBTP_Batch @TransactionsJSON = @BTPN_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'BTPN' AS BankType, ProcessedAt
        FROM #BTPN_Results;
        
        DROP TABLE #BTPN_Results;
        
        PRINT '✅ BTPN completed';
    END
    
    -- BRI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'BRI')
    BEGIN
        PRINT '🔄 Processing BRI transactions...';
        
        DECLARE @BRI_JSON NVARCHAR(MAX);
        SELECT @BRI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'BRI'
            FOR JSON PATH
        );
        
        CREATE TABLE #BRI_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #BRI_Results
        EXEC SP_BRI_FindBTP_Batch @TransactionsJSON = @BRI_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'BRI' AS BankType, ProcessedAt
        FROM #BRI_Results;
        
        DROP TABLE #BRI_Results;
        
        PRINT '✅ BRI completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GROUP 1 BANKS (Array[3] + Array[4])
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- MEGA
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MEGA')
    BEGIN
        PRINT '🔄 Processing MEGA transactions...';
        
        DECLARE @MEGA_JSON NVARCHAR(MAX);
        SELECT @MEGA_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'MEGA'
            FOR JSON PATH
        );
        
        CREATE TABLE #MEGA_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MEGA_Results
        EXEC SP_MEGA_FindBTP_Batch @TransactionsJSON = @MEGA_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'MEGA' AS BankType, ProcessedAt
        FROM #MEGA_Results;
        
        DROP TABLE #MEGA_Results;
        
        PRINT '✅ MEGA completed';
    END
    
    -- PERMATA
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'PERMATA')
    BEGIN
        PRINT '🔄 Processing PERMATA transactions...';
        
        DECLARE @PERMATA_JSON NVARCHAR(MAX);
        SELECT @PERMATA_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'PERMATA'
            FOR JSON PATH
        );
        
        CREATE TABLE #PERMATA_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #PERMATA_Results
        EXEC SP_PERMATA_FindBTP_Batch @TransactionsJSON = @PERMATA_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'PERMATA' AS BankType, ProcessedAt
        FROM #PERMATA_Results;
        
        DROP TABLE #PERMATA_Results;
        
        PRINT '✅ PERMATA completed';
    END
    
    -- DANAMON
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'DANAMON')
    BEGIN
        PRINT '🔄 Processing DANAMON transactions...';
        
        DECLARE @DANAMON_JSON NVARCHAR(MAX);
        SELECT @DANAMON_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'DANAMON'
            FOR JSON PATH
        );
        
        CREATE TABLE #DANAMON_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #DANAMON_Results
        EXEC SP_DANAMON_FindBTP_Batch @TransactionsJSON = @DANAMON_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'DANAMON' AS BankType, ProcessedAt
        FROM #DANAMON_Results;
        
        DROP TABLE #DANAMON_Results;
        
        PRINT '✅ DANAMON completed';
    END
    
    -- CITIBANK
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CITIBANK')
    BEGIN
        PRINT '🔄 Processing CITIBANK transactions...';
        
        DECLARE @CITIBANK_JSON NVARCHAR(MAX);
        SELECT @CITIBANK_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'CITIBANK'
            FOR JSON PATH
        );
        
        CREATE TABLE #CITIBANK_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CITIBANK_Results
        EXEC SP_CITIBANK_FindBTP_Batch @TransactionsJSON = @CITIBANK_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'CITIBANK' AS BankType, ProcessedAt
        FROM #CITIBANK_Results;
        
        DROP TABLE #CITIBANK_Results;
        
        PRINT '✅ CITIBANK completed';
    END
    
    -- SINARMAS
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'SINARMAS')
    BEGIN
        PRINT '🔄 Processing SINARMAS transactions...';
        
        DECLARE @SINARMAS_JSON NVARCHAR(MAX);
        SELECT @SINARMAS_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'SINARMAS'
            FOR JSON PATH
        );
        
        CREATE TABLE #SINARMAS_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #SINARMAS_Results
        EXEC SP_SINARMAS_FindBTP_Batch @TransactionsJSON = @SINARMAS_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'SINARMAS' AS BankType, ProcessedAt
        FROM #SINARMAS_Results;
        
        DROP TABLE #SINARMAS_Results;
        
        PRINT '✅ SINARMAS completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GROUP 2 BANKS (Array[4] + Array[5])
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- CIMB
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CIMB')
    BEGIN
        PRINT '🔄 Processing CIMB transactions...';
        
        DECLARE @CIMB_JSON NVARCHAR(MAX);
        SELECT @CIMB_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'CIMB'
            FOR JSON PATH
        );
        
        CREATE TABLE #CIMB_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CIMB_Results
        EXEC SP_CIMB_FindBTP_Batch @TransactionsJSON = @CIMB_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'CIMB' AS BankType, ProcessedAt
        FROM #CIMB_Results;
        
        DROP TABLE #CIMB_Results;
        
        PRINT '✅ CIMB completed';
    END
    
    -- MAYBANK
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MAYBANK')
    BEGIN
        PRINT '🔄 Processing MAYBANK transactions...';
        
        DECLARE @MAYBANK_JSON NVARCHAR(MAX);
        SELECT @MAYBANK_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'MAYBANK'
            FOR JSON PATH
        );
        
        CREATE TABLE #MAYBANK_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MAYBANK_Results
        EXEC SP_MAYBANK_FindBTP_Batch @TransactionsJSON = @MAYBANK_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'MAYBANK' AS BankType, ProcessedAt
        FROM #MAYBANK_Results;
        
        DROP TABLE #MAYBANK_Results;
        
        PRINT '✅ MAYBANK completed';
    END
    
    -- HSBC
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'HSBC')
    BEGIN
        PRINT '🔄 Processing HSBC transactions...';
        
        DECLARE @HSBC_JSON NVARCHAR(MAX);
        SELECT @HSBC_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'HSBC'
            FOR JSON PATH
        );
        
        CREATE TABLE #HSBC_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #HSBC_Results
        EXEC SP_HSBC_FindBTP_Batch @TransactionsJSON = @HSBC_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'HSBC' AS BankType, ProcessedAt
        FROM #HSBC_Results;
        
        DROP TABLE #HSBC_Results;
        
        PRINT '✅ HSBC completed';
    END
    
    -- UOB
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'UOB')
    BEGIN
        PRINT '🔄 Processing UOB transactions...';
        
        DECLARE @UOB_JSON NVARCHAR(MAX);
        SELECT @UOB_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'UOB'
            FOR JSON PATH
        );
        
        CREATE TABLE #UOB_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #UOB_Results
        EXEC SP_UOB_FindBTP_Batch @TransactionsJSON = @UOB_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'UOB' AS BankType, ProcessedAt
        FROM #UOB_Results;
        
        DROP TABLE #UOB_Results;
        
        PRINT '✅ UOB completed';
    END
    
    -- MUAMALAT
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'MUAMALAT')
    BEGIN
        PRINT '🔄 Processing MUAMALAT transactions...';
        
        DECLARE @MUAMALAT_JSON NVARCHAR(MAX);
        SELECT @MUAMALAT_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'MUAMALAT'
            FOR JSON PATH
        );
        
        CREATE TABLE #MUAMALAT_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #MUAMALAT_Results
        EXEC SP_MUAMALAT_FindBTP_Batch @TransactionsJSON = @MUAMALAT_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'MUAMALAT' AS BankType, ProcessedAt
        FROM #MUAMALAT_Results;
        
        DROP TABLE #MUAMALAT_Results;
        
        PRINT '✅ MUAMALAT completed';
    END
    
    -- OCBC
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'OCBC')
    BEGIN
        PRINT '🔄 Processing OCBC transactions...';
        
        DECLARE @OCBC_JSON NVARCHAR(MAX);
        SELECT @OCBC_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'OCBC'
            FOR JSON PATH
        );
        
        CREATE TABLE #OCBC_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #OCBC_Results
        EXEC SP_OCBC_FindBTP_Batch @TransactionsJSON = @OCBC_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'OCBC' AS BankType, ProcessedAt
        FROM #OCBC_Results;
        
        DROP TABLE #OCBC_Results;
        
        PRINT '✅ OCBC completed';
    END
    
    -- DBS
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'DBS')
    BEGIN
        PRINT '🔄 Processing DBS transactions...';
        
        DECLARE @DBS_JSON NVARCHAR(MAX);
        SELECT @DBS_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'DBS'
            FOR JSON PATH
        );
        
        CREATE TABLE #DBS_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #DBS_Results
        EXEC SP_DBS_FindBTP_Batch @TransactionsJSON = @DBS_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'DBS' AS BankType, ProcessedAt
        FROM #DBS_Results;
        
        DROP TABLE #DBS_Results;
        
        PRINT '✅ DBS completed';
    END
    
    -- CAPITAL
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'CAPITAL')
    BEGIN
        PRINT '🔄 Processing CAPITAL transactions...';
        
        DECLARE @CAPITAL_JSON NVARCHAR(MAX);
        SELECT @CAPITAL_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'CAPITAL'
            FOR JSON PATH
        );
        
        CREATE TABLE #CAPITAL_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #CAPITAL_Results
        EXEC SP_CAPITAL_FindBTP_Batch @TransactionsJSON = @CAPITAL_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'CAPITAL' AS BankType, ProcessedAt
        FROM #CAPITAL_Results;
        
        DROP TABLE #CAPITAL_Results;
        
        PRINT '✅ CAPITAL completed';
    END
    
    -- WOORI
    IF EXISTS (SELECT 1 FROM @Transactions WHERE BankType = 'WOORI')
    BEGIN
        PRINT '🔄 Processing WOORI transactions...';
        
        DECLARE @WOORI_JSON NVARCHAR(MAX);
        SELECT @WOORI_JSON = (
            SELECT TransactionID, TransactionDate, Description
            FROM @Transactions
            WHERE BankType = 'WOORI'
            FOR JSON PATH
        );
        
        CREATE TABLE #WOORI_Results (
            TransactionID INT, TransactionDate NVARCHAR(50), Description NVARCHAR(MAX), CustomerName NVARCHAR(200),
            BTP NVARCHAR(50), MatchPercentage DECIMAL(5,2), MatchCount INT,
            TotalTransactions INT, LastLineNumber INT, TotalBTPOptions INT,
            OptionNumber INT, BestFlag NVARCHAR(10), LatestFlag NVARCHAR(10),
            Label NVARCHAR(50), Status NVARCHAR(20), Message NVARCHAR(500),
            ProcessedAt DATETIME
        );
        
        INSERT INTO #WOORI_Results
        EXEC SP_WOORI_FindBTP_Batch @TransactionsJSON = @WOORI_JSON;
        
        INSERT INTO @AllResults
        SELECT TransactionID, TransactionDate, Description, CustomerName, BTP, MatchPercentage, MatchCount,
               TotalTransactions, LastLineNumber, TotalBTPOptions, OptionNumber,
               BestFlag, LatestFlag, Label, Status, Message, 'WOORI' AS BankType, ProcessedAt
        FROM #WOORI_Results;
        
        DROP TABLE #WOORI_Results;
        
        PRINT '✅ WOORI completed';
    END
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Step 3: Return unified results
    -- ═══════════════════════════════════════════════════════════════════════
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'Returning unified results...';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    
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
        BestFlag,
        LatestFlag,
        Label,
        Status,
        Message,
        BankType,  -- ⭐ Important: Shows which bank's SP processed this
        ProcessedAt
    FROM @AllResults
    ORDER BY TransactionID, OptionNumber;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Statistics
    -- ═══════════════════════════════════════════════════════════════════════
    
    DECLARE @TotalProcessed INT, @TotalMatched INT, @TotalUnknown INT;
    
    SELECT @TotalProcessed = COUNT(DISTINCT TransactionID) FROM @AllResults;
    SELECT @TotalMatched = COUNT(DISTINCT TransactionID) FROM @AllResults WHERE Status NOT IN ('NO_MATCH', 'NO_PATTERN');
    SELECT @TotalUnknown = COUNT(*) FROM @Transactions WHERE BankType = 'UNKNOWN';
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_Batch - COMPLETED';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'Total Input Transactions: ' + CAST(@TotalTransactions AS VARCHAR);
    PRINT 'Successfully Processed: ' + CAST(@TotalProcessed AS VARCHAR);
    PRINT 'Successful BTP Matches: ' + CAST(@TotalMatched AS VARCHAR);
    PRINT 'Unknown Bank Types: ' + CAST(@TotalUnknown AS VARCHAR);
    IF @TotalProcessed > 0
        PRINT 'Overall Match Rate: ' + CAST(CAST(@TotalMatched * 100.0 / NULLIF(@TotalProcessed, 0) AS DECIMAL(5,2)) AS VARCHAR) + '%';
    PRINT '';
    PRINT 'Banks Processed:';
    
    SELECT 
        BankType,
        COUNT(DISTINCT TransactionID) as Transactions,
        SUM(CASE WHEN Status NOT IN ('NO_MATCH', 'NO_PATTERN') THEN 1 ELSE 0 END) as Matched
    FROM @AllResults
    GROUP BY BankType
    ORDER BY BankType;
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
END;
GO
GO

PRINT '✅ MASTER deployed!';
PRINT '';
GO


-- ═══════════════════════════════════════════════════════════════════════════
-- 5. MASTER ToStaging
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR ALTER PROCEDURE [dbo].[SP_MASTER_FindBTP_Batch_ToStaging]
    @TransactionsJSON NVARCHAR(MAX),
    @BatchID NVARCHAR(50) = NULL,
    @UploadedBy NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate BatchID jika tidak disediakan
    IF @BatchID IS NULL
    BEGIN
        SET @BatchID = 'BATCH_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + 
                       REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
    END
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MASTER_FindBTP_Batch_ToStaging - Starting';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'BatchID: ' + @BatchID;
    IF @UploadedBy IS NOT NULL
        PRINT 'Uploaded By: ' + @UploadedBy;
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Execute MASTER SP dan capture results
    -- ═══════════════════════════════════════════════════════════════════════
    
    CREATE TABLE #Results (
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
        BestFlag NVARCHAR(10),
        LatestFlag NVARCHAR(10),
        Label NVARCHAR(50),
        Status NVARCHAR(20),
        Message NVARCHAR(500),
        BankType NVARCHAR(50),
        ProcessedAt DATETIME
    );
    
    PRINT '🔄 Executing SP_MASTER_FindBTP_Batch...';
    
    INSERT INTO #Results
    EXEC SP_MASTER_FindBTP_Batch @TransactionsJSON = @TransactionsJSON;
    
    DECLARE @ResultCount INT = @@ROWCOUNT;
    PRINT '✅ Processed ' + CAST(@ResultCount AS VARCHAR) + ' rows';
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Save results ke staging table
    -- ═══════════════════════════════════════════════════════════════════════
    
    PRINT '🔄 Saving to REKENING_KORAN_STAGING...';
    
    INSERT INTO dbo.REKENING_KORAN_STAGING (
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
        BatchID,
        UploadedBy,
        UploadedAt
    )
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
        BestFlag,
        LatestFlag,
        Label,
        Status,
        Message,
        BankType,
        ProcessedAt,
        @BatchID,
        @UploadedBy,
        GETDATE()
    FROM #Results;
    
    DECLARE @SavedCount INT = @@ROWCOUNT;
    PRINT '✅ Saved ' + CAST(@SavedCount AS VARCHAR) + ' rows';
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Return results untuk display
    -- ═══════════════════════════════════════════════════════════════════════
    
    SELECT * FROM #Results
    ORDER BY TransactionID, OptionNumber;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Return summary
    -- ═══════════════════════════════════════════════════════════════════════
    
    SELECT 
        @BatchID AS BatchID,
        @UploadedBy AS UploadedBy,
        @SavedCount AS TotalRowsSaved,
        GETDATE() AS SavedAt,
        'SUCCESS' AS Status;
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'COMPLETED!';
    PRINT 'BatchID: ' + @BatchID;
    PRINT 'Rows Saved: ' + CAST(@SavedCount AS VARCHAR);
    PRINT '═══════════════════════════════════════════════════════════════════════';
    
    DROP TABLE #Results;
END;
GO
GO

PRINT '✅ MASTER ToStaging deployed!';
PRINT '';
GO


-- ═══════════════════════════════════════════════════════════════════════════
-- DEPLOYMENT COMPLETE!
-- ═══════════════════════════════════════════════════════════════════════════

PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ ALL 5 STORED PROCEDURES DEPLOYED SUCCESSFULLY!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Procedures deployed:';
PRINT '  ✅ SP_TRSF_FindBTP_Batch';
PRINT '  ✅ SP_BIFAST_FindBTP_Batch';
PRINT '  ✅ SP_MANDIRI_FindBTP_Batch';
PRINT '  ✅ SP_MASTER_FindBTP_Batch (ALL 20 BANKS!)';
PRINT '  ✅ SP_MASTER_FindBTP_Batch_ToStaging';
PRINT '';
PRINT 'Ready to test!';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
