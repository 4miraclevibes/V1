USE [POWERAPPS];
GO

/*
    rollback_isapproved_wira_eka.sql
    Tujuan:
    - Reset approval di BTP_REVIEW untuk data CustomerName LIKE '%WIRA EKA%'
    - IsApproved -> 0, ApprovedBy/ApprovedAt -> NULL

    Catatan:
    - Script ini TIDAK menghapus data MP_REKENING_KORAN.
    - Ganti @CustomerNameFilter jika perlu scope berbeda.
*/

DECLARE @CustomerNameFilter NVARCHAR(255) = '%WIRA EKA%';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RowsToReset INT = 0;
    DECLARE @RowsUpdated INT = 0;

  -- Preview data yang akan di-reset
    SELECT
        ID,
        BatchID,
        CustomerName,
        BTP,
        Status,
        TransactionType,
        IsApproved,
        ApprovedBy,
        ApprovedAt
    FROM [dbo].[BTP_REVIEW]
    WHERE CustomerName LIKE @CustomerNameFilter
      AND IsApproved = 1;

    SELECT @RowsToReset = COUNT(*)
    FROM [dbo].[BTP_REVIEW]
    WHERE CustomerName LIKE @CustomerNameFilter
      AND IsApproved = 1;

    -- Reset approval
    UPDATE [dbo].[BTP_REVIEW]
    SET
        IsApproved = 0,
        ApprovedBy = NULL,
        ApprovedAt = NULL,
        ModifiedAt = GETDATE()
    WHERE CustomerName LIKE @CustomerNameFilter
      AND IsApproved = 1;

    SET @RowsUpdated = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @CustomerNameFilter AS CustomerNameFilter,
        @RowsToReset AS RowsFoundBeforeReset,
        @RowsUpdated AS RowsUpdated,
        GETDATE() AS ResetAt,
        'Reset IsApproved WIRA EKA berhasil' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    SELECT
        @CustomerNameFilter AS CustomerNameFilter,
        0 AS RowsUpdated,
        NULL AS ResetAt,
        @ErrorMessage AS ErrorMessage;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
