// Customer Form Logic dengan editing dan view
If(
    IsBlank(editingItemId),
    // Mode view - tidak bisa edit
    Navigate(CostumerScreen, ScreenTransition.Fade),
    
    // Mode edit - bisa edit name, code, distributor, account
    // 1. Create customer baru dengan data yang bisa diubah

Set(
    customerNew,
    Patch(
        MP_CUSTOMER_NEW,
        Defaults(MP_CUSTOMER_NEW),
        {
            name: costumerName.Text,
            code: costumerCode.Text,
            distributor_id: ThisItem.distributor_id,
            //distributor_id: LookUp(Distributors, Distributor = costumerDistributorCb.Selected.Value, Id),
            account_id: costumerAccountCb.Selected.Id,
            account_trading_term: costumerAccountTrade.Text,
            regency_id: costumerKotaCb.Selected.Id,
            // Field lain ambil dari data lama
            createdate: First(Filter(MP_CUSTOMER_NEW, id = editingItemId)).createdate,
            status: "active",
            desc: "Change from customer" &editingItemId,
            city: costumerArea.Text,
            btp: ThisItem.btp,
            btn: ThisItem.btn,
            top: ThisItem.customer_top,
            credit_limit: If(
                IsBlank(ThisItem.credit_limit) || ThisItem.credit_limit = "",
                Blank(),
                Value(ThisItem.credit_limit)
            ),
            GFcode: ThisItem.GFcode,
            kecamatan: ThisItem.kecamatan,
            nik: ThisItem.nik,
            npwp: ThisItem.npwp,
            supply_chain: ThisItem.supply_chain,
            top50: ThisItem.top50,
            va_gdi: ThisItem.va_gdi,
            va_gi: ThisItem.va_gi,
            created_at: Now(),
            updated_at: Now()
        }
    )
);
    
    // 2. Update customer lama menjadi inactive
    
    Patch(
        MP_CUSTOMER_NEW,
        First(Filter(MP_CUSTOMER_NEW, id = editingItemId)),
        {
            status: "inactive",
            desc: "Change to customer" &customerNew.id,
            updated_at: Now()
        }
    );
    
    Refresh(VW_MP_CUSTOMER_COMPLETE_NEW);
    Navigate(CostumerScreen, ScreenTransition.Fade);
    Notify("Berhasil diperbarui", NotificationType.Success)
) 