USE [POWERAPPS];
GO

/****** Object:  View [dbo].[VW_MP_CUSTOMER]    Script Date: 05/06/2026 ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- View lengkap untuk MP_CUSTOMER_NEW dengan semua relasi
-- Dedupe: 1 baris per customer_code -> ambil yang paling baru (updated_at DESC, id DESC)
-- Kecuali distributor DIRECT dan KACS: semua baris tetap ditampilkan (tanpa dedupe)
CREATE OR ALTER VIEW [dbo].[VW_MP_CUSTOMER] AS
SELECT
    -- Data Customer
    c.id AS customer_id,
    c.code AS customer_code,
    c.name AS customer_name,
    c.createdate AS customer_createdate,
    c.created_at AS customer_created_at,
    c.updated_at AS customer_updated_at,
    c.account_trading_term AS customer_account_trading_term,
    c.status AS customer_status,
    c.[desc] AS customer_desc,
    c.city AS city,
    c.btp AS btp,
    c.btn AS btn,
    c.va_gi AS va_gi,
    c.va_gdi AS va_gdi,
    c.nik AS nik,
    c.npwp AS npwp,
    c.[top] AS customer_top,
    CAST(c.credit_limit AS FLOAT) AS credit_limit,
    c.GFcode AS GFcode,
    c.supply_chain AS supply_chain,
    c.area_scm AS area_scm,
    c.distributor_scm AS distributor_scm,
    c.kecamatan AS kecamatan,
    c.top50 AS top50,
    c.blok_release AS blok_release,
    c.btg AS btg,
    c.cutting AS cutting,
    c.phone AS phone,
    c.email AS email,
    c.dn_status AS dn_status,
    c.accountCap AS accountCap,
    c.shop_type AS shop_type,
    c.shopper_type AS shopper_type,
    c.is_va AS is_va,

    -- Data Account
    a.id AS account_id,
    a.account AS account_name,
    a.Kam AS kam_kae,
    a.sort AS account_sort,
    a.accountCap AS account_accountCap,

    -- Data Distributor
    d.id AS distributor_id,
    d.distributor AS distributor_name,
    d.code AS code_distributor,
    d.DistributorScm AS distributorScm,

    -- Data Sub Region
    sr.id AS sub_region_id,
    sr.subRegion AS sub_region_name,

    -- Data Region
    r.id AS region_id,
    r.region AS region_name,

    -- Data Regency
    rg.id AS regency_id,
    rg.kota AS regency_name,

    -- Data Province
    p.id AS province_id,
    p.provinsi AS province_name,

    -- Data Sub Chanel
    sc.id AS sub_chanel_id,
    sc.SubChanel AS sub_chanel_name,

    -- Data Chanel
    ch.id AS chanel_id,
    ch.Chanel AS chanel_name,

    -- Data Market
    m.id AS market_id,
    m.MarketChanel AS market_name

FROM [dbo].[MP_CUSTOMER_NEW] c
    LEFT JOIN [dbo].[Accounts] a ON c.account_id = a.id
    LEFT JOIN [dbo].[Distributors] d ON c.distributor_id = d.id
    LEFT JOIN [dbo].[SubRegions] sr ON d.SubRegionId = sr.id
    LEFT JOIN [dbo].[Regions] r ON sr.RegionId = r.id
    LEFT JOIN [dbo].[Regencies] rg ON c.regency_id = rg.id
    LEFT JOIN [dbo].[Provinces] p ON rg.ProvinceId = p.id
    LEFT JOIN [dbo].[SubChanels] sc ON a.SubChanelId = sc.id
    LEFT JOIN [dbo].[Chanels] ch ON sc.ChanelId = ch.id
    LEFT JOIN [dbo].[Markets] m ON ch.MarketId = m.id
WHERE (
    ISNULL(LTRIM(RTRIM(c.[code])), '') <> ''
    AND UPPER(LTRIM(RTRIM(ISNULL(d.[Distributor], '')))) IN ('DIRECT', 'KACS')
)
OR c.id IN (
    SELECT [id]
    FROM (
        SELECT
            mc.[id],
            ROW_NUMBER() OVER (
                PARTITION BY mc.[code]
                ORDER BY
                    mc.[updated_at] DESC,
                    mc.[id] DESC
            ) AS [rn]
        FROM [dbo].[MP_CUSTOMER_NEW] mc
        LEFT JOIN [dbo].[Distributors] dist ON dist.[Id] = mc.[distributor_id]
        WHERE ISNULL(LTRIM(RTRIM(mc.[code])), '') <> ''
          AND UPPER(LTRIM(RTRIM(ISNULL(dist.[Distributor], '')))) NOT IN ('DIRECT', 'KACS')
    ) AS [ranked]
    WHERE [rn] = 1
);
GO
