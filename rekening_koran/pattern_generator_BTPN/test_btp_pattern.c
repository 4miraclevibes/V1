#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_PATTERNS 20000
#define MAX_LINE_LENGTH 1000

typedef struct {
    char customer_name[200];
    char btp[50];
    int count;
    int total_transactions;
    double match_percentage;
    int last_line_number;
} CustomerPattern;

CustomerPattern patterns[MAX_PATTERNS];
int pattern_count = 0;

// Function to extract customer name from BTPN description
// Format: "KR OTOMATIS LLG-BTPN [CUSTOMER_WORD1] [CUSTOMER_WORD2] [ADDITIONAL_INFO]"
// Smart extraction: If Array[3] is "PT" or "CV", take Array[3] + Array[4] + Array[5]
// Otherwise, take Array[3] + Array[4]
int extract_customer_name(const char* description, char* customer_name) {
    char desc_copy[MAX_LINE_LENGTH];
    strcpy(desc_copy, description);
    
    // Split by space
    char* tokens[100];
    int token_count = 0;
    char* token = strtok(desc_copy, " ");
    
    while (token != NULL && token_count < 100) {
        tokens[token_count] = token;
        token_count++;
        token = strtok(NULL, " ");
    }
    
    // Check if we have at least 5 tokens (array[3] and array[4] exist)
    if (token_count < 5) {
        return 0; // Not enough tokens
    }
    
    // Extract array[3] and array[4] (index 3 and 4)
    char word1[100], word2[100];
    strcpy(word1, tokens[3]);
    strcpy(word2, tokens[4]);
    
    // Check if words are not empty
    if (strlen(word1) == 0 || strlen(word2) == 0) {
        return 0;
    }
    
    // Smart extraction: Check if Array[3] is "PT" or "CV"
    if (strcmp(word1, "PT") == 0 || strcmp(word1, "CV") == 0) {
        // Take Array[3] + Array[4] + Array[5] if available
        if (token_count >= 6) {
            char word3[100];
            strcpy(word3, tokens[5]);
            if (strlen(word3) > 0) {
                snprintf(customer_name, 200, "%s %s %s", word1, word2, word3);
            } else {
                snprintf(customer_name, 200, "%s %s", word1, word2);
            }
        } else {
            snprintf(customer_name, 200, "%s %s", word1, word2);
        }
    } else {
        // Take Array[3] + Array[4] only
        snprintf(customer_name, 200, "%s %s", word1, word2);
    }
    
    return 1; // Success
}

// Function to convert string to uppercase
void to_upper(char* str) {
    while (*str) {
        *str = toupper(*str);
        str++;
    }
}

// Load patterns from SQL file
int load_patterns() {
    FILE* file = fopen("master_customer_btp_pattern_BTPN.sql", "r");
    if (!file) {
        printf("Error: Cannot open master_customer_btp_pattern_BTPN.sql\n");
        return 0;
    }
    
    char line[MAX_LINE_LENGTH];
    int in_values = 0;
    
    while (fgets(line, sizeof(line), file)) {
        // Skip comments and empty lines
        if (line[0] == '-' || line[0] == '\n' || line[0] == '\r') {
            continue;
        }
        
        // Check if we're in the VALUES section
        if (strstr(line, "INSERT INTO") != NULL) {
            in_values = 1;
            continue;
        }
        
        if (in_values && strstr(line, "VALUES") != NULL) {
            continue;
        }
        
        if (in_values && strstr(line, "(") != NULL) {
            // Parse the pattern data
            char* start = strchr(line, '(');
            if (start) {
                start++; // Skip the opening parenthesis
                char* end = strrchr(line, ')');
                if (end) {
                    *end = '\0'; // Remove the closing parenthesis
                }
                
                // Parse: 'customer_name', 'btp', count, total_transactions, match_percentage, last_line_number
                // Find first quote and last quote for customer_name
                char* first_quote = strchr(start, '\'');
                if (first_quote) {
                    first_quote++; // Skip opening quote
                    char* second_quote = strchr(first_quote, '\'');
                    if (second_quote) {
                        *second_quote = '\0'; // Terminate customer_name
                        char* customer_name = first_quote;
                        
                        // Find btp after the comma
                        char* btp_start = second_quote + 1;
                        while (*btp_start == ',' || *btp_start == ' ') btp_start++;
                        if (*btp_start == '\'') btp_start++;
                        char* btp_end = strchr(btp_start, '\'');
                        if (btp_end) {
                            *btp_end = '\0';
                            char* btp = btp_start;
                            
                            // Find remaining fields
                            char* remaining = btp_end + 1;
                            char* count_str = strtok(remaining, ",");
                            char* total_str = strtok(NULL, ",");
                            char* match_str = strtok(NULL, ",");
                            char* line_str = strtok(NULL, ",");
                            
                            if (customer_name && btp && count_str && total_str && match_str && line_str) {
                                // Clean customer_name
                                while (*customer_name == ' ') customer_name++;
                                char* end = customer_name + strlen(customer_name) - 1;
                                while (end > customer_name && (*end == ' ' || *end == '\'')) *end-- = '\0';
                                
                                // Clean btp
                                while (*btp == ' ') btp++;
                                end = btp + strlen(btp) - 1;
                                while (end > btp && (*end == ' ' || *end == '\'')) *end-- = '\0';
                                
                                strcpy(patterns[pattern_count].customer_name, customer_name);
                                strcpy(patterns[pattern_count].btp, btp);
                                patterns[pattern_count].count = atoi(count_str);
                                patterns[pattern_count].total_transactions = atoi(total_str);
                                patterns[pattern_count].match_percentage = atof(match_str);
                                patterns[pattern_count].last_line_number = atoi(line_str);
                                pattern_count++;
                            }
                        }
                    }
                }
            }
        }
    }
    
    fclose(file);
    return 1;
}

