If(
    currentUser.Role = "FSS",
    // Filter untuk user FSS berdasarkan distributor
    FirstN(
        Sort(
            Filter(
                VW_MP_CUSTOMER_COMPLETE,
                customer_status = "active" &&
                (IsBlank(searchDistributor.Text) || searchDistributor.Text in distributor_name) &&
                (IsBlank(searchCode.Text) || searchCode.Text in customer_code) &&
                (IsBlank(searchName.Text) || searchName.Text in customer_name) &&
                //(IsBlank(searchAccount.Text) || searchAccount.Text in account_name) &&
                (IsBlank(searchAccountTrade.Text) || searchAccountTrade.Text in customer_account_trading_term) &&
                //(IsBlank(searchSubChanel.Text) || searchSubChanel.Text in sub_chanel_name) &&
                //(IsBlank(searchChanel.Text) || searchChanel.Text in chanel_name) &&
                //(IsBlank(searchMarketchanel.Text) || searchMarketchanel.Text in market_name) &&
                //(IsBlank(searchKota.Text) || searchKota.Text in regency_name) &&
                (IsBlank(searchStatus.Text) || searchStatus.Text in customer_status) &&
                //(IsBlank(searchProvince.Text) || searchProvince.Text in province_name) &&
                (IsBlank(searchRegionCb.Selected) || region_name = searchRegionCb.Selected.Region) &&
                (IsBlank(searchSubRegionCb.Selected) || sub_region_name = searchSubRegionCb.Selected.SubRegion) &&
                (IsBlank(searchDistributorCb.Selected) || distributor_name = searchDistributorCb.Selected.Value) &&
                (IsBlank(searchAccountCb.Selected) || account_name = searchAccountCb.Selected.Account) &&
                (IsBlank(searchScCb.Selected) || sub_chanel_name = searchScCb.Selected.SubChanel) &&
                (IsBlank(searchChanelCb.Selected) || chanel_name = searchChanelCb.Selected.Chanel) &&
                (IsBlank(searchMcCb.Selected) || market_name = searchMcCb.Selected.MarketChanel) &&
                (IsBlank(searchKotaCb.Selected) || regency_name = searchKotaCb.Selected.Kota) && 
                (IsBlank(searchProvCb.Selected) || province_name = searchProvCb.Selected.Provinsi) &&
                ((distributor_name = Trim(Text(First(Split(currentUser.distributor, ",")).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) >= 2 && distributor_name = Trim(Text(Index(Split(currentUser.distributor, ","), 2).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) >= 3 && distributor_name = Trim(Text(Index(Split(currentUser.distributor, ","), 3).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) >= 4 && distributor_name = Trim(Text(Index(Split(currentUser.distributor, ","), 4).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) >= 5 && distributor_name = Trim(Text(Index(Split(currentUser.distributor, ","), 5).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) > 1 && distributor_name = Trim(Text(Last(Split(currentUser.distributor, ",")).Value))))
            ),
            customer_id,
            SortOrder.Descending
        ),
        200000
    ),
    // Filter untuk user non-FSS (tampilkan semua)
    FirstN(
        Sort(
            Filter(
                VW_MP_CUSTOMER_COMPLETE,
                customer_status = "active" &&
                (IsBlank(searchDistributor.Text) || searchDistributor.Text in distributor_name) &&
                (IsBlank(searchCode.Text) || searchCode.Text in customer_code) &&
                (IsBlank(searchName.Text) || searchName.Text in customer_name) &&
                //(IsBlank(searchAccount.Text) || searchAccount.Text in account_name) &&
                (IsBlank(searchAccountTrade.Text) || searchAccountTrade.Text in customer_account_trading_term) &&
                //(IsBlank(searchSubChanel.Text) || searchSubChanel.Text in sub_chanel_name) &&
                //(IsBlank(searchChanel.Text) || searchChanel.Text in chanel_name) &&
                //(IsBlank(searchMarketchanel.Text) || searchMarketchanel.Text in market_name) &&
                //(IsBlank(searchKota.Text) || searchKota.Text in regency_name) &&
                (IsBlank(searchStatus.Text) || searchStatus.Text in customer_status) &&
                //(IsBlank(searchProvince.Text) || searchProvince.Text in province_name) &&
                (IsBlank(searchRegionCb.Selected) || region_name = searchRegionCb.Selected.Region) &&
                (IsBlank(searchSubRegionCb.Selected) || sub_region_name = searchSubRegionCb.Selected.SubRegion) &&
                (IsBlank(searchDistributorCb.Selected) || distributor_name = searchDistributorCb.Selected.Value) &&
                (IsBlank(searchAccountCb.Selected) || account_name = searchAccountCb.Selected.Account) &&
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
)
