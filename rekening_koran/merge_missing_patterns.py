#!/usr/bin/env python3
"""
Script untuk menggabungkan missing patterns ke master data
"""

import re

def convert_missing_patterns():
    """Convert missing patterns format ke format master data"""
    
    # Read missing patterns
    with open('add_missing_patterns.sql', 'r') as f:
        content = f.read()
    
    # Extract INSERT VALUES section
    lines = content.split('\n')
    insert_started = False
    missing_patterns = []
    
    for line in lines:
        line = line.strip()
        if 'INSERT INTO' in line and 'VALUES' in line:
            insert_started = True
            continue
        if insert_started and line.startswith('(') and line.endswith('),'):
            # Parse: ('customer_name', 'btp', count, count, percentage),
            match = re.match(r"\('([^']+)', '([^']+)', (\d+), (\d+), ([\d.]+)\),", line)
            if match:
                customer_name, btp, match_count, total_trans, match_pct = match.groups()
                # Convert to master data format
                formatted_line = f"    ('{customer_name}', '{btp}', {match_count}, {total_trans}, {match_pct}),"
                missing_patterns.append(formatted_line)
    
    return missing_patterns

def merge_to_master_data():
    """Gabung missing patterns ke master data"""
    
    # Read master data
    with open('insert_customer_btp_pattern_70pct_PLUS.sql', 'r') as f:
        master_content = f.read()
    
    # Get missing patterns
    missing_patterns = convert_missing_patterns()
    
    # Find the last VALUES line in master data
    lines = master_content.split('\n')
    new_lines = []
    last_values_line = -1
    
    for i, line in enumerate(lines):
        new_lines.append(line)
        if line.strip().startswith('(') and line.strip().endswith('),'):
            last_values_line = i
    
    # Insert missing patterns before the last VALUES line
    if last_values_line >= 0:
        # Remove the last comma from the last VALUES line
        last_line = new_lines[last_values_line]
        if last_line.strip().endswith('),'):
            new_lines[last_values_line] = last_line[:-1]  # Remove last comma
        
        # Add missing patterns
        for pattern in missing_patterns:
            new_lines.insert(last_values_line + 1, pattern)
        
        # Add the final semicolon
        new_lines.append(';')
    
    # Write updated master data
    with open('insert_customer_btp_pattern_70pct_PLUS.sql', 'w') as f:
        f.write('\n'.join(new_lines))
    
    print(f"✅ Successfully merged {len(missing_patterns)} missing patterns!")
    print(f"📊 Total patterns now: 2219 + {len(missing_patterns)} = {2219 + len(missing_patterns)}")

if __name__ == "__main__":
    merge_to_master_data()
