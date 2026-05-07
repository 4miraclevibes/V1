USE [POWERAPPS];
GO

/*
    rollback_isapproved_db.sql
    Tujuan:
    - Hapus data MP_REKENING_KORAN yang TransactionType = 'DB' (berdasarkan BatchID kandidat rollback)
    - Mengembalikan status approval untuk data BTP_REVIEW yang TransactionType = 'DB'
    - IsApproved -> 0
    - ApprovedBy -> NULL
    - ApprovedAt -> NULL
    - ModifiedAt -> GETDATE()

    Catatan:
    - Semua proses dijalankan dalam 1 transaksi agar konsisten.
*/

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RowsDeleted INT = 0;
    DECLARE @RowsRolledBack INT = 0;

    -- Simpan kandidat rollback agar DELETE & UPDATE konsisten pada data yang sama
    DECLARE @TargetDB TABLE (
        id INT,
        BatchID NVARCHAR(255)
    );

    INSERT INTO @TargetDB (id, BatchID)
    SELECT
        id,
        BatchID
    FROM [dbo].[BTP_REVIEW]
    WHERE ISNULL(TransactionType, 'CR') = 'DB'
      AND IsApproved = 1;

    -- Cek kandidat data yang akan di-rollback
    SELECT
        t.id,
        t.BatchID,
        b.TransactionType,
        b.IsApproved,
        b.ApprovedBy,
        b.ApprovedAt
    FROM @TargetDB t
    INNER JOIN [dbo].[BTP_REVIEW] b ON b.id = t.id;

    -- Hapus data DB yang sudah terlanjur masuk MP_REKENING_KORAN
    DELETE rk
    FROM [dbo].[MP_REKENING_KORAN] rk
    WHERE ISNULL(rk.TransactionType, 'CR') = 'DB'
      AND EXISTS (
          SELECT 1
          FROM @TargetDB t
          WHERE t.BatchID = rk.BatchID
      );

    SET @RowsDeleted = @@ROWCOUNT;

    -- Rollback approval hanya untuk DB yang sudah approved
    UPDATE b
    SET
        b.IsApproved = 0,
        b.ApprovedBy = NULL,
        b.ApprovedAt = NULL,
        b.ModifiedAt = GETDATE()
    FROM [dbo].[BTP_REVIEW] b
    INNER JOIN @TargetDB t ON t.id = b.id;

    SET @RowsRolledBack = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @RowsDeleted AS RowsDeletedInMPRekeningKoran,
        @RowsRolledBack AS RowsRolledBack,
        GETDATE() AS RolledBackAt,
        'Delete DB di MP_REKENING_KORAN + rollback IsApproved DB berhasil' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    SELECT
        0 AS RowsDeletedInMPRekeningKoran,
        0 AS RowsRolledBack,
        NULL AS RolledBackAt,
        @ErrorMessage AS ErrorMessage;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
