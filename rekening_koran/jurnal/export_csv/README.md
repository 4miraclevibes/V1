# Export Jurnal ke CSV

Folder ini berisi script dan panduan untuk **export data MP_JURNAL ke CSV** via Power Automate (flow dipanggil dari Power Apps).

## File

| File | Keterangan |
|------|------------|
| `SP_EXPORT_JURNAL.sql` | Stored procedure untuk query data jurnal dengan filter (tanggal, company code, reference). |
| `SETUP_LENGKAP_DARI_AWAL.md` | Panduan step-by-step setup Power Automate flow: Execute SP → Parse JSON → CSV → Base64 → SharePoint → Respond ke Power Apps. |
| `README.md` | Dokumen ini. |

## Cara pakai

1. **Database:** Jalankan `SP_EXPORT_JURNAL.sql` di SSMS (create/alter procedure).
2. **Power Automate:** Buat flow sesuai `SETUP_LENGKAP_DARI_AWAL.md` (panggil SP_EXPORT_JURNAL, convert ke CSV, simpan ke SharePoint, return link).
3. **Power Apps:** Panggil flow tersebut; terima `fileName`, `sharePointLink`, `rowCount`, `status`.

## Parameter SP_EXPORT_JURNAL (opsional)

- `@StartDate` – filter document_date dari tanggal ini.
- `@EndDate` – filter document_date sampai tanggal ini.
- `@CompanyCode` – filter by company_code (mis. `id93`, `id92`).
- `@Reference` – filter by reference (mis. `26012026-0001`).

Kosongkan parameter = tidak pakai filter (export semua data jurnal yang memenuhi syarat).
