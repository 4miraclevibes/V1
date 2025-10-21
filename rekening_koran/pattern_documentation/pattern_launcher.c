#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>

#define MAX_BANKS 20

typedef struct {
    int id;
    char name[30];
    char folder[50];
    char executable[60];
    char group[30];
} Bank;

Bank banks[MAX_BANKS] = {
    // Group 1: Array[3] + Array[4]
    {1, "BNI", "pattern_generator_BNI", "test_btp_pattern_bni", "Array[3]+[4]"},
    {2, "BTPN", "pattern_generator_BTPN", "test_btp_pattern_btpn", "Array[3]+[4]"},
    {3, "MANDIRI", "pattern_generator_MANDIRI", "test_btp_pattern_mandiri", "Array[3]+[4]"},
    {4, "BRI", "pattern_generator_BRI", "test_btp_pattern_bri", "Array[3]+[4]"},
    {5, "MEGA", "pattern_generator_MEGA", "test_btp_pattern_mega", "Array[3]+[4]"},
    {6, "PERMATA", "pattern_generator_PERMATA", "test_btp_pattern_permata", "Array[3]+[4]"},
    {7, "DANAMON", "pattern_generator_DANAMON", "test_btp_pattern_danamon", "Array[3]+[4]"},
    {8, "CITIBANK", "pattern_generator_CITIBANK", "test_btp_pattern_citibank", "Array[3]+[4]"},
    {9, "SINARMAS", "pattern_generator_SINARMAS", "test_btp_pattern_sinarmas", "Array[3]+[4]"},
    
    // Group 2: Array[4] + Array[5]
    {10, "CIMB", "pattern_generator_CIMB", "test_btp_pattern_cimb", "Array[4]+[5]"},
    {11, "MAYBANK", "pattern_generator_MAYBANK", "test_btp_pattern_maybank", "Array[4]+[5]"},
    {12, "HSBC", "pattern_generator_HSBC", "test_btp_pattern_hsbc", "Array[4]+[5]"},
    {13, "UOB", "pattern_generator_UOB", "test_btp_pattern_uob", "Array[4]+[5]"},
    {14, "MUAMALAT", "pattern_generator_MUAMALAT", "test_btp_pattern_muamalat", "Array[4]+[5]"},
    {15, "OCBC", "pattern_generator_OCBC", "test_btp_pattern_ocbc", "Array[4]+[5]"},
    {16, "DBS", "pattern_generator_DBS", "test_btp_pattern_dbs", "Array[4]+[5]"},
    {17, "CAPITAL", "pattern_generator_CAPITAL", "test_btp_pattern_capital", "Array[4]+[5]"},
    {18, "WOORI", "pattern_generator_WOORI", "test_btp_pattern_woori", "Array[4]+[5]"},
    
    // Group 3: Special Logic
    {19, "TRSF", "pattern_generator_TRSF", "test_btp_pattern_trsf", "Special Logic"},
    {20, "BI-FAST", "pattern_generator_BIFAST", "test_btp_pattern_bifast", "Special Logic"}
};

void clear_screen() {
    #ifdef _WIN32
        system("cls");
    #else
        system("clear");
    #endif
}

void print_header() {
    printf("\n");
    printf("╔══════════════════════════════════════════════════════════════════════╗\n");
    printf("║                                                                      ║\n");
    printf("║           🏦 BANK PATTERN GENERATOR - LAUNCHER v1.0 🏦              ║\n");
    printf("║                                                                      ║\n");
    printf("║              Command Center for All Pattern Generators              ║\n");
    printf("║                    Total Banks: 20 Systems                          ║\n");
    printf("║                                                                      ║\n");
    printf("╚══════════════════════════════════════════════════════════════════════╝\n");
    printf("\n");
}

