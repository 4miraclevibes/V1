#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE 2048
#define MAX_BTP 20
#define MAX_DESC 1024
#define MAX_CUSTOMER 200
#define MAX_PATTERNS 5000
#define MAX_NO_PATTERN 1000

// Struktur untuk menyimpan customer pattern
typedef struct {
    char customer_name[MAX_CUSTOMER];
    char btp[MAX_BTP];
    int match_count;
    int total_transactions;
    float match_percentage;
} CustomerPattern;

// Struktur untuk menyimpan NO PATTERN cases
typedef struct {
    char btp[MAX_BTP];
    char description[MAX_DESC];
    char extracted_customer[MAX_CUSTOMER];
} NoPatternCase;

// Arrays
CustomerPattern patterns[MAX_PATTERNS];
int pattern_count = 0;

NoPatternCase no_pattern_cases[MAX_NO_PATTERN];
int no_pattern_count = 0;

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
    printf("✅ Berhasil load %d customer patterns\n", pattern_count);
    return 1;
}

// Fungsi untuk extract customer name (improved version)
void extract_customer_from_description(const char *description, char *customer_name) {
    char desc_upper[MAX_DESC];
    strncpy(desc_upper, description, MAX_DESC - 1);
    desc_upper[MAX_DESC - 1] = '\0';
    to_upper(desc_upper);
    
    // Split description menjadi words
    char words[100][50];
    int word_count = 0;
    
    char desc_copy[MAX_DESC];
    strcpy(desc_copy, desc_upper);
    char *token = strtok(desc_copy, " ");
    while (token != NULL && word_count < 100) {
        strncpy(words[word_count], token, 49);
        words[word_count][49] = '\0';
        word_count++;
        token = strtok(NULL, " ");
    }
    
    // Cari ALL CAPS sequence di akhir (customer name)
    char potential_names[10][200];
    int name_count = 0;
    
    for (int start = 0; start < word_count && name_count < 10; start++) {
        for (int end = start; end < word_count && name_count < 10; end++) {
            // Build sequence dari start ke end
            char sequence[200] = "";
            int word_count_in_seq = 0;
            
            for (int i = start; i <= end; i++) {
                // Check apakah word ini ALL CAPS dan minimal 3 karakter
                int is_all_caps = 1;
                int has_letter = 0;
                
                for (int j = 0; words[i][j]; j++) {
                    if (isalpha(words[i][j])) {
                        has_letter = 1;
                        if (!isupper(words[i][j])) {
                            is_all_caps = 0;
                            break;
                        }
                    }
                }
                
                if (is_all_caps && has_letter && strlen(words[i]) >= 3) {
                    // Skip metadata bank dan amount
                    if (strstr(words[i], "TRSF") || strstr(words[i], "E-BANKING") || 
                        strstr(words[i], "CR") || strstr(words[i], "FTSCY") ||
                        strstr(words[i], "WS95") || strstr(words[i], "WS") ||
                        strstr(words[i], "ACSCY") || strstr(words[i], "ATSCY") ||
                        strstr(words[i], "ATBLK") || strstr(words[i], "ACBCA") ||
                        (strlen(words[i]) >= 6 && strstr(words[i], "."))) {
                        break;
                    }
                    
                    if (word_count_in_seq > 0) {
                        char temp[200];
                        snprintf(temp, sizeof(temp), "%s %s", sequence, words[i]);
                        strncpy(sequence, temp, sizeof(sequence) - 1);
                        sequence[sizeof(sequence) - 1] = '\0';
                    } else {
                        strncpy(sequence, words[i], sizeof(sequence) - 1);
                        sequence[sizeof(sequence) - 1] = '\0';
                    }
                    word_count_in_seq++;
                } else {
                    break;
                }
            }
            
            // Add sequence jika cukup panjang dan bermakna
            if (word_count_in_seq > 0 && strlen(sequence) >= 6) {
                strncpy(potential_names[name_count], sequence, 199);
                potential_names[name_count][199] = '\0';
                name_count++;
            }
        }
    }
    
    // Ambil sequence terpanjang sebagai customer name
    if (name_count > 0) {
        int longest_idx = 0;
        int longest_len = strlen(potential_names[0]);
        
        for (int i = 1; i < name_count; i++) {
            if (strlen(potential_names[i]) > longest_len) {
                longest_len = strlen(potential_names[i]);
                longest_idx = i;
            }
        }
        
        strncpy(customer_name, potential_names[longest_idx], MAX_CUSTOMER - 1);
        customer_name[MAX_CUSTOMER - 1] = '\0';
    } else {
        strcpy(customer_name, "UNKNOWN");
    }
}

