// ═══════════════════════════════════════════════════════════════════════════════
// BUTTON OnSelect: Upload JSON & Process BTP Matching
// ═══════════════════════════════════════════════════════════════════════════════

// 1. Get JSON from text input (manual paste)
// User will copy-paste JSON content from file to JSONinput
Set(
    varJSONString,
    JSONinput.Text
);

// 2. Call Power Automate Flow
Set(
    varFlowResult,
    BTP_ProcessBankStatement.Run(
        varJSONString,
        User().Email
    )
);

// 3. Show result notification
If(
    varFlowResult.success,
    // Success: Show notification and clear input
    Notify(
        "✅ Berhasil! " & varFlowResult.totalsaved & " transaksi diproses. BatchID: " & varFlowResult.batchid,
        NotificationType.Success
    );
    Reset(JSONinput),
    
    // Error: Show error message (don't clear input)
    Notify(
        "❌ Error: " & varFlowResult.message,
        NotificationType.Error
    )
);

// Optional: Navigate to Review Screen after success
// If(varFlowResult.success, Navigate(ReviewScreen, ScreenTransition.Fade));

