-- =====================================================
-- REPLACE_MP_FSS_DIST_FROM_REFERENCE.sql
-- =====================================================
-- Replace penuh: MP_FSS_DIST_REFERENCE_09_06_2026 -> MP_FSS_DIST
--
-- - Hapus semua data lama di MP_FSS_DIST
-- - Insert ulang dari reference
-- - Kolom reference kosong (NULL / '') -> 'UNDEFINE'
-- - desc = NULL, status = 'active'
-- - created_at & updated_at = GETDATE()
-- =====================================================

USE [POWERAPPS];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @SyncRunAt DATETIME = GETDATE();
DECLARE @RowsDeleted INT = 0;
DECLARE @RowsInserted INT = 0;
DECLARE @RowsSource INT = 0;

SELECT @RowsSource = COUNT(*)
FROM [dbo].[MP_FSS_DIST_REFERENCE_09_06_2026];

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM [dbo].[MP_FSS_DIST];
    SET @RowsDeleted = @@ROWCOUNT;

    INSERT INTO [dbo].[MP_FSS_DIST] (
        [distributor],
        [region],
        [fresh_dry],
        [market_channel],
        [fss_name],
        [fss_code],
        [fss_type],
        [aspm],
        [status],
        [desc],
        [created_at],
        [updated_at]
    )
    SELECT
        COALESCE(NULLIF(LTRIM(RTRIM(r.[distributor])), ''), N'UNDEFINE'),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[region])), ''), N'UNDEFINE'),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[fresh_dry])), ''), N'UNDEFINE'),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[market_chanel])), ''), N'UNDEFINE'),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[fss_name])), ''), N'UNDEFINE'),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[fss_code])), ''), N'UNDEFINE'),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[fss_type])), ''), N'UNDEFINE'),
        COALESCE(NULLIF(LTRIM(RTRIM(r.[aspm])), ''), N'UNDEFINE'),
        N'active',
        NULL,
        @SyncRunAt,
        @SyncRunAt
    FROM [dbo].[MP_FSS_DIST_REFERENCE_09_06_2026] r;

    SET @RowsInserted = @@ROWCOUNT;

    COMMIT TRANSACTION;

    PRINT 'Replace DIST selesai | deleted=' + CAST(@RowsDeleted AS VARCHAR)
        + ' | inserted=' + CAST(@RowsInserted AS VARCHAR)
        + ' | source=' + CAST(@RowsSource AS VARCHAR);

    SELECT
        @SyncRunAt AS SyncRunAt,
        @RowsDeleted AS RowsDeleted,
        @RowsInserted AS RowsInserted,
        @RowsSource AS RowsInReference,
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
