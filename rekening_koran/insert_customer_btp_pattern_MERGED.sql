-- =====================================================
-- MERGED CUSTOMER → BTP MAPPING
-- =====================================================
-- Merged from multiple sources:
-- - insert_customer_btp_pattern_70pct.sql (2219 patterns)
-- - insert_customer_btp_pattern.sql (2201 patterns)
-- - insert_customer_btp_pattern_70pct_PLUS.sql (2223 patterns)
-- - add_missing_patterns.sql (750 patterns)
-- Total unique patterns: 4
-- Match rate threshold: >=70%
-- Minimum transactions: 1
-- =====================================================

INSERT INTO customer_btp_pattern (customer_name, btp, match_count, total_transactions, match_percentage) VALUES
    ('WS95051 455520.00 ASIA GARMENT', 'S ACC', 0, 15, 100.00),
    ('ALMARIANTHI LA', 'LAN', 0, 9, 100.00),
    ('MA', 'RIFATUL FAUZIYA', 0, 9, 100.00),
    ('ABDILLAH SAFA', 'AT', 0, 7, 100.00);
