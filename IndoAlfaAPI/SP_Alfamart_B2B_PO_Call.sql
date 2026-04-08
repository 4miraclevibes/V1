-- =====================================================
-- SP_Alfamart_B2B_PO_Call
-- =====================================================
-- Hit API Alfamart B2B Auto Download - PO (Purchase Order) saja.
-- Key dipakai: 4924f89cb798223a6a0773475bc87fba
-- Checksum = SHA256(method#key#opt#day#jenis_data#datetime) hex.
-- Result: print response API (belum di-parse).
--
-- Prasyarat: OLE Automation enabled; atau curl di server (untuk fallback body besar).
-- Jika OLE ResponseText null (body besar), fallback: tulis body ke file, curl POST, baca response dari file.
-- =====================================================

USE [POWERAPPS];
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Alfamart_B2B_PO_Call]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @base_url   VARCHAR(100) = 'https://b2b-ap.alfamart.co.id';
    DECLARE @endpoint   VARCHAR(50)  = '/auto-download';
    DECLARE @key        VARCHAR(100) = '4924f89cb798223a6a0773475bc87fba';
    DECLARE @opt        VARCHAR(10)  = 'JSON';
    DECLARE @day        VARCHAR(5)   = '1';
    DECLARE @jenis_data VARCHAR(20)  = 'PO';
    DECLARE @method     VARCHAR(50)  = 'B2B-AUTO-DOWNLOAD';

    -- datetime format: yyyy-MM-dd HH:mm:ss (persis seperti Postman: pad 2 digit)
    DECLARE @datetime VARCHAR(30) =
        CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-' +
        RIGHT('0' + CAST(MONTH(GETDATE()) AS VARCHAR(2)), 2) + '-' +
        RIGHT('0' + CAST(DAY(GETDATE()) AS VARCHAR(2)), 2) + ' ' +
        RIGHT('0' + CAST(DATEPART(HOUR, GETDATE()) AS VARCHAR(2)), 2) + ':' +
        RIGHT('0' + CAST(DATEPART(MINUTE, GETDATE()) AS VARCHAR(2)), 2) + ':' +
        RIGHT('0' + CAST(DATEPART(SECOND, GETDATE()) AS VARCHAR(2)), 2);

    -- input string persis seperti JS: method#key#opt#day#jenis_data#datetime (harus VARCHAR, bukan NVARCHAR)
    DECLARE @input VARCHAR(500) = @method + '#' + @key + '#' + @opt + '#' + @day + '#' + @jenis_data + '#' + @datetime;
    -- SHA256 hex lowercase (CryptoJS.enc.Hex = lowercase)
    DECLARE @checksum VARCHAR(64) = LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @input COLLATE Latin1_General_CI_AS), 2));

    -- Body JSON
    DECLARE @body NVARCHAR(1000) = N'{"key":"' + @key + '","opt":"' + @opt + '","day":"' + @day + '","jenis_data":"' + @jenis_data + '","datetime":"' + @datetime + '","checksum":"' + @checksum + '"}';
    DECLARE @url VARCHAR(500) = @base_url + @endpoint;

    -- Debug: bandingkan dengan Postman pre-request (input & checksum harus sama)
    PRINT 'Input (untuk cek di Postman): ' + @input;
    PRINT 'Checksum: ' + @checksum;

    DECLARE @obj INT;
    DECLARE @responseText NVARCHAR(MAX);
    DECLARE @responseChunk NVARCHAR(4000);
    DECLARE @status INT;
    DECLARE @err INT;
    DECLARE @errMsg NVARCHAR(4000);
    DECLARE @bodyPath VARCHAR(260) = 'C:\temp\alfamart_body.json';
    DECLARE @responsePath VARCHAR(260) = 'C:\temp\alfamart_response.txt';
    DECLARE @curlCmd VARCHAR(2000);

    SET TEXTSIZE 2147483647;

    BEGIN TRY
        -- Coba WinHttp dulu (kadang ResponseText terbaca untuk response 4xx)
        EXEC @err = sp_OACreate 'WinHttp.WinHttpRequest.5.1', @obj OUT;
        IF @err <> 0
        BEGIN
            PRINT 'Error: OLE WinHttp create failed. Cek OLE Automation enabled (UTILITY_CheckOleEnabled.sql).';
            RETURN;
        END

        EXEC sp_OAMethod @obj, 'Open', NULL, 'POST', @url, 'False';
        EXEC sp_OAMethod @obj, 'setRequestHeader', NULL, 'Content-Type', 'application/json';
        EXEC sp_OAMethod @obj, 'Send', NULL, @body;
        -- Tunggu response selesai (kadang body null kalau dibaca terlalu cepat)
        EXEC sp_OAMethod @obj, 'WaitForResponse', NULL, 10;

        EXEC sp_OAGetProperty @obj, 'Status', @status OUT;
        EXEC sp_OAGetProperty @obj, 'ResponseText', @responseChunk OUT;
        EXEC sp_OADestroy @obj;

        SET @responseText = @responseChunk;

        -- Kalau masih null, coba ServerXMLHTTP
        IF @responseChunk IS NULL
        BEGIN
            EXEC @err = sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @obj OUT;
            IF @err = 0
            BEGIN
                EXEC sp_OAMethod @obj, 'Open', NULL, 'POST', @url, 'False';
                EXEC sp_OAMethod @obj, 'setRequestHeader', NULL, 'Content-Type', 'application/json';
                EXEC sp_OAMethod @obj, 'Send', NULL, @body;
                EXEC sp_OAGetProperty @obj, 'ResponseText', @responseChunk OUT;
                EXEC sp_OADestroy @obj;
                SET @responseText = @responseChunk;
            END
        END

        -- Fallback: kalau body masih null (biasa terjadi untuk response besar), pakai curl + file
        IF @responseText IS NULL
        BEGIN
            EXEC master..xp_cmdshell 'if not exist C:\temp mkdir C:\temp';

            -- Tulis body ke file (OLE FileSystemObject)
            EXEC @err = sp_OACreate 'Scripting.FileSystemObject', @obj OUT;
            IF @err = 0
            BEGIN
                DECLARE @fileOut INT;
                EXEC sp_OAMethod @obj, 'CreateTextFile', @fileOut OUT, @bodyPath, 2, 0;
                IF @fileOut IS NOT NULL
                BEGIN
                    EXEC sp_OAMethod @fileOut, 'Write', NULL, @body;
                    EXEC sp_OAMethod @fileOut, 'Close', NULL;
                    EXEC sp_OADestroy @fileOut;
                END
                EXEC sp_OADestroy @obj;
            END

            IF OBJECT_ID('tempdb..#CurlOut') IS NOT NULL DROP TABLE #CurlOut;
            CREATE TABLE #CurlOut (line VARCHAR(8000));
            SET @curlCmd = 'curl -s -X POST -H "Content-Type: application/json" -d @"' + @bodyPath + '" -o "' + @responsePath + '" -w "%{http_code}" "' + @url + '"';
            INSERT INTO #CurlOut (line) EXEC master..xp_cmdshell @curlCmd;

            -- Baca response dari file (OPENROWSET butuh literal path, pakai dynamic SQL)
            DECLARE @sql NVARCHAR(500) = N'SELECT @out = BulkColumn FROM OPENROWSET(BULK ''' + @responsePath + ''', SINGLE_CLOB) AS x';
            BEGIN TRY
                EXEC sp_executesql @sql, N'@out NVARCHAR(MAX) OUTPUT', @out = @responseText OUTPUT;
            END TRY
            BEGIN CATCH
                SET @responseText = NULL;
            END CATCH

            IF @status IS NULL
            BEGIN
                SELECT TOP 1 @status = CAST(LTRIM(RTRIM(line)) AS INT)
                FROM #CurlOut WHERE line IS NOT NULL AND LTRIM(RTRIM(line)) NOT LIKE '%curl%' AND LEN(LTRIM(RTRIM(line))) = 3 AND line LIKE '[0-9][0-9][0-9]';
            END
        END

        -- Parse JSON dan INSERT ke tabel (jika response ada)
        IF @responseText IS NOT NULL AND LEN(LTRIM(RTRIM(@responseText))) > 0
        BEGIN
            DECLARE @responseId BIGINT;
            DECLARE @cntHeader INT, @cntDetail INT;

            INSERT INTO [dbo].[Alfamart_PO_Response] ([status_code], [status], [message])
            SELECT [status_code], [status], [message]
            FROM OPENJSON(@responseText) WITH (
                [status_code] INT '$.status_code',
                [status]      VARCHAR(10) '$.status',
                [message]    NVARCHAR(500) '$.message'
            );
            SET @responseId = SCOPE_IDENTITY();

            -- Header + trailer (satu row per result item)
            INSERT INTO [dbo].[Alfamart_PO_Header] (
                [response_id], [result_index],
                [rec_tag], [po_no], [po_date], [exp_date], [proc_date],
                [dlv_code], [dlv_name], [dlv_town], [sup_code], [sup_name], [sup_add], [sup_phone], [sup_fax],
                [trl_rec_tag], [tot_purchase], [tot_disc], [tot_aft_disc], [tot_ppn], [tot_aft_ppn], [total_fpp],
                [amount_in_words], [contact], [supp_accno], [supp_accnm], [supp_bank], [barcode_in]
            )
            SELECT
                @responseId,
                CAST(res.[key] AS INT),
                h.[rec_tag], h.[po_no], h.[po_date], h.[exp_date], h.[proc_date],
                h.[dlv_code], h.[dlv_name], h.[dlv_town], h.[sup_code], h.[sup_name], h.[sup_add], h.[sup_phone], h.[sup_fax],
                h.[trl_rec_tag], h.[tot_purchase], h.[tot_disc], h.[tot_aft_disc], h.[tot_ppn], h.[tot_aft_ppn], h.[total_fpp],
                h.[amount_in_words], h.[contact], h.[supp_accno], h.[supp_accnm], h.[supp_bank], h.[barcode_in]
            FROM OPENJSON(@responseText, '$.result') AS res
            CROSS APPLY OPENJSON(res.value) WITH (
                [rec_tag]          VARCHAR(20)   '$.header.rec_tag',
                [po_no]            VARCHAR(50)   '$.header.po_no',
                [po_date]          VARCHAR(20)   '$.header.po_date',
                [exp_date]         VARCHAR(20)   '$.header.exp_date',
                [proc_date]        VARCHAR(20)   '$.header.proc_date',
                [dlv_code]         VARCHAR(20)   '$.header.dlv_code',
                [dlv_name]         NVARCHAR(200) '$.header.dlv_name',
                [dlv_town]         NVARCHAR(100) '$.header.dlv_town',
                [sup_code]         VARCHAR(100)  '$.header.sup_code',
                [sup_name]         NVARCHAR(200)  '$.header.sup_name',
                [sup_add]          NVARCHAR(500) '$.header.sup_add',
                [sup_phone]        VARCHAR(50)   '$.header.sup_phone',
                [sup_fax]          VARCHAR(50)   '$.header.sup_fax',
                [trl_rec_tag]      VARCHAR(20)   '$.trl.rec_tag',
                [tot_purchase]     BIGINT        '$.trl.tot_purchase',
                [tot_disc]         BIGINT        '$.trl.tot_disc',
                [tot_aft_disc]     BIGINT        '$.trl.tot_aft_disc',
                [tot_ppn]          BIGINT        '$.trl.tot_ppn',
                [tot_aft_ppn]      BIGINT        '$.trl.tot_aft_ppn',
                [total_fpp]        BIGINT        '$.trl.total_fpp',
                [amount_in_words]  NVARCHAR(500) '$.trl.amount_in_words',
                [contact]          VARCHAR(50)   '$.trl.contact',
                [supp_accno]       VARCHAR(50)   '$.trl.supp_accno',
                [supp_accnm]       NVARCHAR(200) '$.trl.supp_accnm',
                [supp_bank]        VARCHAR(50)   '$.trl.supp_bank',
                [barcode_in]       VARCHAR(50)   '$.trl.barcode_in'
            ) AS h;
            SET @cntHeader = @@ROWCOUNT;

            -- Detail (satu row per line di detail[])
            -- Cegah duplikasi GLOBAL: kombinasi po_no + plu tidak boleh dobel,
            -- walaupun datang dari response yang berbeda.
            INSERT INTO [dbo].[Alfamart_PO_Detail] (
                [header_id], [rec_tag], [desc], [qty_crt], [qty_pcs], [plu], [barcode], [price], [uom], [cnv],
                [disc_a], [remark], [net], [ppnbm], [total], [plu_b], [qty_b], [price_b], [disc_b]
            )
            SELECT
                hdr.[id],
                d.[rec_tag], d.[desc], d.[qty_crt], d.[qty_pcs], d.[plu], d.[barcode], d.[price], d.[uom], d.[cnv],
                d.[disc_a], d.[remark], d.[net], d.[ppnbm], d.[total], d.[plu_b], d.[qty_b], d.[price_b], d.[disc_b]
            FROM OPENJSON(@responseText, '$.result') AS res
            INNER JOIN [dbo].[Alfamart_PO_Header] hdr 
                ON hdr.[response_id] = @responseId 
               AND hdr.[result_index] = CAST(res.[key] AS INT)
            CROSS APPLY OPENJSON(res.value, '$.detail') WITH (
                [rec_tag] VARCHAR(20)       '$.rec_tag',
                [desc]    NVARCHAR(500)     '$.desc',
                [qty_crt] INT               '$.qty_crt',
                [qty_pcs] INT               '$.qty_pcs',
                [plu]     BIGINT            '$.plu',
                [barcode] VARCHAR(50)       '$.barcode',
                [price]   DECIMAL(18,2)     '$.price',
                [uom]     VARCHAR(20)       '$.uom',
                [cnv]     VARCHAR(20)       '$.cnv',
                [disc_a]  VARCHAR(20)       '$.disc_a',
                [remark]  NVARCHAR(200)     '$.remark',
                [net]     DECIMAL(18,2)     '$.net',
                [ppnbm]   DECIMAL(18,2)     '$.ppnbm',
                [total]   BIGINT            '$.total',
                [plu_b]   BIGINT            '$.plu_b',
                [qty_b]   INT               '$.qty_b',
                [price_b] DECIMAL(18,2)     '$.price_b',
                [disc_b]  VARCHAR(20)       '$.disc_b'
            ) AS d
            WHERE NOT EXISTS (
                SELECT 1
                FROM [dbo].[Alfamart_PO_Header] h2
                JOIN [dbo].[Alfamart_PO_Detail] ex
                    ON ex.[header_id] = h2.[id]
                WHERE h2.[po_no] = hdr.[po_no]
                  AND ex.[plu]   = d.[plu]
            );
            SET @cntDetail = @@ROWCOUNT;

            PRINT 'Data di-INSERT: Response id=' + CAST(@responseId AS VARCHAR(20))
                + ', Header=' + CAST(@cntHeader AS VARCHAR(20)) + ', Detail=' + CAST(@cntDetail AS VARCHAR(20)) + ' baris.';
        END

        -- Print summary
        PRINT '=== Alfamart B2B PO - Response ===';
        PRINT 'HTTP Status: ' + ISNULL(CAST(@status AS VARCHAR(10)), 'N/A');
        PRINT 'Response length: ' + ISNULL(CAST(LEN(@responseText) AS VARCHAR(20)), '0') + ' chars';
        PRINT '';

        -- Return full response di result set (bisa panjang)
        SELECT @status AS [HTTP_Status], @responseText AS [Response_Body];

        -- Print response (PRINT max ~8000 char)
        IF LEN(ISNULL(@responseText, '')) > 8000
            PRINT LEFT(@responseText, 8000) + '... [truncated]';
        ELSE IF @responseText IS NOT NULL
            PRINT @responseText;
        ELSE
            PRINT '(Response body kosong - cek HTTP Status di atas)';
    END TRY
    BEGIN CATCH
        SET @errMsg = ERROR_MESSAGE();
        IF @obj IS NOT NULL
            EXEC sp_OADestroy @obj;
        PRINT 'Error: ' + @errMsg;
        RAISERROR(@errMsg, 16, 1);
    END CATCH
END
GO

PRINT 'SP_Alfamart_B2B_PO_Call created.';
PRINT 'Usage: EXEC SP_Alfamart_B2B_PO_Call;';
GO
