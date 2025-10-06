USE [POWERAPPS]
GO

/****** Object:  View [dbo].[VW_NEW_CUSTOMER_FAST_EXTENDED]    Script Date: 02/10/2025 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 
CREATE OR ALTER     VIEW [dbo].[VW_NEW_CUSTOMER_FAST_EXTENDED]

AS

SELECT TMP.*, 

       CAST(1 AS BIT) AS isNoo

FROM (

    -- STT

    SELECT

        ISNULL([name].[Distributor Name],'') [Distributor],

        ISNULL([name].[Area New],'') [Region],

        ISNULL(REPLACE(sm.[Cust_Code],'''',''),'') [Customer Code],

        ISNULL(REPLACE(sm.[Ship_to _Party],'''',''),'') [Customer Name],

        ISNULL(sm.[Account],'') [Account],

        ISNULL(sm.[Channel2],'') [Channel],

        ISNULL(sm.[Sub_Channel2],'') [Sub Channel],

        ISNULL(sm.[Market_Channel],'') [Market Channel],

        CASE WHEN ISNULL(sm.[Market_Channel],'') IN ('Modern Trade','General Trade') THEN 'B2C' ELSE 'B2B' END [Category],

        ISNULL(sm.[Provinsi],'') [Provinsi],

        ISNULL(sm.[KabKota],'') [Kab/Kota],

        ISNULL(sm.[Kecamatan],'') [Kecamatan],

        ISNULL(sm.[KAE],'') Kae,

        ISNULL(sm.[SalesSPV],'') Kam,

        -- Format Createdate yang lebih bagus

        CASE 

            WHEN ISNULL(sm.[Create Date],'19000101') = '19000101' THEN ''

            ELSE FORMAT(CAST(sm.[Create Date] AS DATETIME), 'dd MMMM yyyy', 'en-US')

        END AS Createdate,

        CASE WHEN CONVERT(CHAR(6),CAST(ISNULL(sm.[Create Date],'1900/1/1') AS DATETIME),112)

             IN (
                CONVERT(CHAR(6),GETDATE(),112), 
                CONVERT(CHAR(6),DATEADD(DAY,-10,GETDATE()),112),
                CONVERT(CHAR(6),DATEADD(MONTH,-1,GETDATE()),112)
             )

             THEN 'NOO at ' + RIGHT(CONVERT(CHAR(11),DATEADD(DAY,-10,GETDATE()),113),8)

             ELSE 'Not NOO' END AS NOO,

        ROUND(ISNULL(saleslm.[Net Revenue Rp],0),0) [RevenueLM],

        ROUND(ISNULL(salescm.[Net Revenue Rp],0),0) [RevenueCM]

    FROM ERP_INTERNATIONAL_SAP.[dbo].[Customer_Mapping_Region_sm] sm

    LEFT JOIN ERP_INTERNATIONAL_SAP.[dbo].SAP_MAPPING_DIST_NAME_BW$ [name]

        ON sm.Distributor = [name].Name1

    LEFT JOIN afindo.dbo.vw_sales_lastmonth_stt_bydistributor_bycustomer saleslm

        ON sm.[Cust_Code] = saleslm.[Customer Code] AND [name].[Distributor Name] = saleslm.[Distributor]

    LEFT JOIN afindo.dbo.vw_sales_currentmonth_stt_bydistributor_bycustomer salescm

        ON sm.[Cust_Code] = salescm.[Customer Code] AND [name].[Distributor Name] = salescm.[Distributor]
 
    UNION ALL
 
    -- STD

    SELECT

        ISNULL(a.[distribution],'') [Distributor],

        ISNULL(a.[Region],'') [Region],

        REPLACE(a.[cust code],'''','') [Customer Code],

        REPLACE(SUBSTRING(a.[ship-to party],12,100),'''','') [Customer Name],

        ISNULL(a.[account],'') [Account],

        ISNULL(a.[channel],'') [Channel],

        ISNULL(a.[sub channel],'') [Sub Channel],

        ISNULL(a.[market channel],'') [Market Channel],

        CASE WHEN ISNULL(a.[market channel],'') IN ('Modern Trade','General Trade') THEN 'B2C' ELSE 'B2B' END [Category],

        ISNULL(a.[KECAMATAN],'') [Provinsi],

        ISNULL(a.[Provinsi],'') [Kab/Kota],

        ISNULL(a.[KAB KOTA],'') [Kecamatan],

        ISNULL(a.KAE,'') Kae,

        ISNULL(a.KAM,'') Kam,

        -- Format Createdate yang lebih bagus

        CASE 

            WHEN ISNULL(a.[Mo & Yr],'19000101') = '19000101' THEN ''

            ELSE FORMAT(CAST(a.[Mo & Yr] AS DATETIME), 'dd MMMM yyyy', 'en-US')

        END AS Createdate,

        CASE WHEN CONVERT(CHAR(6),CAST(ISNULL(a.[Mo & Yr],'1900/1/1') AS DATETIME),112)

             IN (
                CONVERT(CHAR(6),GETDATE(),112), 
                CONVERT(CHAR(6),DATEADD(DAY,-10,GETDATE()),112),
                CONVERT(CHAR(6),DATEADD(MONTH,-1,GETDATE()),112)
             )

             THEN 'NOO at ' + RIGHT(CONVERT(CHAR(11),DATEADD(MONTH,-1,GETDATE()),113),8)

             ELSE 'Not NOO' END AS NOO,

        ROUND(ISNULL(saleslm.[Net Revenue Rp],0),0) [RevenueLM],

        ROUND(ISNULL(salescm.[Net Revenue Rp],0),0) [RevenueCM]

    FROM ERP_INTERNATIONAL_SAP.[dbo].[FRP_Mapping_Customer$] a

    LEFT JOIN afindo.dbo.vw_sales_lastmonth_stt_bydistributor_bycustomer saleslm

        ON a.[cust code] = saleslm.[Customer Code] AND a.[DISTRIBUTION] = saleslm.[Distributor]

        AND saleslm.Distributor IN ('KACS','COOLKAS','DIRECT')

    LEFT JOIN afindo.dbo.vw_sales_currentmonth_stt_bydistributor_bycustomer salescm

        ON a.[cust code] = salescm.[Customer Code] AND a.[DISTRIBUTION] = salescm.[Distributor]

        AND salescm.Distributor IN ('KACS','COOLKAS','DIRECT')

    WHERE a.[distribution] IN ('KACS','COOLKAS','DIRECT') AND a.[Cust Code] IS NOT NULL

) TMP

LEFT JOIN [POWERAPPS].[dbo].[VW_MP_CUSTOMER_COMPLETE_NEW] existing

    ON TMP.[Customer Code] = existing.customer_code

    AND TMP.[Customer Name] = existing.customer_name

    AND TMP.[Distributor] = existing.distributor_name

WHERE existing.customer_code IS NULL

    AND TMP.NOO LIKE 'NOO at%'

    AND TMP.RevenueLM + TMP.RevenueCM > 0

GO

