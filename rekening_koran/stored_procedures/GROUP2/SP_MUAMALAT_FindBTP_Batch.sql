-- ═══════════════════════════════════════════════════════════════════════════
-- SP_MUAMALAT_FindBTP_Batch
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   Find BTP (Bill To Party) for MUAMALAT bank transactions (batch processing)
--   
-- Extraction Logic:
--   Group 2: Array[4] + Array[5] (Smart PT/CV)
--   Format: "KR OTOMATIS LLG-MUAMALAT INDON [WORD1] [WORD2] [WORD3]..."
--   
--   Special Word: "INDON" at Array[3] (automatically skipped)
--   
--   Extraction:
--     • Array[4] + Array[5] (default: 2 words)
--     • If Array[4] = "PT" or "CV" → Array[4] + Array[5] + Array[6] (3 words)
--
-- Pattern Count: 1 patterns in master data
--
-- Parameters:
--   @TransactionsJSON - JSON array of transactions
--     Format: [{"TransactionID": 1, "Description": "..."}, ...]
--
-- Returns:
--   Result set with BTP matching information including:
--   - Multiple rows per transaction if multiple BTP options found
--   - BestFlag, LatestFlag, Label columns for easy identification
--   - Detailed statistics and confidence scores
--
-- Author: Auto-generated
-- Date: October 21, 2025
-- Version: 1.0.0
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR ALTER PROCEDURE [dbo].[SP_MUAMALAT_FindBTP_Batch]
    @TransactionsJSON NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Variables
    -- ═══════════════════════════════════════════════════════════════════════
    
    DECLARE @CurrentDescription NVARCHAR(MAX);
    DECLARE @CurrentTransactionID INT;
    DECLARE @CurrentTransactionDate NVARCHAR(50);
    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @WordCount INT;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Temp Tables
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Input transactions
    DECLARE @Transactions TABLE (
        TransactionID INT,
        TransactionDate NVARCHAR(50),
        Description NVARCHAR(MAX)
    );
    
    -- Parsed words
    DECLARE @Words TABLE (
        WordIndex INT,
        Word NVARCHAR(100)
    );
    
    -- Results table (with support for multiple BTP options)
    DECLARE @Results TABLE (
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
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Parse JSON Input
    -- ═══════════════════════════════════════════════════════════════════════
    
    INSERT INTO @Transactions (TransactionID, TransactionDate, Description)
    SELECT 
        TransactionID,
        TransactionDate,
        Description
    FROM OPENJSON(@TransactionsJSON)
    WITH (
        TransactionID INT '$.TransactionID',
        TransactionDate NVARCHAR(50) '$.TransactionDate',
        Description NVARCHAR(MAX) '$.Description'
    );
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Process Each Transaction
    -- ═══════════════════════════════════════════════════════════════════════
    
    DECLARE trans_cursor CURSOR FOR 
        SELECT TransactionID,
        TransactionDate,
        Description 
        FROM @Transactions;
    
    OPEN trans_cursor;
    
    FETCH NEXT FROM trans_cursor INTO @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Reset for each transaction
        SET @CustomerName = NULL;
        DELETE FROM @Words;
        
        -- ═══════════════════════════════════════════════════════════════════
        -- Step 1: Parse description into words
        -- ═══════════════════════════════════════════════════════════════════
        
        ;WITH Numbers AS (
            SELECT TOP (LEN(@CurrentDescription)) 
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as n
            FROM master.dbo.spt_values
        ),
        SplitData AS (
            SELECT 
                n as Position,
                SUBSTRING(@CurrentDescription, n, 1) as Char,
                CASE WHEN SUBSTRING(@CurrentDescription, n, 1) = ' ' THEN 1 ELSE 0 END as IsSpace
            FROM Numbers
        ),
        WordBoundaries AS (
            SELECT 
                Position,
                CASE 
                    WHEN Position = 1 THEN 1
                    WHEN IsSpace = 0 AND LAG(IsSpace) OVER (ORDER BY Position) = 1 THEN 1
                    ELSE 0
                END as IsWordStart
            FROM SplitData
        )
        INSERT INTO @Words (WordIndex, Word)
        SELECT 
            ROW_NUMBER() OVER (ORDER BY Position) as WordIndex,
            LTRIM(RTRIM(SUBSTRING(
                @CurrentDescription,
                Position,
                ISNULL(LEAD(Position) OVER (ORDER BY Position), LEN(@CurrentDescription) + 1) - Position
            ))) as Word
        FROM WordBoundaries
        WHERE IsWordStart = 1;
        
        SELECT @WordCount = COUNT(*) FROM @Words;
        
        -- ═══════════════════════════════════════════════════════════════════
        -- Step 2: Extract customer name using Group 2 logic
        -- Format: "KR OTOMATIS LLG-MUAMALAT INDON [Word1] [Word2] [Word3]..."
        -- Array[4] + Array[5] (with PT/CV smart extraction)
        -- Special word "INDON" at Array[3] is skipped
        -- ═══════════════════════════════════════════════════════════════════
        
        IF @WordCount >= 6
        BEGIN
            DECLARE @Word4 NVARCHAR(100);
            DECLARE @Word5 NVARCHAR(100);
            DECLARE @Word6 NVARCHAR(100);
            
            -- Array[4] in C = WordIndex 5 in SQL (SQL is 1-based, C is 0-based)
            SELECT @Word4 = Word FROM @Words WHERE WordIndex = 5;
            SELECT @Word5 = Word FROM @Words WHERE WordIndex = 6;
            
            -- Smart PT/CV extraction
            IF @Word4 IN ('PT', 'CV') AND @WordCount >= 7
            BEGIN
                SELECT @Word6 = Word FROM @Words WHERE WordIndex = 7;
                SET @CustomerName = @Word4 + ' ' + @Word5 + ' ' + @Word6;
            END
            ELSE
            BEGIN
                SET @CustomerName = @Word4 + ' ' + @Word5;
            END
        END
        
        -- ═══════════════════════════════════════════════════════════════════
        -- Step 3: Find BTP in master data
        -- ═══════════════════════════════════════════════════════════════════
        
        IF @CustomerName IS NOT NULL
        BEGIN
            -- Find all matching BTPs
            DECLARE @MatchingBTPs TABLE (
                customer_name NVARCHAR(200),
                btp NVARCHAR(50),
                match_percentage DECIMAL(5,2),
                match_count INT,
                total_transactions INT,
                last_line_number INT,
                RowNum INT
            );
            
            INSERT INTO @MatchingBTPs
            SELECT 
                customer_name,
                btp,
                match_percentage,
                match_count,
                total_transactions,
                last_line_number,
                ROW_NUMBER() OVER (
                    ORDER BY 
                        CASE WHEN category = 'MUAMALAT' THEN 1 ELSE 2 END,
                        match_percentage DESC,
                        last_line_number DESC,
                        match_count DESC
                ) as RowNum
            FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN]
            WHERE customer_name = @CustomerName
              AND (category = 'MUAMALAT' OR category = 'NEW')
            ORDER BY 
                CASE WHEN category = 'MUAMALAT' THEN 1 ELSE 2 END,
                match_percentage DESC,
                last_line_number DESC,
                match_count DESC;
            
            DECLARE @TotalBTPOptions INT;
            SELECT @TotalBTPOptions = COUNT(*) FROM @MatchingBTPs;
            
            IF @TotalBTPOptions > 0
            BEGIN
                -- Insert all BTP options as separate rows
                INSERT INTO @Results (
                    TransactionID, TransactionDate, Description, CustomerName, BTP,
                    MatchPercentage, MatchCount, TotalTransactions, LastLineNumber,
                    TotalBTPOptions, OptionNumber, IsBest, IsLatest, Status
                )
                SELECT 
                    @CurrentTransactionID,
                    @CurrentTransactionDate,
                @CurrentDescription,
                    customer_name,
                    btp,
                    match_percentage,
                    match_count,
                    total_transactions,
                    last_line_number,
                    @TotalBTPOptions,
                    RowNum,
                    CASE WHEN RowNum = 1 THEN 1 ELSE 0 END, -- IsBest
                    CASE WHEN RowNum = (
                        SELECT TOP 1 RowNum 
                        FROM @MatchingBTPs 
                        ORDER BY last_line_number DESC
                    ) THEN 1 ELSE 0 END, -- IsLatest
                    CASE 
                        WHEN match_percentage >= 95 THEN 'EXCELLENT'
                        WHEN match_percentage >= 80 THEN 'GOOD'
                        WHEN match_percentage >= 60 THEN 'FAIR'
                        ELSE 'LOW'
                    END
                FROM @MatchingBTPs
                ORDER BY RowNum;
            END
            ELSE
            BEGIN
                -- No match found in master data
                INSERT INTO @Results (
                    TransactionID, TransactionDate, Description, CustomerName, BTP,
                    MatchPercentage, MatchCount, TotalTransactions, LastLineNumber,
                    TotalBTPOptions, OptionNumber, IsBest, IsLatest, Status
                )
                VALUES (
                    @CurrentTransactionID,
                    @CurrentTransactionDate,
                @CurrentDescription,
                    @CustomerName,
                    NULL,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    'NO_MATCH'
                );
            END
        END
        ELSE
        BEGIN
            -- Could not extract customer name
            INSERT INTO @Results (
                TransactionID, TransactionDate, Description, CustomerName, BTP,
                MatchPercentage, MatchCount, TotalTransactions, LastLineNumber,
                TotalBTPOptions, OptionNumber, IsBest, IsLatest, Status
            )
            VALUES (
                @CurrentTransactionID,
                @CurrentTransactionDate,
                @CurrentDescription,
                NULL,
                NULL,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                'NO_PATTERN'
            );
        END
        
        FETCH NEXT FROM trans_cursor INTO @CurrentTransactionID, @CurrentTransactionDate, @CurrentDescription;
    END
    
    CLOSE trans_cursor;
    DEALLOCATE trans_cursor;
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Return Results
    -- ═══════════════════════════════════════════════════════════════════════
    
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
    
    -- Debug statistics
    DECLARE @TotalProcessed INT, @TotalMatched INT, @TotalNoMatch INT, @TotalNoPattern INT;
    
    SELECT @TotalProcessed = COUNT(DISTINCT TransactionID) FROM @Results;
    SELECT @TotalMatched = COUNT(DISTINCT TransactionID) FROM @Results WHERE Status NOT IN ('NO_MATCH', 'NO_PATTERN');
    SELECT @TotalNoMatch = COUNT(DISTINCT TransactionID) FROM @Results WHERE Status = 'NO_MATCH';
    SELECT @TotalNoPattern = COUNT(DISTINCT TransactionID) FROM @Results WHERE Status = 'NO_PATTERN';
    
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'SP_MUAMALAT_FindBTP_Batch - Processing Complete';
    PRINT '═══════════════════════════════════════════════════════════════════════';
    PRINT 'Total Transactions Processed: ' + CAST(@TotalProcessed AS VARCHAR);
    PRINT 'Successful Matches: ' + CAST(@TotalMatched AS VARCHAR);
    PRINT 'No Match Found: ' + CAST(@TotalNoMatch AS VARCHAR);
    PRINT 'No Pattern Extracted: ' + CAST(@TotalNoPattern AS VARCHAR);
    PRINT 'Match Rate: ' + CAST(CAST(@TotalMatched * 100.0 / NULLIF(@TotalProcessed, 0) AS DECIMAL(5,2)) AS VARCHAR) + '%';
    PRINT '═══════════════════════════════════════════════════════════════════════';
END;
GO

PRINT '✅ SP_MUAMALAT_FindBTP_Batch created successfully';
PRINT '   Bank: MUAMALAT';
PRINT '   Group: 2 (Array[4] + Array[5])';
PRINT '   Special Word: INDON';
PRINT '   Patterns in master: 1';
GO
