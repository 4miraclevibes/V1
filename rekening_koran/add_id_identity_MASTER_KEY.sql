-- Script untuk menambahkan kolom ID sebagai Primary Key dan Identity pada tabel MASTER_KEY
-- Data yang sudah ada akan dipertahankan

-- Step 1: Backup data yang sudah ada ke tabel temporary
SELECT * INTO [dbo].[MASTER_KEY_TEMP] FROM [dbo].[MASTER_KEY]
GO

-- Step 2: Drop tabel asli
DROP TABLE [dbo].[MASTER_KEY]
GO

-- Step 3: Buat ulang tabel dengan kolom ID sebagai Primary Key dan Identity
CREATE TABLE [dbo].[MASTER_KEY](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[btp] [nvarchar](max) NULL,
	[btn] [nvarchar](max) NULL,
 CONSTRAINT [PK_MASTER_KEY] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

-- Step 4: Insert kembali data dari tabel temporary
SET IDENTITY_INSERT [dbo].[MASTER_KEY] ON
GO

INSERT INTO [dbo].[MASTER_KEY] ([Id], [btp], [btn])
SELECT 
	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as [Id],
	[btp],
	[btn]
FROM [dbo].[MASTER_KEY_TEMP]
GO

SET IDENTITY_INSERT [dbo].[MASTER_KEY] OFF
GO

-- Step 5: Hapus tabel temporary
DROP TABLE [dbo].[MASTER_KEY_TEMP]
GO

-- Step 6: Verifikasi hasil
SELECT COUNT(*) as 'Total Records' FROM [dbo].[MASTER_KEY]
SELECT TOP 5 * FROM [dbo].[MASTER_KEY]
GO

PRINT 'Tabel MASTER_KEY berhasil diupdate dengan kolom ID sebagai Primary Key dan Identity!'
