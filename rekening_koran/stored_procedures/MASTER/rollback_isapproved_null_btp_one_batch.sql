USE [POWERAPPS];
GO

/*
    rollback_isapproved_null_btp_one_batch.sql
    Tujuan:
    - Reset approval di BTP_REVIEW untuk 1 batch tertentu
    - Khusus data dengan BTP NULL/kosong dan IsApproved = 1

    Scope:
    - BatchID = 'BATCH_20260528_032302'
    - Tidak menghapus data di MP_REKENING_KORAN
*/

DECLARE @BatchID NVARCHAR(100) = 'BATCH_20260528_032302';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RowsToReset INT = 0;
    DECLARE @RowsUpdated INT = 0;

    -- Preview data yang akan di-reset
    SELECT
        ID,
        BatchID,
        TransactionID,
        Status,
        TransactionType,
        BTP,
        IsApproved,
        ApprovedBy,
        ApprovedAt
    FROM [dbo].[BTP_REVIEW]
    WHERE BatchID = @BatchID
      AND IsApproved = 1
      AND ISNULL(LTRIM(RTRIM(BTP)), '') = '';

    SELECT @RowsToReset = COUNT(*)
    FROM [dbo].[BTP_REVIEW]
    WHERE BatchID = @BatchID
      AND IsApproved = 1
      AND ISNULL(LTRIM(RTRIM(BTP)), '') = '';

    -- Reset approval
    UPDATE [dbo].[BTP_REVIEW]
    SET
        IsApproved = 0,
        ApprovedBy = NULL,
        ApprovedAt = NULL,
        ModifiedAt = GETDATE()
    WHERE BatchID = @BatchID
      AND IsApproved = 1
      AND ISNULL(LTRIM(RTRIM(BTP)), '') = '';

    SET @RowsUpdated = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @BatchID AS BatchID,
        @RowsToReset AS RowsFoundBeforeReset,
        @RowsUpdated AS RowsUpdated,
        GETDATE() AS ResetAt,
        'Rollback IsApproved untuk BTP null/kosong (single batch) berhasil' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    SELECT
        @BatchID AS BatchID,
        0 AS RowsUpdated,
        NULL AS ResetAt,
        @ErrorMessage AS ErrorMessage;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO

