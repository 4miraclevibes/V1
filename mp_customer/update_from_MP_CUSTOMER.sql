-- Update MP_CUSTOMER_NEW dengan nilai dari MP_CUSTOMER
-- Kolom yang di-update: btp, btn, top, credit_limit, GFcode, npwp, supply_chain, nik, va_gdi, va_gi
-- Join berdasarkan: distributor_id, code, dan name

UPDATE target
SET 
    [btp] = source.[btp],
    [btn] = source.[btn],
    [top] = source.[top],
    [credit_limit] = source.[credit_limit],
    [GFcode] = source.[GFcode],
    [npwp] = source.[npwp],
    [supply_chain] = source.[supply_chain],
    [nik] = source.[nik],
    [va_gdi] = source.[va_gdi],
    [va_gi] = source.[va_gi]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] AS target
INNER JOIN [POWERAPPS].[dbo].[MP_CUSTOMER] AS source
    ON target.[distributor_id] = source.[distributor_id]
    AND target.[code] = source.[code]
WHERE target.[distributor_id] IN (
    1, 
    32
);

-- Untuk cek berapa baris yang akan ter-update, jalankan query ini dulu:
/*
SELECT COUNT(*) AS [total_rows_to_update]
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] AS target
INNER JOIN [POWERAPPS].[dbo].[MP_CUSTOMER] AS source
    ON target.[distributor_id] = source.[distributor_id]
    AND target.[code] = source.[code]
    AND target.[name] = source.[name]
WHERE target.[distributor_id] IN (
    1, 
    32
);
*/

