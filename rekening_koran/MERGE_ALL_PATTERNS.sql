-- =====================================================
-- MERGE ALL BANK PATTERNS INTO SINGLE TABLE
-- Script untuk menggabungkan semua 20 bank patterns
-- =====================================================

-- Create unified table structure
CREATE TABLE master_customer_btp_pattern (
    id INT IDENTITY(1,1) PRIMARY KEY,
    customer_name NVARCHAR(200) NOT NULL,
    btp NVARCHAR(100) NOT NULL,
    category NVARCHAR(50) NOT NULL,  -- NEW: Bank category
    match_count INT NOT NULL,
    total_transactions INT NOT NULL,
    match_percentage DECIMAL(5,2),
    last_line_number INT,
    created_date DATETIME DEFAULT GETDATE(),
    INDEX idx_category (category),
    INDEX idx_btp (btp),
    INDEX idx_customer (customer_name)
);

-- =====================================================
-- INSERT DATA FROM ALL BANKS
-- =====================================================

-- Uncomment dan run SQL files untuk setiap bank:
-- (Pastikan SQL files sudah include kolom 'category')

-- GROUP 1: Array[3] + Array[4] Extraction
-- -----------------------------------------
-- BNI (19 patterns)
-- :r pattern_generator_BNI/master_customer_btp_pattern_BNI.sql

-- BTPN (3 patterns)
-- :r pattern_generator_BTPN/master_customer_btp_pattern_BTPN.sql

-- MANDIRI (131 patterns)
-- :r pattern_generator_MANDIRI/master_customer_btp_pattern_MANDIRI.sql

-- BRI (27 patterns)
-- :r pattern_generator_BRI/master_customer_btp_pattern_BRI.sql

-- MEGA (8 patterns)
-- :r pattern_generator_MEGA/master_customer_btp_pattern_MEGA.sql

-- PERMATA (17 patterns)
-- :r pattern_generator_PERMATA/master_customer_btp_pattern_PERMATA.sql

-- DANAMON (18 patterns)
-- :r pattern_generator_DANAMON/master_customer_btp_pattern_DANAMON.sql

-- CITIBANK (15 patterns)
-- :r pattern_generator_CITIBANK/master_customer_btp_pattern_CITIBANK.sql

-- SINARMAS (5 patterns)
-- :r pattern_generator_SINARMAS/master_customer_btp_pattern_SINARMAS.sql


-- GROUP 2: Array[4] + Array[5] Extraction
-- -----------------------------------------
-- CIMB (97 patterns)
-- :r pattern_generator_CIMB/master_customer_btp_pattern_CIMB.sql

-- MAYBANK (15 patterns)
-- :r pattern_generator_MAYBANK/master_customer_btp_pattern_MAYBANK.sql

-- HSBC (23 patterns)
-- :r pattern_generator_HSBC/master_customer_btp_pattern_HSBC.sql

-- UOB (5 patterns)
-- :r pattern_generator_UOB/master_customer_btp_pattern_UOB.sql

-- MUAMALAT (1 pattern)
-- :r pattern_generator_MUAMALAT/master_customer_btp_pattern_MUAMALAT.sql

-- OCBC (6 patterns)
-- :r pattern_generator_OCBC/master_customer_btp_pattern_OCBC.sql

-- DBS (3 patterns)
-- :r pattern_generator_DBS/master_customer_btp_pattern_DBS.sql

-- CAPITAL (2 patterns)
-- :r pattern_generator_CAPITAL/master_customer_btp_pattern_CAPITAL.sql

-- WOORI (2 patterns)
-- :r pattern_generator_WOORI/master_customer_btp_pattern_WOORI.sql


-- GROUP 3: Special Logic (ALL CAPS after last number)
-- ----------------------------------------------------
-- TRSF (6900 patterns) ⭐ LARGE FILE - USE SPLIT VERSION!
-- Option 1 (RECOMMENDED): Use split file (7 batches of ~1000 rows)
-- :r pattern_generator_TRSF/master_customer_btp_pattern_TRSF_SPLIT.sql
-- 
-- Option 2: Use original file (1 large INSERT - may timeout)
-- :r pattern_generator_TRSF/master_customer_btp_pattern_TRSF.sql

-- BIFAST (763 patterns)
-- :r pattern_generator_BIFAST/master_customer_btp_pattern_BIFAST.sql


-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Total patterns by category
SELECT 
    category,
    COUNT(*) as pattern_count,
    AVG(match_percentage) as avg_match_rate,
    SUM(match_count) as total_matches
FROM master_customer_btp_pattern
GROUP BY category
ORDER BY pattern_count DESC;

-- Total summary
SELECT 
    COUNT(DISTINCT category) as total_banks,
    COUNT(*) as total_patterns,
    SUM(match_count) as total_transactions,
    AVG(match_percentage) as overall_match_rate
FROM master_customer_btp_pattern;

-- Top patterns across all banks
SELECT TOP 20
    customer_name,
    btp,
    category,
    match_count,
    match_percentage
FROM master_customer_btp_pattern
ORDER BY match_count DESC;

-- Find patterns in specific banks
SELECT * 
FROM master_customer_btp_pattern 
WHERE category IN ('BNI', 'MANDIRI', 'BRI')
ORDER BY category, match_count DESC;

-- Search by customer name across all banks
SELECT * 
FROM master_customer_btp_pattern 
WHERE customer_name LIKE '%KOPERASI%'
ORDER BY category;

-- Check duplicates across banks
SELECT 
    customer_name,
    btp,
    COUNT(DISTINCT category) as bank_count,
    STRING_AGG(category, ', ') as banks
FROM master_customer_btp_pattern
GROUP BY customer_name, btp
HAVING COUNT(DISTINCT category) > 1;

