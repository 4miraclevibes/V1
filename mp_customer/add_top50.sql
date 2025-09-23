ALTER TABLE [dbo].[MP_CUSTOMER003]
ADD [top50] [bit] NULL;

-- Update semua data top50 menjadi false
UPDATE [dbo].[MP_CUSTOMER003]
SET [top50] = 0;