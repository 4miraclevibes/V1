#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE 2048
#define MAX_BTP 20
#define MAX_DESC 1024

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

// Fungsi untuk extract customer name dari akhir deskripsi
void extract_potential_customer_name(const char *description, char *result, size_t result_size) {
    result[0] = '\0';
    
    // Cari kata terakhir yang ALL CAPS dan panjang >= 8 karakter
    char desc_copy[MAX_DESC];
    strncpy(desc_copy, description, MAX_DESC - 1);
    desc_copy[MAX_DESC - 1] = '\0';
    
    // Split by space
    char *words[100];
    int word_count = 0;
    
    char *token = strtok(desc_copy, " ");
    while (token != NULL && word_count < 100) {
        words[word_count++] = token;
        token = strtok(NULL, " ");
    }
    
    // Cari dari belakang, ambil kata-kata yang ALL CAPS
    char potential[MAX_DESC] = "";
    int found_caps = 0;
    
    for (int i = word_count - 1; i >= 0 && i >= word_count - 5; i--) {
        int is_caps = 1;
        int has_letter = 0;
        
        for (int j = 0; words[i][j]; j++) {
            if (isalpha(words[i][j])) {
                has_letter = 1;
                if (!isupper(words[i][j])) {
                    is_caps = 0;
                    break;
                }
            }
        }
        
        if (is_caps && has_letter) {
            if (found_caps) {
                char temp[MAX_DESC];
                snprintf(temp, sizeof(temp), "%s %s", words[i], potential);
                strncpy(potential, temp, sizeof(potential) - 1);
            } else {
                strncpy(potential, words[i], sizeof(potential) - 1);
            }
            found_caps = 1;
        } else if (found_caps) {
            break;  // Stop jika sudah dapat caps words dan sekarang bukan caps
        }
    }
    
    strncpy(result, potential, result_size - 1);
    result[result_size - 1] = '\0';
}

