-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE STAGING TABLE FOR BTP MATCHING RESULTS
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Database: POWERAPPS
-- Table: REKENING_KORAN_STAGING
--
-- Purpose:
--   Staging table untuk store hasil dari SP_MASTER_FindBTP_Batch
--   User bisa review di Power Apps sebelum submit ke table final
--   Table ini permanent (bukan #temp), tapi fungsinya untuk staging/temporary
--
-- Usage:
--   1. Execute SP_MASTER_FindBTP_Batch_ToStaging untuk save hasil
--   2. Review data di Power Apps
--   3. Submit data yang diinginkan ke final table
--   4. Hapus/archive data dari staging table
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

-- Drop table jika sudah ada (untuk development/testing)
IF OBJECT_ID('dbo.REKENING_KORAN_STAGING', 'U') IS NOT NULL
    DROP TABLE dbo.REKENING_KORAN_STAGING;
GO

-- Create staging table
CREATE TABLE dbo.REKENING_KORAN_STAGING (
    -- Identity column untuk primary key
    ID INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Transaction info dari bank statement
    TransactionID INT NOT NULL,
    TransactionDate NVARCHAR(50),
    Description NVARCHAR(MAX),
    
    -- BTP Matching results
    CustomerName NVARCHAR(200),
    BTP NVARCHAR(50),
    MatchPercentage DECIMAL(5,2),
    MatchCount INT,
    TotalTransactions INT,
    LastLineNumber INT,
    
    -- Multiple BTP options support
    TotalBTPOptions INT,
    OptionNumber INT,
    BestFlag NVARCHAR(10),
    LatestFlag NVARCHAR(10),
    Label NVARCHAR(50),
    
    -- Status & Message
    Status NVARCHAR(20),
    Message NVARCHAR(500),
    BankType NVARCHAR(50),
    
    -- Audit columns
    ProcessedAt DATETIME,
    CreatedAt DATETIME DEFAULT GETDATE(),
    
    -- Batch tracking (untuk group transactions dari same upload)
    BatchID NVARCHAR(50),
    UploadedBy NVARCHAR(100),
    UploadedAt DATETIME DEFAULT GETDATE()
);
GO

-- Create indexes untuk performance
CREATE INDEX IX_REKENING_KORAN_STAGING_BatchID ON dbo.REKENING_KORAN_STAGING(BatchID);
CREATE INDEX IX_REKENING_KORAN_STAGING_TransactionDate ON dbo.REKENING_KORAN_STAGING(TransactionDate);
CREATE INDEX IX_REKENING_KORAN_STAGING_BankType ON dbo.REKENING_KORAN_STAGING(BankType);
CREATE INDEX IX_REKENING_KORAN_STAGING_UploadedAt ON dbo.REKENING_KORAN_STAGING(UploadedAt);
GO

PRINT '✅ Table REKENING_KORAN_STAGING created successfully!';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Table: dbo.REKENING_KORAN_STAGING';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Purpose: Store hasil dari SP_MASTER_FindBTP_Batch untuk review';
PRINT '';
PRINT 'Columns:';
PRINT '  • Transaction Info: TransactionID, TransactionDate, Description';
PRINT '  • BTP Results: CustomerName, BTP, MatchPercentage, Status, etc.';
PRINT '  • Batch Info: BatchID, UploadedBy, UploadedAt';
PRINT '';
PRINT 'Next Step: Create SP_MASTER_FindBTP_Batch_ToStaging';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

