If(
    currentUser.Role = "FSS",
    // Filter untuk user FSS berdasarkan distributor
    Distinct(
        Filter(
            Distributors,
            (IsBlank(searchSubRegionCb.Selected) || SubRegionId = searchSubRegionCb.Selected.Id) &&
            ((Distributor = Trim(Text(First(Split(currentUser.distributor, ",")).Value))) ||
             (CountRows(Split(currentUser.distributor, ",")) >= 2 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 2).Value))) ||
             (CountRows(Split(currentUser.distributor, ",")) > 2 && Distributor = Trim(Text(Last(Split(currentUser.distributor, ",")).Value))))
        ),
        Distributor
    ),
    // Filter untuk user non-FSS (tampilkan semua)
    Distinct(
        Filter(
            Distributors,
            IsBlank(searchSubRegionCb.Selected) || SubRegionId = searchSubRegionCb.Selected.Id
        ),
        Distributor
    )
)