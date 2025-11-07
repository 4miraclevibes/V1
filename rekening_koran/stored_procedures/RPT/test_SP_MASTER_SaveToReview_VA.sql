/* ======================================================================
   TEST SCRIPT - SP_MASTER_FindBTP_SaveToReview (BankType = 'VA' / RPT)

   Langkah pemakaian:
     1. Buka converter.html → tab TXT/RPT → upload file RPT → klik
        "Copy JSON untuk SP (RPT)".
     2. Paste hasil JSON tersebut ke variabel @RPT_JSON di bawah.
     3. Jalankan script ini di SSMS (database POWERAPPS).
     4. Cek output SELECT terakhir (data yang masuk ke BTP_REVIEW) dan
        PRINT log di Messages window.

   Catatan:
     - Kolom Extended JSON mengikuti struktur parser.js terbaru
       (transaction_id, transaction_time, amount, location, dsb).
     - Jangan lupa ganti @UploadedBy kalau ingin melacak user uploader.
====================================================================== */

USE [POWERAPPS];
GO

DECLARE @RPT_JSON NVARCHAR(MAX) = N'[
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

-- TODO: Ganti isi array di atas dengan hasil paste JSON dari converter (hapus contoh jika perlu)

DECLARE @UploadedBy NVARCHAR(255) = 'rpt.test@company.com';

PRINT '>>> Menjalankan SP_MASTER_FindBTP_SaveToReview untuk payload VA/RPT...';

EXEC [dbo].[SP_MASTER_FindBTP_SaveToReview]
     @TransactionsJSON = @RPT_JSON,
     @BatchID = NULL,
     @UploadedBy = @UploadedBy;

PRINT '>>> Selesai. Periksa hasil SELECT (BTP_REVIEW) di atas.';

/*
Tips Debug:
  - Jika terjadi error, jalankan terlebih dahulu SP_RPT_FindBTP_Batch secara terpisah:
        EXEC dbo.SP_RPT_FindBTP_Batch @InputJSON = @RPT_JSON, @Debug = 1;
  - Pastikan kolom di JSON sesuai dengan struktur converter (btp, customer_name, dll).
  - Gunakan @Debug = 1 pada SP_MASTER jika ingin log tambahan (tambahkan parameter opsional).
*/