void print_menu() {
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("📋 MAIN MENU\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("\n");
    printf("  1. 🔍 Test BTP Pattern (Select Bank)\n");
    printf("  2. 📊 Show All Banks\n");
    printf("  3. 🔧 Generate Patterns (Select Bank)\n");
    printf("  4. 📖 Show Documentation\n");
    printf("  Q. ❌ Quit\n");
    printf("\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("Your choice: ");
}

void print_bank_list() {
    printf("\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("🏦 ALL AVAILABLE BANKS (20 Systems)\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("\n");
    
    printf("📂 GROUP 1: Array[3] + Array[4] Extraction (9 banks)\n");
    printf("────────────────────────────────────────────────────────────────────────\n");
    for (int i = 0; i < 9; i++) {
        printf("  %2d. %-12s [%s]\n", banks[i].id, banks[i].name, banks[i].group);
    }
    
    printf("\n📂 GROUP 2: Array[4] + Array[5] Extraction (9 banks)\n");
    printf("────────────────────────────────────────────────────────────────────────\n");
    for (int i = 9; i < 18; i++) {
        printf("  %2d. %-12s [%s]\n", banks[i].id, banks[i].name, banks[i].group);
    }
    
    printf("\n📂 GROUP 3: Special Logic (2 banks)\n");
    printf("────────────────────────────────────────────────────────────────────────\n");
    for (int i = 18; i < 20; i++) {
        printf("  %2d. %-12s [%s]\n", banks[i].id, banks[i].name, banks[i].group);
    }
    
    printf("\n════════════════════════════════════════════════════════════════════════\n");
}

void run_test_btp(int bank_id) {
    if (bank_id < 1 || bank_id > 20) {
        printf("\n❌ Invalid bank ID!\n");
        return;
    }
    
    Bank selected = banks[bank_id - 1];
    
    printf("\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("🚀 Launching Test BTP Pattern for %s\n", selected.name);
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("Folder: %s\n", selected.folder);
    printf("Extraction Logic: %s\n", selected.group);
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("\n");
    
    // Try standard name first, then with suffix
    char executable[100];
    char check_cmd[256];
    
    // Try: test_btp_pattern (standard)
    strcpy(executable, "test_btp_pattern");
    snprintf(check_cmd, sizeof(check_cmd), "cd ../%s && test -f %s", selected.folder, executable);
    
    if (system(check_cmd) != 0) {
        // Try with suffix: test_btp_pattern_bankname
        strcpy(executable, selected.executable);
        snprintf(check_cmd, sizeof(check_cmd), "cd ../%s && test -f %s", selected.folder, executable);
        
        if (system(check_cmd) != 0) {
            printf("⚠️  Executable not found! Please compile first:\n");
            printf("   cd ../%s\n", selected.folder);
            printf("   gcc test_btp_pattern.c -o test_btp_pattern\n\n");
            return;
        }
    }
    
    printf("▶️  Starting %s Test BTP Pattern...\n", selected.name);
    printf("Executable: %s\n\n", executable);
    
    // Build and run the command
    char command[256];
    snprintf(command, sizeof(command), "cd ../%s && ./%s", selected.folder, executable);
    system(command);
    
    printf("\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("✅ %s Test BTP Pattern Finished\n", selected.name);
    printf("════════════════════════════════════════════════════════════════════════\n");
}

void run_generate_patterns(int bank_id) {
    if (bank_id < 1 || bank_id > 20) {
        printf("\n❌ Invalid bank ID!\n");
        return;
    }
    
    Bank selected = banks[bank_id - 1];
    
    printf("\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("🔧 Generating Patterns for %s\n", selected.name);
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("Folder: %s\n", selected.folder);
    printf("Extraction Logic: %s\n", selected.group);
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("\n");
    
    // Try standard name first, then with suffix
    char executable[100];
    char check_cmd[256];
    
    // Try: generate_patterns (standard)
    strcpy(executable, "generate_patterns");
    snprintf(check_cmd, sizeof(check_cmd), "cd ../%s && test -f %s", selected.folder, executable);
    
    if (system(check_cmd) != 0) {
        // Try with suffix: generate_patterns_bankname
        snprintf(executable, sizeof(executable), "generate_patterns_%s", selected.name);
        // Convert to lowercase
        for (int i = 0; executable[i]; i++) {
            executable[i] = tolower(executable[i]);
        }
        // Handle special cases
        if (strcmp(selected.name, "BI-FAST") == 0) {
            strcpy(executable, "generate_patterns_bifast");
        }
        
        snprintf(check_cmd, sizeof(check_cmd), "cd ../%s && test -f %s", selected.folder, executable);
        
        if (system(check_cmd) != 0) {
            printf("⚠️  Executable not found! Please compile first:\n");
            printf("   cd ../%s\n", selected.folder);
            printf("   gcc generate_patterns.c -o generate_patterns\n\n");
            return;
        }
    }
    
    printf("▶️  Starting %s Pattern Generation...\n", selected.name);
    printf("Executable: %s\n\n", executable);
    
    // Build and run the command
    char command[256];
    snprintf(command, sizeof(command), "cd ../%s && ./%s", selected.folder, executable);
    system(command);
    
    printf("\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("✅ %s Pattern Generation Finished\n", selected.name);
    printf("════════════════════════════════════════════════════════════════════════\n");
}

void show_documentation() {
    printf("\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("📖 Opening Documentation...\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("\n");
    
    system("cat documentation.txt | head -100");
    
    printf("\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
    printf("For full documentation, see: documentation.txt\n");
    printf("════════════════════════════════════════════════════════════════════════\n");
}

int main() {
    char choice[10];
    int bank_id;
    
    while (1) {
        clear_screen();
        print_header();
        print_menu();
        
        if (fgets(choice, sizeof(choice), stdin) == NULL) {
            break;
        }
        
        // Remove newline
        choice[strcspn(choice, "\n")] = 0;
        
        // Convert to uppercase for Q
        if (choice[0] == 'q' || choice[0] == 'Q') {
            printf("\n");
            printf("════════════════════════════════════════════════════════════════════════\n");
            printf("👋 Thank you for using Bank Pattern Generator Launcher!\n");
            printf("════════════════════════════════════════════════════════════════════════\n");
            printf("\n");
            break;
        }
        
        int menu_choice = atoi(choice);
        
        switch (menu_choice) {
            case 1:
                // Test BTP Pattern
                print_bank_list();
                printf("\nSelect bank ID (1-20) or 0 to cancel: ");
                if (fgets(choice, sizeof(choice), stdin) != NULL) {
                    bank_id = atoi(choice);
                    if (bank_id > 0 && bank_id <= 20) {
                        run_test_btp(bank_id);
                        printf("\nPress Enter to continue...");
                        getchar();
                    }
                }
                break;
                
            case 2:
                // Show All Banks
                print_bank_list();
                printf("\nPress Enter to continue...");
                getchar();
                break;
                
            case 3:
                // Generate Patterns
                print_bank_list();
                printf("\nSelect bank ID (1-20) or 0 to cancel: ");
                if (fgets(choice, sizeof(choice), stdin) != NULL) {
                    bank_id = atoi(choice);
                    if (bank_id > 0 && bank_id <= 20) {
                        char confirm[10];
                        printf("\n⚠️  This will regenerate patterns for %s. Continue? (y/n): ", banks[bank_id-1].name);
                        if (fgets(confirm, sizeof(confirm), stdin) != NULL) {
                            if (confirm[0] == 'y' || confirm[0] == 'Y') {
                                run_generate_patterns(bank_id);
                                printf("\nPress Enter to continue...");
                                getchar();
                            }
                        }
                    }
                }
                break;
                
            case 4:
                // Show Documentation
                show_documentation();
                printf("\nPress Enter to continue...");
                getchar();
                break;
                
            default:
                printf("\n❌ Invalid choice! Please try again.\n");
                printf("Press Enter to continue...");
                getchar();
                break;
        }
    }
    
    return 0;
}

