-- =====================================================
-- VIEW: Data PO Alfamart dalam satu result set
-- Susunan kolom mengikuti struktur response JSON
-- (Response → Header/PO → Trailer → Detail per line)
-- Pakai: SELECT * FROM V_Alfamart_PO_WithDetail ORDER BY response_at DESC, result_index, detail_id;
-- =====================================================

USE [POWERAPPS];
GO

CREATE OR ALTER VIEW [dbo].[V_Alfamart_PO_WithDetail] AS
SELECT
    -- === RESPONSE (satu per panggilan API) ===
    R.[id]             AS [response_id],
    R.[response_at],
    R.[status_code],
    R.[status]         AS [response_status],
    R.[message]        AS [response_message],
    -- === HEADER / PO (satu per PO) ===
    H.[id]             AS [header_id],
    H.[result_index],
    H.[rec_tag]        AS [header_rec_tag],
    H.[po_no],
    H.[po_date],
    H.[exp_date],
    H.[proc_date],
    H.[dlv_code],
    H.[dlv_name],
    H.[dlv_town],
    H.[sup_code],
    H.[sup_name],
    H.[sup_add],
    H.[sup_phone],
    H.[sup_fax],
    -- === TRL / Trailer (ringkasan per PO) ===
    H.[trl_rec_tag],
    H.[tot_purchase],
    H.[tot_disc],
    H.[tot_aft_disc],
    H.[tot_ppn],
    H.[tot_aft_ppn],
    H.[total_fpp],
    H.[amount_in_words],
    H.[contact],
    H.[supp_accno],
    H.[supp_accnm],
    H.[supp_bank],
    H.[barcode_in],
    -- === DETAIL (satu baris per line item) ===
    D.[id]             AS [detail_id],
    D.[rec_tag]        AS [detail_rec_tag],
    D.[desc]           AS [detail_desc],
    D.[qty_crt],
    D.[qty_pcs],
    D.[plu],
    D.[barcode],
    D.[price],
    D.[uom],
    D.[cnv],
    D.[disc_a],
    D.[remark],
    D.[net],
    D.[ppnbm],
    D.[total]          AS [detail_total],
    D.[plu_b],
    D.[qty_b],
    D.[price_b],
    D.[disc_b]
FROM [dbo].[Alfamart_PO_Response] R
INNER JOIN [dbo].[Alfamart_PO_Header] H ON H.[response_id] = R.[id]
LEFT JOIN [dbo].[Alfamart_PO_Detail]  D ON D.[header_id]   = H.[id];
GO

PRINT 'View V_Alfamart_PO_WithDetail created.';
PRINT 'Contoh: SELECT * FROM V_Alfamart_PO_WithDetail ORDER BY response_at DESC, result_index, detail_id;';
GO
