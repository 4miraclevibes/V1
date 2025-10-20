#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE_LENGTH 500
#define MAX_CUSTOMERS 30000 // Increased to handle more unique customers
#define MAX_PATTERNS 30000  // Increased to handle more patterns

// Structure to hold customer BTP pattern data
typedef struct {
    char customer_name[200];
    char btp[50];
    int count;
    int total_transactions;
    double match_percentage;
    int last_line_number;
} CustomerPattern;

// Structure to hold total transactions for each customer
typedef struct {
    char customer_name[200];
    int total_transactions;
} CustomerTotal;

CustomerPattern patterns[MAX_PATTERNS];
int pattern_count = 0;

CustomerTotal customer_totals[MAX_CUSTOMERS];
int customer_total_count = 0;

// Function to convert a string to uppercase
void to_upper(char* s) {
    for (int i = 0; s[i]; i++) {
        s[i] = toupper(s[i]);
    }
}

// Function to trim leading/trailing whitespace
void trim_whitespace(char* s) {
    char* end;

    // Trim leading space
    while (isspace((unsigned char)*s)) s++;

    if (*s == 0) // All spaces?
        return;

    // Trim trailing space
    end = s + strlen(s) - 1;
    while (end > s && isspace((unsigned char)*end)) end--;

    // Write new null terminator
    *(end + 1) = 0;
}

// Function to escape single quotes for SQL insertion
void escape_single_quotes(char* str) {
    char buffer[MAX_LINE_LENGTH * 2]; // Buffer to hold escaped string
    int i = 0, j = 0;
    while (str[i] != '\0' && j < MAX_LINE_LENGTH * 2 - 2) { // -2 for potential extra quote and null terminator
        if (str[i] == '\'') {
            buffer[j++] = '\'';
            buffer[j++] = '\'';
        } else {
            buffer[j++] = str[i];
        }
        i++;
    }
    buffer[j] = '\0';
    strcpy(str, buffer);
}

// Function to extract customer name from DANAMON description
// Format: "KR OTOMATIS LLG-DANAMON [CUSTOMER_WORD1] [CUSTOMER_WORD2] [ADDITIONAL_INFO]"
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

// Function to get total transactions for a customer
int get_customer_total_transactions(const char* customer_name) {
    for (int i = 0; i < customer_total_count; i++) {
        if (strcmp(customer_totals[i].customer_name, customer_name) == 0) {
            return customer_totals[i].total_transactions;
        }
    }
    return 0; // Not found
}

// Function to update total transactions for a customer
void update_customer_total_transactions(const char* customer_name) {
    for (int i = 0; i < customer_total_count; i++) {
        if (strcmp(customer_totals[i].customer_name, customer_name) == 0) {
            customer_totals[i].total_transactions++;
            return;
        }
    }
    // If not found, add new customer
    if (customer_total_count < MAX_CUSTOMERS) {
        strcpy(customer_totals[customer_total_count].customer_name, customer_name);
        customer_totals[customer_total_count].total_transactions = 1;
        customer_total_count++;
    } else {
        fprintf(stderr, "Warning: MAX_CUSTOMERS limit reached. Cannot add more customer totals.\n");
    }
}

// Function to generate SQL insert statements
void generate_sql(const char* output_file) {
    FILE* out_file = fopen(output_file, "w");
    if (!out_file) {
        perror("Error opening output SQL file");
        return;
    }

    fprintf(out_file, "-- DANAMON Customer BTP Pattern Master Data\n");
    fprintf(out_file, "-- Generated from DANAMON.csv\n");
    fprintf(out_file, "-- Format: customer_name, btp, count, total_transactions, match_percentage, last_line_number\n\n");

    for (int i = 0; i < pattern_count; i++) {
        char escaped_customer_name[MAX_LINE_LENGTH * 2];
        strcpy(escaped_customer_name, patterns[i].customer_name);
        escape_single_quotes(escaped_customer_name);

        fprintf(out_file, "INSERT INTO master_customer_btp_pattern VALUES ('%s', '%s', %d, %d, %.2f, %d);\n",
                escaped_customer_name,
                patterns[i].btp,
                patterns[i].count,
                patterns[i].total_transactions,
                patterns[i].match_percentage,
                patterns[i].last_line_number);
    }

    fclose(out_file);
}

int main() {
    FILE* file;
    char line[MAX_LINE_LENGTH];
    char btp_str[50];
    char description[MAX_LINE_LENGTH];
    char customer_name[200];
    int line_num = 0;

    printf("=== DANAMON PATTERN GENERATOR ===\n");
    printf("Processing DANAMON.csv...\n");

    file = fopen("DANAMON.csv", "r");
    if (!file) {
        perror("Error opening DANAMON.csv");
        return 1;
    }

    // Skip header
    if (fgets(line, sizeof(line), file) == NULL) {
        fprintf(stderr, "Error: DANAMON.csv is empty or cannot read header.\n");
        fclose(file);
        return 1;
    }
    line_num++;

    while (fgets(line, sizeof(line), file)) {
        line_num++;
        // Remove newline character
        line[strcspn(line, "\n")] = 0;

        // Split BTP and description
        char* token = strtok(line, ";");
        if (token) {
            strcpy(btp_str, token);
            trim_whitespace(btp_str);
        } else {
            fprintf(stderr, "Warning: Skipping line %d due to missing BTP.\n", line_num);
            continue;
        }

        token = strtok(NULL, ""); // Rest of the line is description
        if (token) {
            strcpy(description, token);
            trim_whitespace(description);
        } else {
            fprintf(stderr, "Warning: Skipping line %d due to missing description.\n", line_num);
            continue;
        }

        // Extract customer name
        if (extract_customer_name(description, customer_name)) {
            update_customer_total_transactions(customer_name);

            // Check if pattern already exists
            int found = 0;
            for (int i = 0; i < pattern_count; i++) {
                if (strcmp(patterns[i].customer_name, customer_name) == 0 &&
                    strcmp(patterns[i].btp, btp_str) == 0) {
                    patterns[i].count++;
                    patterns[i].last_line_number = line_num; // Update with latest line number
                    found = 1;
                    break;
                }
            }

            if (!found) {
                if (pattern_count < MAX_PATTERNS) {
                    strcpy(patterns[pattern_count].customer_name, customer_name);
                    strcpy(patterns[pattern_count].btp, btp_str);
                    patterns[pattern_count].count = 1;
                    patterns[pattern_count].last_line_number = line_num;
                    pattern_count++;
                } else {
                    fprintf(stderr, "Warning: MAX_PATTERNS limit reached. Cannot add more patterns.\n");
                }
            }
        } else {
            // fprintf(stderr, "Warning: Could not extract customer name from description on line %d: %s\n", line_num, description);
        }
    }
    fclose(file);

    // Calculate match percentages
    for (int i = 0; i < pattern_count; i++) {
        int total_cust_transactions = get_customer_total_transactions(patterns[i].customer_name);
        if (total_cust_transactions > 0) {
            patterns[i].total_transactions = total_cust_transactions;
            patterns[i].match_percentage = (double)patterns[i].count * 100.0 / total_cust_transactions;
        } else {
            patterns[i].total_transactions = 0;
            patterns[i].match_percentage = 0.0;
        }
    }

    generate_sql("master_customer_btp_pattern_DANAMON.sql");

    printf("\nSQL file generated: master_customer_btp_pattern_DANAMON.sql\n");
    printf("Processing complete!\n");
    printf("Total lines processed: %d\n", line_num - 1); // Exclude header
    printf("Unique customers: %d\n", customer_total_count);
    printf("Patterns generated: %d\n", pattern_count);

    return 0;
}

