-- =====================================================
-- SP_TRUNCATE_MP_JURNAL
-- =====================================================
-- Truncate table MP_JURNAL
-- =====================================================

USE [POWERAPPS]
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_TRUNCATE_MP_JURNAL]
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE [dbo].[MP_JURNAL];
END
GO

PRINT 'SP_TRUNCATE_MP_JURNAL created.';
PRINT 'Usage: EXEC SP_TRUNCATE_MP_JURNAL;';
GO
