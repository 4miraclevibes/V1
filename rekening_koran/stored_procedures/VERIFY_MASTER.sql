-- Verify Master SP structure

SELECT 
    p.name AS ProcedureName,
    p.create_date AS CreateDate,
    p.modify_date AS ModifyDate,
    LEN(OBJECT_DEFINITION(p.object_id)) AS DefinitionLength,
    CASE 
        WHEN LEN(OBJECT_DEFINITION(p.object_id)) > 35000 THEN '✅ New Version (20 banks)'
        WHEN LEN(OBJECT_DEFINITION(p.object_id)) > 15000 THEN '❌ Old Version (6 banks)'
        ELSE '❌ Very Old'
    END AS Version,
    SUBSTRING(OBJECT_DEFINITION(p.object_id), 1, 500) AS First500Chars
FROM sys.procedures p
WHERE p.name = 'SP_MASTER_FindBTP_Batch';

-- Check for CIMB in definition
PRINT '';
PRINT 'Checking if CIMB is in SP definition...';
IF EXISTS (
    SELECT 1 
    FROM sys.procedures p
    WHERE p.name = 'SP_MASTER_FindBTP_Batch'
      AND OBJECT_DEFINITION(p.object_id) LIKE '%CIMB%'
)
    PRINT '✅ CIMB found in SP!'
ELSE
    PRINT '❌ CIMB NOT found - SP not updated!';

-- Check for all 20 banks
PRINT '';
PRINT 'Checking all 20 banks...';
SELECT 
    'TRSF' AS BankName,
    CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''TRSF''%' THEN '✅' ELSE '❌' END AS Found
FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'BIFAST', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''BIFAST''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'MANDIRI', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''MANDIRI''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'BNI', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''BNI''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'BTPN', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''BTPN''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'BRI', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''BRI''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'MEGA', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''MEGA''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'PERMATA', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''PERMATA''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'DANAMON', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''DANAMON''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'CITIBANK', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''CITIBANK''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'SINARMAS', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''SINARMAS''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'CIMB', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''CIMB''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'MAYBANK', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''MAYBANK''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'HSBC', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''HSBC''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'UOB', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''UOB''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'MUAMALAT', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''MUAMALAT''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'OCBC', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''OCBC''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'DBS', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''DBS''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'CAPITAL', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''CAPITAL''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch'
UNION ALL
SELECT 'WOORI', CASE WHEN OBJECT_DEFINITION(p.object_id) LIKE '%''WOORI''%' THEN '✅' ELSE '❌' END FROM sys.procedures p WHERE p.name = 'SP_MASTER_FindBTP_Batch';

