#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE 2048
#define MAX_BTP 20
#define MAX_DESC 1024
#define MAX_PATTERNS 3000

// Struktur untuk menyimpan customer pattern
typedef struct {
    char customer_name[200];
    char btp[MAX_BTP];
    int match_count;
    int total_transactions;
    float match_percentage;
} CustomerPattern;

// Array untuk menyimpan semua patterns
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

// SMART EXTRACTION: Cari customer name di mana saja dalam deskripsi
void extract_customer_names_smart(const char *description, char names[][200], int *count) {
    *count = 0;
    
    char desc_upper[MAX_DESC];
    strncpy(desc_upper, description, MAX_DESC - 1);
    desc_upper[MAX_DESC - 1] = '\0';
    to_upper(desc_upper);
    
    // Split by space untuk dapat semua kata
    char words[200][50];
    int word_count = 0;
    
    char *token = strtok(desc_upper, " ");
    while (token != NULL && word_count < 200) {
        strncpy(words[word_count], token, 49);
        words[word_count][49] = '\0';
        word_count++;
        token = strtok(NULL, " ");
    }
    
    // Pattern 1: Nama di akhir (ALL CAPS sequence)
    char potential_names[20][200];
    int name_count = 0;
    
    // Scan dari belakang untuk cari ALL CAPS sequence
    for (int i = word_count - 1; i >= 0 && name_count < 20; i--) {
        // Skip jika kata pendek atau angka
        if (strlen(words[i]) < 4 || isdigit(words[i][0])) continue;
        
        // Check jika ini ALL CAPS dan bukan metadata
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
        
        if (is_all_caps && has_letter) {
            // Build potential name dari kata ini ke belakang
            char name[200] = "";
            int name_words = 0;
            
            // Ambil kata-kata ALL CAPS dari posisi ini ke belakang
            for (int k = i; k >= 0 && name_words < 6; k--) {
                // Check jika kata ini ALL CAPS
                int word_is_caps = 1;
                int word_has_letter = 0;
                
                for (int l = 0; words[k][l]; l++) {
                    if (isalpha(words[k][l])) {
                        word_has_letter = 1;
                        if (!isupper(words[k][l])) {
                            word_is_caps = 0;
                            break;
                        }
                    }
                }
                
                if (word_is_caps && word_has_letter && strlen(words[k]) >= 4) {
                    // Add ke name
                    if (name_words > 0) {
                        char temp[200];
                        snprintf(temp, sizeof(temp), "%s %s", words[k], name);
                        strncpy(name, temp, sizeof(name) - 1);
                        name[sizeof(name) - 1] = '\0';
                    } else {
                        strncpy(name, words[k], sizeof(name) - 1);
                        name[sizeof(name) - 1] = '\0';
                    }
                    name_words++;
                } else {
                    break; // Stop jika bukan ALL CAPS lagi
                }
            }
            
            if (name_words > 0 && strlen(name) >= 8) {
                strncpy(potential_names[name_count], name, sizeof(potential_names[name_count]) - 1);
                potential_names[name_count][sizeof(potential_names[name_count]) - 1] = '\0';
                name_count++;
            }
        }
    }
    
    // Pattern 2: Cari nama yang ada di master data (anywhere in description)
    for (int p = 0; p < pattern_count; p++) {
        char pattern_upper[200];
        strcpy(pattern_upper, patterns[p].customer_name);
        to_upper(pattern_upper);
        
        if (strstr(desc_upper, pattern_upper) != NULL) {
            // Check apakah sudah ada di potential_names
            int already_exists = 0;
            for (int n = 0; n < name_count; n++) {
                if (strcmp(potential_names[n], pattern_upper) == 0) {
                    already_exists = 1;
                    break;
                }
            }
            
            if (!already_exists && name_count < 20) {
                strncpy(potential_names[name_count], pattern_upper, sizeof(potential_names[name_count]) - 1);
                potential_names[name_count][sizeof(potential_names[name_count]) - 1] = '\0';
                name_count++;
            }
        }
    }
    
    // Copy ke output
    for (int i = 0; i < name_count && i < 10; i++) {
        strncpy(names[i], potential_names[i], 199);
        names[i][199] = '\0';
    }
    
    *count = name_count < 10 ? name_count : 10;
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
    
    printf("📂 Loading master data dari: %s\n", filename);
    
    char line[MAX_LINE];
    int loaded = 0;
    
    while (fgets(line, sizeof(line), file)) {
        // Skip komentar dan baris kosong
        if (line[0] == '-' || line[0] == '\n' || strstr(line, "INSERT INTO") || 
            strstr(line, "VALUES") || strstr(line, "Total rows") || 
            strstr(line, "STATISTICS") || strstr(line, "BTP Coverage")) {
            continue;
        }
        
        // Parse line yang berisi data
        char customer_name[200];
        char btp[MAX_BTP];
        int match_count, total_trans;
        float match_pct;
        
        char *start = strchr(line, '(');
        if (!start) continue;
        
        start++;
        
        // Extract customer_name
        char *quote1 = strchr(start, '\'');
        if (!quote1) continue;
        quote1++;
        char *quote2 = strchr(quote1, '\'');
        if (!quote2) continue;
        
        int name_len = quote2 - quote1;
        strncpy(customer_name, quote1, name_len);
        customer_name[name_len] = '\0';
        
        // Extract BTP
        char *quote3 = strchr(quote2 + 1, '\'');
        if (!quote3) continue;
        quote3++;
        char *quote4 = strchr(quote3, '\'');
        if (!quote4) continue;
        
        int btp_len = quote4 - quote3;
        strncpy(btp, quote3, btp_len);
        btp[btp_len] = '\0';
        
        // Extract numbers
        char *numbers = quote4 + 1;
        if (sscanf(numbers, ", %d, %d, %f", &match_count, &total_trans, &match_pct) == 3) {
            strcpy(patterns[pattern_count].customer_name, customer_name);
            strcpy(patterns[pattern_count].btp, btp);
            patterns[pattern_count].match_count = match_count;
            patterns[pattern_count].total_transactions = total_trans;
            patterns[pattern_count].match_percentage = match_pct;
            pattern_count++;
            loaded++;
            
            if (pattern_count >= MAX_PATTERNS) {
                printf("⚠️  Warning: Mencapai batas maksimal patterns (%d)\n", MAX_PATTERNS);
                break;
            }
        }
    }
    
    fclose(file);
    printf("✅ Berhasil load %d customer patterns\n\n", loaded);
    return loaded;
}

