-- =====================================================
-- Cek data double untuk kombinasi PO Number (po_no) + PLU
-- Sesuai rule di SP_Alfamart_B2B_PO_Call (seharusnya unik).
-- Kalau query ini masih mengembalikan baris, berarti ada duplikasi.
-- =====================================================

USE [POWERAPPS];
GO

;WITH Dup AS (
    SELECT 
        H.po_no,
        D.plu,
        COUNT(*) AS cnt,
        MIN(D.id) AS min_detail_id,
        MAX(D.id) AS max_detail_id
    FROM dbo.Alfamart_PO_Header  H
    JOIN dbo.Alfamart_PO_Detail  D ON D.header_id = H.id
    GROUP BY H.po_no, D.plu
    HAVING COUNT(*) > 1
)
SELECT 
    du.po_no,
    du.plu,
    du.cnt,
    du.min_detail_id,
    du.max_detail_id
FROM Dup du
ORDER BY du.po_no, du.plu;
GO

-- Untuk lihat baris detail-nya (opsional):
-- SELECT H.po_no, D.*
-- FROM dbo.Alfamart_PO_Header H
-- JOIN dbo.Alfamart_PO_Detail D ON D.header_id = H.id
-- WHERE H.po_no = '<ISI_PO_NO>' AND D.plu = <ISI_PLU>
-- ORDER BY D.id;
-- GO