// Fungsi untuk analyze NO PATTERN cases
void analyze_no_pattern_cases() {
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
    
    printf("📂 Analyzing NO PATTERN cases dari TRSF.csv...\n\n");
    
    char line[MAX_LINE];
    int total_processed = 0;
    int found_count = 0;
    int no_pattern_count = 0;
    
    // Skip header
    if (fgets(line, sizeof(line), file)) {
        // Header line, skip
    }
    
    printf("🔄 Processing... (analyzing first 5,000 transactions)\n");
    
    while (fgets(line, sizeof(line), file) && total_processed < 5000 && no_pattern_count < MAX_NO_PATTERN) {
        total_processed++;
        
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
        
        // Extract customer name dari description
        char customer_name[MAX_CUSTOMER];
        extract_customer_from_description(description, customer_name);
        
        // Skip jika customer name tidak valid
        if (strcmp(customer_name, "UNKNOWN") == 0 || strlen(customer_name) < 6) {
            no_pattern_count++;
            continue;
        }
        
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
            found_count++;
        } else {
            // Store NO PATTERN case
            if (no_pattern_count < MAX_NO_PATTERN) {
                strcpy(no_pattern_cases[no_pattern_count].btp, btp);
                strcpy(no_pattern_cases[no_pattern_count].description, description);
                strcpy(no_pattern_cases[no_pattern_count].extracted_customer, customer_name);
                no_pattern_count++;
            }
        }
        
        // Progress indicator
        if (total_processed % 1000 == 0) {
            printf("📊 Processed %d transactions... (Found: %d, No Pattern: %d)\n", 
                   total_processed, found_count, no_pattern_count);
        }
    }
    
    fclose(file);
    
    // Analyze NO PATTERN cases
    printf("\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("                      NO PATTERN ANALYSIS\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("  Total Processed    : %d\n", total_processed);
    printf("  Pattern Found      : %d (%.1f%%)\n", found_count, (found_count * 100.0) / total_processed);
    printf("  No Pattern Cases   : %d (%.1f%%)\n", no_pattern_count, (no_pattern_count * 100.0) / total_processed);
    printf("═══════════════════════════════════════════════════════════════════\n");
    
    // Show sample NO PATTERN cases
    printf("\n🔍 SAMPLE NO PATTERN CASES:\n");
    printf("───────────────────────────────────────────────────────────────────\n");
    
    int sample_count = no_pattern_count > 20 ? 20 : no_pattern_count;
    for (int i = 0; i < sample_count; i++) {
        printf("[%d] BTP: %s\n", i + 1, no_pattern_cases[i].btp);
        printf("    Extracted: %s\n", no_pattern_cases[i].extracted_customer);
        printf("    Description: %.100s...\n", no_pattern_cases[i].description);
        printf("\n");
    }
    
    // Generate potential missing patterns
    printf("💡 POTENTIAL MISSING PATTERNS:\n");
    printf("───────────────────────────────────────────────────────────────────\n");
    
    FILE *output_file = fopen("potential_missing_patterns.sql", "w");
    if (output_file) {
        fprintf(output_file, "-- POTENTIAL MISSING PATTERNS\n");
        fprintf(output_file, "-- Generated from NO PATTERN analysis\n");
        fprintf(output_file, "-- Total potential patterns: %d\n\n", no_pattern_count);
        
        for (int i = 0; i < no_pattern_count; i++) {
            fprintf(output_file, "-- BTP: %s\n", no_pattern_cases[i].btp);
            fprintf(output_file, "-- Extracted: %s\n", no_pattern_cases[i].extracted_customer);
            fprintf(output_file, "-- Description: %.100s\n", no_pattern_cases[i].description);
            fprintf(output_file, "INSERT INTO customer_btp_pattern (customer_name, btp, match_count, total_transactions, match_percentage) VALUES ('%s', '%s', 1, 1, 100.00);\n\n",
                    no_pattern_cases[i].extracted_customer, no_pattern_cases[i].btp);
        }
        
        fclose(output_file);
        printf("✅ Generated potential_missing_patterns.sql with %d patterns\n", no_pattern_count);
    }
}

int main() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║           NO PATTERN ANALYSIS TOOL v1.0                          ║\n");
    printf("║           Analyze cases that result in NO PATTERN                 ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n");
    
    // Load master data
    if (!load_master_data("insert_customer_btp_pattern_70pct_PLUS.sql")) {
        return 1;
    }
    
    // Analyze NO PATTERN cases
    analyze_no_pattern_cases();
    
    printf("\n═══════════════════════════════════════════════════════════════════\n");
    
    return 0;
}
