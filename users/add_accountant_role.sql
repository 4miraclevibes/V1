USE [POWERAPPS]
GO

-- Drop constraint lama jika ada
IF EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_MP_USER_NEW_Role')
BEGIN
    ALTER TABLE [dbo].[MP_USER_NEW] DROP CONSTRAINT [CK_MP_USER_NEW_Role]
END
GO

-- Update data yang tidak sesuai (jika ada role selain yang diizinkan)
UPDATE [dbo].[MP_USER_NEW] 
SET [role] = 'FSS' 
WHERE [role] NOT IN ('FINANCE', 'ADMIN', 'IT', 'BA', 'FSS', 'ACCOUNTANT')
GO

-- Add constraint baru dengan role ACCOUNTANT
ALTER TABLE [dbo].[MP_USER_NEW]  WITH CHECK ADD  CONSTRAINT [CK_MP_USER_NEW_Role] CHECK  (([role]='FINANCE' OR [role]='ADMIN' OR [role]='IT' OR [role]='BA' OR [role]='FSS' OR [role]='ACCOUNTANT'))
GO

ALTER TABLE [dbo].[MP_USER_NEW] CHECK CONSTRAINT [CK_MP_USER_NEW_Role]
GO
