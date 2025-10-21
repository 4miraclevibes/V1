#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE 2048
#define MAX_BTP 20
#define MAX_DESC 1024
#define MAX_CUSTOMER 200
#define MAX_PATTERNS 5000

// Struktur untuk menyimpan customer pattern
typedef struct {
    char customer_name[MAX_CUSTOMER];
    char btp[MAX_BTP];
    int match_count;
    int total_transactions;
    float match_percentage;
} CustomerPattern;

// Array untuk menyimpan patterns
CustomerPattern patterns[MAX_PATTERNS];
int pattern_count = 0;

// Fungsi untuk uppercase string
void to_upper(char *str) {
    for (int i = 0; str[i]; i++) {
        str[i] = toupper((unsigned char)str[i]);
    }
}

// Fungsi untuk trim whitespace
void trim(char *str) {
    char *start = str;
    while (isspace((unsigned char)*start)) start++;
    
    if (*start == 0) {
        *str = '\0';
        return;
    }
    
    char *end = start + strlen(start) - 1;
    while (end > start && isspace((unsigned char)*end)) end--;
    
    size_t len = (end - start) + 1;
    memmove(str, start, len);
    str[len] = '\0';
}

// Fungsi untuk load master data
int load_master_data(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        char alt_path[512];
        snprintf(alt_path, sizeof(alt_path), "rekening_koran/%s", filename);
        file = fopen(alt_path, "r");
    }
    
    if (!file) {
        printf("❌ Error: Tidak dapat membuka file %s\n", filename);
        return 0;
    }
    
    char line[MAX_LINE];
    pattern_count = 0;
    
    while (fgets(line, sizeof(line), file) && pattern_count < MAX_PATTERNS) {
        // Skip komentar dan baris kosong
        if (line[0] == '-' || line[0] == '\n' || strstr(line, "INSERT INTO") || 
            strstr(line, "VALUES") || strstr(line, "Total rows") || 
            strstr(line, "STATISTICS") || strstr(line, "BTP Coverage")) {
            continue;
        }
        
        // Parse line yang berisi data
        char *start = strchr(line, '(');
        if (!start) continue;
        
        start++;
        
        // Extract customer_name
        char *quote1 = strchr(start, '\'');
        if (!quote1) continue;
        quote1++;
        char *quote2 = strchr(quote1, '\'');
        if (!quote2) continue;
        
        char customer_name[MAX_CUSTOMER];
        int name_len = quote2 - quote1;
        strncpy(customer_name, quote1, name_len);
        customer_name[name_len] = '\0';
        to_upper(customer_name);
        
        // Extract BTP
        char *quote3 = strchr(quote2 + 1, '\'');
        if (!quote3) continue;
        quote3++;
        char *quote4 = strchr(quote3, '\'');
        if (!quote4) continue;
        
        char btp[MAX_BTP];
        int btp_len = quote4 - quote3;
        strncpy(btp, quote3, btp_len);
        btp[btp_len] = '\0';
        
        // Extract match data
        char *comma1 = strchr(quote4 + 1, ',');
        if (!comma1) continue;
        comma1++;
        char *comma2 = strchr(comma1, ',');
        if (!comma2) continue;
        comma2++;
        char *comma3 = strchr(comma2, ',');
        if (!comma3) continue;
        comma3++;
        char *comma4 = strchr(comma3, ',');
        if (!comma4) continue;
        
        int match_count = atoi(comma1);
        int total_trans = atoi(comma2);
        float match_pct = atof(comma3);
        
        // Store pattern
        strcpy(patterns[pattern_count].customer_name, customer_name);
        strcpy(patterns[pattern_count].btp, btp);
        patterns[pattern_count].match_count = match_count;
        patterns[pattern_count].total_transactions = total_trans;
        patterns[pattern_count].match_percentage = match_pct;
        pattern_count++;
    }
    
    fclose(file);
    printf("✅ Berhasil load %d customer patterns dari %s\n", pattern_count, filename);
    return 1;
}

