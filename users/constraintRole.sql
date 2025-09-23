USE [POWERAPPS]
GO

/****** Object:  Table [dbo].[MP_USER_NEW]    Script Date: 22/09/2025 13:51:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MP_USER_NEW](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[username] [nvarchar](100) NOT NULL,
	[password] [nvarchar](255) NOT NULL,
	[role] [nvarchar](20) NOT NULL,
	[status] [nvarchar](10) NULL,
	[created_at] [datetime2](7) NULL,
	[updated_at] [datetime2](7) NULL,
	[email] [nvarchar](255) NULL,
	[name] [nvarchar](255) NULL,
 CONSTRAINT [PK_MP_USER_NEW] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_MP_USER_NEW_Username] UNIQUE NONCLUSTERED 
(
	[username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[MP_USER_NEW] ADD  DEFAULT ('FSS') FOR [role]
GO

ALTER TABLE [dbo].[MP_USER_NEW] ADD  DEFAULT ('active') FOR [status]
GO

ALTER TABLE [dbo].[MP_USER_NEW] ADD  DEFAULT (getdate()) FOR [created_at]
GO

ALTER TABLE [dbo].[MP_USER_NEW] ADD  DEFAULT (getdate()) FOR [updated_at]
GO

ALTER TABLE [dbo].[MP_USER_NEW]  WITH CHECK ADD  CONSTRAINT [CK_MP_USER_NEW_Email] CHECK  (([email] like '%_@__%.__%'))
GO

ALTER TABLE [dbo].[MP_USER_NEW] CHECK CONSTRAINT [CK_MP_USER_NEW_Email]
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

ALTER TABLE [dbo].[MP_USER_NEW]  WITH CHECK ADD  CONSTRAINT [CK_MP_USER_NEW_Status] CHECK  (([status]='inactive' OR [status]='active'))
GO

ALTER TABLE [dbo].[MP_USER_NEW] CHECK CONSTRAINT [CK_MP_USER_NEW_Status]
GO


