═══════════════════════════════════════════════════════════════════
  TRSF PATTERNS - SPLIT FILE USAGE GUIDE
═══════════════════════════════════════════════════════════════════

📄 FILES AVAILABLE:
───────────────────────────────────────────────────────────────────

1. master_customer_btp_pattern_TRSF.sql
   • Original file with 6,900 patterns in ONE large INSERT
   • 497 KB
   • Use this if your SQL Server can handle large batches

2. master_customer_btp_pattern_TRSF_SPLIT.sql ⭐ RECOMMENDED
   • Split into 7 batches of ~1,000 rows each
   • 502 KB
   • Easier to import, less chance of timeout/memory errors


📊 SPLIT FILE STRUCTURE:
───────────────────────────────────────────────────────────────────

BATCH 1: Rows    1 -  1,000  (1,000 patterns)
BATCH 2: Rows 1,001 -  2,000  (1,000 patterns)
BATCH 3: Rows 2,001 -  3,000  (1,000 patterns)
BATCH 4: Rows 3,001 -  4,000  (1,000 patterns)
BATCH 5: Rows 4,001 -  5,000  (1,000 patterns)
BATCH 6: Rows 5,001 -  6,000  (1,000 patterns)
BATCH 7: Rows 6,001 -  6,900  (  900 patterns)

Total: 6,900 patterns


🚀 HOW TO IMPORT (Method 1: Manual Copy-Paste):
───────────────────────────────────────────────────────────────────

1. Open master_customer_btp_pattern_TRSF_SPLIT.sql in text editor

2. Find BATCH 1 section:
   -- ═════════════════════════════════════════════════════
   -- BATCH 1/7: Rows 1 to 1000
   -- ═════════════════════════════════════════════════════

3. Copy from "INSERT INTO" to the semicolon (;)
   Include ALL 1,000 rows in VALUES section

4. Paste and execute in SQL Server Management Studio

5. Wait for "1000 rows affected" message

6. Repeat for BATCH 2, 3, 4, 5, 6, 7

7. Done! Total 6,900 rows imported ✅


🚀 HOW TO IMPORT (Method 2: Execute Entire File):
───────────────────────────────────────────────────────────────────

Option A - SQL Server Management Studio:
1. Open → File → Open → master_customer_btp_pattern_TRSF_SPLIT.sql
2. Click Execute (F5)
3. All 7 batches will run sequentially
4. Check messages: Should show 7 separate "rows affected" messages

Option B - sqlcmd:
sqlcmd -S your_server -d your_database -i master_customer_btp_pattern_TRSF_SPLIT.sql


✅ VERIFICATION:
───────────────────────────────────────────────────────────────────

After import, verify count:

SELECT COUNT(*) 
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN]
WHERE category = 'TRSF';

Expected result: 6,900 rows


💡 TIPS:
───────────────────────────────────────────────────────────────────

• Each batch is independent - if one fails, others still work
• You can run batches in parallel if needed
• Clear separators (═══) make it easy to find each batch
• Each batch ends with semicolon (;)
• Progress markers: "-- ✅ Batch complete!"


⚠️ TROUBLESHOOTING:
───────────────────────────────────────────────────────────────────

Problem: "String or binary data would be truncated"
Solution: Check your table column sizes match the schema

Problem: "Timeout expired"
Solution: You're already using split file - good! Try increasing timeout

Problem: "Duplicate key error"
Solution: Clear table first or check for existing TRSF data

Problem: "Cannot insert NULL"
Solution: Ensure table structure includes 'category' column


📋 TABLE SCHEMA REQUIRED:
───────────────────────────────────────────────────────────────────

CREATE TABLE [dbo].[MASTER_CUSTOMER_BTP_PATTERN] (
    id INT IDENTITY(1,1) PRIMARY KEY,
    customer_name NVARCHAR(200) NOT NULL,
    btp NVARCHAR(100) NOT NULL,
    category NVARCHAR(50) NOT NULL,      -- NEW!
    match_count INT NOT NULL,
    total_transactions INT NOT NULL,
    match_percentage DECIMAL(5,2),
    last_line_number INT
);


🎯 QUICK STATS:
───────────────────────────────────────────────────────────────────

Bank Category: TRSF
Total Patterns: 6,900
File Format: SQL INSERT statements
Split into: 7 batches
Rows per batch: ~1,000 (last batch has 900)
Ready to import: YES ✅


═══════════════════════════════════════════════════════════════════
For questions or issues, refer to main documentation.
═══════════════════════════════════════════════════════════════════

