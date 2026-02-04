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
    'PKUD-0774', -- code
    'DBESTO', -- name
    'PEKANBARU', -- city
    '03/02/2026', -- createdate
    '138', -- distributor_id
    '63', -- account_id
    'ATT-KOSONG', -- account_trading_term
    '612', -- regency_id
    GETDATE(), -- created_at
    GETDATE(), -- updated_at
    'active', -- status
    '', -- desc
    '', -- btp
    '', -- top
    '', -- credit_limit
    ''  -- GFcode
);
