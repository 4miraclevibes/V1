-- Update distributor_id ke 10278 untuk customer dengan code yang ditentukan
UPDATE [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
SET distributor_id = 10278
WHERE code IN (
    'COGJKS_000167',
    'COGJKS_000205', 
    'COGJKS_001210',
    'COGJKS_001951',
    'COGJKS_002002',
    'COGJKS_002276',
    'COGJKS_004066',
    'COGJKS_004230',
    'COGJKS_004348',
    'COGJKS_004447',
    'COGJKS_004565'
)
GO