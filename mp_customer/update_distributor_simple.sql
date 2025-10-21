-- Simple update: Change distributor_id from 138 to 10280
-- Execute this script to update all customers with distributor_id = 138

UPDATE [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
SET 
    distributor_id = '10280',
    updated_at = GETDATE()
WHERE distributor_id = '138';

-- Verify the update
SELECT COUNT(*) as 'Total Records with distributor_id = 10280' 
FROM [POWERAPPS].[dbo].[MP_CUSTOMER_NEW] 
WHERE distributor_id = '10280';
