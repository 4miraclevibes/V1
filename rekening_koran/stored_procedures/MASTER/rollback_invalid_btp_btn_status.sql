USE [POWERAPPS];
GO

/*
    rollback_invalid_btp_btn_status.sql
    Tujuan:
    - Perbaiki data yang terlanjur berstatus FAIR/GOOD/EXCELLENT
      padahal BTP atau BTN(CustomerName) kosong.
    - Hapus data terkait di MP_REKENING_KORAN.
    - Reset approval di BTP_REVIEW.
*/

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RowsDeleted INT = 0;
    DECLARE @RowsUpdated INT = 0;

    DECLARE @Target TABLE (
        ID INT PRIMARY KEY,
        BatchID NVARCHAR(255)
    );

    INSERT INTO @Target (ID, BatchID)
    SELECT
        br.ID,
        br.BatchID
    FROM dbo.BTP_REVIEW br
    WHERE br.Status IN ('FAIR', 'GOOD', 'EXCELLENT')
      AND (
          ISNULL(LTRIM(RTRIM(br.BTP)), '') = ''
          OR ISNULL(LTRIM(RTRIM(br.CustomerName)), '') = ''
      );

    -- Hapus data final table yang terlanjur masuk
    DELETE rk
    FROM dbo.MP_REKENING_KORAN rk
    WHERE EXISTS (
        SELECT 1
        FROM @Target t
        WHERE t.BatchID = rk.BatchID
    );
    SET @RowsDeleted = @@ROWCOUNT;

    -- Perbaiki status dan reset approval
    UPDATE br
    SET
        br.Status = CASE
            WHEN ISNULL(LTRIM(RTRIM(br.BTP)), '') = '' THEN 'NO_BTP'
            WHEN ISNULL(LTRIM(RTRIM(br.CustomerName)), '') = '' THEN 'NO_PATTERN'
            ELSE br.Status
        END,
        br.Message = CASE
            WHEN ISNULL(LTRIM(RTRIM(br.BTP)), '') = '' THEN 'BTP tidak ditemukan/kosong - status dikoreksi dari auto approve'
            WHEN ISNULL(LTRIM(RTRIM(br.CustomerName)), '') = '' THEN 'BTN/CustomerName tidak ditemukan - status dikoreksi dari auto approve'
            ELSE br.Message
        END,
        br.IsApproved = 0,
        br.ApprovedBy = NULL,
        br.ApprovedAt = NULL,
        br.ModifiedAt = GETDATE()
    FROM dbo.BTP_REVIEW br
    INNER JOIN @Target t ON t.ID = br.ID;
    SET @RowsUpdated = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @RowsDeleted AS RowsDeletedInMPRekeningKoran,
        @RowsUpdated AS RowsUpdatedInBTPReview,
        GETDATE() AS FixedAt,
        'Rollback invalid EXCELLENT/GOOD/FAIR (BTP/BTN kosong) selesai' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    SELECT
        0 AS RowsDeletedInMPRekeningKoran,
        0 AS RowsUpdatedInBTPReview,
        NULL AS FixedAt,
        @ErrorMessage AS ErrorMessage;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
