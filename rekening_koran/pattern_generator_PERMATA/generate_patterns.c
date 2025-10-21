#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE_LENGTH 1000
#define MAX_CUSTOMERS 1000
#define MAX_PATTERNS 1000
#define MAX_CUSTOMER_TOTALS 10000

// Structure to store customer patterns
typedef struct {
    char customer_name[200];
    char btp[50];
    int count;
    int total_transactions;
    double match_percentage;
    int last_line_number;
} CustomerPattern;

// Structure to store customer totals
typedef struct {
    char customer_name[200];
    int total_transactions;
} CustomerTotal;

// Global variables
CustomerPattern patterns[MAX_PATTERNS];
CustomerTotal customer_totals[MAX_CUSTOMER_TOTALS];
int pattern_count = 0;
int customer_total_count = 0;

// Function to convert string to uppercase
void to_upper(char* str) {
    while (*str) {
        *str = toupper(*str);
        str++;
    }
}

// Function to check if a string is all uppercase
int is_all_caps(const char* str) {
    while (*str) {
        if (!isupper(*str) && *str != ' ') {
            return 0;
        }
        str++;
    }
    return 1;
}

// Function to extract customer name from PERMATA description
// Format: "KR OTOMATIS LLG-PERMATA [CUSTOMER_WORD1] [CUSTOMER_WORD2] [ADDITIONAL_INFO]"
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

// Function to escape single quotes for SQL
void escape_single_quotes(const char* input, char* output) {
    int i = 0, j = 0;
    while (input[i] != '\0') {
        if (input[i] == '\'') {
            output[j++] = '\'';
            output[j++] = '\'';
        } else {
            output[j++] = input[i];
        }
        i++;
    }
    output[j] = '\0';
}

// Function to find customer total
int find_customer_total(const char* customer_name, int* total) {
    for (int i = 0; i < customer_total_count; i++) {
        if (strcmp(customer_totals[i].customer_name, customer_name) == 0) {
            *total = customer_totals[i].total_transactions;
            return 1;
        }
    }
    return 0;
}

// Function to add or update customer total
void add_customer_total(const char* customer_name, int count) {
    for (int i = 0; i < customer_total_count; i++) {
        if (strcmp(customer_totals[i].customer_name, customer_name) == 0) {
            customer_totals[i].total_transactions += count;
            return;
        }
    }
    
    // Add new customer total
    if (customer_total_count < MAX_CUSTOMER_TOTALS) {
        strcpy(customer_totals[customer_total_count].customer_name, customer_name);
        customer_totals[customer_total_count].total_transactions = count;
        customer_total_count++;
    }
}

// Function to find existing pattern
int find_pattern(const char* customer_name, const char* btp, int* index) {
    for (int i = 0; i < pattern_count; i++) {
        if (strcmp(patterns[i].customer_name, customer_name) == 0 && 
            strcmp(patterns[i].btp, btp) == 0) {
            *index = i;
            return 1;
        }
    }
    return 0;
}

// Function to add or update pattern
void add_pattern(const char* customer_name, const char* btp, int line_number) {
    int index;
    if (find_pattern(customer_name, btp, &index)) {
        // Update existing pattern
        patterns[index].count++;
        if (line_number > patterns[index].last_line_number) {
            patterns[index].last_line_number = line_number;
        }
    } else {
        // Add new pattern
        if (pattern_count < MAX_PATTERNS) {
            strcpy(patterns[pattern_count].customer_name, customer_name);
            strcpy(patterns[pattern_count].btp, btp);
            patterns[pattern_count].count = 1;
            patterns[pattern_count].total_transactions = 0; // Will be updated later
            patterns[pattern_count].match_percentage = 0.0; // Will be calculated later
            patterns[pattern_count].last_line_number = line_number;
            pattern_count++;
        }
    }
}

// Function to calculate match percentages
void calculate_match_percentages() {
    for (int i = 0; i < pattern_count; i++) {
        int total_transactions;
        if (find_customer_total(patterns[i].customer_name, &total_transactions)) {
            patterns[i].total_transactions = total_transactions;
            patterns[i].match_percentage = (patterns[i].count * 100.0) / total_transactions;
        }
    }
}

// Function to generate SQL file
void generate_sql() {
    FILE* file = fopen("master_customer_btp_pattern_PERMATA.sql", "w");
    if (!file) {
        printf("Error: Cannot create SQL file\n");
        return;
    }
    
    fprintf(file, "-- PERMATA Customer BTP Pattern Master Data\n");
    fprintf(file, "-- Generated from PERMATA.csv\n");
    fprintf(file, "-- Format: customer_name, btp, category, count, total_transactions, match_percentage, last_line_number\n\n");
    
    for (int i = 0; i < pattern_count; i++) {
        char escaped_customer_name[400];
        escape_single_quotes(patterns[i].customer_name, escaped_customer_name);
        
        fprintf(file, "INSERT INTO master_customer_btp_pattern VALUES ('%s', '%s', 'PERMATA', %d, %d, %.2f, %d);\n",
                escaped_customer_name, patterns[i].btp, patterns[i].count, 
                patterns[i].total_transactions, patterns[i].match_percentage, 
                patterns[i].last_line_number);
    }
    
    fclose(file);
    printf("SQL file generated: master_customer_btp_pattern_PERMATA.sql\n");
}

int main() {
    FILE* file = fopen("PERMATA.csv", "r");
    if (!file) {
        printf("Error: Cannot open PERMATA.csv\n");
        return 1;
    }
    
    char line[MAX_LINE_LENGTH];
    int line_number = 0;
    int processed_lines = 0;
    
    printf("=== PERMATA PATTERN GENERATOR ===\n");
    printf("Processing PERMATA.csv...\n\n");
    
    // Skip header
    if (fgets(line, sizeof(line), file)) {
        line_number++;
    }
    
    // First pass: collect customer totals
    while (fgets(line, sizeof(line), file)) {
        line_number++;
        
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        
        // Split by semicolon
        char* btp = strtok(line, ";");
        char* desc = strtok(NULL, ";");
        
        if (btp && desc) {
            char customer_name[200];
            if (extract_customer_name(desc, customer_name)) {
                add_customer_total(customer_name, 1);
                processed_lines++;
            }
        }
    }
    
    // Reset file pointer
    rewind(file);
    
    // Skip header again
    if (fgets(line, sizeof(line), file)) {
        line_number = 1;
    }
    
    // Second pass: collect patterns
    while (fgets(line, sizeof(line), file)) {
        line_number++;
        
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        
        // Split by semicolon
        char* btp = strtok(line, ";");
        char* desc = strtok(NULL, ";");
        
        if (btp && desc) {
            char customer_name[200];
            if (extract_customer_name(desc, customer_name)) {
                add_pattern(customer_name, btp, line_number);
            }
        }
    }
    
    fclose(file);
    
    // Calculate match percentages
    calculate_match_percentages();
    
    // Generate SQL file
    generate_sql();
    
    printf("Processing complete!\n");
    printf("Total lines processed: %d\n", processed_lines);
    printf("Unique customers: %d\n", customer_total_count);
    printf("Patterns generated: %d\n", pattern_count);
    
    return 0;
}