// Find BTP for a given customer name
int find_btp(const char* customer_name, char* btp, int* count, int* total_transactions, double* match_percentage, int* last_line_number) {
    char search_name[200];
    strcpy(search_name, customer_name);
    to_upper(search_name);
    
    for (int i = 0; i < pattern_count; i++) {
        char pattern_name[200];
        strcpy(pattern_name, patterns[i].customer_name);
        to_upper(pattern_name);
        
        if (strcmp(pattern_name, search_name) == 0) {
            strcpy(btp, patterns[i].btp);
            *count = patterns[i].count;
            *total_transactions = patterns[i].total_transactions;
            *match_percentage = patterns[i].match_percentage;
            *last_line_number = patterns[i].last_line_number;
            return 1;
        }
    }
    return 0;
}

// Display all available BTPs
void display_btp_list() {
    printf("\n=== DAFTAR BTP YANG TERSEDIA ===\n");
    printf("Total patterns: %d\n\n", pattern_count);
    
    // Group by BTP
    char unique_btps[1000][50];
    int btp_counts[1000];
    int unique_btp_count = 0;
    
    // Find unique BTPs
    for (int i = 0; i < pattern_count; i++) {
        int found = 0;
        for (int j = 0; j < unique_btp_count; j++) {
            if (strcmp(unique_btps[j], patterns[i].btp) == 0) {
                btp_counts[j]++;
                found = 1;
                break;
            }
        }
        if (!found && unique_btp_count < 1000) {
            strcpy(unique_btps[unique_btp_count], patterns[i].btp);
            btp_counts[unique_btp_count] = 1;
            unique_btp_count++;
        }
    }
    
    // Display grouped by BTP
    for (int i = 0; i < unique_btp_count; i++) {
        printf("BTP: %s (digunakan oleh %d customer)\n", unique_btps[i], btp_counts[i]);
        printf("----------------------------------------\n");
        
        for (int j = 0; j < pattern_count; j++) {
            if (strcmp(patterns[j].btp, unique_btps[i]) == 0) {
                printf("  %-30s | Count: %3d | Total: %3d | Match: %6.2f%% | Line: %d\n",
                       patterns[j].customer_name, patterns[j].count, 
                       patterns[j].total_transactions, patterns[j].match_percentage, 
                       patterns[j].last_line_number);
            }
        }
        printf("\n");
    }
}

// Display latest BTPs (top 20 by last_line_number)
void display_latest_btps() {
    printf("\n=== BTP TERBARU (TOP 20) ===\n");
    
    // Sort by last_line_number (simple bubble sort)
    CustomerPattern sorted_patterns[MAX_PATTERNS];
    for (int i = 0; i < pattern_count; i++) {
        sorted_patterns[i] = patterns[i];
    }
    
    for (int i = 0; i < pattern_count - 1; i++) {
        for (int j = 0; j < pattern_count - i - 1; j++) {
            if (sorted_patterns[j].last_line_number < sorted_patterns[j + 1].last_line_number) {
                CustomerPattern temp = sorted_patterns[j];
                sorted_patterns[j] = sorted_patterns[j + 1];
                sorted_patterns[j + 1] = temp;
            }
        }
    }
    
    printf("Customer Name                    | BTP         | Count | Total | Match %% | Line\n");
    printf("--------------------------------|-------------|-------|-------|---------|------\n");
    
    int display_count = (pattern_count < 20) ? pattern_count : 20;
    for (int i = 0; i < display_count; i++) {
        printf("%-30s | %-11s | %5d | %5d | %7.2f%% | %4d\n",
               sorted_patterns[i].customer_name, sorted_patterns[i].btp, 
               sorted_patterns[i].count, sorted_patterns[i].total_transactions, 
               sorted_patterns[i].match_percentage, sorted_patterns[i].last_line_number);
    }
}

