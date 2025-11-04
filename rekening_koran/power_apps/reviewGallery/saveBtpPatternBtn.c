// ═══════════════════════════════════════════════════════════════════════════════
// BUTTON OnSelect: Save New BTP Pattern to Master
// ═══════════════════════════════════════════════════════════════════════════════

// Delegation-safe: Get last ID using First() + Sort (instead of Last + CountRows)
With(
    {
        lastRecord: First(
            Sort(MASTER_CUSTOMER_BTP_PATTERN, id, SortOrder.Descending)
        )
    },
    // 1. Save to MASTER_CUSTOMER_BTP_PATTERN
    Patch(
        MASTER_CUSTOMER_BTP_PATTERN,
        Defaults(MASTER_CUSTOMER_BTP_PATTERN),
        {
            customer_name: ThisItem.CustomerName,
            category: ThisItem.BankType,
            match_count: 1,
            total_transactions: 1,
            match_percentage: 100,
            last_line_number: If(
                !IsBlank(lastRecord.id),
                lastRecord.id + 1,
                1
            ),
            created_date: Now(),
            btp: rkBtpRV.Text
        }
    );
    
    // 2. Insert to MP_REKENING_KORAN
    Patch(
        MP_REKENING_KORAN,
        Defaults(MP_REKENING_KORAN),
        {
            trx_date: If(
                !IsBlank(ThisItem.TransactionDate),
                DateValue(ThisItem.TransactionDate),
                Today()
            ),
            created_at: Now(),
            updated_at: Now(),
            credit: "9999",
            btp: rkBtpRV.Text,
            desc: If(
                !IsBlank(ThisItem.Description),
                Left(ThisItem.Description, 255),
                ""
            )
        }
    );
    
    // 3. Update BTP_REVIEW: Set IsApproved = 1 (mirip approveToFinal)
    Patch(
        BTP_REVIEW,
        LookUp(BTP_REVIEW, ID = ThisItem.ID),
        {
            IsApproved: true,
            ApprovedBy: User().Email,
            ApprovedAt: Now(),
            ModifiedAt: Now()
        }
    )
);

// Show success notification
Notify(
    "✅ BTP Pattern berhasil disimpan dan ditambahkan ke Rekening Koran!",
    NotificationType.Success
);

// Navigate back to distributor screen
Navigate(
    RKScreen,
    ScreenTransition.Fade
);