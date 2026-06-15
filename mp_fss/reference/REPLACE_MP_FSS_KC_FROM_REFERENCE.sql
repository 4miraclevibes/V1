-- =====================================================
-- REPLACE_MP_FSS_KC_FROM_REFERENCE.sql
-- =====================================================
-- Replace penuh MP_FSS_KC dari tiga reference:
--   1. MP_FSS_KC_REFERENCE_09_06_2026
--   2. MP_FSS_DIRECT_REFERENCE_09_06_2026
--   3. MP_FSS_OD_REFERENCE_09_06_2026
--
-- KC & OD : market_chanel kosong -> SKIP
-- DIRECT  : market_chanel & fss_code -> 'UNDEFINE'
-- sales_executive kosong (semua sumber) -> 'no salesman'
-- desc = NULL, status = 'active', created_at & updated_at = GETDATE()
-- =====================================================

USE [POWERAPPS];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @SyncRunAt DATETIME = GETDATE();
DECLARE @RowsDeleted INT = 0;
DECLARE @RowsInsertedKC INT = 0;
DECLARE @RowsInsertedDirect INT = 0;
DECLARE @RowsInsertedOD INT = 0;
DECLARE @RowsSkippedKC INT = 0;
DECLARE @RowsSkippedOD INT = 0;
DECLARE @RowsSourceKC INT = 0;
DECLARE @RowsSourceDirect INT = 0;
DECLARE @RowsSourceOD INT = 0;

SELECT @RowsSourceKC = COUNT(*)
FROM [dbo].[MP_FSS_KC_REFERENCE_09_06_2026];

SELECT @RowsSkippedKC = COUNT(*)
FROM [dbo].[MP_FSS_KC_REFERENCE_09_06_2026]
WHERE ISNULL(LTRIM(RTRIM([market_chanel])), '') = '';

SELECT @RowsSourceDirect = COUNT(*)
FROM [dbo].[MP_FSS_DIRECT_REFERENCE_09_06_2026];

SELECT @RowsSourceOD = COUNT(*)
FROM [dbo].[MP_FSS_OD_REFERENCE_09_06_2026];

