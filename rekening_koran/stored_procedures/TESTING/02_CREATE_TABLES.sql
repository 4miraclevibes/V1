-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE TABLES FOR TESTING
-- ═══════════════════════════════════════════════════════════════════════════
-- Purpose: Create table untuk menyimpan hasil dari MASTER SP
-- Database: POWERAPPS (existing database)
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- Table: BTP_MATCHING_RESULTS
-- Stores results from SP_MASTER_FindBTP_Batch
-- ═══════════════════════════════════════════════════════════════════════════

IF OBJECT_ID('dbo.BTP_MATCHING_RESULTS', 'U') IS NOT NULL
    DROP TABLE dbo.BTP_MATCHING_RESULTS;
GO

CREATE TABLE dbo.BTP_MATCHING_RESULTS (
    -- Primary Key
    ResultID INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Transaction Information
    TransactionID INT NOT NULL,
    TransactionDate NVARCHAR(50) NULL,
    Description NVARCHAR(MAX) NULL,
    
    -- Matching Results
    CustomerName NVARCHAR(200) NULL,
    BTP NVARCHAR(50) NULL,
    MatchPercentage DECIMAL(5,2) NULL,
    MatchCount INT NULL,
    TotalTransactions INT NULL,
    LastLineNumber INT NULL,
    
    -- Multiple BTP Options Support
    TotalBTPOptions INT NULL,
    OptionNumber INT NULL,
    BestFlag NVARCHAR(10) NULL,
    LatestFlag NVARCHAR(10) NULL,
    Label NVARCHAR(50) NULL,
    
    -- Status Information
    Status NVARCHAR(20) NULL,
    Message NVARCHAR(500) NULL,
    BankType NVARCHAR(50) NULL,
    
    -- Timestamps
    ProcessedAt DATETIME NULL,
    InsertedAt DATETIME DEFAULT GETDATE(),
    
    -- Indexing for better query performance
    INDEX IX_TransactionID (TransactionID),
    INDEX IX_BankType (BankType),
    INDEX IX_Status (Status),
    INDEX IX_TransactionDate (TransactionDate),
    INDEX IX_BTP (BTP),
    INDEX IX_InsertedAt (InsertedAt)
);
GO

PRINT '✅ Table BTP_MATCHING_RESULTS created successfully!';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Table Structure:';
PRINT '  • ResultID (PK) - Auto increment';
PRINT '  • TransactionID - ID dari transaction';
PRINT '  • TransactionDate - Tanggal transaksi';
PRINT '  • Description - Deskripsi transaksi';
PRINT '  • CustomerName - Nama customer yang ditemukan';
PRINT '  • BTP - BTP yang match';
PRINT '  • MatchPercentage - Persentase match';
PRINT '  • Status - Status matching (EXCELLENT, GOOD, NO_MATCH, etc)';
PRINT '  • BankType - Bank yang memproses (TRSF, BIFAST, MANDIRI, etc)';
PRINT '  • InsertedAt - Timestamp kapan data disimpan';
PRINT '';
PRINT 'Next step: Create stored procedure using 03_CREATE_SP_SAVE_RESULTS.sql';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

