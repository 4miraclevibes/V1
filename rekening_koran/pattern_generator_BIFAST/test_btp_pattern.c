#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_PATTERNS 20000
#define MAX_LINE 1024
#define MAX_NAME 200
#define MAX_BTP 20
#define MAX_DESC 500
#define MAX_WORDS 100
#define MAX_WORD_LEN 100

typedef struct {
    char customer_name[MAX_NAME];
    char btp[MAX_BTP];
    int match_count;
    int total_transactions;
    float match_percentage;
    int last_line_number; // Baris terakhir di CSV (latest BTP usage)
} CustomerPattern;

CustomerPattern *patterns = NULL;
int pattern_count = 0;

void to_upper(char *str) {
    for (int i = 0; str[i]; i++) {
        str[i] = toupper((unsigned char)str[i]);
    }
}

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

// Extract customer name dengan logic v2 (simple dan benar)
void extract_customer_name(const char *description, char *customer_name) {
    // JANGAN to_upper! Biar bisa detect mapping salah (lowercase = error)
    char desc_copy[MAX_DESC];
    strncpy(desc_copy, description, MAX_DESC - 1);
    desc_copy[MAX_DESC - 1] = '\0';
    
    // Split by space
    char words[MAX_WORDS][MAX_WORD_LEN];
    int word_count = 0;
    
    char *token = strtok(desc_copy, " ");
    while (token != NULL && word_count < MAX_WORDS) {
        strncpy(words[word_count], token, MAX_WORD_LEN - 1);
        words[word_count][MAX_WORD_LEN - 1] = '\0';
        word_count++;
        token = strtok(NULL, " ");
    }
    
    if (word_count == 0) {
        strcpy(customer_name, "UNKNOWN");
        return;
    }
    
    // Cek dari belakang, cari index terakhir yang ada angka
    int last_number_index = -1;
    for (int i = word_count - 1; i >= 0; i--) {
        if (has_number(words[i])) {
            last_number_index = i;
            break;
        }
    }
    
    // Jika tidak ada angka, return UNKNOWN
    if (last_number_index == -1) {
        strcpy(customer_name, "UNKNOWN");
        return;
    }
    
    // Jika angka ada di word terakhir, tidak ada customer name
    if (last_number_index == word_count - 1) {
        strcpy(customer_name, "UNKNOWN");
        return;
    }
    
    // Ambil HANYA ALL CAPS words SETELAH last_number_index
    // Sesuai dokumentasi: "Customer name = ALL CAPS words SETELAH word tsb"
    // SKIP: prefix bulan (JAN, FEB, etc)
    
    // List bulan untuk di-skip sebagai prefix
    const char *months[] = {
        "JAN", "JANUARI", "FEB", "FEBRUARI", "MAR", "MARET", 
        "APR", "APRIL", "MAY", "MEI", "JUN", "JUNI", 
        "JUL", "JULI", "AUG", "AGT", "AGUSTUS", 
        "SEP", "SEPT", "SEPTEMBER", "OCT", "OKT", "OKTOBER", 
        "NOV", "NOVEMBER", "DEC", "DES", "DESEMBER", NULL
    };
    
    char result[200] = "";
    int result_count = 0;
    
    for (int i = last_number_index + 1; i < word_count; i++) {
        // Hanya ambil ALL CAPS words (minimal 2 chars untuk avoid typo)
        if (is_all_caps(words[i]) && strlen(words[i]) >= 2) {
            // Skip bulan prefix
            int is_month = 0;
            for (int m = 0; months[m] != NULL; m++) {
                if (strcmp(words[i], months[m]) == 0) {
                    is_month = 1;
                    break;
                }
            }
            
            // Skip jika bulan
            if (is_month) continue;
            
            // Tambahkan ke result
            if (result_count > 0) {
                strcat(result, " ");
            }
            strcat(result, words[i]);
            result_count++;
        }
    }
    
    // Minimal harus ada hasil yang valid (minimal 3 chars total)
    if (strlen(result) >= 3) {
        strcpy(customer_name, result);
    } else {
        strcpy(customer_name, "UNKNOWN");
    }
}

