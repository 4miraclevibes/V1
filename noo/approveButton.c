// Cek semua LookUp terlebih dahulu
Set(
    distributorLookup,
    LookUp(
        Distributors,
        Distributor = ThisItem.Distributor,
        Id
    )
);
Set(
    accountLookup,
    LookUp(
        Accounts,
        Id = costumerAccountCbNoo.Selected.Id,
        Id
    )
);
Set(
    regencyLookup,
    LookUp(
        Regencies,
        Kota = costumerKotaNoo.Text,
        Id
    )
);
// Buat pesan error yang spesifik
Set(
    errorMessage,
    ""
);
If(
    IsBlank(distributorLookup),
    Set(
        errorMessage,
        errorMessage & "• Distributor: " & ThisItem.Distributor
    ),
    ""
);
If(
    IsBlank(accountLookup),
    Set(
        errorMessage,
        If(
            errorMessage <> "",
            errorMessage & Char(10),
            ""
        ) & "• Account: " & costumerAccountCbNoo.Selected.Account
    ),
    ""
);
// Cek FSS berdasarkan data combobox yang valid
If(
    FSSID.Text = "NEED TO FILL" || FSSID.Text = "" || IsBlank(FSSID.Text),
    Set(
        errorMessage,
        If(
            errorMessage <> "",
            errorMessage & Char(10),
            ""
        ) & "• FSS: Harus dipilih dari daftar yang tersedia"
    ),
    ""
);
If(
    IsBlank(regencyLookup),
    Set(
        errorMessage,
        If(
            errorMessage <> "",
            errorMessage & Char(10),
            ""
        ) & "• Kab/Kota: " & ThisItem.'Kab/Kota'
    ),
    ""
);
// Cek apakah ada error
If(
    errorMessage = "",
    // Semua ditemukan - lakukan Patch
    Set(
        customerSelected,
        Patch(
            MP_CUSTOMER,
            Defaults(MP_CUSTOMER),
            {
                id: GUID(),
                name: ThisItem.'Customer Name',
                code: ThisItem.'Customer Code',
                distributor_id: distributorLookup,
                account_id: accountLookup,
                account_trading_term: costumerAttNoo.Text,
                regency_id: regencyLookup,
                city:"kosong",
                createdate: ThisItem.Createdate,
                status: "active",
                desc: "Approve from NOO Pada Tanggal : " & Now() & " | Dengan Status NOO : " & isNooValue,
                created_at: Now(),
                updated_at: Now()
            }
        )
    );
    If(
        ThisItem.Distributor = "KACS" || ThisItem.Distributor = "COOLKAS",
        // Ambil data FSS berdasarkan ID
        Set(
            fssSelected,
            LookUp(
                MP_MASTER_FSS_KC,
                id = Value(FSSID.Text)// Pastikan FSSID.Text adalah angka, gunakan Value jika perlu
            )
        );
        // Simpan data ke MP_FSS_KC
        Patch(
            MP_FSS_KC,
            Defaults(MP_FSS_KC),
            {
                distributor: distributorLookup,
                market_chanel: ThisItem.'Market Channel',
                customer_code: ThisItem.'Customer Code',
                customer_name: ThisItem.'Customer Name',
                kabupaten_kota: regencyLookup,
                fss_name: fssSelected.fssname,
                fss_code: fssSelected.fsscode,
                fss_type: fssSelected.fsstype,
                aspm: "-",
                sales_executive:"-",
                desc:"active",
                status:"active",
                customer_id:customerSelected.id,
                master_fss_id:fssSelected.id,
                created_at: Now(),
                updated_at: Now()
            }
        ),
        // Ambil data FSS berdasarkan ID
        Set(
            fssSelected,
            LookUp(
                MP_MASTER_FSS_KC,
                id = Value(FSSID.Text)// Pastikan FSSID.Text adalah angka, gunakan Value jika perlu
            )
        );
        // Simpan data ke MP_FSS_KC
        Patch(
            MP_FSS_OUTLET,
            Defaults(MP_FSS_OUTLET),
            {
                distributor: distributorLookup,
                market_chanel: ThisItem.'Market Channel',
                customer_code: ThisItem.'Customer Code',
                customer_name: ThisItem.'Customer Name',
                kabupaten_kota: regencyLookup,
                fss_name: fssSelected.fssname,
                fss_code: fssSelected.fsscode,
                fss_type: fssSelected.fsstype,
                aspm: "-",
                sales_executive:"-",
                desc:"active",
                status:"active",
                customer_id:customerSelected.id,
                master_fss_id:fssSelected.id,
                created_at: Now(),
                updated_at: Now()
            }
        );
    );
    Navigate(
        CostumerScreenNoo,
        ScreenTransition.Fade
    );
    Notify(
        "✅ Berhasil diperbarui",
        NotificationType.Success
    ),
    // Ada yang tidak ditemukan - tampilkan error spesifik
    Notify(
        "🚫 Data master tidak ditemukan:" & Char(10) & Char(10) & errorMessage & Char(10) & Char(10) & "📋 Silakan periksa data master terlebih dahulu.",
        NotificationType.Error
    )
)