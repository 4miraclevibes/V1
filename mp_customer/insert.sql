INSERT INTO [POWERAPPS].[dbo].[MP_CUSTOMER] (
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
    'COGLPG_013508', -- code
    'KOPERASI PPLHI LAMPUNG', -- name
    'LAMPUNG', -- city
    '8/13/2025', -- createdate
    '60', -- distributor_id
    '83', -- account_id
    'ATT-KOSONG', -- account_trading_term
    '500', -- regency_id
    GETDATE(), -- created_at
    GETDATE(), -- updated_at
    'active', -- status
    '', -- desc
    '', -- btp
    '', -- top
    '', -- credit_limit
    ''  -- GFcode
);
