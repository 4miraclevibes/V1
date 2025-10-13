#!/usr/bin/env python3
"""
Clean Master Data - Remove duplicate patterns with invoice codes
"""

import re

def parse_existing_sql(sql_content):
    """Parse existing SQL file and extract patterns"""
    patterns = []
    # Regex to find VALUES tuples
    matches = re.findall(r"\('([^']*)', '([^']*)', (\d+), (\d+), ([\d.]+)\)", sql_content)
    for match in matches:
        patterns.append({
            'customer_name': match[0],
            'btp': match[1],
            'match_count': int(match[2]),
            'total_transactions': int(match[3]),
            'match_percentage': float(match[4])
        })
    return patterns

def has_invoice_code(customer_name):
    """Check if customer name contains invoice code or transaction code"""
    # Check for common invoice/transaction patterns
    patterns = [
        r'INV/',           # Invoice prefix
        r'^C\d[A-Z]Z',     # Transaction codes starting with C1JZ, C2AZ, etc
        r'^C[A-Z]Z\d',     # Transaction codes like CBZ01231204133
        r'^N\d{7}',        # Transaction codes like N7120477
        r'WS\d{5}',        # Bank codes like WS95031
        r'^\w+\d{6,}\s',   # Codes with 6+ digits at start (TZ00124011798)
        r'REF:',           # Reference codes
        r'K\d{10,}',       # K codes like K002000009352
        r'N\d{4,}\s',      # N codes like N7025763
    ]
    
    for pattern in patterns:
        if re.search(pattern, customer_name):
            return True
    return False

def consolidate_patterns(patterns):
    """Consolidate patterns - keep clean names, remove duplicates with codes"""
    # Group by BTP
    btp_groups = {}
    for p in patterns:
        btp = p['btp']
        if btp not in btp_groups:
            btp_groups[btp] = []
        btp_groups[btp].append(p)
    
    # For each BTP, keep only clean patterns
    cleaned_patterns = []
    removed_count = 0
    
    for btp, group in btp_groups.items():
        # Separate clean and dirty patterns
        clean_patterns = [p for p in group if not has_invoice_code(p['customer_name'])]
        dirty_patterns = [p for p in group if has_invoice_code(p['customer_name'])]
        
        # If we have clean patterns, keep them and remove dirty ones
        if clean_patterns:
            # Keep clean patterns
            cleaned_patterns.extend(clean_patterns)
            removed_count += len(dirty_patterns)
            
            if dirty_patterns:
                print(f"🧹 BTP {btp}: Kept {len(clean_patterns)} clean, removed {len(dirty_patterns)} dirty")
                print(f"   Clean: {[p['customer_name'] for p in clean_patterns[:3]]}")
                if len(dirty_patterns) <= 3:
                    print(f"   Removed: {[p['customer_name'] for p in dirty_patterns]}")
                else:
                    print(f"   Removed: {len(dirty_patterns)} patterns with invoice codes")
        else:
            # No clean patterns, keep all (might be legitimate)
            cleaned_patterns.extend(group)
    
    return cleaned_patterns, removed_count

def generate_sql_output(patterns):
    """Generate SQL INSERT statements"""
    lines = []
    lines.append("-- =====================================================")
    lines.append("-- INSERT STATEMENTS: CUSTOMER → BTP MAPPING")
    lines.append("-- CLEANED VERSION - No invoice codes")
    lines.append("-- =====================================================")
    lines.append(f"-- Total entries: {len(patterns)}")
    lines.append("-- Match rate threshold: ≥70%")
    lines.append("-- Minimum transactions: 1")
    lines.append("-- =====================================================")
    lines.append("")
    lines.append("INSERT INTO [dbo].[MASTER_CUSTOMER_BTP_PATTERN]")
    lines.append("    ([customer_name], [btp], [match_count], [total_transactions], [match_percentage])")
    lines.append("VALUES")
    
    # Generate VALUES tuples
    values_lines = []
    for p in patterns:
        values_lines.append(f"    ('{p['customer_name']}', '{p['btp']}', {p['match_count']}, {p['total_transactions']}, {p['match_percentage']:.2f})")
    
    lines.append(",\n".join(values_lines) + ";")
    lines.append("")
    lines.append(f"-- Total rows inserted: {len(patterns)}")
    
    return "\n".join(lines)

def main():
    print("\n╔═══════════════════════════════════════════════════════════════════╗")
    print("║                                                                   ║")
    print("║        CLEAN MASTER DATA TOOL v1.0                               ║")
    print("║        Remove duplicate patterns with invoice codes              ║")
    print("║                                                                   ║")
    print("╚═══════════════════════════════════════════════════════════════════╝\n")
    
    # Read master data
    input_file = "insert_customer_btp_pattern_70pct_PLUS.sql"
    output_file = "insert_customer_btp_pattern_CLEAN.sql"
    
    print(f"📂 Reading master data from: {input_file}")
    with open(input_file, 'r') as f:
        content = f.read()
    
    # Parse patterns
    print("🔍 Parsing patterns...")
    patterns = parse_existing_sql(content)
    print(f"✅ Found {len(patterns)} patterns\n")
    
    # Consolidate patterns
    print("🧹 Cleaning patterns...")
    cleaned_patterns, removed_count = consolidate_patterns(patterns)
    print(f"\n✅ Cleaning complete!")
    print(f"   Original patterns: {len(patterns)}")
    print(f"   Cleaned patterns: {len(cleaned_patterns)}")
    print(f"   Removed patterns: {removed_count}\n")
    
    # Generate SQL output
    print(f"📝 Generating cleaned SQL file...")
    sql_output = generate_sql_output(cleaned_patterns)
    
    with open(output_file, 'w') as f:
        f.write(sql_output)
    
    print(f"✅ Cleaned SQL saved to: {output_file}\n")
    print("💡 NEXT STEPS:")
    print("   1. Review cleaned patterns")
    print("   2. Use CLEAN file as base for aggressive missing patterns")
    print("   3. Regenerate FINAL master data")
    print("   4. Test coverage again\n")
    print("═══════════════════════════════════════════════════════════════════\n")

if __name__ == "__main__":
    main()

