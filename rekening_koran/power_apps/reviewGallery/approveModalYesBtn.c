// ═══════════════════════════════════════════════════════════════════════════════
// MODAL BUTTON OnSelect: Confirm Approval (Yes)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Description:
//   User klik "Yes" di modal confirmation → Execute approval SP
//   Close modal setelah selesai
//
// ═══════════════════════════════════════════════════════════════════════════════

// 1. Close modal first
Set(
    varShowApproveModal,
    false
);

// 2. Show loading indicator
Set(varLoading, true);

// 3. Execute approval SP (mengikuti pattern loginBtn.c)
With(
    {
        // Execute stored procedure
        result: POWERAPPS2.dboSPMASTERApproveToFinal({
            ApprovedBy: User().Email
        })
    },
    // Cek apakah ada data yang dikembalikan
    If(
        CountRows(result.ResultSets.Table1) > 0,
        // Success: Ada result
        With(
            {
                approveData: First(result.ResultSets.Table1)
            },
            // Check if there are rows inserted
            If(
                Value(Text(approveData.RowsInserted)) > 0,
                // Success with rows inserted
                Notify(
                    "✅ Berhasil! " & Text(approveData.RowsInserted) & 
                    " transaksi di-approve dan dipindahkan ke MP_REKENING_KORAN. " &
                    "(" & Text(approveData.RowsUpdated) & " rows updated)",
                    NotificationType.Success
                );
                // Refresh BTP_REVIEW data source
                Refresh(BTP_REVIEW);
                // Clear loading indicator
                Set(varLoading, false),
                
                // No rows to approve
                Notify(
                    "ℹ️ Tidak ada transaksi yang perlu di-approve. " &
                    "Semua transaksi FAIR/GOOD/EXCELLENT sudah di-approve sebelumnya.",
                    NotificationType.Information
                );
                // Clear loading indicator
                Set(varLoading, false)
            )
        ),
        
        // Error: No result returned
        Notify(
            "❌ Error: Gagal approve transactions. Tidak ada response dari server.",
            NotificationType.Error
        );
        // Clear loading indicator
        Set(varLoading, false)
    )
);

