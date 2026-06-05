-- =====================================================
-- SYNC_INSERT_MP_CUSTOMER_FROM_REFERENCE.sql
-- =====================================================
-- Sync: MP_CUSTOMER_REFERENCE_05_06_2026 -> MP_CUSTOMER_NEW
--
-- INSERT : baris baru (belum ada pasangan code + distributor_name + customer_name)
-- UPDATE : createdate untuk SEMUA row existing yang match reference
--
-- Unik: customer_code + distributor_name + customer_name
-- Duplikat di reference: ketiga kolom sama persis -> ambil 1 baris
--
-- Set @ShowPreview = 1 jika perlu detail duplikat di SSMS
-- =====================================================

USE POWERAPPS;
GO

IF OBJECT_ID('dbo.MP_CUSTOMER_REF_SYNC_INSERT_LOG', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[MP_CUSTOMER_REF_SYNC_INSERT_LOG] (
        [id] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [sync_run_at] DATETIME NOT NULL,
        [customer_code] NVARCHAR(100) NOT NULL,
        [customer_name] NVARCHAR(500) NULL,
        [distributor_name] NVARCHAR(500) NULL,
        [account_name] NVARCHAR(500) NULL,
        [regency_name] NVARCHAR(500) NULL,
        [shop_type] NVARCHAR(255) NULL,
        [shopper_type] NVARCHAR(255) NULL,
        [is_va] BIT NULL,
        [distributor_id] BIGINT NULL,
        [account_id] BIGINT NULL,
        [regency_id] BIGINT NULL,
        [new_customer_id] BIGINT NULL
    );
END
GO

IF COL_LENGTH('dbo.MP_CUSTOMER_REF_SYNC_INSERT_LOG', 'shop_type') IS NULL
    ALTER TABLE [dbo].[MP_CUSTOMER_REF_SYNC_INSERT_LOG] ADD [shop_type] NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.MP_CUSTOMER_REF_SYNC_INSERT_LOG', 'shopper_type') IS NULL
    ALTER TABLE [dbo].[MP_CUSTOMER_REF_SYNC_INSERT_LOG] ADD [shopper_type] NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.MP_CUSTOMER_REF_SYNC_INSERT_LOG', 'is_va') IS NULL
    ALTER TABLE [dbo].[MP_CUSTOMER_REF_SYNC_INSERT_LOG] ADD [is_va] BIT NULL;
GO

IF OBJECT_ID('dbo.MP_CUSTOMER_REF_SYNC_LOOKUP_MISS_LOG', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[MP_CUSTOMER_REF_SYNC_LOOKUP_MISS_LOG] (
        [id] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [sync_run_at] DATETIME NOT NULL,
        [customer_code] NVARCHAR(100) NOT NULL,
        [customer_name] NVARCHAR(500) NULL,
        [distributor_name] NVARCHAR(500) NULL,
        [account_name] NVARCHAR(500) NULL,
        [regency_name] NVARCHAR(500) NULL,
        [miss_distributor] BIT NOT NULL DEFAULT 0,
        [miss_account] BIT NOT NULL DEFAULT 0,
        [miss_regency] BIT NOT NULL DEFAULT 0
    );
END
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @SyncRunAt DATETIME = GETDATE();
DECLARE @RowsInserted INT = 0;
DECLARE @RowsCreatedateUpdated INT = 0;
DECLARE @RowsLookupMiss INT = 0;
DECLARE @RowsDuplicateRef INT = 0;
DECLARE @ShowPreview BIT = 0;

IF OBJECT_ID('tempdb..#DistLkp') IS NOT NULL DROP TABLE #DistLkp;
IF OBJECT_ID('tempdb..#AccLkp') IS NOT NULL DROP TABLE #AccLkp;
IF OBJECT_ID('tempdb..#RegLkp') IS NOT NULL DROP TABLE #RegLkp;
IF OBJECT_ID('tempdb..#ExistingTriple') IS NOT NULL DROP TABLE #ExistingTriple;
IF OBJECT_ID('tempdb..#RefSource') IS NOT NULL DROP TABLE #RefSource;
IF OBJECT_ID('tempdb..#NewRowsToSync') IS NOT NULL DROP TABLE #NewRowsToSync;

-- Index key limit SQL Server = 900 bytes
-- name_key: NVARCHAR(400) | dist_key (composite): NVARCHAR(350) | code_key: NVARCHAR(100)
SELECT
    CAST(LTRIM(RTRIM(ISNULL(d.[Distributor], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI AS [name_key],
    MIN(d.[Id]) AS [distributor_id]
INTO #DistLkp
FROM [dbo].[Distributors] d
WHERE ISNULL(LTRIM(RTRIM(d.[Distributor])), '') <> ''
GROUP BY CAST(LTRIM(RTRIM(ISNULL(d.[Distributor], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI;

CREATE UNIQUE NONCLUSTERED INDEX IX_DistLkp ON #DistLkp ([name_key]);

SELECT
    CAST(LTRIM(RTRIM(ISNULL(a.[account], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI AS [name_key],
    MIN(a.[id]) AS [account_id]
INTO #AccLkp
FROM [dbo].[Accounts] a
WHERE ISNULL(LTRIM(RTRIM(a.[account])), '') <> ''
GROUP BY CAST(LTRIM(RTRIM(ISNULL(a.[account], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI;

CREATE UNIQUE NONCLUSTERED INDEX IX_AccLkp ON #AccLkp ([name_key]);

SELECT
    CAST(LTRIM(RTRIM(ISNULL(rg.[kota], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI AS [name_key],
    MIN(rg.[id]) AS [regency_id]
INTO #RegLkp
FROM [dbo].[Regencies] rg
WHERE ISNULL(LTRIM(RTRIM(rg.[kota])), '') <> ''
GROUP BY CAST(LTRIM(RTRIM(ISNULL(rg.[kota], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI;

CREATE UNIQUE NONCLUSTERED INDEX IX_RegLkp ON #RegLkp ([name_key]);

-- Sudah ada di MP_CUSTOMER_NEW: pasangan code + distributor_name + customer_name
CREATE TABLE #ExistingTriple (
    [code_key] NVARCHAR(100) NOT NULL,
    [dist_key] NVARCHAR(350) NOT NULL,
    [cust_name_key] NVARCHAR(500) NOT NULL
);

INSERT INTO #ExistingTriple ([code_key], [dist_key], [cust_name_key])
SELECT DISTINCT
    CAST(LTRIM(RTRIM(ISNULL(c.[code], ''))) AS NVARCHAR(100)) COLLATE Latin1_General_CI_AI,
    CAST(LTRIM(RTRIM(ISNULL(d.[Distributor], ''))) AS NVARCHAR(350)) COLLATE Latin1_General_CI_AI,
    CAST(LTRIM(RTRIM(ISNULL(c.[name], ''))) AS NVARCHAR(500)) COLLATE Latin1_General_CI_AI
FROM [dbo].[MP_CUSTOMER_NEW] c
LEFT JOIN [dbo].[Distributors] d ON d.[Id] = c.[distributor_id]
WHERE ISNULL(LTRIM(RTRIM(c.[code])), '') <> '';

CREATE NONCLUSTERED INDEX IX_ExistingTriple ON #ExistingTriple ([code_key], [dist_key]);

CREATE TABLE #RefSource (
    [customer_code] NVARCHAR(100) NOT NULL,
    [dist_key] NVARCHAR(350) NOT NULL,
    [cust_name_key] NVARCHAR(500) NOT NULL,
    [customer_name] NVARCHAR(500) NULL,
    [city] NVARCHAR(500) NULL,
    [customer_createdate] NVARCHAR(100) NULL,
    [account_trading_term] NVARCHAR(500) NULL,
    [distributor_name] NVARCHAR(500) NULL,
    [account_name] NVARCHAR(500) NULL,
    [regency_name] NVARCHAR(500) NULL,
    [shop_type] NVARCHAR(255) NULL,
    [shopper_type] NVARCHAR(255) NULL,
    [distributor_id] BIGINT NULL,
    [account_id] BIGINT NULL,
    [regency_id] BIGINT NULL,
    [row_num] INT NOT NULL
);

INSERT INTO #RefSource (
    [customer_code], [dist_key], [cust_name_key], [customer_name], [city], [customer_createdate],
    [account_trading_term], [distributor_name], [account_name], [regency_name],
    [shop_type], [shopper_type], [distributor_id], [account_id], [regency_id], [row_num]
)
SELECT
    CAST(NULLIF(LTRIM(RTRIM(r.[customer_code])), '') AS NVARCHAR(100)),
    CAST(ISNULL(NULLIF(LTRIM(RTRIM(r.[distributor_name])), ''), '') AS NVARCHAR(350)) COLLATE Latin1_General_CI_AI,
    CAST(LTRIM(RTRIM(ISNULL(r.[customer_name], ''))) AS NVARCHAR(500)) COLLATE Latin1_General_CI_AI,
    CAST(NULLIF(LTRIM(RTRIM(r.[customer_name])), '') AS NVARCHAR(500)),
    CAST(NULLIF(LTRIM(RTRIM(r.[city])), '') AS NVARCHAR(500)),
    CAST(
        CASE
            WHEN r.[customer_createdate] IS NULL THEN NULL
            ELSE CONVERT(NVARCHAR(10), TRY_CAST(r.[customer_createdate] AS DATE), 103)
        END AS NVARCHAR(100)
    ),
    CAST(NULLIF(LTRIM(RTRIM(r.[account_trading_term])), '') AS NVARCHAR(500)),
    CAST(NULLIF(LTRIM(RTRIM(r.[distributor_name])), '') AS NVARCHAR(500)),
    CAST(NULLIF(LTRIM(RTRIM(r.[account_name])), '') AS NVARCHAR(500)),
    CAST(NULLIF(LTRIM(RTRIM(r.[regency_name])), '') AS NVARCHAR(500)),
    CAST(NULLIF(LTRIM(RTRIM(r.[shop_type])), '') AS NVARCHAR(255)),
    CAST(NULLIF(LTRIM(RTRIM(r.[shopper_type])), '') AS NVARCHAR(255)),
    dl.[distributor_id],
    al.[account_id],
    rl.[regency_id],
    ROW_NUMBER() OVER (
        PARTITION BY
            CAST(NULLIF(LTRIM(RTRIM(r.[customer_code])), '') AS NVARCHAR(100)),
            CAST(ISNULL(NULLIF(LTRIM(RTRIM(r.[distributor_name])), ''), '') AS NVARCHAR(350)) COLLATE Latin1_General_CI_AI,
            CAST(LTRIM(RTRIM(ISNULL(r.[customer_name], ''))) AS NVARCHAR(500)) COLLATE Latin1_General_CI_AI
        ORDER BY (SELECT NULL)
    )
FROM [dbo].[MP_CUSTOMER_REFERENCE_05_06_2026] r
LEFT JOIN #DistLkp dl
    ON dl.[name_key] = CAST(LTRIM(RTRIM(ISNULL(r.[distributor_name], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI
LEFT JOIN #AccLkp al
    ON al.[name_key] = CAST(LTRIM(RTRIM(ISNULL(r.[account_name], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI
LEFT JOIN #RegLkp rl
    ON rl.[name_key] = CAST(LTRIM(RTRIM(ISNULL(r.[regency_name], ''))) AS NVARCHAR(400)) COLLATE Latin1_General_CI_AI
WHERE ISNULL(LTRIM(RTRIM(r.[customer_code])), '') <> '';

CREATE NONCLUSTERED INDEX IX_RefSource ON #RefSource ([customer_code], [dist_key]);

SELECT @RowsDuplicateRef = ISNULL(SUM(cnt - 1), 0)
FROM (
    SELECT COUNT(*) AS cnt
    FROM #RefSource
    GROUP BY [customer_code], [dist_key], [cust_name_key]
    HAVING COUNT(*) > 1
) d;

IF @ShowPreview = 1
BEGIN
    SELECT
        s.[customer_code],
        s.[distributor_name],
        s.[customer_name],
        COUNT(*) AS duplicate_count_in_reference
    FROM #RefSource s
    GROUP BY s.[customer_code], s.[distributor_name], s.[customer_name]
    HAVING COUNT(*) > 1
    ORDER BY COUNT(*) DESC, s.[customer_code], s.[distributor_name], s.[customer_name];
END

CREATE TABLE #NewRowsToSync (
    [customer_code] NVARCHAR(100) NOT NULL,
    [dist_key] NVARCHAR(350) NOT NULL,
    [cust_name_key] NVARCHAR(500) NOT NULL,
    [customer_name] NVARCHAR(500) NULL,
    [city] NVARCHAR(500) NULL,
    [customer_createdate] NVARCHAR(100) NULL,
    [account_trading_term] NVARCHAR(500) NULL,
    [distributor_name] NVARCHAR(500) NULL,
    [account_name] NVARCHAR(500) NULL,
    [regency_name] NVARCHAR(500) NULL,
    [shop_type] NVARCHAR(255) NULL,
    [shopper_type] NVARCHAR(255) NULL,
    [distributor_id] BIGINT NULL,
    [account_id] BIGINT NULL,
    [regency_id] BIGINT NULL,
    PRIMARY KEY ([customer_code], [dist_key], [cust_name_key])
);

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO #NewRowsToSync (
        [customer_code], [dist_key], [cust_name_key], [customer_name], [city], [customer_createdate],
        [account_trading_term], [distributor_name], [account_name], [regency_name],
        [shop_type], [shopper_type],
        [distributor_id], [account_id], [regency_id]
    )
    SELECT
        s.[customer_code], s.[dist_key], s.[cust_name_key], s.[customer_name], s.[city], s.[customer_createdate],
        s.[account_trading_term], s.[distributor_name], s.[account_name], s.[regency_name],
        s.[shop_type], s.[shopper_type],
        s.[distributor_id], s.[account_id], s.[regency_id]
    FROM #RefSource s
    WHERE s.[row_num] = 1
      AND NOT EXISTS (
          SELECT 1
          FROM #ExistingTriple e
          WHERE e.[code_key] = s.[customer_code] COLLATE Latin1_General_CI_AI
            AND e.[dist_key] = s.[dist_key] COLLATE Latin1_General_CI_AI
            AND e.[cust_name_key] = s.[cust_name_key] COLLATE Latin1_General_CI_AI
      );

    -- UPDATE createdate untuk existing yang match reference (code + distributor_name + customer_name)
    UPDATE c
    SET
        c.[createdate] = CAST(s.[customer_createdate] AS NVARCHAR(MAX)),
        c.[updated_at] = CAST(@SyncRunAt AS DATETIME2(7))
    FROM [dbo].[MP_CUSTOMER_NEW] c
    LEFT JOIN [dbo].[Distributors] d ON d.[Id] = c.[distributor_id]
    INNER JOIN #RefSource s
        ON s.[row_num] = 1
       AND CAST(LTRIM(RTRIM(ISNULL(c.[code], ''))) AS NVARCHAR(100)) COLLATE Latin1_General_CI_AI
           = s.[customer_code] COLLATE Latin1_General_CI_AI
       AND CAST(LTRIM(RTRIM(ISNULL(d.[Distributor], ''))) AS NVARCHAR(350)) COLLATE Latin1_General_CI_AI
           = s.[dist_key] COLLATE Latin1_General_CI_AI
       AND CAST(LTRIM(RTRIM(ISNULL(c.[name], ''))) AS NVARCHAR(500)) COLLATE Latin1_General_CI_AI
           = s.[cust_name_key] COLLATE Latin1_General_CI_AI;

    SET @RowsCreatedateUpdated = @@ROWCOUNT;

    INSERT INTO [dbo].[MP_CUSTOMER_REF_SYNC_LOOKUP_MISS_LOG] (
        [sync_run_at], [customer_code], [customer_name],
        [distributor_name], [account_name], [regency_name],
        [miss_distributor], [miss_account], [miss_regency]
    )
    SELECT
        @SyncRunAt, t.[customer_code], t.[customer_name],
        t.[distributor_name], t.[account_name], t.[regency_name],
        CASE WHEN ISNULL(t.[distributor_name], '') <> '' AND t.[distributor_id] IS NULL THEN 1 ELSE 0 END,
        CASE WHEN ISNULL(t.[account_name], '') <> '' AND t.[account_id] IS NULL THEN 1 ELSE 0 END,
        CASE WHEN ISNULL(t.[regency_name], '') <> '' AND t.[regency_id] IS NULL THEN 1 ELSE 0 END
    FROM #NewRowsToSync t
    WHERE (ISNULL(t.[distributor_name], '') <> '' AND t.[distributor_id] IS NULL)
       OR (ISNULL(t.[account_name], '') <> '' AND t.[account_id] IS NULL)
       OR (ISNULL(t.[regency_name], '') <> '' AND t.[regency_id] IS NULL);

    SET @RowsLookupMiss = @@ROWCOUNT;

    MERGE [dbo].[MP_CUSTOMER_NEW] AS c
    USING #NewRowsToSync AS t
        ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT (
            [code], [name], [city], [createdate],
            [distributor_id], [account_id], [account_trading_term], [regency_id],
            [shop_type], [shopper_type],
            [created_at], [updated_at], [status]
        )
        VALUES (
            CAST(t.[customer_code] AS NVARCHAR(MAX)),
            CAST(t.[customer_name] AS NVARCHAR(MAX)),
            CAST(t.[city] AS NVARCHAR(MAX)),
            CAST(t.[customer_createdate] AS NVARCHAR(MAX)),
            t.[distributor_id],
            t.[account_id],
            CAST(t.[account_trading_term] AS NVARCHAR(MAX)),
            t.[regency_id],
            CAST(t.[shop_type] AS NVARCHAR(255)),
            CAST(t.[shopper_type] AS NVARCHAR(255)),
            CAST(@SyncRunAt AS DATETIME2(7)),
            CAST(@SyncRunAt AS DATETIME2(7)),
            N'active'
        )
    OUTPUT
        @SyncRunAt,
        t.[customer_code],
        t.[customer_name],
        t.[distributor_name],
        t.[account_name],
        t.[regency_name],
        t.[shop_type],
        t.[shopper_type],
        CAST(NULL AS BIT),
        t.[distributor_id],
        t.[account_id],
        t.[regency_id],
        INSERTED.[id]
    INTO [dbo].[MP_CUSTOMER_REF_SYNC_INSERT_LOG] (
        [sync_run_at], [customer_code], [customer_name],
        [distributor_name], [account_name], [regency_name],
        [shop_type], [shopper_type], [is_va],
        [distributor_id], [account_id], [regency_id], [new_customer_id]
    );

    SET @RowsInserted = @@ROWCOUNT;

    COMMIT TRANSACTION;

    PRINT 'Sync selesai | inserted=' + CAST(@RowsInserted AS VARCHAR)
        + ' | createdate_updated=' + CAST(@RowsCreatedateUpdated AS VARCHAR)
        + ' | dup_ref_skipped=' + CAST(@RowsDuplicateRef AS VARCHAR)
        + ' | lookup_miss=' + CAST(@RowsLookupMiss AS VARCHAR);

    SELECT
        @SyncRunAt AS SyncRunAt,
        @RowsInserted AS RowsInserted,
        @RowsCreatedateUpdated AS RowsCreatedateUpdated,
        @RowsDuplicateRef AS DuplicateReferenceRowsSkipped,
        @RowsLookupMiss AS LookupMissLogged,
        N'Sync berhasil' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

    SELECT @SyncRunAt AS SyncRunAt, 0 AS RowsInserted, @ErrorMessage AS ErrorMessage;
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
GO
