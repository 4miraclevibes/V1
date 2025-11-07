# 🚀 Quick Start — RPT (Virtual Account)

## 1. Sumber Data
- Gunakan tool `converter.html` (tab TXT / RPT) untuk mengubah file TXT menjadi JSON.
- Output penting (per record):
  - `transaction_id`
  - `transaction_date`
  - `transaction_time`
  - `btp`
  - `customer_name`
  - `amount`
  - `location`
  - `keterangan1`
  - `keterangan2`

## 2. Eksekusi Stored Procedure
```sql
DECLARE @JSON NVARCHAR(MAX) = N'[...]'; -- JSON hasil converter

EXEC [dbo].[SP_RPT_FindBTP_Batch]
    @InputJSON = @JSON,
    @Debug = 1; -- optional
```

## 3. Integrasi ke Master Flow
`SP_MASTER_FindBTP_SaveToReview` otomatis mengarahkan transaksi dengan `BankType = 'VA'` ke SP ini. Pastikan JSON input ke master SP menyertakan kolom-kolom di atas; kalau tidak ada `description`, master SP akan membentuk deskripsi default dari `customer_name/keterangan`.

## 4. Output & Status
- `NO_BTP` → BTP kosong di file TXT.
- `NO_MATCH` → BTP tidak ditemukan di master maupun MP_CUSTOMER_NEW.
- `EXCELLENT/GOOD/FAIR/LOW` → Menunjukkan confidence berdasarkan data master.
- `DataSource` menunjukkan asal customer name (`MASTER_CUSTOMER_BTP_PATTERN` atau fallback `MP_CUSTOMER_NEW`).

## 5. Langkah Lanjut
1. Jika `NO_MATCH`, tambahkan pattern baru ke `MASTER_CUSTOMER_BTP_PATTERN`.
2. Jika fallback ke MP_CUSTOMER_NEW terlalu sering, pertimbangkan membuat bulk insert pattern.
3. Gunakan `@Debug = 1` untuk melihat ringkasan match saat development/testing.


