-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE DATABASE FOR TESTING
-- ═══════════════════════════════════════════════════════════════════════════
-- Purpose: Create database untuk testing dan menyimpan hasil dari MASTER SP
-- Usage: Execute di SQL Server Management Studio (SSMS)
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if database exists, if yes drop it (CAREFUL!)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'rekening_koran_testing')
BEGIN
    PRINT '⚠️  Database rekening_koran_testing already exists. Dropping...';
    
    -- Set to single user mode to close all connections
    ALTER DATABASE rekening_koran_testing SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    DROP DATABASE rekening_koran_testing;
    
    PRINT '✅ Old database dropped successfully!';
END

-- Create new database
CREATE DATABASE rekening_koran_testing;
GO

PRINT '✅ Database rekening_koran_testing created successfully!';
GO

-- Switch to the new database
USE rekening_koran_testing;
GO

PRINT '✅ Switched to rekening_koran_testing database';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT 'Database rekening_koran_testing is ready!';
PRINT 'Next step: Create tables using 02_CREATE_TABLES.sql';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

