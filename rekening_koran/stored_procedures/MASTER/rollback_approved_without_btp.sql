USE [POWERAPPS];
GO

/*
    rollback_approved_without_btp.sql
    Tujuan:
    - Hapus data di MP_REKENING_KORAN yang berasal dari review dengan BTP kosong/tidak ditemukan
    - Kembalikan IsApproved di BTP_REVIEW untuk data dengan BTP kosong/tidak ditemukan

    Kriteria target rollback:
    - Status IN ('FAIR','GOOD','EXCELLENT')
    - IsApproved = 1
    - BTP NULL / kosong / whitespace
*/

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RowsDeleted INT = 0;
    DECLARE @RowsRolledBack INT = 0;

    DECLARE @Target TABLE (
        ID INT PRIMARY KEY,
        BatchID NVARCHAR(255)
    );

    INSERT INTO @Target (ID, BatchID)
    SELECT
        r.ID,
        r.BatchID
    FROM [dbo].[BTP_REVIEW] r
    WHERE r.Status IN ('FAIR', 'GOOD', 'EXCELLENT')
      AND r.IsApproved = 1
      AND ISNULL(LTRIM(RTRIM(r.BTP)), '') = '';

    -- Preview kandidat rollback
    SELECT
        t.ID,
        t.BatchID,
        r.TransactionType,
        r.Status,
        r.BTP,
        r.IsApproved,
        r.ApprovedBy,
        r.ApprovedAt
    FROM @Target t
    INNER JOIN [dbo].[BTP_REVIEW] r ON r.ID = t.ID;

    -- Hapus transaksi yang sudah masuk final table untuk batch kandidat
    DELETE rk
    FROM [dbo].[MP_REKENING_KORAN] rk
    WHERE EXISTS (
        SELECT 1
        FROM @Target t
        WHERE t.BatchID = rk.BatchID
    );

    SET @RowsDeleted = @@ROWCOUNT;

    -- Kembalikan status approval di BTP_REVIEW
    UPDATE r
    SET
        r.IsApproved = 0,
        r.ApprovedBy = NULL,
        r.ApprovedAt = NULL,
        r.ModifiedAt = GETDATE()
    FROM [dbo].[BTP_REVIEW] r
    INNER JOIN @Target t ON t.ID = r.ID;

    SET @RowsRolledBack = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @RowsDeleted AS RowsDeletedInMPRekeningKoran,
        @RowsRolledBack AS RowsRolledBackInBtpReview,
        GETDATE() AS RolledBackAt,
        'Rollback approval tanpa BTP berhasil' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    SELECT
        0 AS RowsDeletedInMPRekeningKoran,
        0 AS RowsRolledBackInBtpReview,
        NULL AS RolledBackAt,
        @ErrorMessage AS ErrorMessage;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
