// Button Refresh - Reload data dari database
// Taruh di Button OnSelect property

// Refresh BTP_REVIEW
ClearCollect(
    colBtpReview,
    BTP_REVIEW
);

// Refresh count
ClearCollect(
    colBtpCount,
    VW_BTP_REVIEW_COUNT
);

Notify("Data refreshed!", NotificationType.Success);
