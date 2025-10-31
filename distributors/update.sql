-- Update distributor_id ke 10278 untuk customer dengan code yang ditentukan
UPDATE [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
SET distributor_id = 138
WHERE code IN (
    'INUL-0008',
    'KSGY-0008',
    'INIF-0002',
    'INUW-0057'
);
GO