/* ======================================================================
   TEST SCRIPT - SP_RPT_FindBTP_Batch (RPT / Virtual Account)

   Langkah pemakaian:
     1. Buka converter.html → tab TXT/RPT → upload file RPT → klik
        "Copy JSON untuk SP (RPT)".
     2. Paste JSON tersebut ke variabel @JSON di bawah.
     3. Jalankan script ini di SSMS untuk melihat output SP langsung.
     4. Gunakan @Debug = 1 untuk log tambahan jika perlu.
====================================================================== */

USE [POWERAPPS];
GO

DECLARE @JSON NVARCHAR(MAX) = N'[
    {
        "transaction_id": 1,
        "transaction_date": "05/11/25",
        "transaction_time": "06:11:44",
        "btp": "2300016953",
        "customer_name": "PT  ERA KOPI AND",
        "amount": 463270.00,
        "location": "9508N",
        "keterangan1": "-",
        "keterangan2": "-",
        "description": "RPT: PT  ERA KOPI AND | - | -",
        "bank_type": "VA"
    }
]';

-- TODO: ganti isi array di atas dengan JSON dari converter sebelum dijalankan.

EXEC [dbo].[SP_RPT_FindBTP_Batch]
    @InputJSON = @JSON,
    @Debug = 1;


