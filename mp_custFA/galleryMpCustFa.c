    // Filter untuk user non-FSS (tampilkan semua)
    FirstN(
        Sort(
            Filter(
                VW_MP_CUSTOMER,
                customer_status = "active" &&
                Not IsBlank(va_gi) &&
                //(IsBlank(searchDistributor.Text) || searchDistributor.Text in distributor_name) &&
                (IsBlank(searchCode.Text) || searchCode.Text in customer_code) &&
                (IsBlank(searchName.Text) || searchName.Text in customer_name) &&
                //(IsBlank(searchAccount.Text) || searchAccount.Text in account_name) &&
                (IsBlank(searchAccountTrade.Text) || searchAccountTrade.Text in customer_account_trading_term) &&
                //(IsBlank(searchSubChanel.Text) || searchSubChanel.Text in sub_chanel_name) &&
                //(IsBlank(searchChanel.Text) || searchChanel.Text in chanel_name) &&
                //(IsBlank(searchMarketchanel.Text) || searchMarketchanel.Text in market_name) &&
                //(IsBlank(searchKota.Text) || searchKota.Text in regency_name) &&
                (IsBlank(searchBtpMpc.Text) || searchBtpMpc.Text in customer_status) &&
                //(IsBlank(searchProvince.Text) || searchProvince.Text in province_name) &&
                (IsBlank(searchRegionCb.Selected) || region_name = searchRegionCb.Selected.Region) &&
                (IsBlank(searchSubRegionCb.Selected) || sub_region_name = searchSubRegionCb.Selected.SubRegion) &&
                (IsBlank(searchDistributorCbTop50.Selected) || distributor_name = searchDistributorCbTop50.Selected.Value) &&
                (IsBlank(searchAccountCbTop50.Selected) || account_name = searchAccountCbTop50.Selected.Value) &&
                (IsBlank(searchScCb.Selected) || sub_chanel_name = searchScCb.Selected.SubChanel) &&
                (IsBlank(searchChanelCb.Selected) || chanel_name = searchChanelCb.Selected.Chanel) &&
                (IsBlank(searchMcCb.Selected) || market_name = searchMcCb.Selected.MarketChanel) &&
                (IsBlank(searchKotaCb.Selected) || regency_name = searchKotaCb.Selected.Kota) && 
                (IsBlank(searchProvCb.Selected) || province_name = searchProvCb.Selected.Provinsi)
            ),
            customer_id,
            SortOrder.Descending
        ),
        200000
    )