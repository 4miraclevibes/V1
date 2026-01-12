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
    '15A00190', -- code
    'Askara Coffee Roastery', -- name
    'SURABAYA', -- city
    '10/22/2025', -- createdate
    '18', -- distributor_id
    '59', -- account_id
    'OTHER-CAFE', -- account_trading_term
    '297', -- regency_id
    GETDATE(), -- created_at
    GETDATE(), -- updated_at
    'active', -- status
    '', -- desc
    '', -- btp
    '', -- top
    '', -- credit_limit
    ''  -- GFcode
);