int load_master_data(const char *filename) {
    // Allocate memory
    patterns = (CustomerPattern *)malloc(MAX_PATTERNS * sizeof(CustomerPattern));
    if (!patterns) {
        printf("❌ Error: Tidak dapat allocate memory\n");
        return 0;
    }
    
    FILE *file = fopen(filename, "r");
    if (!file) {
        char alt_path[512];
        snprintf(alt_path, sizeof(alt_path), "../%s", filename);
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
        if (line[0] == '-' || strstr(line, "INSERT INTO") || 
            strstr(line, "VALUES") || strlen(line) < 10) {
            continue;
        }
        
        char *start = strchr(line, '(');
        if (!start) continue;
        start++;
        
        char *quote1 = strchr(start, '\'');
        if (!quote1) continue;
        quote1++;
        char *quote2 = strchr(quote1, '\'');
        if (!quote2) continue;
        
        char customer_name[MAX_NAME];
        int name_len = quote2 - quote1;
        strncpy(customer_name, quote1, name_len);
        customer_name[name_len] = '\0';
        
        char *quote3 = strchr(quote2 + 1, '\'');
        if (!quote3) continue;
        quote3++;
        char *quote4 = strchr(quote3, '\'');
        if (!quote4) continue;
        
        char btp[MAX_BTP];
        int btp_len = quote4 - quote3;
        strncpy(btp, quote3, btp_len);
        btp[btp_len] = '\0';
        
        int match_count, total_trans, last_line;
        float match_pct;
        char *numbers = quote4 + 1;
        int parsed = sscanf(numbers, ", %d, %d, %f, %d", &match_count, &total_trans, &match_pct, &last_line);
        if (parsed >= 3) {
            strcpy(patterns[pattern_count].customer_name, customer_name);
            strcpy(patterns[pattern_count].btp, btp);
            patterns[pattern_count].match_count = match_count;
            patterns[pattern_count].total_transactions = total_trans;
            patterns[pattern_count].match_percentage = match_pct;
            patterns[pattern_count].last_line_number = (parsed == 4) ? last_line : 0;
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

// Find BEST BTP (highest match rate) untuk customer name
int find_btp(const char *description, char *found_btp, char *found_customer, float *match_pct, 
             CustomerPattern *all_matches, int *match_count_out) {
    char customer_name[200];
    extract_customer_name(description, customer_name);
    
    if (strcmp(customer_name, "UNKNOWN") == 0) {
        *match_count_out = 0;
        return 0;
    }
    
    // Convert to uppercase for matching
    to_upper(customer_name);
    
    // Cari SEMUA BTP yang match dengan customer name
    CustomerPattern matches[50];
    int match_count = 0;
    
    for (int i = 0; i < pattern_count && match_count < 50; i++) {
        char pattern_upper[MAX_NAME];
        strcpy(pattern_upper, patterns[i].customer_name);
        to_upper(pattern_upper);
        
        if (strcmp(customer_name, pattern_upper) == 0) {
            matches[match_count] = patterns[i];
            match_count++;
        }
    }
    
    if (match_count == 0) {
        *match_count_out = 0;
        return 0;
    }
    
    // Sort by: 1) match % (highest), 2) total trans (most), 3) last line (most recent)
    for (int i = 0; i < match_count - 1; i++) {
        for (int j = i + 1; j < match_count; j++) {
            int should_swap = 0;
            
            // Primary: match percentage (highest)
            if (matches[j].match_percentage > matches[i].match_percentage) {
                should_swap = 1;
            } 
            // Secondary: total transactions (most) - jika match % sama
            else if (matches[j].match_percentage == matches[i].match_percentage) {
                if (matches[j].total_transactions > matches[i].total_transactions) {
                    should_swap = 1;
                }
                // Tertiary: last line number (most recent) - jika sama
                else if (matches[j].total_transactions == matches[i].total_transactions) {
                    if (matches[j].last_line_number > matches[i].last_line_number) {
                        should_swap = 1;
                    }
                }
            }
            
            if (should_swap) {
                CustomerPattern temp = matches[i];
                matches[i] = matches[j];
                matches[j] = temp;
            }
        }
    }
    
    // Copy all matches untuk analysis
    for (int i = 0; i < match_count && i < 10; i++) {
        all_matches[i] = matches[i];
    }
    *match_count_out = (match_count > 10) ? 10 : match_count;
    
    // Return BEST match (highest match rate)
    strcpy(found_btp, matches[0].btp);
    strcpy(found_customer, matches[0].customer_name);
    *match_pct = matches[0].match_percentage;
    
    return 1;
}

void test_from_csv(int limit) {
    FILE *file = fopen("../BI-FAST.csv", "r");
    if (!file) {
        file = fopen("BI-FAST.csv", "r");
    }
    
    if (!file) {
        printf("❌ Error: Tidak dapat membuka BI-FAST.csv\n");
        return;
    }
    
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║           BATCH TESTING DARI BIFAST.CSV                            ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    char line[MAX_LINE];
    int tested = 0;
    int found = 0;
    int not_found = 0;
    
    // Skip header
    if (fgets(line, sizeof(line), file)) {
        // Header
    }
    
    printf("🔄 Processing %d samples...\n\n", limit);
    
    while (fgets(line, sizeof(line), file) && tested < limit) {
        char *semicolon = strchr(line, ';');
        if (!semicolon) continue;
        
        char btp_original[MAX_BTP];
        char description[MAX_DESC];
        
        int btp_len = semicolon - line;
        if (btp_len >= MAX_BTP) btp_len = MAX_BTP - 1;
        strncpy(btp_original, line, btp_len);
        btp_original[btp_len] = '\0';
        trim(btp_original);
        
        semicolon++;
        int desc_len = strlen(semicolon) - 1;
        if (desc_len >= MAX_DESC) desc_len = MAX_DESC - 1;
        strncpy(description, semicolon, desc_len);
        description[desc_len] = '\0';
        trim(description);
        
        if (strlen(btp_original) == 0 || strlen(description) == 0) continue;
        
        tested++;
        
        char found_btp[MAX_BTP];
        char found_customer[MAX_NAME];
        float match_pct;
        CustomerPattern all_matches[10];
        int match_count;
        
        if (find_btp(description, found_btp, found_customer, &match_pct, all_matches, &match_count)) {
            found++;
            
            int is_match = (strcmp(btp_original, found_btp) == 0);
            
            if (tested <= 20 || !is_match) {
                printf("[%d] %s", tested, is_match ? "✅ MATCH" : "⚠️  MISMATCH");
                if (match_count > 1) printf(" (%d BTPs found)", match_count);
                if (match_pct < 70.0) printf(" (⚠️ <70%%)");
                printf("\n");
                printf("    Original BTP  : %s\n", btp_original);
                printf("    Best BTP      : %s (%.1f%% - %d/%d trans)\n", 
                       found_btp, match_pct, all_matches[0].match_count, all_matches[0].total_transactions);
                printf("    Customer      : %s\n", found_customer);
                
                // Show all matches jika ada multiple BTPs
                if (match_count > 1 && !is_match) {
                    printf("    All Options   :\n");
                    
                    // Find latest BTP (highest line number)
                    int latest_idx = 0;
                    for (int m = 1; m < match_count; m++) {
                        if (all_matches[m].last_line_number > all_matches[latest_idx].last_line_number) {
                            latest_idx = m;
                        }
                    }
                    
                    // Show all options (expand to show more if original not in top 5)
                    int show_count = 5;
                    int original_idx = -1;
                    for (int m = 0; m < match_count; m++) {
                        if (strcmp(btp_original, all_matches[m].btp) == 0) {
                            original_idx = m;
                            if (m >= 5) show_count = m + 1; // Expand to include original
                            break;
                        }
                    }
                    
                    for (int m = 0; m < match_count && m < show_count; m++) {
                        int is_original = (strcmp(btp_original, all_matches[m].btp) == 0);
                        int is_latest = (m == latest_idx);
                        
                        printf("      %s [%d] BTP: %s (%.1f%% - %d/%d trans)%s\n",
                               is_original ? "✅" : "  ", m + 1, all_matches[m].btp, all_matches[m].match_percentage,
                               all_matches[m].match_count, all_matches[m].total_transactions,
                               is_latest ? " 🕒 LATEST" : "");
                    }
                    
                    if (match_count > show_count) {
                        printf("      ... dan %d BTP lainnya\n", match_count - show_count);
                    }
                    
                    printf("    💡 Latest BTP : %s (last used at line %d)\n", 
                           all_matches[latest_idx].btp, all_matches[latest_idx].last_line_number);
                }
                
                if (tested <= 20) {
                    printf("    Description   : %s\n", description);
                }
                printf("\n");
            }
        } else {
            not_found++;
            
            if (tested <= 20 || not_found <= 10) {
                printf("[%d] ❌ NO PATTERN\n", tested);
                printf("    Original BTP  : %s\n", btp_original);
                if (tested <= 20) {
                    printf("    Description   : %s\n", description);
                }
                printf("\n");
            }
        }
        
        if (tested % 5000 == 0 && tested > 0) {
            printf("📊 Progress: %d/%d (Found: %d, No Pattern: %d)\n\n", 
                   tested, limit, found, not_found);
        }
    }
    
    fclose(file);
    
    float found_pct = (found * 100.0) / tested;
    float not_found_pct = (not_found * 100.0) / tested;
    
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("                      TESTING SUMMARY\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("  Total Tested       : %d\n", tested);
    printf("  Pattern Found      : %d (%.1f%%)\n", found, found_pct);
    printf("  No Pattern Found   : %d (%.1f%%)\n", not_found, not_found_pct);
    printf("═══════════════════════════════════════════════════════════════════\n");
    
    if (found_pct >= 85.0) {
        printf("✅ GREAT! Coverage >= 85%% - Target achieved!\n");
    } else if (found_pct >= 80.0) {
        printf("⚠️  GOOD! Coverage >= 80%% - Very close to target\n");
    } else if (found_pct >= 70.0) {
        printf("⚠️  FAIR! Coverage >= 70%% - Need improvement\n");
    } else {
        printf("❌ Coverage < 70%% - Need significant improvement\n");
    }
    
    printf("═══════════════════════════════════════════════════════════════════\n\n");
}

void display_btp_list() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                    DAFTAR BTP YANG TERSEDIA                      ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    // Sort patterns by BTP untuk grouping
    CustomerPattern sorted_patterns[MAX_PATTERNS];
    for (int i = 0; i < pattern_count; i++) {
        sorted_patterns[i] = patterns[i];
    }
    
    // Sort by BTP, then by last_line_number (latest first)
    for (int i = 0; i < pattern_count - 1; i++) {
        for (int j = i + 1; j < pattern_count; j++) {
            int should_swap = 0;
            
            // Primary: BTP (alphabetical)
            if (strcmp(sorted_patterns[j].btp, sorted_patterns[i].btp) < 0) {
                should_swap = 1;
            }
            // Secondary: last_line_number (latest first) - jika BTP sama
            else if (strcmp(sorted_patterns[j].btp, sorted_patterns[i].btp) == 0) {
                if (sorted_patterns[j].last_line_number > sorted_patterns[i].last_line_number) {
                    should_swap = 1;
                }
            }
            
            if (should_swap) {
                CustomerPattern temp = sorted_patterns[i];
                sorted_patterns[i] = sorted_patterns[j];
                sorted_patterns[j] = temp;
            }
        }
    }
    
    // Group by BTP dan tampilkan
    char current_btp[MAX_BTP] = "";
    int btp_count = 0;
    int total_btps = 0;
    
    printf("  Daftar BTP (dengan customer name dan info terbaru):\n");
    printf("  ─────────────────────────────────────────────────────────────────\n");
    
    for (int i = 0; i < pattern_count; i++) {
        if (strcmp(current_btp, sorted_patterns[i].btp) != 0) {
            // New BTP found
            if (strlen(current_btp) > 0) {
                printf("\n");
            }
            
            strcpy(current_btp, sorted_patterns[i].btp);
            btp_count = 1;
            total_btps++;
            
            printf("  BTP: %s\n", current_btp);
            printf("    Customer: %s (%.1f%% - %d/%d trans, line %d)\n", 
                   sorted_patterns[i].customer_name, 
                   sorted_patterns[i].match_percentage,
                   sorted_patterns[i].match_count,
                   sorted_patterns[i].total_transactions,
                   sorted_patterns[i].last_line_number);
        } else {
            // Same BTP, show additional customer
            btp_count++;
            printf("    Customer: %s (%.1f%% - %d/%d trans, line %d)\n", 
                   sorted_patterns[i].customer_name, 
                   sorted_patterns[i].match_percentage,
                   sorted_patterns[i].match_count,
                   sorted_patterns[i].total_transactions,
                   sorted_patterns[i].last_line_number);
        }
    }
    
    printf("\n  Total BTPs: %d\n", total_btps);
    printf("═══════════════════════════════════════════════════════════════════\n\n");
}

void display_latest_btps() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                    BTP TERBARU (LATEST USAGE)                     ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    // Sort by last_line_number (highest = latest)
    CustomerPattern sorted_patterns[MAX_PATTERNS];
    for (int i = 0; i < pattern_count; i++) {
        sorted_patterns[i] = patterns[i];
    }
    
    for (int i = 0; i < pattern_count - 1; i++) {
        for (int j = i + 1; j < pattern_count; j++) {
            if (sorted_patterns[j].last_line_number > sorted_patterns[i].last_line_number) {
                CustomerPattern temp = sorted_patterns[i];
                sorted_patterns[i] = sorted_patterns[j];
                sorted_patterns[j] = temp;
            }
        }
    }
    
    printf("  Top 20 BTP Terbaru (berdasarkan last usage):\n");
    printf("  ─────────────────────────────────────────────────────────────────\n");
    
    int shown = 0;
    for (int i = 0; i < pattern_count && shown < 20; i++) {
        if (sorted_patterns[i].last_line_number > 0) {
            printf("  %2d. BTP: %s | Customer: %s | Line: %d | Match: %.1f%%\n", 
                   shown + 1,
                   sorted_patterns[i].btp,
                   sorted_patterns[i].customer_name,
                   sorted_patterns[i].last_line_number,
                   sorted_patterns[i].match_percentage);
            shown++;
        }
    }
    
    if (shown == 0) {
        printf("  ❌ Tidak ada data dengan last_line_number > 0\n");
    }
    
    printf("═══════════════════════════════════════════════════════════════════\n\n");
}

void display_statistics() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                   MASTER DATA STATISTICS                         ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    int perfect = 0, excellent = 0, very_good = 0, good = 0, fair = 0;
    
    for (int i = 0; i < pattern_count; i++) {
        if (patterns[i].match_percentage == 100.0) perfect++;
        else if (patterns[i].match_percentage >= 95.0) excellent++;
        else if (patterns[i].match_percentage >= 90.0) very_good++;
        else if (patterns[i].match_percentage >= 80.0) good++;
        else if (patterns[i].match_percentage >= 70.0) fair++;
    }
    
    printf("  Total Patterns Loaded   : %d\n\n", pattern_count);
    printf("  Distribusi Quality:\n");
    printf("  ─────────────────────────────────────────────────────────────────\n");
    printf("  🟢 Perfect Match (100%%)   : %d (%.1f%%)\n", perfect, (perfect * 100.0) / pattern_count);
    printf("  🟢 Excellent (≥95%%)       : %d (%.1f%%)\n", excellent, (excellent * 100.0) / pattern_count);
    printf("  🔵 Very Good (≥90%%)       : %d (%.1f%%)\n", very_good, (very_good * 100.0) / pattern_count);
    printf("  🟡 Good (≥80%%)            : %d (%.1f%%)\n", good, (good * 100.0) / pattern_count);
    printf("  🟠 Fair (70-79%%)          : %d (%.1f%%)\n", fair, ((fair) * 100.0) / pattern_count);
    printf("  🔴 Low (<70%%)             : %d (%.1f%%)\n", pattern_count - fair, ((pattern_count - fair) * 100.0) / pattern_count);
    printf("\n");
    
    // Top 10 by transaction volume
    printf("  Top 10 Customer by Transaction Volume:\n");
    printf("  ─────────────────────────────────────────────────────────────────\n");
    
    CustomerPattern top[10];
    int top_count = 0;
    
    for (int i = 0; i < pattern_count && i < 10; i++) {
        top[i] = patterns[i];
        top_count++;
    }
    
    for (int i = 10; i < pattern_count; i++) {
        int min_idx = 0;
        for (int j = 1; j < 10; j++) {
            if (top[j].total_transactions < top[min_idx].total_transactions) {
                min_idx = j;
            }
        }
        
        if (patterns[i].total_transactions > top[min_idx].total_transactions) {
            top[min_idx] = patterns[i];
        }
    }
    
    for (int i = 0; i < 9; i++) {
        for (int j = i + 1; j < 10; j++) {
            if (top[j].total_transactions > top[i].total_transactions) {
                CustomerPattern temp = top[i];
                top[i] = top[j];
                top[j] = temp;
            }
        }
    }
    
    for (int i = 0; i < top_count; i++) {
        printf("  %2d. %-30s %s (%d trans, %.1f%%)\n", 
               i + 1, top[i].customer_name, top[i].btp, 
               top[i].total_transactions, top[i].match_percentage);
    }
    
    printf("═══════════════════════════════════════════════════════════════════\n\n");
}

void manual_test() {
    char description[MAX_DESC];
    
    printf("\n───────────────────────────────────────────────────────────────────\n");
    printf("Masukkan deskripsi BIFAST:\n");
    printf("(contoh: BIFAST E-BANKING CR 0201/FTSCY/WS95011 455520.00 RONNY YULIADY)\n");
    printf("───────────────────────────────────────────────────────────────────\n");
    printf("Desc: ");
    
    fgets(description, sizeof(description), stdin);
    trim(description);
    
    if (strlen(description) == 0) {
        printf("⚠️  Deskripsi kosong.\n");
        return;
    }
    
    // Tampilkan info BTP yang tersedia untuk referensi
    printf("\n💡 INFO: Untuk melihat daftar BTP yang tersedia, pilih menu 'A'\n");
    printf("💡 INFO: Untuk melihat BTP terbaru, pilih menu 'B'\n\n");
    
    char found_btp[MAX_BTP];
    char found_customer[MAX_NAME];
    float match_pct;
    CustomerPattern all_matches[10];
    int match_count;
    
    if (find_btp(description, found_btp, found_customer, &match_pct, all_matches, &match_count)) {
        printf("\n═══════════════════════════════════════════════════════════════════\n");
        if (match_count > 1) {
            printf("                ⚠️  %d PATTERNS FOUND!\n", match_count);
        } else {
            printf("                     ✅ PATTERN FOUND!\n");
        }
        printf("═══════════════════════════════════════════════════════════════════\n");
        
        printf("  BEST MATCH (Highest Match Rate):\n");
        printf("  ─────────────────────────────────────────────────────────────────\n");
        printf("  BTP                : %s\n", found_btp);
        printf("  Customer Name      : %s\n", found_customer);
        printf("  Match Percentage   : %.2f%%\n", match_pct);
        printf("  Match Count        : %d\n", all_matches[0].match_count);
        printf("  Total Transactions : %d\n", all_matches[0].total_transactions);
        
        if (match_pct < 70.0) {
            printf("\n  ⚠️  WARNING: Match percentage di bawah 70%%!\n");
            printf("  → Pattern kurang reliable\n");
        } else if (match_pct < 80.0) {
            printf("\n  ⚠️  CAUTION: Match percentage di bawah 80%%\n");
        }
        
        // Show all options jika ada multiple BTPs
        if (match_count > 1) {
            printf("\n  ALL OPTIONS (Sorted by: Match%% → Trans → Latest):\n");
            printf("  ─────────────────────────────────────────────────────────────────\n");
            
            // Find latest BTP
            int latest_idx = 0;
            for (int i = 1; i < match_count; i++) {
                if (all_matches[i].last_line_number > all_matches[latest_idx].last_line_number) {
                    latest_idx = i;
                }
            }
            
            for (int i = 0; i < match_count; i++) {
                int is_latest = (i == latest_idx);
                printf("  [%d] BTP: %s (%.1f%% - %d/%d trans)%s\n",
                       i + 1, all_matches[i].btp, all_matches[i].match_percentage,
                       all_matches[i].match_count, all_matches[i].total_transactions,
                       is_latest ? " 🕒 LATEST" : "");
            }
            
            printf("\n  💡 Latest BTP: %s (last used at line %d)\n", 
                   all_matches[latest_idx].btp, all_matches[latest_idx].last_line_number);
            printf("     Sorted by: Match %% → Total Trans → Latest Used\n");
        }
        
        printf("═══════════════════════════════════════════════════════════════════\n\n");
    } else {
        printf("\n═══════════════════════════════════════════════════════════════════\n");
        printf("                     ❌ NO PATTERN FOUND\n");
        printf("═══════════════════════════════════════════════════════════════════\n");
        printf("  Deskripsi tidak mengandung customer name yang ada di master data.\n");
        printf("═══════════════════════════════════════════════════════════════════\n\n");
    }
}

void print_menu() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║          BTP PATTERN MATCHING - TESTING TOOL v2                  ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    printf("  1. Test dengan input manual (single)\n");
    printf("  2. Test batch dari BI-FAST.csv (10 sample)\n");
    printf("  3. Test batch dari BI-FAST.csv (50 sample)\n");
    printf("  4. Test batch dari BI-FAST.csv (100 sample)\n");
    printf("  5. Test batch dari BI-FAST.csv (1,000 sample)\n");
    printf("  6. Test batch dari BI-FAST.csv (5,000 sample)\n");
    printf("  7. Test batch dari BI-FAST.csv (10,000 sample)\n");
    printf("  8. Test batch dari BI-FAST.csv (50,000 sample) 🎯\n");
    printf("  9. Statistik master data\n");
    printf("  A. Daftar BTP yang tersedia\n");
    printf("  B. BTP terbaru (latest usage)\n");
    printf("  0. Keluar\n");
    printf("\n───────────────────────────────────────────────────────────────────\n");
    printf("  Pilih: ");
}

