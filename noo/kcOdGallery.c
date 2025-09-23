If(
    currentUser.role = "FSS",
    FirstN(
        Sort(
            Filter(
                VW_NEW_CUSTOMER_FAST,
                (
                    Distributor = "PT. CAHAYA INTI PUTRA SEJAHTERA - BANDUNG" ||
                    Distributor = "PT. CATUR SENTOSA ANUGERAH - BANDUNG" ||
                    Distributor = "PT. CATUR SENTOSA ANUGERAH - BOGOR" ||
                    Distributor = "PT. CATUR SENTOSA ANUGERAH - CENGKARENG" ||
                    Distributor = "PT. CATUR SENTOSA ANUGERAH - SUBANG" ||
                    Distributor = "PT. TIGARAKSA SATRIA - JAKARTA" ||
                    Distributor = "PT. UNI GEMILANG SENTOSA" ||
                    Distributor = "KACS" || Distributor = "COOLKAS"
                ) && 
                //(IsBlank(searchDistributorNoo.Text) || searchDistributorNoo.Text in Distributor) &&
                (IsBlank(searchCodeNoo.Text) || searchCodeNoo.Text in 'Customer Code') &&
                (IsBlank(searchNameNoo.Text) || searchNameNoo.Text in 'Customer Name') &&
                //(IsBlank(searchMarketchanelNoo.Text) || searchMarketchanelNoo.Text in 'Market Channel') &&
                (IsBlank(searchAccCbNoo.Selected) || Account = searchAccCbNoo.Selected.Value) &&
                (IsBlank(searchMcCbNoo.Selected) || 'Market Channel' = searchMcCbNoo.Selected.Value) &&
                (IsBlank(searchStatusNoo.Text) || searchStatusNoo.Text in NOO) &&
                (IsBlank(searchCdNoo.Text) || searchCdNoo.Text in Createdate) &&
                (IsBlank(searchRegionCbNoo.Selected) || Region = searchRegionCbNoo.Selected.Value) &&
                (IsBlank(searchDistributorCbNoo.Selected) || Distributor = searchDistributorCbNoo.Selected.Value) &&
                // Filter distributor berdasarkan currentUser jika role FSS
                ((Distributor = Trim(Text(First(Split(currentUser.distributor, ",")).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) >= 2 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 2).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) >= 3 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 3).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) >= 4 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 4).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) >= 5 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 5).Value))) ||
                 (CountRows(Split(currentUser.distributor, ",")) > 1 && Distributor = Trim(Text(Last(Split(currentUser.distributor, ",")).Value))))
            ),
            RevenueCM,
            SortOrder.Descending
        ),
        200000
    ),
    FirstN(
        Sort(
            Filter(
                VW_NEW_CUSTOMER_FAST,
                (
                    Distributor = "PT. CAHAYA INTI PUTRA SEJAHTERA - BANDUNG" ||
                    Distributor = "PT. CATUR SENTOSA ANUGERAH - BANDUNG" ||
                    Distributor = "PT. CATUR SENTOSA ANUGERAH - BOGOR" ||
                    Distributor = "PT. CATUR SENTOSA ANUGERAH - CENGKARENG" ||
                    Distributor = "PT. CATUR SENTOSA ANUGERAH - SUBANG" ||
                    Distributor = "PT. TIGARAKSA SATRIA - JAKARTA" ||
                    Distributor = "PT. UNI GEMILANG SENTOSA" ||
                    Distributor = "KACS" || Distributor = "COOLKAS"
                ) && 
                //(IsBlank(searchDistributorNoo.Text) || searchDistributorNoo.Text in Distributor) &&
                (IsBlank(searchCodeNoo.Text) || searchCodeNoo.Text in 'Customer Code') &&
                (IsBlank(searchNameNoo.Text) || searchNameNoo.Text in 'Customer Name') &&
                //(IsBlank(searchMarketchanelNoo.Text) || searchMarketchanelNoo.Text in 'Market Channel') &&
                (IsBlank(searchAccCbNoo.Selected) || Account = searchAccCbNoo.Selected.Value) &&
                (IsBlank(searchMcCbNoo.Selected) || 'Market Channel' = searchMcCbNoo.Selected.Value) &&
                (IsBlank(searchStatusNoo.Text) || searchStatusNoo.Text in NOO) &&
                (IsBlank(searchCdNoo.Text) || searchCdNoo.Text in Createdate) &&
                (IsBlank(searchRegionCbNoo.Selected) || Region = searchRegionCbNoo.Selected.Value) &&
                (IsBlank(searchDistributorCbNoo.Selected) || Distributor = searchDistributorCbNoo.Selected.Value)
            ),
            RevenueCM,
            SortOrder.Descending
        ),
        200000
    )
)