SELECT @RowsSkippedOD = COUNT(*)
FROM [dbo].[MP_FSS_OD_REFERENCE_09_06_2026]
WHERE ISNULL(LTRIM(RTRIM([market_chanel])), '') = '';

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM [dbo].[MP_FSS_KC];
    SET @RowsDeleted = @@ROWCOUNT;

    -- Sumber 1: KC reference
    INSERT INTO [dbo].[MP_FSS_KC] (
        [distributor],
        [market_chanel],
        [customer_code],
        [customer_name],
        [kabupaten_kota],
        [fss_name],
        [fss_code],
        [fss_type],
        [sales_executive],
        [aspm],
        [status],
        [desc],
        [created_at],
        [updated_at],
        [customer_id],
        [master_fss_id]
    )
    SELECT
        NULLIF(LTRIM(RTRIM(r.[distributor])), ''),
        NULLIF(LTRIM(RTRIM(r.[market_chanel])), ''),
        NULLIF(LTRIM(RTRIM(r.[customer_code])), ''),
        NULLIF(LTRIM(RTRIM(r.[customer_name])), ''),
        NULLIF(LTRIM(RTRIM(r.[kabupaten_kota])), ''),
        NULLIF(LTRIM(RTRIM(r.[fss_name])), ''),
        NULLIF(LTRIM(RTRIM(r.[fss_code])), ''),
        NULLIF(LTRIM(RTRIM(r.[fss_type])), ''),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[sales_executive])), ''), N'no salesman'),
        NULLIF(LTRIM(RTRIM(r.[aspm])), ''),
        N'active',
        NULL,
        @SyncRunAt,
        @SyncRunAt,
        NULL,
        NULL
    FROM [dbo].[MP_FSS_KC_REFERENCE_09_06_2026] r
    WHERE ISNULL(LTRIM(RTRIM(r.[market_chanel])), '') <> '';

    SET @RowsInsertedKC = @@ROWCOUNT;

    -- Sumber 2: DIRECT reference (kolom tidak ada -> UNDEFINE)
    INSERT INTO [dbo].[MP_FSS_KC] (
        [distributor],
        [market_chanel],
        [customer_code],
        [customer_name],
        [kabupaten_kota],
        [fss_name],
        [fss_code],
        [fss_type],
        [sales_executive],
        [aspm],
        [status],
        [desc],
        [created_at],
        [updated_at],
        [customer_id],
        [master_fss_id]
    )
    SELECT
        NULLIF(LTRIM(RTRIM(r.[distributor])), ''),
        N'UNDEFINE',
        NULLIF(LTRIM(RTRIM(r.[customer_code])), ''),
        NULLIF(LTRIM(RTRIM(r.[customer_name])), ''),
        NULLIF(LTRIM(RTRIM(r.[kabupaten_kota])), ''),
        NULLIF(LTRIM(RTRIM(r.[fss_name])), ''),
        N'UNDEFINE',
        NULLIF(LTRIM(RTRIM(r.[fss_type])), ''),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[sales_executive])), ''), N'no salesman'),
        NULLIF(LTRIM(RTRIM(r.[aspm])), ''),
        N'active',
        NULL,
        @SyncRunAt,
        @SyncRunAt,
        NULL,
        NULL
    FROM [dbo].[MP_FSS_DIRECT_REFERENCE_09_06_2026] r;

    SET @RowsInsertedDirect = @@ROWCOUNT;

    -- Sumber 3: OD reference (mapping sama seperti KC)
    INSERT INTO [dbo].[MP_FSS_KC] (
        [distributor],
        [market_chanel],
        [customer_code],
        [customer_name],
        [kabupaten_kota],
        [fss_name],
        [fss_code],
        [fss_type],
        [sales_executive],
        [aspm],
        [status],
        [desc],
        [created_at],
        [updated_at],
        [customer_id],
        [master_fss_id]
    )
    SELECT
        NULLIF(LTRIM(RTRIM(r.[distributor])), ''),
        NULLIF(LTRIM(RTRIM(r.[market_chanel])), ''),
        NULLIF(LTRIM(RTRIM(r.[customer_code])), ''),
        NULLIF(LTRIM(RTRIM(r.[customer_name])), ''),
        NULLIF(LTRIM(RTRIM(r.[kabupaten_kota])), ''),
        NULLIF(LTRIM(RTRIM(r.[fss_name])), ''),
        NULLIF(LTRIM(RTRIM(r.[fss_code])), ''),
        NULLIF(LTRIM(RTRIM(r.[fss_type])), ''),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[sales_executive])), ''), N'no salesman'),
        NULLIF(LTRIM(RTRIM(r.[aspm])), ''),
        N'active',
        NULL,
        @SyncRunAt,
        @SyncRunAt,
        NULL,
        NULL
    FROM [dbo].[MP_FSS_OD_REFERENCE_09_06_2026] r
    WHERE ISNULL(LTRIM(RTRIM(r.[market_chanel])), '') <> '';

    SET @RowsInsertedOD = @@ROWCOUNT;

    COMMIT TRANSACTION;

    PRINT 'Replace selesai | deleted=' + CAST(@RowsDeleted AS VARCHAR)
        + ' | inserted_kc=' + CAST(@RowsInsertedKC AS VARCHAR)
        + ' | inserted_direct=' + CAST(@RowsInsertedDirect AS VARCHAR)
        + ' | inserted_od=' + CAST(@RowsInsertedOD AS VARCHAR)
        + ' | skipped_kc_no_market_chanel=' + CAST(@RowsSkippedKC AS VARCHAR)
        + ' | skipped_od_no_market_chanel=' + CAST(@RowsSkippedOD AS VARCHAR)
        + ' | source_kc=' + CAST(@RowsSourceKC AS VARCHAR)
        + ' | source_direct=' + CAST(@RowsSourceDirect AS VARCHAR)
        + ' | source_od=' + CAST(@RowsSourceOD AS VARCHAR);

    SELECT
        @SyncRunAt AS SyncRunAt,
        @RowsDeleted AS RowsDeleted,
        @RowsInsertedKC AS RowsInsertedFromKC,
        @RowsInsertedDirect AS RowsInsertedFromDirect,
        @RowsInsertedOD AS RowsInsertedFromOD,
        @RowsInsertedKC + @RowsInsertedDirect + @RowsInsertedOD AS RowsInsertedTotal,
        @RowsSkippedKC AS RowsSkippedKCNoMarketChanel,
        @RowsSkippedOD AS RowsSkippedODNoMarketChanel,
        @RowsSourceKC AS RowsInKCReference,
        @RowsSourceDirect AS RowsInDirectReference,
        @RowsSourceOD AS RowsInODReference,
        N'Replace berhasil' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

    SELECT @SyncRunAt AS SyncRunAt, @ErrorMessage AS ErrorMessage;
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
GO
