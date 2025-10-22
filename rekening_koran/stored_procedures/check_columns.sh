#!/bin/bash

echo "=== MASTER SP Expected Columns (from @AllResults) ==="
grep -A 20 "DECLARE @AllResults TABLE" MASTER/SP_MASTER_FindBTP_Batch.sql | grep -E "^\s+(TransactionID|TransactionDate|Description|CustomerName|BTP|MatchPercentage|MatchCount|TotalTransactions|LastLineNumber|TotalBTPOptions|OptionNumber|BestFlag|LatestFlag|Label|Status|Message|BankType|ProcessedAt)" | wc -l

echo ""
echo "=== TRSF SP Output Columns (from final SELECT) ==="
grep -B 2 "FROM @Results" TRSF/SP_TRSF_FindBTP_Batch.sql | grep -A 50 "SELECT" | grep -v "ORDER BY" | grep -v "FROM" | grep -v "CASE" | grep -E "^\s+(TransactionID|TransactionDate|Description|CustomerName|BTP|MatchPercentage|MatchCount|TotalTransactions|LastLineNumber|TotalBTPOptions|OptionNumber|.*AS BestFlag|.*AS LatestFlag|.*AS Label|Status|.*AS Message|ProcessedAt)" | wc -l

echo ""
echo "Detailed TRSF columns:"
sed -n '289,322p' TRSF/SP_TRSF_FindBTP_Batch.sql | grep -E "^\s+[A-Z]|AS [A-Z]" | head -20

