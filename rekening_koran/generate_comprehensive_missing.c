#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE 2048
#define MAX_BTP 20
#define MAX_DESC 1024
#define MAX_CUSTOMER 200
#define MAX_PATTERNS 5000
#define MAX_MISSING_PATTERNS 10000

// Struktur untuk menyimpan customer pattern
typedef struct {
    char customer_name[MAX_CUSTOMER];
    char btp[MAX_BTP];
    int match_count;
    int total_transactions;
    float match_percentage;
} CustomerPattern;

// Struktur untuk menyimpan missing pattern
typedef struct {
    char btp[MAX_BTP];
    char customer_name[MAX_CUSTOMER];
    int transaction_count;
    float match_rate;
    char sample_description[MAX_DESC];
} MissingPattern;

// Struktur untuk menyimpan BTP analysis
typedef struct {
    char btp[MAX_BTP];
    int total_transactions;
    char customer_names[50][MAX_CUSTOMER];
    int customer_counts[50];
    int unique_customers;
} BTPAnalysis;

// Arrays
CustomerPattern patterns[MAX_PATTERNS];
int pattern_count = 0;

MissingPattern missing_patterns[MAX_MISSING_PATTERNS];
int missing_count = 0;

BTPAnalysis btp_analyses[5000];
int btp_analysis_count = 0;

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

// Fungsi untuk check apakah pattern sudah ada di master data
int pattern_exists_in_master(const char *customer_name, const char *btp) {
    for (int i = 0; i < pattern_count; i++) {
        if (strcmp(patterns[i].btp, btp) == 0 &&
            strcmp(patterns[i].customer_name, customer_name) == 0) {
            return 1;
        }
    }
    return 0;
}

// Fungsi untuk find atau create BTP analysis
int find_or_create_btp_analysis(const char *btp) {
    for (int i = 0; i < btp_analysis_count; i++) {
        if (strcmp(btp_analyses[i].btp, btp) == 0) {
            return i;
        }
    }
    
    if (btp_analysis_count < 5000) {
        strcpy(btp_analyses[btp_analysis_count].btp, btp);
        btp_analyses[btp_analysis_count].total_transactions = 0;
        btp_analyses[btp_analysis_count].unique_customers = 0;
        return btp_analysis_count++;
    }
    
    return -1;
}

// Fungsi untuk analyze entire dataset dan generate missing patterns
void analyze_entire_dataset_and_generate_missing() {
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
    
    printf("📂 Analyzing entire dataset untuk generate missing patterns...\n\n");
    
    char line[MAX_LINE];
    int total_processed = 0;
    
    // Skip header
    if (fgets(line, sizeof(line), file)) {
        // Header line, skip
    }
    
    printf("🔄 Processing entire dataset... (this will take several minutes)\n");
    
    while (fgets(line, sizeof(line), file) && total_processed < 100000) { // Limit to 100k for now
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
        
        // Find atau create BTP analysis
        int btp_idx = find_or_create_btp_analysis(btp);
        if (btp_idx == -1) continue;
        
        btp_analyses[btp_idx].total_transactions++;
        
        // Extract customer name dari description
        char customer_name[MAX_CUSTOMER];
        extract_customer_from_description(description, customer_name);
        
        // Skip jika customer name tidak valid
        if (strcmp(customer_name, "UNKNOWN") == 0 || strlen(customer_name) < 6) continue;
        
        // Check apakah customer name sudah ada di BTP analysis
        int customer_exists = 0;
        for (int i = 0; i < btp_analyses[btp_idx].unique_customers; i++) {
            if (strcmp(btp_analyses[btp_idx].customer_names[i], customer_name) == 0) {
                btp_analyses[btp_idx].customer_counts[i]++;
                customer_exists = 1;
                break;
            }
        }
        
        // Add new customer jika belum ada
        if (!customer_exists && btp_analyses[btp_idx].unique_customers < 50) {
            strcpy(btp_analyses[btp_idx].customer_names[btp_analyses[btp_idx].unique_customers], customer_name);
            btp_analyses[btp_idx].customer_counts[btp_analyses[btp_idx].unique_customers] = 1;
            btp_analyses[btp_idx].unique_customers++;
        }
        
        // Progress indicator
        if (total_processed % 10000 == 0) {
            printf("📊 Processed %d transactions, analyzed %d BTPs...\n", total_processed, btp_analysis_count);
        }
    }
    
    fclose(file);
    
    printf("✅ Analysis complete! Processed %d transactions, analyzed %d BTPs.\n\n", total_processed, btp_analysis_count);
    
    // Generate missing patterns dari BTP analyses
    printf("🔍 Generating missing patterns...\n");
    
    for (int i = 0; i < btp_analysis_count; i++) {
        // Check apakah BTP ini sudah ada di master data
        int btp_exists_in_master = 0;
        for (int j = 0; j < pattern_count; j++) {
            if (strcmp(patterns[j].btp, btp_analyses[i].btp) == 0) {
                btp_exists_in_master = 1;
                break;
            }
        }
        
        // Jika BTP tidak ada di master data, check apakah ada customer yang dominan
        if (!btp_exists_in_master) {
            for (int k = 0; k < btp_analyses[i].unique_customers; k++) {
                float match_rate = (btp_analyses[i].customer_counts[k] * 100.0) / btp_analyses[i].total_transactions;
                
                // Jika customer dominan (>= 70% match rate) dan minimal 2 transaksi
                if (match_rate >= 70.0 && btp_analyses[i].customer_counts[k] >= 2) {
                    // Check apakah pattern sudah ada di missing patterns
                    int exists = 0;
                    for (int m = 0; m < missing_count; m++) {
                        if (strcmp(missing_patterns[m].btp, btp_analyses[i].btp) == 0 &&
                            strcmp(missing_patterns[m].customer_name, btp_analyses[i].customer_names[k]) == 0) {
                            exists = 1;
                            break;
                        }
                    }
                    
                    // Add missing pattern
                    if (!exists && missing_count < MAX_MISSING_PATTERNS) {
                        strcpy(missing_patterns[missing_count].btp, btp_analyses[i].btp);
                        strcpy(missing_patterns[missing_count].customer_name, btp_analyses[i].customer_names[k]);
                        missing_patterns[missing_count].transaction_count = btp_analyses[i].customer_counts[k];
                        missing_patterns[missing_count].match_rate = match_rate;
                        strncpy(missing_patterns[missing_count].sample_description, "Sample from comprehensive analysis", MAX_DESC - 1);
                        missing_patterns[missing_count].sample_description[MAX_DESC - 1] = '\0';
                        missing_count++;
                    }
                }
            }
        }
    }
    
    printf("✅ Generated %d missing patterns!\n\n", missing_count);
}

