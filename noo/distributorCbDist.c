If(
    currentUser.Role = "FSS",
    // Filter untuk user FSS berdasarkan distributor
    Distinct(
        Filter(
            VW_NEW_CUSTOMER_FAST,
            (Distributor = "PT. CAHAYA INTI PUTRA SEJAHTERA - BANDUNG" || 
             Distributor = "PT. CATUR SENTOSA ANUGERAH - BANDUNG" || 
             Distributor = "PT. CATUR SENTOSA ANUGERAH - BOGOR" || 
             Distributor = "PT. CATUR SENTOSA ANUGERAH - CENGKARENG" || 
             Distributor = "PT. CATUR SENTOSA ANUGERAH - SUBANG" || 
             Distributor = "PT. TIGARAKSA SATRIA - JAKARTA" || 
             Distributor = "PT. UNI GEMILANG SENTOSA" || 
             Distributor = "KACS" || 
             Distributor = "COOLKAS") &&
            // Filter distributor berdasarkan currentUser jika role FSS
            ((Distributor = Trim(Text(First(Split(currentUser.distributor, ",")).Value))) ||
             (CountRows(Split(currentUser.distributor, ",")) >= 2 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 2).Value))) ||
             (CountRows(Split(currentUser.distributor, ",")) >= 3 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 3).Value))) ||
             (CountRows(Split(currentUser.distributor, ",")) >= 4 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 4).Value))) ||
             (CountRows(Split(currentUser.distributor, ",")) >= 5 && Distributor = Trim(Text(Index(Split(currentUser.distributor, ","), 5).Value))) ||
             (CountRows(Split(currentUser.distributor, ",")) > 1 && Distributor = Trim(Text(Last(Split(currentUser.distributor, ",")).Value))))
        ),
        Distributor
    ),
    // Filter untuk user non-FSS (tampilkan semua)
    Distinct(
        Filter(
            VW_NEW_CUSTOMER_FAST,
            Distributor = "PT. CAHAYA INTI PUTRA SEJAHTERA - BANDUNG" || 
            Distributor = "PT. CATUR SENTOSA ANUGERAH - BANDUNG" || 
            Distributor = "PT. CATUR SENTOSA ANUGERAH - BOGOR" || 
            Distributor = "PT. CATUR SENTOSA ANUGERAH - CENGKARENG" || 
            Distributor = "PT. CATUR SENTOSA ANUGERAH - SUBANG" || 
            Distributor = "PT. TIGARAKSA SATRIA - JAKARTA" || 
            Distributor = "PT. UNI GEMILANG SENTOSA" || 
            Distributor = "KACS" || 
            Distributor = "COOLKAS"
        ),
        Distributor
    )
)