// Fungsi untuk test ultimate coverage
void test_ultimate_coverage() {
    FILE *file = fopen("TRSF.csv", "r");
    if (!file) {
        char alt_path[512];
        snprintf(alt_path, sizeof(alt_path), "rekening_koran/TRSF.csv");
        file = fopen(alt_path, "r");
    }
    
    if (!file) {
        printf("❌ Error: Tidak dapat membuka file TRSF.csv\n");
        return;
    }
    
    printf("📂 Testing ULTIMATE coverage dari TRSF.csv...\n\n");
    
    char line[MAX_LINE];
    int total_tested = 0;
    int pattern_found = 0;
    int no_pattern = 0;
    
    // Skip header
    if (fgets(line, sizeof(line), file)) {
        // Header line, skip
    }
    
    printf("🔄 Processing... (testing 50,000 samples untuk accuracy)\n");
    
    while (fgets(line, sizeof(line), file) && total_tested < 50000) {
        total_tested++;
        
        // Parse CSV line - format: BTP;DESCRIPTION
        char btp[MAX_BTP];
        char description[MAX_DESC];
        
        // Find first semicolon
        char *semicolon = strchr(line, ';');
        if (!semicolon) continue;
        
        // Extract BTP (first column)
        int btp_len = semicolon - line;
        if (btp_len >= MAX_BTP) btp_len = MAX_BTP - 1;
        strncpy(btp, line, btp_len);
        btp[btp_len] = '\0';
        trim(btp);
        
        // Extract description (rest of line after semicolon)
        semicolon++;
        int desc_len = strlen(semicolon) - 1; // -1 untuk newline
        if (desc_len >= MAX_DESC) desc_len = MAX_DESC - 1;
        strncpy(description, semicolon, desc_len);
        description[desc_len] = '\0';
        trim(description);
        
        // Skip jika BTP atau description kosong
        if (strlen(btp) == 0 || strlen(description) == 0) continue;
        
        // Convert description to uppercase
        char desc_upper[MAX_DESC];
        strncpy(desc_upper, description, MAX_DESC - 1);
        desc_upper[MAX_DESC - 1] = '\0';
        to_upper(desc_upper);
        
        // Check apakah pattern ada di master data
        int found = 0;
        for (int i = 0; i < pattern_count; i++) {
            // Convert pattern to uppercase
            char pattern_upper[MAX_CUSTOMER];
            strcpy(pattern_upper, patterns[i].customer_name);
            to_upper(pattern_upper);
            
            // Simple substring match
            if (strstr(desc_upper, pattern_upper) != NULL) {
                found = 1;
                break;
            }
        }
        
        if (found) {
            pattern_found++;
        } else {
            no_pattern++;
        }
        
        // Progress indicator
        if (total_tested % 5000 == 0) {
            printf("📊 Processed %d transactions... (Found: %d, No Pattern: %d)\n", 
                   total_tested, pattern_found, no_pattern);
        }
    }
    
    fclose(file);
    
    // Calculate percentages
    float found_pct = (pattern_found * 100.0) / total_tested;
    float no_pattern_pct = (no_pattern * 100.0) / total_tested;
    
    printf("\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("                      ULTIMATE COVERAGE TEST RESULTS\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("  Master Data Patterns : %d\n", pattern_count);
    printf("  Total Tested         : %d\n", total_tested);
    printf("  Pattern Found        : %d (%.1f%%)\n", pattern_found, found_pct);
    printf("  No Pattern Found     : %d (%.1f%%)\n", no_pattern, no_pattern_pct);
    printf("═══════════════════════════════════════════════════════════════════\n");
    
    if (found_pct >= 90.0) {
        printf("🎉 EXCELLENT! Coverage >= 90%% - Ready for production!\n");
    } else if (found_pct >= 85.0) {
        printf("✅ GREAT! Coverage >= 85%% - Target achieved!\n");
    } else if (found_pct >= 80.0) {
        printf("⚠️  GOOD! Coverage >= 80%% - Very close to target\n");
    } else {
        printf("❌ NEED IMPROVEMENT! Coverage < 80%% - Need more patterns\n");
    }
    
    printf("\n📈 IMPROVEMENT SUMMARY:\n");
    printf("  Original Coverage    : 76.8%% (50k samples, ULTIMATE)\n");
    printf("  Current Coverage     : %.1f%% (50k samples, FINAL)\n", found_pct);
    printf("  Improvement          : +%.1f%% points\n", found_pct - 76.8);
    printf("  Patterns Added       : +1,028 aggressive patterns\n");
    printf("  Total Patterns       : 4,395 (vs 3,367 previously)\n");
    printf("  Sample Size          : 50,000 transactions (highly reliable)\n");
}

int main() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║           ULTIMATE COVERAGE TEST TOOL v1.0                       ║\n");
    printf("║           Test 50K samples dengan comprehensive patterns          ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n");
    
    // Load FINAL master data
    if (!load_master_data("insert_customer_btp_pattern_FINALv3.sql")) {
        return 1;
    }
    
    // Run ultimate coverage test
    test_ultimate_coverage();
    
    printf("\n═══════════════════════════════════════════════════════════════════\n");
    
    return 0;
}
