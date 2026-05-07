-- Tambah kolom area_scm dan distributor_scm ke MP_CUSTOMER_NEW (nilai awal NULL / kosong)
ALTER TABLE [POWERAPPS].[dbo].[MP_CUSTOMER_NEW]
ADD [area_scm] NVARCHAR(500) NULL,
    [distributor_scm] NVARCHAR(500) NULL;
