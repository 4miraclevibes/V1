#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE 1024
#define MAX_BTP 20
#define MAX_DESC 512
#define MAX_WORDS 100
#define MAX_WORD_LEN 100
#define MAX_PATTERNS 10000

typedef struct {
    char btp[MAX_BTP];
    char customer_name[200];
} Pattern;

Pattern *patterns = NULL;
int pattern_count = 0;

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

int has_number(const char *str) {
    for (int i = 0; str[i]; i++) {
        if (isdigit(str[i])) {
            return 1;
        }
    }
    return 0;
}

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

void extract_customer_name(const char *description, char *customer_name) {
    char desc_upper[MAX_DESC];
    strncpy(desc_upper, description, MAX_DESC - 1);
    desc_upper[MAX_DESC - 1] = '\0';
    to_upper(desc_upper);
    
    char words[MAX_WORDS][MAX_WORD_LEN];
    int word_count = 0;
    
    char desc_copy[MAX_DESC];
    strcpy(desc_copy, desc_upper);
    
    char *token = strtok(desc_copy, " ");
    while (token != NULL && word_count < MAX_WORDS) {
        strncpy(words[word_count], token, MAX_WORD_LEN - 1);
        words[word_count][MAX_WORD_LEN - 1] = '\0';
        word_count++;
        token = strtok(NULL, " ");
    }
    
    int last_number_index = -1;
    for (int i = word_count - 1; i >= 0; i--) {
        if (has_number(words[i])) {
            last_number_index = i;
            break;
        }
    }
    
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

int load_patterns() {
    // Allocate memory for patterns
    patterns = (Pattern *)malloc(MAX_PATTERNS * sizeof(Pattern));
    if (!patterns) {
        printf("❌ Error: Tidak dapat allocate memory\n");
        return 0;
    }
    
    FILE *file = fopen("master_customer_btp_pattern.sql", "r");
    if (!file) {
        printf("❌ Error: Tidak dapat membuka master_customer_btp_pattern.sql\n");
        return 0;
    }
    
    char line[MAX_LINE];
    while (fgets(line, sizeof(line), file)) {
        if (strstr(line, "INSERT INTO") || strstr(line, "VALUES") || 
            strstr(line, "--") || strlen(line) < 10) {
            continue;
        }
        
        char *start = strchr(line, '(');
        char *end = strrchr(line, ')');
        if (!start || !end) continue;
        
        *end = '\0';
        char *data = start + 1;
        
        char *customer_name_str = strtok(data, ",");
        char *btp_str = strtok(NULL, ",");
        
        if (!customer_name_str || !btp_str) continue;
        
        trim(customer_name_str);
        trim(btp_str);
        
        if (customer_name_str[0] == '\'') customer_name_str++;
        if (customer_name_str[strlen(customer_name_str) - 1] == '\'') 
            customer_name_str[strlen(customer_name_str) - 1] = '\0';
        
        if (btp_str[0] == '\'') btp_str++;
        if (btp_str[strlen(btp_str) - 1] == '\'') 
            btp_str[strlen(btp_str) - 1] = '\0';
        
        if (pattern_count < MAX_PATTERNS) {
            strcpy(patterns[pattern_count].btp, btp_str);
            strcpy(patterns[pattern_count].customer_name, customer_name_str);
            pattern_count++;
        }
    }
    
    fclose(file);
    return pattern_count;
}

int find_pattern(const char *btp, const char *customer_name) {
    for (int i = 0; i < pattern_count; i++) {
        if (strcmp(patterns[i].btp, btp) == 0 && 
            strcmp(patterns[i].customer_name, customer_name) == 0) {
            return 1;
        }
    }
    return 0;
}

void test_coverage() {
    FILE *file = fopen("../TRSF.csv", "r");
    if (!file) {
        file = fopen("TRSF.csv", "r");
    }
    if (!file) {
        printf("❌ Error: Tidak dapat membuka TRSF.csv\n");
        return;
    }
    
    printf("📂 Testing coverage dari TRSF.csv...\n\n");
    
    char line[MAX_LINE];
    int total_tested = 0;
    int found = 0;
    int not_found = 0;
    
    // Skip header
    if (fgets(line, sizeof(line), file)) {
        // Header
    }
    
    printf("🔄 Processing... (testing 50,000 samples)\n");
    
    while (fgets(line, sizeof(line), file) && total_tested < 50000) {
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
        
        char customer_name[200];
        extract_customer_name(description, customer_name);
        
        total_tested++;
        
        if (find_pattern(btp, customer_name)) {
            found++;
        } else {
            not_found++;
        }
        
        if (total_tested % 5000 == 0) {
            printf("📊 Processed %d transactions... (Found: %d, No Pattern: %d)\n", 
                   total_tested, found, not_found);
        }
    }
    
    fclose(file);
    
    float found_pct = (found * 100.0) / total_tested;
    float not_found_pct = (not_found * 100.0) / total_tested;
    
    printf("\n═══════════════════════════════════════════════════════════════════\n");
    printf("                      COVERAGE TEST RESULTS\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("  Master Data Patterns : %d\n", pattern_count);
    printf("  Total Tested         : %d\n", total_tested);
    printf("  Pattern Found        : %d (%.1f%%)\n", found, found_pct);
    printf("  No Pattern Found     : %d (%.1f%%)\n", not_found, not_found_pct);
    printf("═══════════════════════════════════════════════════════════════════\n");
    
    if (found_pct >= 85.0) {
        printf("✅ GREAT! Coverage >= 85%% - Target achieved!\n\n");
    } else if (found_pct >= 80.0) {
        printf("⚠️  GOOD! Coverage >= 80%% - Very close to target\n\n");
    } else {
        printf("❌ Coverage < 80%% - Need improvement\n\n");
    }
}

int main() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║           COVERAGE TEST TOOL v2                                  ║\n");
    printf("║           Test 50K samples dengan pattern generator v2           ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    int loaded = load_patterns();
    printf("✅ Berhasil load %d customer patterns\n", loaded);
    
    test_coverage();
    
    return 0;
}