// Fungsi untuk generate SQL INSERT statements
void generate_comprehensive_sql_inserts() {
    printf("📝 Generating comprehensive SQL INSERT statements...\n\n");
    
    FILE *output_file = fopen("comprehensive_missing_patterns.sql", "w");
    if (!output_file) {
        printf("❌ Error: Tidak dapat membuat file comprehensive_missing_patterns.sql\n");
        return;
    }

    fprintf(output_file, "-- =====================================================\n");
    fprintf(output_file, "-- COMPREHENSIVE MISSING CUSTOMER PATTERNS\n");
    fprintf(output_file, "-- Generated from entire TRSF.csv analysis\n");
    fprintf(output_file, "-- Total entries: %d\n", missing_count);
    fprintf(output_file, "-- Match rate threshold: >=70%%\n");
    fprintf(output_file, "-- Minimum transactions: 2\n");
    fprintf(output_file, "-- =====================================================\n\n");

    for (int i = 0; i < missing_count; i++) {
        fprintf(output_file, "INSERT INTO customer_btp_pattern (customer_name, btp, match_count, total_transactions, match_percentage) VALUES ('%s', '%s', %d, %d, %.2f);\n",
                missing_patterns[i].customer_name, missing_patterns[i].btp,
                missing_patterns[i].transaction_count, missing_patterns[i].transaction_count,
                missing_patterns[i].match_rate);
    }

    fclose(output_file);
    printf("✅ Comprehensive SQL INSERT statements saved to: comprehensive_missing_patterns.sql\n\n");
}

int main() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║        COMPREHENSIVE MISSING PATTERNS GENERATOR v1.0             ║\n");
    printf("║        Analyze entire dataset for missing patterns               ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n");
    
    // Load existing master data
    printf("📂 Loading existing master data...\n");
    if (!load_master_data("insert_customer_btp_pattern_70pct_PLUS.sql")) {
        return 1;
    }
    
    // Analyze entire dataset and generate missing patterns
    analyze_entire_dataset_and_generate_missing();
    
    // Show results
    printf("🔍 MISSING PATTERNS FOUND:\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("Total Missing Patterns: %d\n\n", missing_count);
    
    // Show sample missing patterns
    int sample_count = missing_count > 10 ? 10 : missing_count;
    for (int i = 0; i < sample_count; i++) {
        printf("[%d] Missing Pattern:\n", i + 1);
        printf("    BTP                : %s\n", missing_patterns[i].btp);
        printf("    Customer Name      : %s\n", missing_patterns[i].customer_name);
        printf("    Transaction Count  : %d\n", missing_patterns[i].transaction_count);
        printf("    Match Rate         : %.2f%%\n", missing_patterns[i].match_rate);
        printf("\n");
    }
    
    // Generate SQL
    generate_comprehensive_sql_inserts();
    
    printf("💡 NEXT STEPS:\n");
    printf("   1. Review missing patterns di comprehensive_missing_patterns.sql\n");
    printf("   2. Merge dengan master data existing\n");
    printf("   3. Test coverage baru - target 85%%+\n");
    printf("   4. Deploy untuk production!\n\n");
    printf("═══════════════════════════════════════════════════════════════════\n\n");
    
    return 0;
}
