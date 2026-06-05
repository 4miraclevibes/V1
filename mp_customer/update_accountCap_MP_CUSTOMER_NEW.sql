-- =====================================================
-- update_accountCap_MP_CUSTOMER_NEW.sql
-- =====================================================
-- Purpose:
--   Update [accountCap] di MP_CUSTOMER_NEW berdasarkan accountCap.csv
--
-- Alur:
--   1. Data mapping dari accountCap.csv (account_name -> accountCap)
--   2. Cek account_name via VW_MP_CUSTOMER, cocokkan dengan accountCap.csv
--   3. Ambil account_id dari customer yang match di view
--   4. Update accountCap di MP_CUSTOMER_NEW untuk SEMUA customer
--      yang punya account_id tersebut (bukan hanya 1 row di view)
--
-- Sumber: mp_customer/accountCap.csv
-- Total mapping rows: 219
--
-- Prasyarat:
--   - Kolom accountCap sudah ada di MP_CUSTOMER_NEW
--   - Jalankan ALTER_ADD_accountCap_MP_CUSTOMER_NEW.sql jika belum
-- =====================================================

USE POWERAPPS;
GO

-- Pastikan tipe kolom sesuai data CSV (teks, bukan angka)
IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'MP_CUSTOMER_NEW'
      AND COLUMN_NAME = 'accountCap'
      AND DATA_TYPE IN ('float', 'real', 'decimal', 'numeric', 'int', 'bigint')
)
BEGIN
    ALTER TABLE [dbo].[MP_CUSTOMER_NEW]
    ALTER COLUMN [accountCap] NVARCHAR(255) NULL;
    PRINT 'Kolom accountCap diubah ke NVARCHAR(255)';
END
GO

DECLARE @Source TABLE (
    [account_name] NVARCHAR(255) NOT NULL PRIMARY KEY,
    [accountCap] NVARCHAR(255) NULL
);

