-- Check distributor data before and after update
-- This script helps verify the data before making changes

-- Check current data with distributor_id = 138
SELECT 
    'BEFORE UPDATE' as 'Status',
    COUNT(*) as 'Record Count',
    distributor_id
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
WHERE distributor_id = '138'
GROUP BY distributor_id;

-- Check current data with distributor_id = 10280
SELECT 
    'BEFORE UPDATE' as 'Status',
    COUNT(*) as 'Record Count',
    distributor_id
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
WHERE distributor_id = '10280'
GROUP BY distributor_id;

-- Show sample records with distributor_id = 138
SELECT TOP 5
    code,
    name,
    city,
    distributor_id,
    created_at,
    updated_at
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
WHERE distributor_id = '138'
ORDER BY created_at DESC;

-- Show sample records with distributor_id = 10280 (if any exist)
SELECT TOP 5
    code,
    name,
    city,
    distributor_id,
    created_at,
    updated_at
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
WHERE distributor_id = '10280'
ORDER BY created_at DESC;
