-- Update distributor_id from 138 to 10280
-- This script updates all customers with distributor_id = 138 to distributor_id = 10280

-- Update MP_CUSTOMER_NEW table
UPDATE [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
SET 
    distributor_id = '10280',
    updated_at = GETDATE()
WHERE distributor_id = '138';

-- Check how many records were updated
SELECT 
    COUNT(*) as 'Records Updated',
    'MP_CUSTOMER_NEW' as 'Table'
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
WHERE distributor_id = '10280'
AND updated_at >= DATEADD(minute, -5, GETDATE()); -- Records updated in last 5 minutes

-- Show sample of updated records
SELECT TOP 10
    code,
    name,
    city,
    distributor_id,
    updated_at
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
WHERE distributor_id = '10280'
ORDER BY updated_at DESC;

-- Optional: Update MP_CUSTOMER table if it exists and has the same structure
-- Uncomment the following lines if MP_CUSTOMER table also needs to be updated

/*
UPDATE [POWERAPPS].[dbo].[MP_CUSTOMER] 
SET 
    distributor_id = '10280',
    updated_at = GETDATE()
WHERE distributor_id = '138';

-- Check MP_CUSTOMER updates
SELECT 
    COUNT(*) as 'Records Updated',
    'MP_CUSTOMER' as 'Table'
FROM [POWERAPPS].[dbo].[MP_CUSTOMER] 
WHERE distributor_id = '10280'
AND updated_at >= DATEADD(minute, -5, GETDATE());
*/