INSERT INTO @Source ([account_name], [accountCap])
VALUES
    (N'INDOMARET', N'INDOMARET'),
    (N'OTHER - CAFE', N'OTHER FOOD SERVICE'),
    (N'ALFAMART', N'ALFAMART'),
    (N'KOPI KENANGAN', N'KOPI KENANGAN'),
    (N'LION', N'LION'),
    (N'OTHER - RESTAURANT', N'OTHER FOOD SERVICE'),
    (N'STARBUCKS', N'STARBUCKS'),
    (N'OTHER - AGENT', N'OTHER FOOD SERVICE'),
    (N'GENERAL TRADE', N'GENERAL TRADE'),
    (N'ALFAMIDI', N'ALFAMIDI'),
    (N'OTHER - BAKERY', N'OTHER FOOD SERVICE'),
    (N'HYPERMART', N'HYPERMART'),
    (N'INDOMARET POIN', N'INDOMARET POIN'),
    (N'MTI B EAST INDONESIA', N'MTI B'),
    (N'ASTRONOUT', N'ASTRONOUT'),
    (N'MTI B EAST JAVA & BALNUS', N'MTI B'),
    (N'GRAND LUCKY', N'GRAND LUCKY'),
    (N'OTHER - PUBLIC SERVICES', N'OTHER FOOD SERVICE'),
    (N'MTI B NORTHERN SUMATRA', N'MTI B'),
    (N'MTI B SOUTHERN SUMATRA', N'MTI B'),
    (N'YOGYA', N'YOGYA'),
    (N'FRESH FACTORY', N'FRESH FACTORY'),
    (N'BRASTAGI', N'BRASTAGI'),
    (N'FARMERS MARKET', N'FARMERS MARKET'),
    (N'OTHER - BUBBLE DRINK', N'OTHER FOOD SERVICE'),
    (N'OTHER - HOTEL', N'OTHER FOOD SERVICE'),
    (N'PEPITO', N'PEPITO'),
    (N'AEON', N'AEON'),
    (N'YUMMY FOOD', N'YUMMY FOOD'),
    (N'MTI B WEST JAVA & CENTRAL JAVA', N'MTI B'),
    (N'LOTTE SHOPPING', N'LOTTE SHOPPING'),
    (N'BEARD PAPA', N'BEARD PAPA'),
    (N'WARUNG NAKO', N'WARUNG NAKO'),
    (N'LOTTE MART', N'LOTTE MART'),
    (N'OTHER - PRIBADI', N'OTHER FOOD SERVICE'),
    (N'DIAMOND', N'DIAMOND'),
    (N'OTHER - DESSERT', N'OTHER FOOD SERVICE'),
    (N'FOODHALL', N'FOODHALL'),
    (N'OTHER - CATERING', N'OTHER FOOD SERVICE'),
    (N'HERO', N'HERO'),
    (N'RANCH MARKET', N'RANCH MARKET'),
    (N'HOKKY', N'HOKKY'),
    (N'TIP TOP', N'TIP TOP'),
    (N'PAPAYA', N'PAPAYA'),
    (N'CHATIME', N'CHATIME'),
    (N'SATU SAMA', N'MTI A - OTHERS'),
    (N'HARI HARI', N'HARI HARI'),
    (N'MTI B GREATER JAKARTA', N'MTI B'),
    (N'HOME DELIVERY', N'HOME DELIVERY'),
    (N'BORMA', N'BORMA'),
    (N'OTHER E-COMMERCE', N'OTHER E-COMMERCE'),
    (N'TOP SERATUS', N'TOP SERATUS'),
    (N'MTI B JABODETABEK', N'MTI B'),
    (N'SUZUYA', N'MTI A - OTHERS'),
    (N'FAMILY MART', N'FAMILY MART'),
    (N'TIARA', N'TIARA'),
    (N'NAGA', N'MTI A - OTHERS'),
    (N'% ARABICA', N'OTHER FOOD SERVICE'),
    (N'ES TEH INDONESIA', N'ES TEH INDONESIA'),
    (N'FRESTIVE', N'FRESTIVE'),
    (N'JCO', N'JCO'),
    (N'UNION GROUP', N'UNION GROUP'),
    (N'TOTAL BUAH', N'TOTAL BUAH'),
    (N'BINTANG', N'MTI A - OTHERS'),
    (N'ALL FRESH', N'ALL FRESH'),
    (N'CHANDRA', N'MTI A - OTHERS'),
    (N'SNL', N'MTI A - OTHERS'),
    (N'COLD N BREW GROUP', N'OTHER FOOD SERVICE'),
    (N'CLANDYS', N'MTI A - OTHERS'),
    (N'SEGARI', N'SEGARI'),
    (N'DUTA BUAH', N'MTI A - OTHERS'),
    (N'BARSOL/JOX GROUP', N'OTHER FOOD SERVICE'),
    (N'IRIAN', N'MTI A - OTHERS'),
    (N'CEMARA', N'MTI A - OTHERS'),
    (N'TOKO KITA CAFE', N'OTHER FOOD SERVICE'),
    (N'BOOST JUICE', N'BOOST JUICE'),
    (N'SAYUR BOX', N'SAYUR BOX'),
    (N'YOMART', N'YOMART'),
    (N'XING FU TANG', N'XING FU TANG'),
    (N'MAJU BERSAMA', N'MTI A - OTHERS'),
    (N'BOGAJAYA GROUP', N'OTHER FOOD SERVICE'),
    (N'BUDIMAN', N'MTI A - OTHERS'),
    (N'MARKET CITY', N'MARKET CITY'),
    (N'PARIS BAGUETTE', N'OTHER FOOD SERVICE'),
    (N'JC', N'MTI A - OTHERS'),
    (N'JAKARTA FRUIT', N'MTI A - OTHERS'),
    (N'JAPFA BEST', N'JAPFA BEST'),
    (N'LETON GROUP', N'OTHER FOOD SERVICE'),
    (N'XXI CAFE', N'XXI CAFE'),
    (N'GELAEL', N'MTI A - OTHERS'),
    (N'PASAR BUAH PEKANBARU', N'MTI A - OTHERS'),
    (N'FRESHMART', N'MTI A - OTHERS'),
    (N'ETTORE', N'OTHER FOOD SERVICE'),
    (N'PAUL BAKERY', N'OTHER FOOD SERVICE'),
    (N'ANOMALI COFFEE', N'OTHER FOOD SERVICE'),
    (N'BAJI PAMAI', N'MTI A - OTHERS'),
    (N'SMARCO', N'MTI A - OTHERS'),
    (N'LAZADA', N'LAZADA'),
    (N'GOLDEN BLACK COFFEE', N'OTHER FOOD SERVICE'),
    (N'MINI MART', N'MTI A - OTHERS'),
    (N'ADA GROUP', N'MTI A - OTHERS'),
    (N'PANDE PUTRI', N'MTI A - OTHERS'),
    (N'COLD STONE', N'OTHER FOOD SERVICE'),
    (N'MIROTA', N'MTI A - OTHERS'),
    (N'GOTO', N'GOTO'),
    (N'GELATO FACTORY', N'OTHER FOOD SERVICE'),
    (N'SETIABUDI SM', N'MTI A - OTHERS'),
    (N'MITRA MART', N'MTI A - OTHERS'),
    (N'RUMAH BUAH', N'MTI A - OTHERS'),
    (N'LLAO LLAO', N'OTHER FOOD SERVICE'),
    (N'NOB BAKERY GROUP', N'OTHER FOOD SERVICE'),
    (N'GRABMART KILAT', N'GRABMART KILAT'),
    (N'RITA RITELINDO', N'MTI A - OTHERS'),
    (N'PILONA COFFEE', N'OTHER FOOD SERVICE'),
    (N'DELTA DEWATA', N'MTI A - OTHERS'),
    (N'SAMUDRA SWALAYAN', N'MTI A - OTHERS'),
    (N'AEON DELICA', N'OTHER FOOD SERVICE'),
    (N'KOPI KONNICHIWA', N'OTHER FOOD SERVICE'),
    (N'CIRCLE K', N'CIRCLE K'),
    (N'ASKITCHEN GROUP', N'OTHER FOOD SERVICE'),
    (N'EJJI CAFE', N'OTHER FOOD SERVICE'),
    (N'KEM CHICKS', N'KEM CHICKS'),
    (N'BRAVO SUPERMARKET', N'MTI A - OTHERS'),
    (N'ANYAR KIMIA PO SERANG', N'OTHER FOOD SERVICE'),
    (N'PISON COFFEE', N'OTHER FOOD SERVICE'),
    (N'THE GADE', N'OTHER FOOD SERVICE'),
    (N'LEONI GELATO', N'OTHER FOOD SERVICE'),
    (N'LAKU BALI', N'OTHER FOOD SERVICE'),
    (N'DUNKIN DONUT', N'OTHER FOOD SERVICE'),
    (N'CARREFOUR', N'CARREFOUR'),
    (N'BALI JAYA GROUP', N'OTHER FOOD SERVICE'),
    (N'NANNY''S PAVILION', N'OTHER FOOD SERVICE'),
    (N'ANAK PANAH GROUP', N'OTHER FOOD SERVICE'),
    (N'KOI', N'OTHER FOOD SERVICE'),
    (N'SARI BUANA UD', N'OTHER FOOD SERVICE'),
    (N'ERAMART', N'MTI A - OTHERS'),
    (N'LAI LAI', N'MTI A - OTHERS'),
    (N'ALFAMART BEAN SPOT', N'OTHER FOOD SERVICE'),
    (N'HITAM MANIS GROUP', N'OTHER FOOD SERVICE'),
    (N'FILOSOFI KOPI', N'OTHER FOOD SERVICE'),
    (N'BONNET', N'MTI A - OTHERS'),
    (N'JUSTUS STEAK HOUSE', N'OTHER FOOD SERVICE'),
    (N'SATURDAYS GROUP', N'OTHER FOOD SERVICE'),
    (N'STUJA GROUP', N'OTHER FOOD SERVICE'),
    (N'KRISPY KREME', N'OTHER FOOD SERVICE'),
    (N'REVOLVER GROUP', N'OTHER FOOD SERVICE'),
    (N'UD. SUTARMI', N'OTHER FOOD SERVICE'),
    (N'MATCH BOX GROUP', N'OTHER FOOD SERVICE'),
    (N'MIE KOBER', N'OTHER FOOD SERVICE'),
    (N'LAIN HATI', N'OTHER FOOD SERVICE'),
    (N'NATIONAL', N'NO ACCOUNT CAP'),
    (N'GAYA GELATO', N'OTHER FOOD SERVICE'),
    (N'GOURMET GARAGE GROUP', N'OTHER FOOD SERVICE'),
    (N'SEJIWA COFFEE GROUP', N'OTHER FOOD SERVICE'),
    (N'HURRICANE GRILL', N'OTHER FOOD SERVICE'),
    (N'VENCHI GELATO', N'OTHER FOOD SERVICE'),
    (N'GS RETAIL', N'GS RETAIL'),
    (N'NAKOA CAFE', N'OTHER FOOD SERVICE'),
    (N'LOTUS', N'OTHER FOOD SERVICE'),
    (N'ALLO FRESH', N'ALLO FRESH'),
    (N'KOKUMI', N'OTHER FOOD SERVICE'),
    (N'BLI BLI', N'BLI BLI'),
    (N'PRIMA FRESHMART', N'PRIMA FRESHMART'),
    (N'CBTL', N'OTHER FOOD SERVICE'),
    (N'SHELL DELI2GO', N'OTHER FOOD SERVICE'),
    (N'CHEZ CHOUX', N'OTHER FOOD SERVICE'),
    (N'REDDOG', N'OTHER FOOD SERVICE'),
    (N'BEST MEAT', N'BEST MEAT'),
    (N'ANTHOLOGY COFFE', N'OTHER FOOD SERVICE'),
    (N'EXCELSO COFFEE', N'OTHER FOOD SERVICE'),
    (N'RAMAYANA', N'RAMAYANA'),
    (N'STREET BOBA', N'OTHER FOOD SERVICE'),
    (N'0', N'NO ACCOUNT CAP'),
    (N'CARREFOUR ALFA', N'CARREFOUR ALFA'),
    (N'MOR', N'MOR'),
    (N'OTHERS', N'NO ACCOUNT CAP'),
    (N'DEAR BUTTER', N'OTHER FOOD SERVICE'),
    (N'TOMORO COFFEE', N'OTHER FOOD SERVICE'),
    (N'FORE', N'OTHER FOOD SERVICE'),
    (N'FREE SAMPLE', N'NO ACCOUNT CAP'),
    (N'CV. RUMAH ZAIDA', N'OTHER FOOD SERVICE'),
    (N'TITIK TEMU GROUP', N'OTHER FOOD SERVICE'),
    (N'KOPI KIRI', N'OTHER FOOD SERVICE'),
    (N'LULU', N'LULU'),
    (N'SHOPEE', N'SHOPEE'),
    (N'MTI WEST', N'MTI B'),
    (N'PREMIUM SCHOOL', N'OTHER FOOD SERVICE'),
    (N'TRANSPORTER', N'NO ACCOUNT CAP'),
    (N'GENERAL TRADE - RETAIL', N'GENERAL TRADE'),
    (N'LOKA', N'MTI A - OTHERS'),
    (N'PT SURI TANI PEMUKA', N'OTHER FOOD SERVICE'),
    (N'MTI NORTH', N'MTI B'),
    (N'INTERNAL SALES', N'NO ACCOUNT CAP'),
    (N'MTI EAST', N'MTI B'),
    (N'BLISS ICE CREAM PASAR MINGGU', N'OTHER FOOD SERVICE'),
    (N'ANOMALI COFFEE TMII', N'OTHER FOOD SERVICE'),
    (N'MTI C EAST JAVA & BALNUS', N'MTI B'),
    (N'OTHER - FOOD SERVICE', N'OTHER FOOD SERVICE'),
    (N'MTI C NORTHERN SUMATRA', N'MTI B'),
    (N'OTHER - DESERT', N'OTHER FOOD SERVICE'),
    (N'OTHER - CAF├Ë', N'OTHER FOOD SERVICE'),
    (N'CHAMP RESTO', N'CHAMP RESTO'),
    (N'MTI C GREATER JAKARTA', N'MTI B'),
    (N'TOKONOW', N'TOKONOW'),
    (N'MTI C SOUTHERN SUMATRA', N'MTI B'),
    (N'MAIKU INTERMODA', N'OTHER FOOD SERVICE'),
    (N'KOPI MUST CO', N'OTHER FOOD SERVICE'),
    (N'ASIA PLAZA', N'MTI A - OTHERS'),
    (N'KAISAR', N'MTI A - OTHERS'),
    (N'MTI C EAST INDONESIA', N'MTI B'),
    (N'GOODS DINNER', N'OTHER FOOD SERVICE'),
    (N'OTHER - BEVERAGES', N'OTHER FOOD SERVICE'),
    (N'MTI C WEST JAVA & CENTRAL JAVA', N'MTI B'),
    (N'MTI OTHER JKT', N'MTI B'),
    (N'PAMELLA SUPERMARKET', N'MTI A - OTHERS'),
    (N'MTI C JABODETABEK', N'MTI B'),
    (N'KOPI CINDAY', N'OTHER FOOD SERVICE'),
    (N'GIANT', N'HERO'),
    (N'LIGO', N'MTI B');

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RowsUpdated INT = 0;
    DECLARE @MatchedAccounts INT = 0;

    DECLARE @MatchedAccount TABLE (
        [account_id] BIGINT NOT NULL PRIMARY KEY,
        [account_name] NVARCHAR(255) NULL,
        [accountCap] NVARCHAR(255) NULL
    );

    -- Step 1: account_name match di VW_MP_CUSTOMER -> simpan account_id + accountCap
    INSERT INTO @MatchedAccount ([account_id], [account_name], [accountCap])
    SELECT DISTINCT
        v.[account_id],
        MAX(v.[account_name]) AS [account_name],
        MAX(s.[accountCap]) AS [accountCap]
    FROM [dbo].[VW_MP_CUSTOMER] v
    INNER JOIN @Source s
        ON LTRIM(RTRIM(ISNULL(v.[account_name], ''))) COLLATE Latin1_General_CI_AI
         = LTRIM(RTRIM(s.[account_name])) COLLATE Latin1_General_CI_AI
    WHERE v.[account_id] IS NOT NULL
    GROUP BY v.[account_id];

    SET @MatchedAccounts = @@ROWCOUNT;

    -- Fallback: match langsung ke Accounts jika belum masuk dari view
    INSERT INTO @MatchedAccount ([account_id], [account_name], [accountCap])
    SELECT DISTINCT
        a.[id],
        MAX(a.[account]) AS [account_name],
        MAX(s.[accountCap]) AS [accountCap]
    FROM [dbo].[Accounts] a
    INNER JOIN @Source s
        ON LTRIM(RTRIM(ISNULL(a.[account], ''))) COLLATE Latin1_General_CI_AI
         = LTRIM(RTRIM(s.[account_name])) COLLATE Latin1_General_CI_AI
    WHERE NOT EXISTS (
        SELECT 1
        FROM @MatchedAccount m
        WHERE m.[account_id] = a.[id]
    )
    GROUP BY a.[id];

    SET @MatchedAccounts = @MatchedAccounts + @@ROWCOUNT;

    -- Preview: account_id yang match dari view/accounts
    SELECT
        m.[account_id],
        m.[account_name],
        m.[accountCap] AS New_accountCap,
        COUNT(c.[id]) AS CustomerRowsToUpdate
    FROM @MatchedAccount m
    LEFT JOIN [dbo].[MP_CUSTOMER_NEW] c
        ON c.[account_id] = m.[account_id]
    GROUP BY m.[account_id], m.[account_name], m.[accountCap]
    ORDER BY m.[account_name];

    -- Preview: sample customer per account (via view)
    SELECT
        v.[customer_id],
        v.[customer_code],
        v.[customer_name],
        v.[account_id],
        v.[account_name],
        c.[accountCap] AS Current_accountCap,
        m.[accountCap] AS New_accountCap
    FROM [dbo].[VW_MP_CUSTOMER] v
    INNER JOIN @MatchedAccount m
        ON m.[account_id] = v.[account_id]
    INNER JOIN [dbo].[MP_CUSTOMER_NEW] c
        ON c.[id] = v.[customer_id]
    ORDER BY v.[account_name], v.[customer_id];

    -- Preview: account_name di CSV yang belum match
    SELECT
        s.[account_name],
        s.[accountCap]
    FROM @Source s
    WHERE NOT EXISTS (
        SELECT 1
        FROM @MatchedAccount m
        WHERE LTRIM(RTRIM(ISNULL(m.[account_name], ''))) COLLATE Latin1_General_CI_AI
            = LTRIM(RTRIM(s.[account_name])) COLLATE Latin1_General_CI_AI
    )
    ORDER BY s.[account_name];

    -- Step 2: UPDATE semua row MP_CUSTOMER_NEW yang account_id-nya match
    UPDATE c
    SET
        c.[accountCap] = m.[accountCap],
        c.[updated_at] = GETDATE()
    FROM [dbo].[MP_CUSTOMER_NEW] c
    INNER JOIN @MatchedAccount m
        ON m.[account_id] = c.[account_id];

    SET @RowsUpdated = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @RowsUpdated AS RowsUpdated,
        @MatchedAccounts AS MatchedAccounts,
        (SELECT COUNT(*) FROM @Source) AS TotalMappingRows,
        (
            SELECT COUNT(*)
            FROM [dbo].[MP_CUSTOMER_NEW]
            WHERE [accountCap] IS NOT NULL
              AND LTRIM(RTRIM([accountCap])) <> ''
        ) AS CustomersWithAccountCapAfter,
        (
            SELECT COUNT(*)
            FROM [dbo].[MP_CUSTOMER_NEW]
            WHERE [accountCap] IS NULL
               OR LTRIM(RTRIM([accountCap])) = ''
        ) AS CustomersStillNullAccountCap,
        GETDATE() AS UpdatedAt,
        'Update accountCap berhasil' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    SELECT
        0 AS RowsUpdated,
        @ErrorMessage AS ErrorMessage;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
