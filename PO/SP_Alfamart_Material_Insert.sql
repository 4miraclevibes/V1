USE [POWERAPPS];
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Alfamart_Material_Insert]
    @material_no    VARCHAR(100),
    @ALFAMART_no    VARCHAR(100),
    @material_desc  NVARCHAR(255) = NULL,
    @ALFAMART_desc  NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validasi wajib isi
    IF NULLIF(LTRIM(RTRIM(@material_no)), '') IS NULL
    BEGIN
        RAISERROR('material_no wajib diisi.', 16, 1);
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(@ALFAMART_no)), '') IS NULL
    BEGIN
        RAISERROR('ALFAMART_no wajib diisi.', 16, 1);
        RETURN;
    END

    -- Cegah duplikasi pasangan material_no + ALFAMART_no
    IF EXISTS (
        SELECT 1
        FROM [ERP_INTERNATIONAL_SAP].[dbo].[ALFAMART_MATERIAL]
        WHERE [material_no] = @material_no
          AND [ALFAMART_no] = @ALFAMART_no
    )
    BEGIN
        RAISERROR('Data sudah ada: kombinasi material_no + ALFAMART_no duplikat.', 16, 1);
        RETURN;
    END

    INSERT INTO [ERP_INTERNATIONAL_SAP].[dbo].[ALFAMART_MATERIAL] (
        [material_no],
        [ALFAMART_no],
        [material_desc],
        [ALFAMART_desc]
    )
    VALUES (
        @material_no,
        @ALFAMART_no,
        @material_desc,
        @ALFAMART_desc
    );

    SELECT
        'OK' AS [status],
        'Insert ALFAMART_MATERIAL berhasil.' AS [message],
        @material_no AS [material_no],
        @ALFAMART_no AS [ALFAMART_no];
END
GO

PRINT 'SP created: [POWERAPPS].[dbo].[SP_Alfamart_Material_Insert]';
PRINT 'Usage example: EXEC dbo.SP_Alfamart_Material_Insert @material_no=''MAT001'', @ALFAMART_no=''ALFA001'', @material_desc=''Material A'', @ALFAMART_desc=''Desc A'';';
GO

