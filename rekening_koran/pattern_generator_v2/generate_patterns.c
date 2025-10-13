#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE 1024
#define MAX_BTP 20
#define MAX_DESC 512
#define MAX_WORDS 100
#define MAX_WORD_LEN 100
#define MAX_PATTERNS 30000

typedef struct {
    char btp[MAX_BTP];
    char customer_name[200];
    int transaction_count;
    float match_rate;
    int last_line_number; // Track baris terakhir di CSV (untuk latest usage)
} Pattern;

Pattern patterns[MAX_PATTERNS];
int pattern_count = 0;

typedef struct {
    char btp[MAX_BTP];
    char customer_names[100][200];
    int customer_counts[100];
    int customer_last_lines[100]; // Track baris terakhir untuk setiap customer
    int unique_customers;
    int total_transactions;
} BTPAnalysis;

BTPAnalysis btp_analyses[5000];
int btp_analysis_count = 0;

void to_upper(char *s) {
    for (int i = 0; s[i]; i++) {
        s[i] = toupper((unsigned char)s[i]);
    }
}

void trim(char *s) {
    char *end;
    while (isspace((unsigned char)*s)) s++;
    if (*s == 0) return;
    end = s + strlen(s) - 1;
    while (end > s && isspace((unsigned char)*end)) end--;
    *(end + 1) = 0;
}

// Check apakah string mengandung angka
int has_number(const char *str) {
    for (int i = 0; str[i]; i++) {
        if (isdigit(str[i])) {
            return 1;
        }
    }
    return 0;
}

// Check apakah string adalah ALL CAPS (hanya huruf uppercase, boleh ada non-alphanumeric)
int is_all_caps(const char *str) {
    int has_letter = 0;
    for (int i = 0; str[i]; i++) {
        if (isalpha(str[i])) {
            has_letter = 1;
            if (!isupper(str[i])) {
                return 0;
            }
        }
    }
    return has_letter;
}

// Extract customer name dari description dengan logic BENAR
void extract_customer_name(const char *description, char *customer_name) {
    char desc_upper[MAX_DESC];
    strncpy(desc_upper, description, MAX_DESC - 1);
    desc_upper[MAX_DESC - 1] = '\0';
    to_upper(desc_upper);
    
    // Split by space
    char words[MAX_WORDS][MAX_WORD_LEN];
    int word_count = 0;
    
    char *token = strtok(desc_upper, " ");
    while (token != NULL && word_count < MAX_WORDS) {
        strncpy(words[word_count], token, MAX_WORD_LEN - 1);
        words[word_count][MAX_WORD_LEN - 1] = '\0';
        word_count++;
        token = strtok(NULL, " ");
    }
    
    // Cek dari belakang, cari index terakhir yang ada angka
    int last_number_index = -1;
    for (int i = word_count - 1; i >= 0; i--) {
        if (has_number(words[i])) {
            last_number_index = i;
            break;
        }
    }
    
    // Jika tidak ada angka, ambil semua ALL CAPS words
    if (last_number_index == -1) {
        char result[200] = "";
        int result_count = 0;
        
        for (int i = 0; i < word_count; i++) {
            if (is_all_caps(words[i]) && strlen(words[i]) >= 3) {
                if (result_count > 0) {
                    strcat(result, " ");
                }
                strcat(result, words[i]);
                result_count++;
            }
        }
        
        if (strlen(result) >= 4) {
            strcpy(customer_name, result);
        } else {
            strcpy(customer_name, "UNKNOWN");
        }
        return;
    }
    
    // Ambil semua kata SETELAH last_number_index (dari index+1 sampai akhir)
    // Hanya ambil ALL CAPS words
    char result[200] = "";
    int result_count = 0;
    
    for (int i = last_number_index + 1; i < word_count; i++) {
        if (is_all_caps(words[i]) && strlen(words[i]) >= 3) {
            if (result_count > 0) {
                strcat(result, " ");
            }
            strcat(result, words[i]);
            result_count++;
        }
    }
    
    if (strlen(result) >= 4) {
        strcpy(customer_name, result);
    } else {
        strcpy(customer_name, "UNKNOWN");
    }
}

