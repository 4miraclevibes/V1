-- Truncate table Distributors
-- This will remove all data from the Distributors table

IF EXISTS (SELECT * FROM sysobjects WHERE name='Distributors' AND xtype='U')
BEGIN
    TRUNCATE TABLE [Distributors];
    PRINT 'Table Distributors has been truncated successfully.';
END
ELSE
BEGIN
    PRINT 'Table Distributors does not exist.';
END

