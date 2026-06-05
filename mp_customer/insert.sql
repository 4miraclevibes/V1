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
    'P008995', -- code
    'PT Dunkindo Cipta Raya', -- name
    'SURABAYA', -- city
    '02/06/2026', -- createdate
    '202', -- distributor_id
    '64', -- account_id
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
