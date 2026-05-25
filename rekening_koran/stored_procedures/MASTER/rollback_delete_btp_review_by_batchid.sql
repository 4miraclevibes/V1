USE [POWERAPPS];
GO

/*
    rollback_delete_btp_review_by_batchid.sql
    Tujuan:
    - Hapus total data dari BTP_REVIEW berdasarkan BatchID.

    Cara pakai:
    1) Ganti nilai @BatchID sesuai batch yang ingin dihapus.
    2) Jalankan script.
*/

DECLARE @BatchID NVARCHAR(255) = 'BATCH_20260508_080737';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RowsToDelete INT = 0;
    DECLARE @RowsDeleted INT = 0;

    SELECT @RowsToDelete = COUNT(*)
    FROM [dbo].[BTP_REVIEW]
    WHERE [BatchID] = @BatchID;

    -- Preview jumlah data target
    SELECT
        @BatchID AS BatchID,
        @RowsToDelete AS RowsFoundInBTPReview,
        GETDATE() AS CheckedAt;

    -- Hapus total data batch dari BTP_REVIEW
    DELETE FROM [dbo].[BTP_REVIEW]
    WHERE [BatchID] = @BatchID;

    SET @RowsDeleted = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @BatchID AS BatchID,
        @RowsDeleted AS RowsDeleted,
        GETDATE() AS DeletedAt,
        'Delete total BTP_REVIEW by BatchID berhasil' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    SELECT
        @BatchID AS BatchID,
        0 AS RowsDeleted,
        NULL AS DeletedAt,
        @ErrorMessage AS ErrorMessage;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
