// App OnStart - Load data ke Collection
// Taruh di App.OnStart property

// Load BTP_REVIEW ke collection
ClearCollect(
    colBtpReview,
    BTP_REVIEW
);

// Load VW_BTP_REVIEW_COUNT ke collection
ClearCollect(
    colBtpCount,
    VW_BTP_REVIEW_COUNT
);
