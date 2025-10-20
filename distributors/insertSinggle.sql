IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Distributors' AND xtype='U')

CREATE TABLE [Distributors] (

    [Id] BIGINT IDENTITY(1,1) PRIMARY KEY,

    [Distributor] VARCHAR(255) NOT NULL,

    [SubRegionId] BIGINT NOT NULL

);
 
INSERT INTO [distributors] ([distributor], [sub_region_id]) VALUES

('COOLKAS', '1'),
 