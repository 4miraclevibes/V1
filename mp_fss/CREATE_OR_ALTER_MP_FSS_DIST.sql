-- =====================================================
-- CREATE_OR_ALTER_MP_FSS_DIST.sql
-- =====================================================
-- Sinkronkan struktur [dbo].[MP_FSS_DIST] -> sesuai definisi lokal
-- Kolom target: distributor, region, fresh_dry, market_channel,
--   fss_name, fss_code, fss_type, aspm, status, desc,
--   created_at, updated_at, id
-- Migrasi: rsm -> aspm (rename jika masih ada)
-- =====================================================

USE [POWERAPPS];
GO

IF OBJECT_ID(N'dbo.MP_FSS_DIST', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[MP_FSS_DIST] (
        [id] BIGINT IDENTITY(1,1) NOT NULL,
        [distributor] NVARCHAR(255) NULL,
        [region] NVARCHAR(255) NULL,
        [fresh_dry] NVARCHAR(100) NULL,
        [market_channel] NVARCHAR(255) NULL,
        [fss_name] NVARCHAR(255) NULL,
        [fss_code] NVARCHAR(255) NULL,
        [fss_type] NVARCHAR(100) NULL,
        [aspm] NVARCHAR(255) NULL,
        [status] NVARCHAR(50) NOT NULL CONSTRAINT [DF_MP_FSS_DIST_status] DEFAULT (N'active'),
        [desc] NVARCHAR(MAX) NULL,
        [created_at] DATETIME2(7) NULL,
        [updated_at] DATETIME2(7) NULL,
        CONSTRAINT [PK_MP_FSS_DIST] PRIMARY KEY CLUSTERED ([id])
    );
    PRINT 'Tabel MP_FSS_DIST dibuat';
END
ELSE
    PRINT 'Tabel MP_FSS_DIST sudah ada';
GO

-- rsm -> aspm
IF COL_LENGTH('dbo.MP_FSS_DIST', 'aspm') IS NULL
   AND COL_LENGTH('dbo.MP_FSS_DIST', 'rsm') IS NOT NULL
BEGIN
    EXEC sp_rename N'dbo.MP_FSS_DIST.rsm', N'aspm', N'COLUMN';
    PRINT 'Kolom rsm di-rename menjadi aspm';
END
GO

IF COL_LENGTH('dbo.MP_FSS_DIST', 'distributor') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [distributor] NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'region') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [region] NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'fresh_dry') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [fresh_dry] NVARCHAR(100) NULL;
-- market_chanel -> market_channel (perbaikan typo lama di DIST)
IF COL_LENGTH('dbo.MP_FSS_DIST', 'market_channel') IS NULL
   AND COL_LENGTH('dbo.MP_FSS_DIST', 'market_chanel') IS NOT NULL
BEGIN
    EXEC sp_rename N'dbo.MP_FSS_DIST.market_chanel', N'market_channel', N'COLUMN';
    PRINT 'Kolom market_chanel di-rename menjadi market_channel';
END
GO

IF COL_LENGTH('dbo.MP_FSS_DIST', 'market_channel') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [market_channel] NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'fss_name') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [fss_name] NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'fss_code') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [fss_code] NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'fss_type') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [fss_type] NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'aspm') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [aspm] NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'status') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [status] NVARCHAR(50) NOT NULL
        CONSTRAINT [DF_MP_FSS_DIST_status] DEFAULT (N'active');
IF COL_LENGTH('dbo.MP_FSS_DIST', 'desc') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [desc] NVARCHAR(MAX) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'created_at') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [created_at] DATETIME2(7) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'updated_at') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [updated_at] DATETIME2(7) NULL;
IF COL_LENGTH('dbo.MP_FSS_DIST', 'id') IS NULL
    ALTER TABLE [dbo].[MP_FSS_DIST] ADD [id] BIGINT IDENTITY(1,1) NOT NULL;
GO

-- Verifikasi
SELECT
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH,
    c.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_SCHEMA = 'dbo'
  AND c.TABLE_NAME = 'MP_FSS_DIST'
ORDER BY c.ORDINAL_POSITION;
GO
