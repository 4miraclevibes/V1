-- =====================================================
-- MANUAL PATTERN ADDITIONS
-- untuk BTP yang tidak masuk otomatis karena issues
-- =====================================================

-- CASE: Invoice Number bikin match rate rendah
-- Setelah manual review, pattern sebenarnya konsisten
-- =====================================================

-- BTP 2300014763: DAVID TANTRIS OR F
-- Issue: Invoice number detected sebagai part of customer name
-- Real match rate: ~71% (karena 39 transaksi dengan invoice di depan)
-- Solution: Add manual dengan warning
INSERT INTO [dbo].[MASTER_CUSTOMER_BTP_PATTERN] 
    ([customer_name], [btp], [match_count], [total_transactions], [match_percentage])
VALUES
    ('DAVID TANTRIS OR F', '2300014763', 97, 136, 71.32);
-- ⚠️ WARNING: Match 71.32% (below 80%, use with caution)


-- BTP 2300010747: NG SIOE HOH  
-- Issue: Variasi dengan/tanpa invoice number
-- Solution: Add both variations
INSERT INTO [dbo].[MASTER_CUSTOMER_BTP_PATTERN] 
    ([customer_name], [btp], [match_count], [total_transactions], [match_percentage])
VALUES
    ('NG SIOE HOH', '2300010747', 1, 2, 50.00);
-- ⚠️ WARNING: Only 50% match (very low confidence)


-- NOTE: Entries di atas untuk TESTING purposes
-- Di production, sebaiknya:
-- 1. Fix extraction algorithm untuk strip invoice number
-- 2. Regenerate master data dengan logic yang lebih baik
-- 3. Data cleansing untuk standardize format

-- =====================================================
-- TESTING: Load manual patterns
-- =====================================================
-- :r add_manual_pattern.sql

