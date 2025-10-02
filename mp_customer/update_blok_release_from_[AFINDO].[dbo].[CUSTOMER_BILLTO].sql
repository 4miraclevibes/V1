-- ========================================
-- STEP 1: PREVIEW/VIEW JOIN DULU - CEK DATA YANG AKAN DI-UPDATE
-- ========================================
-- Query ini untuk melihat data yang akan ter-update
-- Jalankan query ini dulu untuk memastikan data sudah benar

SELECT 
    target.[code],
    target.[name],
    target.[btp],
    target.[blok_release] AS [blok_release_lama],
    source.[status] AS [blok_release_baru],
    source.[billto_party],
    source.[billto_party_name],
    source.[type],
    target.[distributor_id]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] AS target
INNER JOIN [AFINDO].[dbo].[CUSTOMER_BILLTO] AS source
    ON target.[btp] = source.[billto_party]
WHERE target.[distributor_id] IN (
    1,
    32
)
ORDER BY target.[code];

-- ========================================
-- STEP 2: CEK JUMLAH BARIS YANG AKAN TER-UPDATE
-- ========================================
/*
SELECT COUNT(*) AS [total_rows_to_update]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] AS target
INNER JOIN [AFINDO].[dbo].[CUSTOMER_BILLTO] AS source
    ON target.[btp] = source.[billto_party]
WHERE target.[distributor_id] IN (
    1,
    32
);
*/

-- ========================================
-- STEP 3: UPDATE QUERY - JALANKAN SETELAH YAKIN DATA SUDAH BENAR
-- ========================================
-- HATI-HATI: Query ini akan mengupdate data!
-- Pastikan sudah run STEP 1 dan STEP 2 dulu sebelum run query ini

/*
UPDATE target
SET 
    [blok_release] = source.[status]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] AS target
INNER JOIN [AFINDO].[dbo].[CUSTOMER_BILLTO] AS source
    ON target.[btp] = source.[billto_party]
WHERE target.[distributor_id] IN (
    1,
    32
);
*/

