// ═══════════════════════════════════════════════════════════════════════════════
// MODAL BUTTON OnSelect: Cancel Approval (No)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Description:
//   User klik "No" di modal confirmation → Close modal, tidak lakukan apa-apa
//
// ═══════════════════════════════════════════════════════════════════════════════

// Close modal
Set(
    varShowApproveModal,
    false
);

// Optional: Show info notification
Notify(
    "ℹ️ Approval dibatalkan.",
    NotificationType.Information
)

