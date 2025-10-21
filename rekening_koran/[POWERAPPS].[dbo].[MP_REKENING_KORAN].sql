USE [POWERAPPS]
GO
 
/****** Object:  Table [dbo].[MP_REKENING_KORAN]    Script Date: 06/10/2025 13:07:00 ******/
SET ANSI_NULLS ON
GO
 
SET QUOTED_IDENTIFIER ON
GO
 
CREATE TABLE [dbo].[MP_REKENING_KORAN](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[trx_date] [date] NULL,
	[created_at] [datetime] NULL,
	[updated_at] [datetime] NULL,
	[credit] [varchar](255) NULL,
	[btp] [varchar](255) NULL,
	[desc] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO