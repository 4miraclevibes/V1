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
    'Test', -- code
    'Test', -- name
    'Test', -- city
    '8/13/2025', -- createdate
    '1', -- distributor_id
    '1', -- account_id
    'TEST', -- account_trading_term
    '1', -- regency_id
    GETDATE(), -- created_at
    GETDATE(), -- updated_at
    'active', -- status
    '', -- desc
    '', -- btp
    '', -- top
    '', -- credit_limit
    ''  -- GFcode
);
