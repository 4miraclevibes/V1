#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE_LENGTH 1000
#define MAX_CUSTOMERS 10000
#define MAX_PATTERNS 20000

typedef struct {
    char customer_name[200];
    char btp[50];
    int count;
    int total_transactions;
    double match_rate;
    int last_line_number;
} CustomerPattern;

typedef struct {
    char customer_name[200];
    int total_transactions;
} CustomerTotal;


// Function to extract customer name from DBS description
// Format: "KR OTOMATIS LLG-DBS INDONESIA [CUSTOMER_WORD1] [CUSTOMER_WORD2] [ADDITIONAL_INFO]"
// Smart extraction: If Array[4] is "PT" or "CV", take Array[4] + Array[5] + Array[6]
// Otherwise, take Array[4] + Array[5]
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
    
    // Check if we have at least 6 tokens (array[4] and array[5] exist)
    if (token_count < 6) {
        return 0; // Not enough tokens
    }
    
    // Extract array[4] and array[5] (index 4 and 5)
    char word1[100], word2[100];
    strcpy(word1, tokens[4]);
    strcpy(word2, tokens[5]);
    
    // Check if words are not empty
    if (strlen(word1) == 0 || strlen(word2) == 0) {
        return 0;
    }
    
    // Smart extraction: Check if Array[4] is "PT" or "CV"
    if (strcmp(word1, "PT") == 0 || strcmp(word1, "CV") == 0) {
        // Take Array[4] + Array[5] + Array[6] if available
        if (token_count >= 7) {
            char word3[100];
            strcpy(word3, tokens[6]);
            if (strlen(word3) > 0) {
                snprintf(customer_name, 200, "%s %s %s", word1, word2, word3);
            } else {
                snprintf(customer_name, 200, "%s %s", word1, word2);
            }
        } else {
            snprintf(customer_name, 200, "%s %s", word1, word2);
        }
    } else {
        // Take Array[4] + Array[5] only
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

int main() {
    printf("Starting DBS pattern generation...\n");
    
    FILE* file = fopen("DBS.csv", "r");
    if (!file) {
        printf("Error: Cannot open DBS.csv\n");
        return 1;
    }
    
    printf("File opened successfully\n");
    
    CustomerPattern patterns[MAX_PATTERNS];
    CustomerTotal customer_totals[MAX_CUSTOMERS];
    int pattern_count = 0;
    int customer_total_count = 0;
    
    char line[MAX_LINE_LENGTH];
    int line_number = 0;
    int processed_lines = 0;
    int skipped_lines = 0;
    
    printf("Processing DBS data...\n");
    
    // First pass: collect all customer transaction totals
    while (fgets(line, sizeof(line), file)) {
        line_number++;
        if (line_number == 1) continue; // Skip header
        
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        
        char* btp = strtok(line, ";");
        char* desc = strtok(NULL, ";");
        
        if (!btp || !desc) {
            printf("Skipping line %d: invalid format\n", line_number);
            skipped_lines++;
            continue;
        }
        
        char customer_name[200];
        if (extract_customer_name(desc, customer_name)) {
            processed_lines++;
            if (processed_lines % 10 == 0) {
                printf("Processed %d valid lines\n", processed_lines);
            }
            
            // Find or add customer total
            int found = 0;
            for (int i = 0; i < customer_total_count; i++) {
                if (strcmp(customer_totals[i].customer_name, customer_name) == 0) {
                    customer_totals[i].total_transactions++;
                    found = 1;
                    break;
                }
            }
            
            if (!found && customer_total_count < MAX_CUSTOMERS) {
                strcpy(customer_totals[customer_total_count].customer_name, customer_name);
                customer_totals[customer_total_count].total_transactions = 1;
                customer_total_count++;
            }
        } else {
            printf("Skipping line %d: cannot extract customer name from '%s'\n", line_number, desc);
            skipped_lines++;
        }
    }
    
    printf("First pass complete. Found %d unique customers\n", customer_total_count);
    printf("Skipped %d lines (non-numeric BTP or invalid format)\n", skipped_lines);
    
    // Reset file pointer
    rewind(file);
    line_number = 0;
    processed_lines = 0;
    
    // Second pass: collect patterns
    while (fgets(line, sizeof(line), file)) {
        line_number++;
        if (line_number == 1) continue; // Skip header
        
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        
        char* btp = strtok(line, ";");
        char* desc = strtok(NULL, ";");
        
        if (!btp || !desc) {
            continue;
        }
        
        char customer_name[200];
        if (extract_customer_name(desc, customer_name)) {
            processed_lines++;
            if (processed_lines % 10 == 0) {
                printf("Second pass: processed %d valid lines\n", processed_lines);
            }
            
            // Find existing pattern or create new one
            int found = 0;
            for (int i = 0; i < pattern_count; i++) {
                if (strcmp(patterns[i].customer_name, customer_name) == 0 && 
                    strcmp(patterns[i].btp, btp) == 0) {
                    patterns[i].count++;
                    patterns[i].last_line_number = line_number;
                    found = 1;
                    break;
                }
            }
            
            if (!found && pattern_count < MAX_PATTERNS) {
                strcpy(patterns[pattern_count].customer_name, customer_name);
                strcpy(patterns[pattern_count].btp, btp);
                patterns[pattern_count].count = 1;
                patterns[pattern_count].last_line_number = line_number;
                pattern_count++;
            }
        }
    }
    
    fclose(file);
    
    printf("Second pass complete. Found %d patterns\n", pattern_count);
    
    // Calculate total transactions and match rates
    for (int i = 0; i < pattern_count; i++) {
        // Find customer total
        for (int j = 0; j < customer_total_count; j++) {
            if (strcmp(patterns[i].customer_name, customer_totals[j].customer_name) == 0) {
                patterns[i].total_transactions = customer_totals[j].total_transactions;
                patterns[i].match_rate = (patterns[i].count * 100.0) / customer_totals[j].total_transactions;
                break;
            }
        }
    }
    
    // Generate SQL file
    FILE* sql_file = fopen("master_customer_btp_pattern_DBS.sql", "w");
    if (!sql_file) {
        printf("Error: Cannot create SQL file\n");
        return 1;
    }
    
    fprintf(sql_file, "-- DBS Customer BTP Patterns\n");
    fprintf(sql_file, "-- Generated from DBS.csv\n");
    fprintf(sql_file, "-- Total patterns: %d\n", pattern_count);
    fprintf(sql_file, "-- Skipped non-numeric BTPs: %d lines\n\n", skipped_lines);
    
    fprintf(sql_file, "INSERT INTO master_customer_btp_pattern (customer_name, btp, count, total_transactions, match_percentage, last_line_number) VALUES\n");
    
    for (int i = 0; i < pattern_count; i++) {
        char escaped_customer[400];
        escape_single_quotes(patterns[i].customer_name, escaped_customer);
        
        fprintf(sql_file, "('%s', '%s', %d, %d, %.2f, %d)",
                escaped_customer, patterns[i].btp, patterns[i].count, 
                patterns[i].total_transactions, patterns[i].match_rate, patterns[i].last_line_number);
        
        if (i < pattern_count - 1) {
            fprintf(sql_file, ",\n");
        } else {
            fprintf(sql_file, ";\n");
        }
    }
    
    fclose(sql_file);
    
    // Print summary
    printf("\n=== DBS PATTERN GENERATION COMPLETE ===\n");
    printf("Total patterns generated: %d\n", pattern_count);
    printf("Total unique customers: %d\n", customer_total_count);
    printf("Skipped non-numeric BTPs: %d lines\n", skipped_lines);
    printf("SQL file created: master_customer_btp_pattern_DBS.sql\n\n");
    
    // Show top 10 patterns by count
    printf("Top 10 patterns by transaction count:\n");
    printf("Customer Name                    | BTP         | Count | Total | Match %%\n");
    printf("--------------------------------|-------------|-------|-------|--------\n");
    
    // Sort by count (simple bubble sort)
    for (int i = 0; i < pattern_count - 1; i++) {
        for (int j = 0; j < pattern_count - i - 1; j++) {
            if (patterns[j].count < patterns[j + 1].count) {
                CustomerPattern temp = patterns[j];
                patterns[j] = patterns[j + 1];
                patterns[j + 1] = temp;
            }
        }
    }
    
    for (int i = 0; i < 10 && i < pattern_count; i++) {
        printf("%-30s | %-11s | %5d | %5d | %6.2f%%\n",
               patterns[i].customer_name, patterns[i].btp, patterns[i].count,
               patterns[i].total_transactions, patterns[i].match_rate);
    }
    
    return 0;
}

