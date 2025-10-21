#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

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

int main() {
    printf("🔍 SIMILARITY DEBUG TOOL\n");
    printf("═══════════════════════════════════════════════════════════════════\n\n");
    
    // Test cases
    const char* test_cases[][2] = {
        {"ARLEN VERTA RAMADH", "RIZKY DWI RAMADHAN"},
        {"ARLEN VERTA RAMADH", "WS95031 683280.00 ARLEN VERTA RAMADH"},
        {"ARLEN VERTA RAMADH", "ARLEN VERTA RAMADH"},
        {"RONNY YULIADY", "RONNY YULIADY"},
        {"DAVID TANTRIS", "DAVID TANTRIS OR F"},
        {"BROOKLYN BOGA UTAM", "WS95051 455520.00 BROOKLYN BOGA UTAM"}
    };
    
    int num_tests = sizeof(test_cases) / sizeof(test_cases[0]);
    
    for (int i = 0; i < num_tests; i++) {
        const char* str1 = test_cases[i][0];
        const char* str2 = test_cases[i][1];
        
        float similarity = calculate_similarity(str1, str2);
        int word_order = strict_word_order_match(str1, str2);
        
        printf("Test %d:\n", i + 1);
        printf("  String 1: \"%s\"\n", str1);
        printf("  String 2: \"%s\"\n", str2);
        printf("  Similarity: %.1f%%\n", similarity);
        printf("  Word Order: %s\n", word_order ? "✅ MATCH" : "❌ NO MATCH");
        printf("  Criteria (>=85%% + word order): %s\n", 
               (similarity >= 85.0 && word_order) ? "✅ ACCEPT" : "❌ REJECT");
        printf("\n");
    }
    
    printf("═══════════════════════════════════════════════════════════════════\n");
    printf("💡 Analysis:\n");
    printf("   - Similarity >= 85%% AND Word Order = ACCEPT\n");
    printf("   - Otherwise = REJECT\n");
    
    return 0;
}
