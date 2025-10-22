-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE: BTP_REVIEW Table
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Description:
--   Table untuk nyimpen hasil matching BTP sebelum final approval
--   Finance akan review dan approve satu-satu di sini
--
-- ═══════════════════════════════════════════════════════════════════════════

USE POWERAPPS;
GO

-- Drop if exists
IF OBJECT_ID('dbo.BTP_REVIEW', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.BTP_REVIEW;
    PRINT '✅ Dropped existing BTP_REVIEW table';
END
GO

-- Create table
CREATE TABLE [dbo].[BTP_REVIEW] (
    -- Primary key
    ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Batch info
    BatchID NVARCHAR(100) NOT NULL,
    UploadedBy NVARCHAR(255) NULL,
    UploadedAt DATETIME DEFAULT GETDATE(),
    
    -- Transaction info (from JSON input)
    TransactionID INT NOT NULL,
    TransactionDate NVARCHAR(50) NULL,
    Description NVARCHAR(MAX) NULL,
    
    -- Matching results (from SP_MASTER_FindBTP_Batch)
    CustomerName NVARCHAR(200) NULL,
    BTP NVARCHAR(50) NULL,
    MatchPercentage DECIMAL(5,2) NULL,
    MatchCount INT NULL,
    TotalTransactions INT NULL,
    LastLineNumber INT NULL,
    TotalBTPOptions INT NULL,
    OptionNumber INT NULL,
    BestFlag NVARCHAR(10) NULL,
    LatestFlag NVARCHAR(10) NULL,
    Label NVARCHAR(50) NULL,
    Status NVARCHAR(20) NULL,
    Message NVARCHAR(500) NULL,
    BankType NVARCHAR(50) NULL,
    ProcessedAt DATETIME NULL,
    
    -- Approval info
    IsApproved BIT DEFAULT 0,
    ApprovedBy NVARCHAR(255) NULL,
    ApprovedAt DATETIME NULL,
    Notes NVARCHAR(MAX) NULL,
    
    -- Timestamps
    CreatedAt DATETIME DEFAULT GETDATE(),
    ModifiedAt DATETIME DEFAULT GETDATE()
);
GO

-- Create indexes for performance
CREATE INDEX IX_BTP_REVIEW_BatchID ON dbo.BTP_REVIEW(BatchID);
CREATE INDEX IX_BTP_REVIEW_IsApproved ON dbo.BTP_REVIEW(IsApproved);
CREATE INDEX IX_BTP_REVIEW_UploadedAt ON dbo.BTP_REVIEW(UploadedAt);
GO

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '✅ BTP_REVIEW table created successfully!';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Table structure:';
PRINT '  - ID (PK, auto-increment)';
PRINT '  - BatchID, UploadedBy, UploadedAt';
PRINT '  - TransactionID, TransactionDate, Description';
PRINT '  - CustomerName, BTP, MatchPercentage, ...';
PRINT '  - IsApproved, ApprovedBy, ApprovedAt, Notes';
PRINT '  - CreatedAt, ModifiedAt';
PRINT '';
PRINT 'Indexes created:';
PRINT '  ✅ IX_BTP_REVIEW_BatchID';
PRINT '  ✅ IX_BTP_REVIEW_IsApproved';
PRINT '  ✅ IX_BTP_REVIEW_UploadedAt';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