// Fungsi untuk analyze BTP
void analyze_btp(const char *btp, const char *csv_file) {
    FILE *file = fopen(csv_file, "r");
    
    if (!file) {
        char alt_path[512];
        snprintf(alt_path, sizeof(alt_path), "rekening_koran/%s", csv_file);
        file = fopen(alt_path, "r");
    }
    
    if (!file) {
        printf("❌ Error: Tidak dapat membuka file %s\n", csv_file);
        return;
    }
    
    printf("\n");
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("  INVESTIGASI BTP: %s\n", btp);
    printf("═══════════════════════════════════════════════════════════════════\n\n");
    
    char line[MAX_LINE];
    int total_transactions = 0;
    char customer_names[100][100];
    int customer_counts[100];
    int unique_customers = 0;
    
    // Skip header
    fgets(line, sizeof(line), file);
    
    while (fgets(line, sizeof(line), file)) {
        char btp_line[MAX_BTP];
        char desc[MAX_DESC];
        
        char *delimiter = strchr(line, ';');
        if (!delimiter) continue;
        
        int btp_len = delimiter - line;
        strncpy(btp_line, line, btp_len);
        btp_line[btp_len] = '\0';
        trim(btp_line);
        
        // Check if BTP match
        if (strcmp(btp_line, btp) != 0) continue;
        
        // Get full description
        strcpy(desc, delimiter + 1);
        trim(desc);
        
        // Skip jika bukan TRSF
        if (strncasecmp(desc, "TRSF", 4) != 0) continue;
        
        total_transactions++;
        
        // Extract potential customer name
        char customer_name[200];
        extract_potential_customer_name(desc, customer_name, sizeof(customer_name));
        
        // Count by customer name
        if (strlen(customer_name) >= 8) {
            int found = 0;
            for (int i = 0; i < unique_customers; i++) {
                if (strcmp(customer_names[i], customer_name) == 0) {
                    customer_counts[i]++;
                    found = 1;
                    break;
                }
            }
            
            if (!found && unique_customers < 100) {
                strcpy(customer_names[unique_customers], customer_name);
                customer_counts[unique_customers] = 1;
                unique_customers++;
            }
        }
        
        // Show first 5 samples
        if (total_transactions <= 5) {
            printf("  [%d] %s\n", total_transactions, desc);
            if (strlen(customer_name) >= 8) {
                printf("      → Detected: %s\n", customer_name);
            } else {
                printf("      → No customer name detected\n");
            }
            printf("\n");
        }
    }
    
    fclose(file);
    
    printf("───────────────────────────────────────────────────────────────────\n");
    printf("  SUMMARY\n");
    printf("───────────────────────────────────────────────────────────────────\n");
    printf("  Total Transaksi    : %d\n", total_transactions);
    printf("  Unique Customers   : %d\n", unique_customers);
    printf("\n");
    
    if (unique_customers > 0) {
        // Sort by count
        for (int i = 0; i < unique_customers - 1; i++) {
            for (int j = i + 1; j < unique_customers; j++) {
                if (customer_counts[j] > customer_counts[i]) {
                    // Swap counts
                    int temp_count = customer_counts[i];
                    customer_counts[i] = customer_counts[j];
                    customer_counts[j] = temp_count;
                    
                    // Swap names
                    char temp_name[100];
                    strcpy(temp_name, customer_names[i]);
                    strcpy(customer_names[i], customer_names[j]);
                    strcpy(customer_names[j], temp_name);
                }
            }
        }
        
        printf("  Customer Distribution:\n");
        printf("  ─────────────────────────────────────────────────────────────────\n");
        
        int display_limit = unique_customers > 10 ? 10 : unique_customers;
        for (int i = 0; i < display_limit; i++) {
            float percentage = (customer_counts[i] * 100.0) / total_transactions;
            printf("  %2d. %-40s %3d (%.1f%%)\n", 
                   i + 1, customer_names[i], customer_counts[i], percentage);
        }
        
        if (unique_customers > 10) {
            printf("      ... dan %d customer lainnya\n", unique_customers - 10);
        }
        
        printf("\n");
        printf("  Analisis:\n");
        printf("  ─────────────────────────────────────────────────────────────────\n");
        
        if (total_transactions == 0) {
            printf("  ❌ ALASAN: Tidak ada transaksi TRSF untuk BTP ini\n");
            printf("  → BTP mungkin salah atau tidak punya transaksi TRSF\n");
        } else if (unique_customers == 0) {
            printf("  ❌ ALASAN: Tidak ada customer name yang terdeteksi\n");
            printf("  → Format deskripsi tidak standar atau tidak ada nama customer\n");
        } else if (unique_customers == 1) {
            float match_rate = (customer_counts[0] * 100.0) / total_transactions;
            printf("  Customer Dominan   : %s\n", customer_names[0]);
            printf("  Match Rate         : %.1f%% (%d/%d)\n", 
                   match_rate, customer_counts[0], total_transactions);
            
            if (match_rate < 70.0) {
                printf("\n  ❌ ALASAN: Match rate terlalu rendah (< 70%%)\n");
                printf("  → Pattern tidak konsisten, tidak reliable untuk matching\n");
            } else if (match_rate < 80.0) {
                printf("\n  ⚠️  ALASAN: Match rate di bawah 80%% (hanya di 70%% threshold)\n");
                printf("  → Jika pakai threshold 80%%, BTP ini tidak masuk\n");
                printf("  → Coba gunakan master data 70%% threshold\n");
            } else {
                printf("\n  ✅ HARUSNYA ADA di master data!\n");
                printf("  → Coba cari dengan nama: %s\n", customer_names[0]);
                printf("  → Mungkin ada variasi penulisan atau typo\n");
            }
        } else {
            // Check apakah ada customer yang dominan (>= 70%)
            int dominant_customer = -1;
            float max_match_rate = 0.0;
            
            for (int i = 0; i < unique_customers; i++) {
                float match_rate = (customer_counts[i] * 100.0) / total_transactions;
                if (match_rate > max_match_rate) {
                    max_match_rate = match_rate;
                    dominant_customer = i;
                }
            }
            
            if (max_match_rate >= 70.0) {
                printf("  ✅ HARUSNYA ADA di master data!\n");
                printf("  Customer Dominan   : %s\n", customer_names[dominant_customer]);
                printf("  Match Rate         : %.1f%% (%d/%d)\n", 
                       max_match_rate, customer_counts[dominant_customer], total_transactions);
                printf("  → Pattern dominan >= 70%%, seharusnya masuk master data\n");
                printf("  → Coba cari dengan nama: %s\n", customer_names[dominant_customer]);
            } else {
                printf("  ❌ ALASAN: Multiple customers, tidak ada yang dominan\n");
                printf("  → BTP ini digunakan untuk %d customer berbeda\n", unique_customers);
                printf("  → Customer terbesar: %s (%.1f%%)\n", 
                       customer_names[dominant_customer], max_match_rate);
                printf("  → Tidak ada customer yang >= 70%% match rate\n");
                printf("  → Pattern tidak konsisten untuk auto-matching\n");
            }
        }
    } else {
        printf("  ❌ ALASAN: Tidak ada customer name yang terdeteksi\n");
        printf("  → Format deskripsi tidak standar\n");
        printf("  → Tidak ada ALL CAPS customer name di akhir deskripsi\n");
    }
    
    printf("═══════════════════════════════════════════════════════════════════\n\n");
}

int main(int argc, char *argv[]) {
    printf("\n");
    printf("╔═══════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                   ║\n");
    printf("║        NO PATTERN INVESTIGATOR - BTP Analysis Tool               ║\n");
    printf("║                                                                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════════════╝\n");
    
    if (argc > 1) {
        // BTP dari command line argument
        printf("\nInvestigating BTP: %s\n", argv[1]);
        analyze_btp(argv[1], "TRSF.csv");
    } else {
        // Interactive mode
        printf("\n");
        printf("Tool ini akan analyze BTP yang NO PATTERN untuk cari tahu alasannya.\n");
        printf("\n");
        
        while (1) {
            printf("───────────────────────────────────────────────────────────────────\n");
            printf("Masukkan BTP yang ingin di-investigate (atau 'exit' untuk keluar):\n");
            printf("BTP: ");
            
            char btp[MAX_BTP];
            if (fgets(btp, sizeof(btp), stdin) == NULL) break;
            
            trim(btp);
            
            if (strlen(btp) == 0) continue;
            if (strcasecmp(btp, "exit") == 0 || strcasecmp(btp, "quit") == 0) break;
            
            analyze_btp(btp, "TRSF.csv");
            
            printf("Analyze BTP lain? (y/n): ");
            char answer[10];
            fgets(answer, sizeof(answer), stdin);
            if (answer[0] != 'y' && answer[0] != 'Y') break;
            printf("\n");
        }
    }
    
    printf("\n👋 Selesai!\n\n");
    return 0;
}
