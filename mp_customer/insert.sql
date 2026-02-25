INSERT INTO [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] (
    [code],
    [name],
    [city],
    [createdate],
    [distributor_id],
    [account_id],
    [account_trading_term],
    [regency_id],
    [created_at],
    [updated_at],
    [status],
    [desc],
    [btp],
    [top],
    [credit_limit],
    [GFcode]
) VALUES (
    'BMPG2/340', -- code
    'LAPAN KOPI', -- name
    'PALEMBANG', -- city
    '23/02/2026', -- createdate
    '32', -- distributor_id
    '59', -- account_id
    'ATT-KOSONG', -- account_trading_term
    '857', -- regency_id
    GETDATE(), -- created_at
    GETDATE(), -- updated_at
    'active', -- status
    '', -- desc
    '', -- btp
    '', -- top
    '', -- credit_limit
    ''  -- GFcode
);
