USE [POWERAPPS]
GO

/****** Object:  Table [dbo].[MP_CUSTOMER_NEW_09_10_2025]    Script Date: 10/10/2025 13:59:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MP_CUSTOMER_NEW_09_10_2025](
	[id] [bigint] NOT NULL,
	[code] [nvarchar](max) NULL,
	[name] [nvarchar](max) NULL,
	[city] [nvarchar](max) NULL,
	[createdate] [nvarchar](max) NULL,
	[distributor_id] [bigint] NULL,
	[account_id] [bigint] NULL,
	[account_trading_term] [nvarchar](max) NULL,
	[regency_id] [bigint] NULL,
	[created_at] [datetime2](7) NULL,
	[updated_at] [datetime2](7) NULL,
 CONSTRAINT [PK_MP_CUSTOMER_NEW_09_10_2025] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


