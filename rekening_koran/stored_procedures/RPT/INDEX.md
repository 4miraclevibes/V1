# 📚 INDEX — Stored Procedures RPT

## Stored Procedure
- `SP_RPT_FindBTP_Batch.sql`
  - Input: JSON hasil konversi TXT (virtual account Greenfields).
  - Output: Daftar kandidat BTP + metadata untuk disimpan ke `BTP_REVIEW`.
  - Fallback: `MP_CUSTOMER_NEW` jika `MASTER_CUSTOMER_BTP_PATTERN` tidak memiliki BTP.

## Dependensi
- Tabel referensi:
  - `POWERAPPS.dbo.MASTER_CUSTOMER_BTP_PATTERN`
  - `POWERAPPS.dbo.MP_CUSTOMER_NEW`

- Konsumer utama:
  - `SP_MASTER_FindBTP_SaveToReview` (bank type `VA`).

## Referensi Terkait
- `rekening_koran/html_to_json_converter/converter.html`
- `rekening_koran/html_to_json_converter/parser.js`
- `rekening_koran/html_to_json_converter/rpt_example.txt`