// Fungsi untuk test smart extraction
void test_smart_extraction(const char *description) {
    printf("\n═══════════════════════════════════════════════════════════════════\n");
    printf("  SMART EXTRACTION TEST\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("Input: %s\n\n", description);
    
    char names[10][200];
    int count;
    
    extract_customer_names_smart(description, names, &count);
    
    printf("Detected Customer Names (%d):\n", count);
    printf("───────────────────────────────────────────────────────────────────\n");
    
    for (int i = 0; i < count; i++) {
        printf("%d. %s\n", i + 1, names[i]);
        
        // Cek apakah ada di master data
        for (int j = 0; j < pattern_count; j++) {
            char pattern_upper[200];
            strcpy(pattern_upper, patterns[j].customer_name);
            to_upper(pattern_upper);
            
            if (strcmp(names[i], pattern_upper) == 0) {
                printf("   ✅ FOUND in master: %s → %s (%.1f%%)\n", 
                       patterns[j].customer_name, patterns[j].btp, patterns[j].match_percentage);
                break;
            }
        }
    }
    
    printf("═══════════════════════════════════════════════════════════════════\n\n");
}

int main() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║        SMART PATTERN EXTRACTION - TESTING TOOL                    ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n");
    
    // Load master data
    if (!load_master_data("insert_customer_btp_pattern_70pct_PLUS.sql")) {
        printf("❌ Gagal load master data. Program dihentikan.\n");
        return 1;
    }
    
    printf("🧠 Smart Extraction Features:\n");
    printf("   • Cari customer name di mana saja dalam deskripsi\n");
    printf("   • Detect ALL CAPS sequences (minimal 8 karakter)\n");
    printf("   • Cross-reference dengan master data\n");
    printf("   • Handle variasi format depan\n");
    printf("\n");
    
    // Test cases
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("  TEST CASES\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    
    test_smart_extraction("TRSF E-BANKING CR 2401/FTSCY/WS95031 455520.00 Portos bakery Inv. N7159289 DAVID TANTRIS OR F");
    test_smart_extraction("TRSF E-BANKING CR 0301/FTSCY/WS95051 6518040.00 KOKUMINDO BERKAT M");
    test_smart_extraction("TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 GF fresh 2dus 3jan 2024 RONNY YULIADY");
    test_smart_extraction("TRSF E-BANKING CR 1001/FTSCY/WS95271 683280.00 Domu Kuncit N69065 24 10Nov23 FRANKI SEPTINUS");
    
    printf("💡 Key Insight:\n");
    printf("   Smart extraction akan detect customer name bahkan jika:\n");
    printf("   • Ada invoice number di depan\n");
    printf("   • Format depan berbeda\n");
    printf("   • Customer name di tengah\n");
    printf("   • Multiple variations\n");
    
    return 0;
}