// Manual test function
void manual_test() {
    char description[MAX_LINE_LENGTH];
    char customer_name[200];
    char btp[50];
    int count, total_transactions, last_line_number;
    double match_percentage;
    
    printf("\n=== MANUAL TEST BTPN PATTERN ===\n");
    printf("Masukkan description BTPN (format: KR OTOMATIS LLG-BTPN ...):\n");
    printf("Contoh: KR OTOMATIS LLG-BTPN AEON INDONESIA, PT\n");
    printf("Atau ketik 'quit' untuk keluar\n\n");
    printf("Description: ");
    
    if (fgets(description, sizeof(description), stdin)) {
        // Remove newline
        description[strcspn(description, "\n")] = 0;
        
        if (strcmp(description, "quit") == 0) {
            return;
        }
        
        if (extract_customer_name(description, customer_name)) {
            printf("\nExtracted customer name: '%s'\n", customer_name);
            
            if (find_btp(customer_name, btp, &count, &total_transactions, &match_percentage, &last_line_number)) {
                printf("\n=== BEST MATCH ===\n");
                printf("Customer Name: %s\n", customer_name);
                printf("BTP: %s\n", btp);
                printf("Count: %d\n", count);
                printf("Total Transactions: %d\n", total_transactions);
                printf("Match Percentage: %.2f%%\n", match_percentage);
                printf("Last Line Number: %d\n", last_line_number);
            } else {
                printf("\nNO PATTERN FOUND for customer: %s\n", customer_name);
                printf("Available options:\n");
                printf("- Ketik 'A' untuk melihat daftar BTP yang tersedia\n");
                printf("- Ketik 'B' untuk melihat BTP terbaru\n");
            }
        } else {
            printf("\nERROR: Cannot extract customer name from description\n");
            printf("Format yang benar: KR OTOMATIS LLG-BTPN [WORD1] [WORD2] [ADDITIONAL_INFO]\n");
        }
    }
}

// Print menu
void print_menu() {
    printf("\n=== BTPN BTP PATTERN TESTER ===\n");
    printf("1. Manual Test (test description)\n");
    printf("2. Load Patterns\n");
    printf("3. Display All Patterns\n");
    printf("A. Daftar BTP yang tersedia\n");
    printf("B. BTP terbaru (latest usage)\n");
    printf("0. Exit\n");
    printf("Pilih menu: ");
}

int main() {
    printf("BTPN BTP Pattern Tester\n");
    printf("=======================\n");
    
    if (!load_patterns()) {
        printf("Failed to load patterns. Make sure master_customer_btp_pattern_BTPN.sql exists.\n");
        return 1;
    }
    
    printf("Loaded %d patterns from master_customer_btp_pattern_BTPN.sql\n", pattern_count);
    
    char input[10];
    int choice;
    while (1) {
        print_menu();
        if (fgets(input, sizeof(input), stdin)) {
            input[strcspn(input, "\n")] = 0; // Remove newline
            
            if (sscanf(input, "%d", &choice) == 1) {
                // Numeric input
            } else if (strlen(input) == 1) {
                // Single character input
                choice = input[0];
            } else {
                choice = -1; // Invalid
            }
        }
        
        switch (choice) {
            case 1:
                manual_test();
                break;
            case 2:
                if (load_patterns()) {
                    printf("Patterns reloaded successfully. Total: %d\n", pattern_count);
                } else {
                    printf("Failed to reload patterns.\n");
                }
                break;
            case 3:
                printf("\n=== ALL PATTERNS ===\n");
                printf("Customer Name                    | BTP         | Count | Total | Match %% | Line\n");
                printf("--------------------------------|-------------|-------|-------|---------|------\n");
                for (int i = 0; i < pattern_count; i++) {
                    printf("%-30s | %-11s | %5d | %5d | %7.2f%% | %4d\n",
                           patterns[i].customer_name, patterns[i].btp, 
                           patterns[i].count, patterns[i].total_transactions, 
                           patterns[i].match_percentage, patterns[i].last_line_number);
                }
                break;
            case 0:
                printf("Goodbye!\n");
                return 0;
            default:
                if (choice == 'A' || choice == 'a') {
                    display_btp_list();
                } else if (choice == 'B' || choice == 'b') {
                    display_latest_btps();
                } else {
                    printf("Invalid choice. Please try again.\n");
                }
                break;
        }
    }
    
    return 0;
}