int main() {
    printf("\n");
    printf("╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║           BTP PATTERN MATCHING TESTING TOOL v2.0                 ║\n");
    printf("║                  File-Based Testing (No Database)                ║\n");
    printf("║                  Clean Logic - Simple & Correct                  ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    if (!load_master_data("master_customer_btp_pattern_BIFAST.sql")) {
        printf("❌ Gagal load master data. Program dihentikan.\n");
        return 1;
    }
    
    while (1) {
        print_menu();
        
        char input[10];
        fgets(input, sizeof(input), stdin);
        trim(input);
        
        if (strlen(input) == 0) {
            printf("⚠️  Pilihan tidak valid. Coba lagi.\n");
            continue;
        }
        
        char choice = input[0];
        
        switch (choice) {
            case '0':
                printf("\n👋 Terima kasih! Bye bye...\n\n");
                if (patterns) free(patterns);
                return 0;
                
            case '1':
                manual_test();
                break;
                
            case '2':
                test_from_csv(10);
                break;
                
            case '3':
                test_from_csv(50);
                break;
                
            case '4':
                test_from_csv(100);
                break;
                
            case '5':
                test_from_csv(1000);
                break;
                
            case '6':
                test_from_csv(5000);
                break;
                
            case '7':
                test_from_csv(10000);
                break;
                
            case '8':
                test_from_csv(50000);
                break;
                
            case '9':
                display_statistics();
                break;
                
            case 'A':
            case 'a':
                display_btp_list();
                break;
                
            case 'B':
            case 'b':
                display_latest_btps();
                break;
                
            default:
                printf("⚠️  Pilihan tidak valid. Coba lagi.\n");
                break;
        }
    }
    
    if (patterns) free(patterns);
    return 0;
}

