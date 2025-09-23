// Customer Form Logic dengan editing dan view
If(
    IsBlank(editingItemId),
    // Mode view - tidak bisa edit
    Navigate(KamKaeScreen, ScreenTransition.Fade),
    // Mode edit - lakukan update dengan error handling
    If(
        !IsBlank(LookUp(Accounts, Id = editingItemId)),
        // Record ditemukan - lakukan update
        Patch(
            Accounts,
            LookUp(Accounts, Id = editingItemId),
            {
                Account: kamkaeAccount.Text,
                GroupKam: kamkaeGroup.Text,
                Kam: kamkaeName.Text,
                status: "active",
                sort: accountSort.Text
            }
        );
        Navigate(KamKaeScreen, ScreenTransition.Fade);
        Notify("Berhasil diperbarui", NotificationType.Success),
        // Record tidak ditemukan - tampilkan error
        Notify("Data tidak ditemukan. ID: " & editingItemId, NotificationType.Error)
    )
) 