// Analyze TRSF.csv dan generate patterns
void analyze_trsf() {
    FILE *file = fopen("../TRSF.csv", "r");
    if (!file) {
        file = fopen("TRSF.csv", "r");
    }
    if (!file) {
        printf("❌ Error: Tidak dapat membuka TRSF.csv\n");
        return;
    }
    
    printf("📂 Analyzing TRSF.csv...\n\n");
    
    char line[MAX_LINE];
    int processed = 0;
    int line_number = 0;
    
    // Skip header
    if (fgets(line, sizeof(line), file)) {
        line_number++; // Header line
    }
    
    // Process all lines
    while (fgets(line, sizeof(line), file)) {
        line_number++;
        processed++;
        
        // Parse CSV: BTP;DESCRIPTION
        char *semicolon = strchr(line, ';');
        if (!semicolon) continue;
        
        char btp[MAX_BTP];
        char description[MAX_DESC];
        
        int btp_len = semicolon - line;
        if (btp_len >= MAX_BTP) btp_len = MAX_BTP - 1;
        strncpy(btp, line, btp_len);
        btp[btp_len] = '\0';
        trim(btp);
        
        semicolon++;
        int desc_len = strlen(semicolon) - 1;
        if (desc_len >= MAX_DESC) desc_len = MAX_DESC - 1;
        strncpy(description, semicolon, desc_len);
        description[desc_len] = '\0';
        trim(description);
        
        if (strlen(btp) == 0 || strlen(description) == 0) continue;
        
        // Extract customer name
        char customer_name[200];
        extract_customer_name(description, customer_name);
        
        if (strcmp(customer_name, "UNKNOWN") == 0) continue;
        
        // Find or create BTP analysis
        int btp_idx = -1;
        for (int i = 0; i < btp_analysis_count; i++) {
            if (strcmp(btp_analyses[i].btp, btp) == 0) {
                btp_idx = i;
                break;
            }
        }
        
        if (btp_idx == -1) {
            if (btp_analysis_count >= 5000) continue;
            strcpy(btp_analyses[btp_analysis_count].btp, btp);
            btp_analyses[btp_analysis_count].unique_customers = 0;
            btp_analyses[btp_analysis_count].total_transactions = 0;
            btp_idx = btp_analysis_count;
            btp_analysis_count++;
        }
        
        // Find or create customer in BTP
        int customer_idx = -1;
        for (int i = 0; i < btp_analyses[btp_idx].unique_customers; i++) {
            if (strcmp(btp_analyses[btp_idx].customer_names[i], customer_name) == 0) {
                customer_idx = i;
                break;
            }
        }
        
        if (customer_idx == -1) {
            if (btp_analyses[btp_idx].unique_customers >= 100) continue;
            strcpy(btp_analyses[btp_idx].customer_names[btp_analyses[btp_idx].unique_customers], customer_name);
            btp_analyses[btp_idx].customer_counts[btp_analyses[btp_idx].unique_customers] = 1;
            btp_analyses[btp_idx].customer_last_lines[btp_analyses[btp_idx].unique_customers] = line_number;
            btp_analyses[btp_idx].unique_customers++;
        } else {
            btp_analyses[btp_idx].customer_counts[customer_idx]++;
            btp_analyses[btp_idx].customer_last_lines[customer_idx] = line_number; // Update last line
        }
        
        btp_analyses[btp_idx].total_transactions++;
        
        if (processed % 10000 == 0) {
            printf("📊 Processed %d transactions...\n", processed);
        }
    }
    
    fclose(file);
    
    printf("✅ Analyzed %d transactions, found %d unique BTPs\n\n", processed, btp_analysis_count);
    
    // Generate ALL patterns (no filtering, include all customer-BTP combinations)
    printf("🔍 Generating ALL patterns (no threshold filtering)...\n\n");
    
    for (int i = 0; i < btp_analysis_count; i++) {
        for (int j = 0; j < btp_analyses[i].unique_customers; j++) {
            float match_rate = (btp_analyses[i].customer_counts[j] * 100.0) / btp_analyses[i].total_transactions;
            
            // Generate ALL patterns (min 1 transaction aja)
            if (btp_analyses[i].customer_counts[j] >= 1) {
                if (pattern_count >= MAX_PATTERNS) break;
                
                strcpy(patterns[pattern_count].btp, btp_analyses[i].btp);
                strcpy(patterns[pattern_count].customer_name, btp_analyses[i].customer_names[j]);
                patterns[pattern_count].transaction_count = btp_analyses[i].customer_counts[j];
                patterns[pattern_count].match_rate = match_rate;
                patterns[pattern_count].last_line_number = btp_analyses[i].customer_last_lines[j];
                pattern_count++;
            }
        }
    }
    
    printf("✅ Generated %d patterns (ALL combinations)\n\n", pattern_count);
}

// Generate SQL output
void generate_sql() {
    FILE *output = fopen("master_customer_btp_pattern.sql", "w");
    if (!output) {
        printf("❌ Error: Tidak dapat membuat file SQL\n");
        return;
    }
    
    fprintf(output, "-- =====================================================\n");
    fprintf(output, "-- INSERT STATEMENTS: CUSTOMER → BTP MAPPING\n");
    fprintf(output, "-- Pattern Generator v2 - CLEAN LOGIC (ALL PATTERNS)\n");
    fprintf(output, "-- =====================================================\n");
    fprintf(output, "-- Total entries: %d\n", pattern_count);
    fprintf(output, "-- Match rate threshold: NONE (all combinations included)\n");
    fprintf(output, "-- Minimum transactions: 1\n");
    fprintf(output, "-- Logic: Check from last word, find last word with number, pattern starts from next word\n");
    fprintf(output, "-- =====================================================\n\n");
    fprintf(output, "INSERT INTO [dbo].[MASTER_CUSTOMER_BTP_PATTERN]\n");
    fprintf(output, "    ([customer_name], [btp], [match_count], [total_transactions], [match_percentage], [last_line_number])\n");
    fprintf(output, "VALUES\n");
    
    for (int i = 0; i < pattern_count; i++) {
        fprintf(output, "    ('%s', '%s', %d, %d, %.2f, %d)%s\n",
                patterns[i].customer_name,
                patterns[i].btp,
                patterns[i].transaction_count,
                patterns[i].transaction_count,
                patterns[i].match_rate,
                patterns[i].last_line_number,
                (i < pattern_count - 1) ? "," : ";");
    }
    
    fprintf(output, "\n-- Total rows inserted: %d\n", pattern_count);
    
    fclose(output);
    
    printf("✅ SQL generated: master_customer_btp_pattern.sql\n");
}

int main() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║        PATTERN GENERATOR v2 - CLEAN LOGIC                        ║\n");
    printf("║        Check from last word, find last number, pattern starts    ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    analyze_trsf();
    generate_sql();
    
    printf("\n✅ DONE!\n");
    printf("   Total patterns: %d\n", pattern_count);
    printf("   Output file: master_customer_btp_pattern.sql\n\n");
    
    return 0;
}
