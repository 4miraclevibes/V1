// =====================================================
// Button 2: Download File dari SharePoint
// =====================================================
// Solusi bypass CSP blob block: Download dari SharePoint link
// =====================================================

// Check apakah SharePoint link sudah ready
If(
    varLinkReady && !IsBlank(varSharePointLink),
    // Download langsung dari SharePoint link (bypass CSP!)
    Download(varSharePointLink);
    Notify("📥 Download started...", NotificationType.Success, 2000),
    // Error
    Notify("❌ No file ready. Generate link first.", NotificationType.Warning, 3000)
);