USE [POWERAPPS];
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Alfamart_Customer_Insert]
    @SOLD_TO_NO       VARCHAR(100),
    @SHIP_TO_NO       VARCHAR(100),
    @ALFAMART_SOLD_NO VARCHAR(100),
    @DESCRIPTION      NVARCHAR(255) = NULL,
    @TEXT             NVARCHAR(255) = NULL,
    @STATUS           VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(RTRIM(@SOLD_TO_NO)), '') IS NULL
    BEGIN
        RAISERROR('SOLD_TO_NO wajib diisi.', 16, 1);
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(@SHIP_TO_NO)), '') IS NULL
    BEGIN
        RAISERROR('SHIP_TO_NO wajib diisi.', 16, 1);
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(@ALFAMART_SOLD_NO)), '') IS NULL
    BEGIN
        RAISERROR('ALFAMART_SOLD_NO wajib diisi.', 16, 1);
        RETURN;
    END

    -- Cegah duplikasi customer key
    IF EXISTS (
        SELECT 1
        FROM [ERP_INTERNATIONAL_SAP].[dbo].[ALFAMART_CUSTOMER]
        WHERE [SOLD_TO_NO]       = @SOLD_TO_NO
          AND [SHIP_TO_NO]       = @SHIP_TO_NO
          AND [ALFAMART_SOLD_NO] = @ALFAMART_SOLD_NO
    )
    BEGIN
        RAISERROR('Data sudah ada: kombinasi SOLD_TO_NO + SHIP_TO_NO + ALFAMART_SOLD_NO duplikat.', 16, 1);
        RETURN;
    END

    INSERT INTO [ERP_INTERNATIONAL_SAP].[dbo].[ALFAMART_CUSTOMER] (
        [SOLD_TO_NO],
        [SHIP_TO_NO],
        [ALFAMART_SOLD_NO],
        [DESCRIPTION],
        [TEXT],
        [STATUS]
    )
    VALUES (
        @SOLD_TO_NO,
        @SHIP_TO_NO,
        @ALFAMART_SOLD_NO,
        @DESCRIPTION,
        @TEXT,
        @STATUS
    );

    SELECT
        'OK' AS [status],
        'Insert ALFAMART_CUSTOMER berhasil.' AS [message],
        @SOLD_TO_NO AS [SOLD_TO_NO],
        @SHIP_TO_NO AS [SHIP_TO_NO],
        @ALFAMART_SOLD_NO AS [ALFAMART_SOLD_NO];
END
GO

PRINT 'SP created: [POWERAPPS].[dbo].[SP_Alfamart_Customer_Insert]';
PRINT 'Usage example: EXEC dbo.SP_Alfamart_Customer_Insert @SOLD_TO_NO=''10001'', @SHIP_TO_NO=''20001'', @ALFAMART_SOLD_NO=''ALFA01'', @DESCRIPTION=''Desc'', @TEXT=''Text'', @STATUS=''ACTIVE'';';
GO

