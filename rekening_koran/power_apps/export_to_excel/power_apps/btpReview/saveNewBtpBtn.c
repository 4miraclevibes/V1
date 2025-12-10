// Simpan ID record yang akan di-patch
Set(
    varRecordToKeep,
    LookUp(MASTER_CUSTOMER_BTP_PATTERN, customer_name = ThisItem.CustomerName)
);

// Patch record tersebut
Patch(
    MASTER_CUSTOMER_BTP_PATTERN,
    varRecordToKeep,
    {
        btp: rkNewBtp.Text
    }
);

// Delete semua record dengan customer_name yang sama, kecuali yang baru saja di-patch
RemoveIf(
    MASTER_CUSTOMER_BTP_PATTERN,
    customer_name = ThisItem.CustomerName && id <> varRecordToKeep.id
);

Refresh(BTP_REVIEW);
Notify("Berhasil diperbarui", NotificationType.Success)