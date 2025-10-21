#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_PATTERNS 3000
#define MAX_LINE 1024
#define MAX_NAME 200
#define MAX_BTP 20
#define MAX_DESC 500

// Struktur untuk menyimpan customer pattern
typedef struct {
    char customer_name[MAX_NAME];
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

// Fungsi untuk load master data dari file SQL
int load_master_data(const char *filename) {
    FILE *file = fopen(filename, "r");
    
    // Jika gagal, coba dengan path rekening_koran/
    if (!file) {
        char alt_path[512];
        snprintf(alt_path, sizeof(alt_path), "rekening_koran/%s", filename);
        file = fopen(alt_path, "r");
    }
    
    if (!file) {
        printf("❌ Error: Tidak dapat membuka file %s\n", filename);
        printf("💡 Pastikan Anda menjalankan program dari folder:\n");
        printf("   - Langsung di folder rekening_koran/, ATAU\n");
        printf("   - Di parent folder (V1/)\n");
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
        // Format: ('CUSTOMER NAME', 'BTP', match_count, total_trans, match_pct),
        char customer_name[MAX_NAME];
        char btp[MAX_BTP];
        int match_count, total_trans;
        float match_pct;
        
        // Cari pattern ('...',  '...',  num,  num,  num.num)
        char *start = strchr(line, '(');
        if (!start) continue;
        
        start++; // skip '('
        
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

// Fungsi untuk hitung similarity percentage dengan word-based matching
float calculate_similarity(const char *str1, const char *str2) {
    if (strlen(str1) == 0 || strlen(str2) == 0) return 0.0;
    
    // Split strings menjadi words
    char words1[10][50], words2[10][50];
    int count1 = 0, count2 = 0;
    
    // Parse str1
    char temp1[200];
    strcpy(temp1, str1);
    char *token = strtok(temp1, " ");
    while (token != NULL && count1 < 10) {
        strcpy(words1[count1], token);
        count1++;
        token = strtok(NULL, " ");
    }
    
    // Parse str2
    char temp2[200];
    strcpy(temp2, str2);
    token = strtok(temp2, " ");
    while (token != NULL && count2 < 10) {
        strcpy(words2[count2], token);
        count2++;
        token = strtok(NULL, " ");
    }
    
    // Hitung word similarity
    int matched_words = 0;
    int total_words = count1 > count2 ? count1 : count2;
    
    for (int i = 0; i < count1; i++) {
        for (int j = 0; j < count2; j++) {
            if (strcmp(words1[i], words2[j]) == 0) {
                matched_words++;
                break;
            }
        }
    }
    
    // Calculate similarity percentage
    float similarity = (matched_words * 100.0) / total_words;
    
    // Additional check: jika ada exact substring match, berikan bonus
    if (strstr(str1, str2) != NULL || strstr(str2, str1) != NULL) {
        int min_len = strlen(str1) < strlen(str2) ? strlen(str1) : strlen(str2);
        int max_len = strlen(str1) > strlen(str2) ? strlen(str1) : strlen(str2);
        float substring_sim = (min_len * 100.0) / max_len;
        
        // Ambil yang lebih tinggi antara word similarity dan substring similarity
        if (substring_sim > similarity) {
            similarity = substring_sim;
        }
    }
    
    return similarity;
}

// Fungsi untuk strict word order matching
int strict_word_order_match(const char *str1, const char *str2) {
    char words1[10][50], words2[10][50];
    int count1 = 0, count2 = 0;
    
    // Parse str1
    char temp1[200];
    strcpy(temp1, str1);
    char *token = strtok(temp1, " ");
    while (token != NULL && count1 < 10) {
        strcpy(words1[count1], token);
        count1++;
        token = strtok(NULL, " ");
    }
    
    // Parse str2
    char temp2[200];
    strcpy(temp2, str2);
    token = strtok(temp2, " ");
    while (token != NULL && count2 < 10) {
        strcpy(words2[count2], token);
        count2++;
        token = strtok(NULL, " ");
    }
    
    // Check jika ada minimal 2 words yang match dengan urutan yang benar
    int consecutive_matches = 0;
    int max_consecutive = 0;
    
    for (int i = 0; i < count1; i++) {
        for (int j = 0; j < count2; j++) {
            if (strcmp(words1[i], words2[j]) == 0) {
                // Check consecutive matches
                int temp_consecutive = 1;
                int k = i + 1, l = j + 1;
                
                while (k < count1 && l < count2 && strcmp(words1[k], words2[l]) == 0) {
                    temp_consecutive++;
                    k++;
                    l++;
                }
                
                if (temp_consecutive > max_consecutive) {
                    max_consecutive = temp_consecutive;
                }
            }
        }
    }
    
    // Return 1 jika ada minimal 2 consecutive words match
    return max_consecutive >= 2;
}

// ULTRA SMART EXTRACTION: Extract semua kemungkinan customer name
void extract_customer_names_ultra_smart(const char *description, char names[][200], int *count) {
    *count = 0;
    
    char desc_upper[MAX_DESC];
    strncpy(desc_upper, description, MAX_DESC - 1);
    desc_upper[MAX_DESC - 1] = '\0';
    to_upper(desc_upper);
    
    // Step 1: Extract semua ALL CAPS sequences (minimal 6 karakter)
    char all_caps_sequences[20][200];
    int caps_count = 0;
    
    char words[100][50];
    int word_count = 0;
    
    // Split description menjadi words
    char desc_copy[MAX_DESC];
    strcpy(desc_copy, desc_upper);
    char *token = strtok(desc_copy, " ");
    while (token != NULL && word_count < 100) {
        strncpy(words[word_count], token, 49);
        words[word_count][49] = '\0';
        word_count++;
        token = strtok(NULL, " ");
    }
    
    // Scan semua kemungkinan ALL CAPS sequences
    for (int start = 0; start < word_count && caps_count < 20; start++) {
        for (int end = start; end < word_count && caps_count < 20; end++) {
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
                    break; // Stop jika bukan ALL CAPS
                }
            }
            
            // Add sequence jika cukup panjang dan bermakna
            if (word_count_in_seq > 0 && strlen(sequence) >= 6) {
                // Skip jika terlalu umum (metadata bank)
                if (strstr(sequence, "TRSF") || strstr(sequence, "E-BANKING") || 
                    strstr(sequence, "CR ") || strstr(sequence, "FTSCY") ||
                    strstr(sequence, "WS95")) {
                    continue;
                }
                
                // Check apakah sudah ada
                int already_exists = 0;
                for (int n = 0; n < caps_count; n++) {
                    if (strcmp(all_caps_sequences[n], sequence) == 0) {
                        already_exists = 1;
                        break;
                    }
                }
                
                if (!already_exists) {
                    strncpy(all_caps_sequences[caps_count], sequence, 199);
                    all_caps_sequences[caps_count][199] = '\0';
                    caps_count++;
                }
            }
        }
    }
    
    // Step 2: Cross-reference dengan master data
    for (int c = 0; c < caps_count && *count < 10; c++) {
        // Cek apakah sequence ini ada di master data
        for (int p = 0; p < pattern_count; p++) {
            char pattern_upper[200];
            strcpy(pattern_upper, patterns[p].customer_name);
            to_upper(pattern_upper);
            
            // STRICT MATCHING: Exact match atau high similarity dengan word order
            int is_exact_match = (strcmp(all_caps_sequences[c], pattern_upper) == 0);
            
            // Word boundary substring match (bukan character substring)
            int is_word_boundary_match = 0;
            if (strstr(all_caps_sequences[c], pattern_upper) != NULL) {
                // Check apakah substring match adalah word boundary
                char *pos = strstr(all_caps_sequences[c], pattern_upper);
                if (pos == all_caps_sequences[c] || *(pos-1) == ' ') {
                    // Check akhir juga
                    int end_pos = pos - all_caps_sequences[c] + strlen(pattern_upper);
                    if (end_pos == strlen(all_caps_sequences[c]) || all_caps_sequences[c][end_pos] == ' ') {
                        is_word_boundary_match = 1;
                    }
                }
            }
            
            float similarity = calculate_similarity(all_caps_sequences[c], pattern_upper);
            int has_word_order = strict_word_order_match(all_caps_sequences[c], pattern_upper);
            
            // Accept match jika:
            // 1. Exact match, atau
            // 2. Word boundary substring match dengan minimal 6 karakter, atau
            // 3. High similarity (>=85%) dengan word order yang benar
            if (is_exact_match || 
                (is_word_boundary_match && strlen(all_caps_sequences[c]) >= 6) ||
                (similarity >= 85.0 && has_word_order)) {
                
                // Check apakah sudah ada
                int already_exists = 0;
                for (int n = 0; n < *count; n++) {
                    if (strcmp(names[n], pattern_upper) == 0) {
                        already_exists = 1;
                        break;
                    }
                }
                
                if (!already_exists) {
                    strncpy(names[*count], pattern_upper, 199);
                    names[*count][199] = '\0';
                    (*count)++;
                    break; // Ambil yang pertama match
                }
            }
        }
    }
    
    // Step 3: Jika tidak ada match di master, ambil sequence terpanjang sebagai fallback
    if (*count == 0 && caps_count > 0) {
        // Cari sequence terpanjang
        int longest_idx = 0;
        int longest_len = strlen(all_caps_sequences[0]);
        
        for (int i = 1; i < caps_count; i++) {
            if (strlen(all_caps_sequences[i]) > longest_len) {
                longest_len = strlen(all_caps_sequences[i]);
                longest_idx = i;
            }
        }
        
        strncpy(names[*count], all_caps_sequences[longest_idx], 199);
        names[*count][199] = '\0';
        (*count)++;
    }
}

// Fungsi untuk mencari SEMUA BTP yang match dari deskripsi
int find_all_btp_from_description(const char *description, CustomerPattern *results, int max_results) {
    char customer_names[10][200];
    int name_count;
    
    // Ultra smart extraction untuk dapat customer names
    extract_customer_names_ultra_smart(description, customer_names, &name_count);
    
    typedef struct {
        int idx;
        int name_length;
        float match_pct;
        float similarity;
        char customer_name[200];
        char btp[MAX_BTP];
    } MatchInfo;
    
    MatchInfo matches[MAX_PATTERNS];
    int match_count = 0;
    
    // Cari BTP yang match dengan customer names yang terdeteksi
    for (int n = 0; n < name_count; n++) {
        for (int i = 0; i < pattern_count; i++) {
            char pattern_upper[MAX_NAME];
            strcpy(pattern_upper, patterns[i].customer_name);
            to_upper(pattern_upper);
            
            // Check apakah customer name match dengan pattern
            if (strcmp(customer_names[n], pattern_upper) == 0) {
                // Check apakah sudah ada di matches
                int already_exists = 0;
                for (int m = 0; m < match_count; m++) {
                    if (matches[m].idx == i) {
                        already_exists = 1;
                        break;
                    }
                }
                
                if (!already_exists) {
                    int name_len = strlen(patterns[i].customer_name);
                    matches[match_count].idx = i;
                    matches[match_count].name_length = name_len;
                    matches[match_count].match_pct = patterns[i].match_percentage;
                    matches[match_count].similarity = 100.0;
                    strcpy(matches[match_count].customer_name, patterns[i].customer_name);
                    strcpy(matches[match_count].btp, patterns[i].btp);
                    match_count++;
                }
            }
        }
    }
    
    // Fallback: Exact substring match (untuk backward compatibility)
    if (match_count == 0) {
        char desc_upper[MAX_DESC];
        strncpy(desc_upper, description, MAX_DESC - 1);
        desc_upper[MAX_DESC - 1] = '\0';
        to_upper(desc_upper);
        
        for (int i = 0; i < pattern_count; i++) {
            char pattern_upper[MAX_NAME];
            strcpy(pattern_upper, patterns[i].customer_name);
            to_upper(pattern_upper);
            
            int name_len = strlen(patterns[i].customer_name);
            
            // WORD BOUNDARY EXACT MATCH
            int is_word_boundary_match = 0;
            if (strstr(desc_upper, pattern_upper) != NULL) {
                // Check apakah substring match adalah word boundary
                char *pos = strstr(desc_upper, pattern_upper);
                if (pos == desc_upper || *(pos-1) == ' ') {
                    // Check akhir juga
                    int end_pos = pos - desc_upper + strlen(pattern_upper);
                    if (end_pos == strlen(desc_upper) || desc_upper[end_pos] == ' ') {
                        is_word_boundary_match = 1;
                    }
                }
            }
            
            if (is_word_boundary_match) {
                matches[match_count].idx = i;
                matches[match_count].name_length = name_len;
                matches[match_count].match_pct = patterns[i].match_percentage;
                matches[match_count].similarity = 100.0;
                strcpy(matches[match_count].customer_name, patterns[i].customer_name);
                strcpy(matches[match_count].btp, patterns[i].btp);
                match_count++;
            }
            // STRICT PARTIAL MATCH (untuk handle nama terpotong)
            else if (name_len >= 10) {  // Minimal 10 karakter untuk partial match
                float similarity = calculate_similarity(desc_upper, pattern_upper);
                int has_word_order = strict_word_order_match(desc_upper, pattern_upper);
                
                // Stricter criteria: minimal 85% similarity dengan word order yang benar
                if (similarity >= 85.0 && has_word_order) {
                    matches[match_count].idx = i;
                    matches[match_count].name_length = name_len;
                    matches[match_count].match_pct = patterns[i].match_percentage;
                    matches[match_count].similarity = similarity;
                    strcpy(matches[match_count].customer_name, patterns[i].customer_name);
                    strcpy(matches[match_count].btp, patterns[i].btp);
                    match_count++;
                }
            }
        }
    }
    
    if (match_count == 0) return 0;
    
    // BUSINESS LOGIC: Group by customer name untuk detect duplicate BTP
    typedef struct {
        char customer_name[200];
        char btp_list[10][MAX_BTP];
        int btp_count;
        float avg_match_pct;
        int total_transactions;
    } CustomerGroup;
    
    CustomerGroup customer_groups[50];
    int group_count = 0;
    
    // Group matches by customer name
    for (int i = 0; i < match_count; i++) {
        // Check apakah customer name sudah ada di groups
        int group_idx = -1;
        for (int g = 0; g < group_count; g++) {
            if (strcmp(customer_groups[g].customer_name, matches[i].customer_name) == 0) {
                group_idx = g;
                break;
            }
        }
        
        // Jika belum ada, buat group baru
        if (group_idx == -1) {
            strcpy(customer_groups[group_count].customer_name, matches[i].customer_name);
            strcpy(customer_groups[group_count].btp_list[0], matches[i].btp);
            customer_groups[group_count].btp_count = 1;
            customer_groups[group_count].avg_match_pct = matches[i].match_pct;
            customer_groups[group_count].total_transactions = patterns[matches[i].idx].total_transactions;
            group_count++;
        }
        // Jika sudah ada, tambahkan BTP ke group
        else {
            // Check apakah BTP sudah ada di group
            int btp_exists = 0;
            for (int b = 0; b < customer_groups[group_idx].btp_count; b++) {
                if (strcmp(customer_groups[group_idx].btp_list[b], matches[i].btp) == 0) {
                    btp_exists = 1;
                    break;
                }
            }
            
            // Tambahkan BTP jika belum ada
            if (!btp_exists && customer_groups[group_idx].btp_count < 10) {
                strcpy(customer_groups[group_idx].btp_list[customer_groups[group_idx].btp_count], matches[i].btp);
                customer_groups[group_idx].btp_count++;
                customer_groups[group_idx].avg_match_pct = (customer_groups[group_idx].avg_match_pct + matches[i].match_pct) / 2.0;
            }
        }
    }
    
    // Convert groups ke results dengan business logic
    int result_count = 0;
    
    for (int g = 0; g < group_count && result_count < max_results; g++) {
        // NORMAL CASE: 1 customer = 1 BTP
        if (customer_groups[g].btp_count == 1) {
            // Find pattern untuk BTP ini
            for (int i = 0; i < pattern_count; i++) {
                if (strcmp(patterns[i].customer_name, customer_groups[g].customer_name) == 0 &&
                    strcmp(patterns[i].btp, customer_groups[g].btp_list[0]) == 0) {
                    results[result_count] = patterns[i];
                    result_count++;
                    break;
                }
            }
        }
        // WARNING CASE: 1 customer = multiple BTP (ada duplikasi/error)
        else if (customer_groups[g].btp_count > 1) {
            // Tampilkan semua BTP dengan warning
            for (int b = 0; b < customer_groups[g].btp_count && result_count < max_results; b++) {
                // Find pattern untuk BTP ini
                for (int i = 0; i < pattern_count; i++) {
                    if (strcmp(patterns[i].customer_name, customer_groups[g].customer_name) == 0 &&
                        strcmp(patterns[i].btp, customer_groups[g].btp_list[b]) == 0) {
                        results[result_count] = patterns[i];
                        result_count++;
                        break;
                    }
                }
            }
        }
    }
    
    return result_count;
}

// Fungsi untuk get confidence tier
const char* get_confidence_tier(float match_pct) {
    if (match_pct >= 95.0) return "VERY_HIGH";
    if (match_pct >= 90.0) return "HIGH";
    if (match_pct >= 80.0) return "MEDIUM";
    if (match_pct >= 70.0) return "LOW_MEDIUM";
    return "LOW";
}

const char* get_confidence_color(float match_pct) {
    if (match_pct >= 95.0) return "🟢"; // Green
    if (match_pct >= 90.0) return "🔵"; // Blue
    if (match_pct >= 80.0) return "🟡"; // Yellow
    if (match_pct >= 70.0) return "🟠"; // Orange
    return "🔴"; // Red
}

const char* get_recommended_action(float match_pct) {
    if (match_pct >= 95.0) return "Auto-fill without review";
    if (match_pct >= 90.0) return "Auto-fill with audit";
    if (match_pct >= 80.0) return "Suggest with confirmation";
    if (match_pct >= 70.0) return "Suggest with validation";
    return "Manual entry";
}

// Fungsi untuk display multiple hasil
void display_multiple_results(const CustomerPattern *results, int count) {
    printf("\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    
    // Check apakah ada duplicate BTP (same customer, different BTP)
    int has_duplicate_btp = 0;
    if (count > 1) {
        for (int i = 0; i < count; i++) {
            for (int j = i + 1; j < count; j++) {
                if (strcmp(results[i].customer_name, results[j].customer_name) == 0) {
                    has_duplicate_btp = 1;
                    break;
                }
            }
            if (has_duplicate_btp) break;
        }
    }
    
    if (count == 1) {
        printf("                     ✅ PATTERN FOUND!\n");
    } else if (has_duplicate_btp) {
        printf("                ⚠️  %d PATTERNS FOUND!\n", count);
        printf("                🚨 DUPLICATE BTP DETECTED!\n");
    } else {
        printf("                ✅ %d PATTERNS FOUND!\n", count);
    }
    printf("═══════════════════════════════════════════════════════════════════\n\n");
    
    // Display warning untuk duplicate BTP
    if (has_duplicate_btp) {
        printf("🚨 WARNING: 1 Customer memiliki multiple BTP!\n");
        printf("   Business Rule: 1 Customer = 1 BTP\n");
        printf("   → Ada duplikasi/error dalam master data\n");
        printf("   → Pilih BTP yang benar atau report ke admin\n\n");
    }
    
    for (int i = 0; i < count; i++) {
        if (count > 1) {
            printf("───────────────────────────────────────────────────────────────────\n");
            printf("  OPTION %d:\n", i + 1);
            printf("───────────────────────────────────────────────────────────────────\n");
        }
        
        printf("  BTP                : %s\n", results[i].btp);
        printf("  Customer Name      : %s\n", results[i].customer_name);
        printf("  Match Percentage   : %.2f%%\n", results[i].match_percentage);
        printf("  Match Count        : %d\n", results[i].match_count);
        printf("  Total Transactions : %d\n", results[i].total_transactions);
        printf("  Confidence         : %s %s\n", 
               get_confidence_color(results[i].match_percentage),
               get_confidence_tier(results[i].match_percentage));
        printf("  Recommended Action : %s\n", get_recommended_action(results[i].match_percentage));
        
        // WARNING untuk <70%
        if (results[i].match_percentage < 70.0) {
            printf("\n  ⚠️  WARNING: Match percentage di bawah 70%%!\n");
            printf("  → Pattern kurang reliable, gunakan dengan hati-hati\n");
            printf("  → Recommended: Manual verification required\n");
        } else if (results[i].match_percentage < 80.0) {
            printf("\n  ⚠️  CAUTION: Match percentage di bawah 80%%\n");
            printf("  → Termasuk kategori FAIR, perlu extra validation\n");
        }
        
        if (i < count - 1) {
            printf("\n");
        }
    }
    
    if (count > 1) {
        printf("\n───────────────────────────────────────────────────────────────────\n");
        if (has_duplicate_btp) {
            printf("  🚨 DUPLICATE BTP DETECTED!\n");
            printf("  → Business Rule: 1 Customer = 1 BTP\n");
            printf("  → Ada %d BTP untuk customer yang sama\n", count);
            printf("  → Pilih BTP yang benar atau report ke admin\n");
        } else {
            printf("  💡 TIPS: Ada %d BTP untuk customer yang mirip.\n", count);
            printf("      Pilih yang paling sesuai atau confidence tertinggi.\n");
        }
    }
    
    printf("═══════════════════════════════════════════════════════════════════\n\n");
}

// Fungsi untuk testing batch dari TRSF.csv
void test_from_csv(const char *csv_file, int limit) {
    FILE *file = fopen(csv_file, "r");
    
    // Jika gagal, coba dengan path rekening_koran/
    if (!file) {
        char alt_path[512];
        snprintf(alt_path, sizeof(alt_path), "rekening_koran/%s", csv_file);
        file = fopen(alt_path, "r");
    }
    
    if (!file) {
        printf("❌ Error: Tidak dapat membuka file %s\n", csv_file);
        printf("💡 Pastikan file TRSF.csv ada di folder yang sama dengan program\n");
        return;
    }
    
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║           BATCH TESTING DARI TRSF.CSV                            ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    char line[MAX_LINE];
    int tested = 0;
    int found = 0;
    int not_found = 0;
    
    // Skip header jika ada
    fgets(line, sizeof(line), file);
    
    while (fgets(line, sizeof(line), file) && tested < limit) {
        // Parse CSV: btp;description
        char btp_original[MAX_BTP];
        char description[MAX_DESC];
        
        char *delimiter = strchr(line, ';');
        if (!delimiter) continue;
        
        // Get BTP original
        int btp_len = delimiter - line;
        strncpy(btp_original, line, btp_len);
        btp_original[btp_len] = '\0';
        trim(btp_original);
        
        // Get description
        strcpy(description, delimiter + 1);
        trim(description);
        
        // Skip jika bukan TRSF
        if (strncasecmp(description, "TRSF", 4) != 0) continue;
        
        tested++;
        
        // Cari pattern (ambil max 3 hasil)
        CustomerPattern results[3];
        int result_count = find_all_btp_from_description(description, results, 3);
        
        if (result_count > 0) {
            found++;
            
            // Check apakah ada yang match dengan original
            int has_match = 0;
            for (int i = 0; i < result_count; i++) {
                if (strcmp(btp_original, results[i].btp) == 0) {
                    has_match = 1;
                    break;
                }
            }
            
            printf("[%d] %s", tested, has_match ? "✅ MATCH" : "⚠️  MISMATCH");
            if (result_count > 1) printf(" (%d options)", result_count);
            printf("\n");
            
            printf("    Original BTP  : %s\n", btp_original);
            
            for (int i = 0; i < result_count; i++) {
                if (result_count > 1) printf("    Option %d BTP  : ", i + 1);
                else printf("    Suggested BTP : ");
                
                printf("%s (%.1f%% conf", results[i].btp, results[i].match_percentage);
                if (results[i].match_percentage < 70.0) printf(" ⚠️ <70%%");
                else if (results[i].match_percentage < 80.0) printf(" ⚠️ <80%%");
                printf(")\n");
                
                if (result_count > 1) printf("                  : ");
                else printf("    Customer      : ");
                printf("%s\n", results[i].customer_name);
            }
            
            printf("    Description   : %s\n", description);
            printf("\n");
        } else {
            not_found++;
            printf("[%d] ❌ NO PATTERN\n", tested);
            printf("    Original BTP  : %s\n", btp_original);
            printf("    Description   : %s\n", description);
            printf("\n");
        }
    }
    
    fclose(file);
    
    printf("\n═══════════════════════════════════════════════════════════════════\n");
    printf("                      TESTING SUMMARY\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("  Total Tested       : %d\n", tested);
    printf("  Pattern Found      : %d (%.1f%%)\n", found, (found * 100.0) / tested);
    printf("  No Pattern Found   : %d (%.1f%%)\n", not_found, (not_found * 100.0) / tested);
    printf("═══════════════════════════════════════════════════════════════════\n\n");
}

// Menu utama
void print_menu() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║          BTP PATTERN MATCHING - TESTING TOOL                     ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    printf("  1. Test dengan input manual (single)\n");
    printf("  2. Test batch dari TRSF.csv (10 sample)\n");
    printf("  3. Test batch dari TRSF.csv (50 sample)\n");
    printf("  4. Test batch dari TRSF.csv (100 sample)\n");
    printf("  5. Statistik master data\n");
    printf("  0. Keluar\n");
    printf("\n───────────────────────────────────────────────────────────────────\n");
    printf("  Pilih: ");
}

// Fungsi untuk display statistik
void display_statistics() {
    printf("\n╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                   MASTER DATA STATISTICS                         ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    int perfect = 0, excellent = 0, very_good = 0, good = 0, fair = 0;
    
    for (int i = 0; i < pattern_count; i++) {
        if (patterns[i].match_percentage == 100.0) perfect++;
        if (patterns[i].match_percentage >= 95.0) excellent++;
        if (patterns[i].match_percentage >= 90.0) very_good++;
        if (patterns[i].match_percentage >= 80.0) good++;
        if (patterns[i].match_percentage >= 70.0) fair++;
    }
    
    printf("  Total Patterns Loaded   : %d\n\n", pattern_count);
    printf("  Distribusi Quality:\n");
    printf("  ─────────────────────────────────────────────────────────────────\n");
    printf("  🟢 Perfect Match (100%%)   : %d (%.1f%%)\n", perfect, (perfect * 100.0) / pattern_count);
    printf("  🟢 Excellent (≥95%%)       : %d (%.1f%%)\n", excellent, (excellent * 100.0) / pattern_count);
    printf("  🔵 Very Good (≥90%%)       : %d (%.1f%%)\n", very_good, (very_good * 100.0) / pattern_count);
    printf("  🟡 Good (≥80%%)            : %d (%.1f%%)\n", good, (good * 100.0) / pattern_count);
    printf("  🟠 Fair (70-79%%)          : %d (%.1f%%)\n", fair - good, ((fair - good) * 100.0) / pattern_count);
    printf("\n");
    
    // Top 10 by transaction volume
    printf("  Top 10 Customer by Transaction Volume:\n");
    printf("  ─────────────────────────────────────────────────────────────────\n");
    
    // Simple bubble sort for top 10
    CustomerPattern top[10];
    int top_count = 0;
    
    for (int i = 0; i < pattern_count && i < 10; i++) {
        top[i] = patterns[i];
        top_count++;
    }
    
    for (int i = 10; i < pattern_count; i++) {
        // Find minimum in top
        int min_idx = 0;
        for (int j = 1; j < 10; j++) {
            if (top[j].total_transactions < top[min_idx].total_transactions) {
                min_idx = j;
            }
        }
        
        // Replace if current is bigger
        if (patterns[i].total_transactions > top[min_idx].total_transactions) {
            top[min_idx] = patterns[i];
        }
    }
    
    // Sort top 10
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

int main() {
    printf("\n");
    printf("╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║           BTP PATTERN MATCHING TESTING TOOL v1.0                 ║\n");
    printf("║                  File-Based Testing (No Database)                ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n\n");
    
    // Load master data (pilih file yang mau dipakai)
    printf("Pilih master data file:\n");
    printf("  1. insert_customer_btp_pattern_70pct.sql (2219 patterns, threshold 70%%)\n");
    printf("  2. insert_customer_btp_pattern.sql (2201 patterns, threshold 80%%)\n");
    printf("  3. insert_customer_btp_pattern_70pct_PLUS.sql (2223 patterns, with manual additions) ⭐\n");
    printf("\nPilih (1/2/3): ");
    
    int choice;
    scanf("%d", &choice);
    getchar(); // consume newline
    
    const char *master_file;
    if (choice == 1) {
        master_file = "insert_customer_btp_pattern_70pct.sql";
    } else if (choice == 2) {
        master_file = "insert_customer_btp_pattern.sql";
    } else {
        master_file = "insert_customer_btp_pattern_70pct_PLUS.sql";
    }
    
    if (!load_master_data(master_file)) {
        printf("❌ Gagal load master data. Program dihentikan.\n");
        return 1;
    }
    
    // Main loop
    while (1) {
        print_menu();
        
        int menu_choice;
        scanf("%d", &menu_choice);
        getchar(); // consume newline
        
        switch (menu_choice) {
            case 0:
                printf("\n👋 Terima kasih! Bye bye...\n\n");
                return 0;
                
            case 1: {
                // Manual input testing
                char description[MAX_DESC];
                
                printf("\n───────────────────────────────────────────────────────────────────\n");
                printf("Masukkan deskripsi TRSF:\n");
                printf("(contoh: TRSF E-BANKING CR 0201/FTSCY/WS95011 455520.00 GF fresh RONNY YULIADY)\n");
                printf("───────────────────────────────────────────────────────────────────\n");
                printf("Desc: ");
                
                fgets(description, sizeof(description), stdin);
                trim(description);
                
                if (strlen(description) == 0) {
                    printf("⚠️  Deskripsi kosong. Coba lagi.\n");
                    break;
                }
                
                // Cari semua matching patterns (max 5)
                CustomerPattern results[5];
                int result_count = find_all_btp_from_description(description, results, 5);
                
                if (result_count > 0) {
                    display_multiple_results(results, result_count);
                } else {
                    printf("\n");
                    printf("═══════════════════════════════════════════════════════════════════\n");
                    printf("                     ❌ NO PATTERN FOUND\n");
                    printf("═══════════════════════════════════════════════════════════════════\n");
                    printf("  Deskripsi tidak mengandung customer name yang ada di master data.\n");
                    printf("  → Perlu manual entry untuk BTP ini.\n");
                    printf("\n  💡 TIP: Gunakan tool investigate untuk analyze BTP:\n");
                    printf("      ./investigate_no_pattern [BTP]\n");
                    printf("═══════════════════════════════════════════════════════════════════\n\n");
                }
                break;
            }
            
            case 2:
                test_from_csv("TRSF.csv", 10);
                break;
                
            case 3:
                test_from_csv("TRSF.csv", 50);
                break;
                
            case 4:
                test_from_csv("TRSF.csv", 100);
                break;
                
            case 5:
                display_statistics();
                break;
                
            default:
                printf("⚠️  Pilihan tidak valid. Coba lagi.\n");
                break;
        }
    }
    
    return 0;
}

