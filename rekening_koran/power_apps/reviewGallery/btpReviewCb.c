// Ambil CustomerName dari ID, lalu cari semua distinct BTP dengan CustomerName yang sama
// Delegation-safe: Gunakan comparison operator saja (no IsBlank!)
With(
    {
        customerName: LookUp(
            BTP_REVIEW,
            ID = editingItemId,
            CustomerName
        )
    },
    Distinct(
        Filter(
            BTP_REVIEW,
            CustomerName = customerName && 
            BTP <> ""
        ),
        BTP
    )
)


// ═══════════════════════════════════════════════════════════════════════════════
// DEFAULT: Ambil BTP dengan MatchPercentage tertinggi (first)
// Return: Table dengan field 'Value' (sama format kayak Distinct)
// ═══════════════════════════════════════════════════════════════════════════════
With(
    {
        customerName: LookUp(
            BTP_REVIEW,
            ID = editingItemId,
            CustomerName
        )
    },
    Table(
        {
            Value: First(
                Sort(
                    Filter(
                        BTP_REVIEW,
                        CustomerName = customerName && 
                        BTP <> ""
                    ),
                    MatchPercentage,
                    SortOrder.Descending
                )
            ).BTP
        }
    )
)