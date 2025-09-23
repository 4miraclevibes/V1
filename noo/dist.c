If(
    currentUser.Role = "FSS",
    // Filter untuk user FSS berdasarkan distributor
    FirstN(
        Sort(
            Filter(
                VW_NEW_CUSTOMER_FAST,
                (
                    Distributor <> "PT. CAHAYA INTI PUTRA SEJAHTERA - BANDUNG" && 
                    Distributor <> "PT. CATUR SENTOSA ANUGERAH - BANDUNG" && 
                    Distributor <> "PT. CATUR SENTOSA ANUGERAH - BOGOR" && 
                    Distributor <> "PT. CATUR SENTOSA ANUGERAH - CENGKARENG" && 
                    Distributor <> "PT. CATUR SENTOSA ANUGERAH - SUBANG" && 
                    Distributor <> "PT. TIGARAKSA SATRIA - JAKARTA" && 
                    Distributor <> "PT. UNI GEMILANG SENTOSA" && 
                    Distributor <> "KACS" && 
                    Distributor <> "COOLKAS" &&
                    Distributor <> "DIRECT"
                ) && 
                (IsBlank(searchDistributorNoo_1.Text) || searchDistributorNoo_1.Text in Distributor) &&
                (IsBlank(searchCodeNoo_1.Text) || searchCodeNoo_1.Text in 'Customer Code') && 
                (IsBlank(searchNameNoo_1.Text) || searchNameNoo_1.Text in 'Customer Name') && 
                (IsBlank(searchStatusNoo_1.Text) || searchStatusNoo_1.Text in NOO) && 
                (IsBlank(searchCdNoo_1.Text) || searchCdNoo_1.Text in Createdate) && 
                (IsBlank(searchRegionCbNoo_1.Selected) || Region = searchRegionCbNoo_1.Selected.Value) && 
                (IsBlank(searchDistributorCbNoo_1.Selected) || Distributor = searchDistributorCbNoo_1.Selected.Value) &&
                (IsBlank(searchAccCbNoo2.Selected) || Account = searchAccCbNoo2.Selected.Value) &&
                (IsBlank(searchMcCbNoo2.Selected) || 'Market Channel' = searchMcCbNoo2.Selected.Value) &&
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
    // Filter untuk user non-FSS (tampilkan semua)
    FirstN(
        Sort(
            Filter(
                VW_NEW_CUSTOMER_FAST,
                (
                    Distributor <> "PT. CAHAYA INTI PUTRA SEJAHTERA - BANDUNG" && 
                    Distributor <> "PT. CATUR SENTOSA ANUGERAH - BANDUNG" && 
                    Distributor <> "PT. CATUR SENTOSA ANUGERAH - BOGOR" && 
                    Distributor <> "PT. CATUR SENTOSA ANUGERAH - CENGKARENG" && 
                    Distributor <> "PT. CATUR SENTOSA ANUGERAH - SUBANG" && 
                    Distributor <> "PT. TIGARAKSA SATRIA - JAKARTA" && 
                    Distributor <> "PT. UNI GEMILANG SENTOSA" && 
                    Distributor <> "KACS" && 
                    Distributor <> "COOLKAS" &&
                    Distributor <> "DIRECT"
                ) && 
                (IsBlank(searchDistributorNoo_1.Text) || searchDistributorNoo_1.Text in Distributor) &&
                (IsBlank(searchCodeNoo_1.Text) || searchCodeNoo_1.Text in 'Customer Code') && 
                (IsBlank(searchNameNoo_1.Text) || searchNameNoo_1.Text in 'Customer Name') && 
                (IsBlank(searchStatusNoo_1.Text) || searchStatusNoo_1.Text in NOO) && 
                (IsBlank(searchCdNoo_1.Text) || searchCdNoo_1.Text in Createdate) && 
                (IsBlank(searchRegionCbNoo_1.Selected) || Region = searchRegionCbNoo_1.Selected.Value) && 
                (IsBlank(searchDistributorCbNoo_1.Selected) || Distributor = searchDistributorCbNoo_1.Selected.Value) &&
                (IsBlank(searchAccCbNoo2.Selected) || Account = searchAccCbNoo2.Selected.Value) &&
                (IsBlank(searchMcCbNoo2.Selected) || 'Market Channel' = searchMcCbNoo2.Selected.Value)
            ),
            RevenueCM,
            SortOrder.Descending
        ),
        200000
    )
)