USE [POWERAPPS]
GO

/****** Object:  View [dbo].[VW_MP_CUSTOMER_COMPLETE]    Script Date: 22/09/2025 11:19:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO














-- View lengkap untuk MP_CUSTOMER dengan semua relasi
CREATE OR ALTER                 VIEW [dbo].[VW_MP_CUSTOMER_COMPLETE] AS
SELECT
    -- Data Customer
    c.id AS customer_id,
    c.code AS customer_code,
    c.name AS customer_name,
    c.createdate AS customer_createdate,
    c.account_trading_term AS customer_account_trading_term,
    c.status AS customer_status,
    c.[desc] AS customer_desc,
	c.city AS city,
	c.btp AS btp,
	c.[top] AS customer_top,
	c.credit_limit AS credit_limit,
	c.GFcode AS GFcode,
	c.supply_chain AS supply_chain,
	c.kecamatan AS kecamatan,
    c.top50 AS top50,
 
    -- Data Account
    a.id AS account_id,
    a.account AS account_name,
    a.Kam as kam_kae,
	a.sort as account_sort,
 
    -- Data Distributor
    d.id AS distributor_id,
    d.distributor AS distributor_name,
 
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
 
FROM [dbo].[MP_CUSTOMER] c
    -- Relasi Account
    LEFT JOIN [dbo].[Accounts] a ON c.account_id = a.id
    -- Relasi Distributor
    LEFT JOIN [dbo].[Distributors] d ON c.distributor_id = d.id
    -- Relasi Sub Region (dari Distributor)
    LEFT JOIN [dbo].[SubRegions] sr ON d.SubRegionId = sr.id
    -- Relasi Region (dari Sub Region)
    LEFT JOIN [dbo].[Regions] r ON sr.RegionId = r.id
    -- Relasi Regency
    LEFT JOIN [dbo].[Regencies] rg ON c.regency_id = rg.id
    -- Relasi Province (dari Regency)
    LEFT JOIN [dbo].[Provinces] p ON rg.ProvinceId = p.id
    -- Relasi Sub Chanel (dari Account)
    LEFT JOIN [dbo].[SubChanels] sc ON a.SubChanelId = sc.id
    -- Relasi Chanel (dari Sub Chanel)
    LEFT JOIN [dbo].[Chanels] ch ON sc.ChanelId = ch.id
    -- Relasi Market (dari Chanel)
    LEFT JOIN [dbo].[Markets] m ON ch.MarketId = m.id
WHERE c.id IN (
    SELECT MAX(id) 
    FROM [dbo].[MP_CUSTOMER] 
    GROUP BY code
);
GO


