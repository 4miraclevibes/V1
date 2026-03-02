# Export Jurnal CSV ke File (Rekening Koran)

## File yang Dibuat

| File | Fungsi |
|------|--------|
| `[dbo].[SP_EXPORT_JURNAL_CSV_FILE].sql` | SP: export MP_JURNAL ke CSV, simpan ke C:\REKENINGKORAN\, panggil batch |
| `copy-rekeningkoran.bat` | Batch: copy semua CSV ke rekeningkoran share, move ke uploadsuccess/failed |
| `copy-jurnal-terbaru-ke-hris.bat` | Batch: copy **hanya file CSV terbaru** ke HRIS input |

## Setup (di mesin SQL Server)

1. **Buat folder** (wajib – beri hak **Full Control** ke SQL Server service account):
   ```
   C:\REKENINGKORAN\
   C:\REKENINGKORAN\uploadsuccess\
   C:\REKENINGKORAN\uploadfailed\
   ```
   - Klik kanan folder → Properties → Security → Edit → Add → masukkan service account (mis. `NT SERVICE\MSSQLSERVER`)
   - Beri hak **Full Control**

2. **Copy batch ke server:**
   - `copy-rekeningkoran.bat` → `C:\REKENINGKORAN\`
   - `copy-jurnal-terbaru-ke-hris.bat` → `C:\REKENINGKORAN\`

3. **Network share:** Pastikan folder berikut ada dan writable:
   - `\\10.54.20.8\sap\shd\rekeningkoran`
   - `\\10.54.20.8\sap\shd\hris\sap_in\zaffie001\input`

## Alur

1. Jalankan: `EXEC SP_EXPORT_JURNAL_CSV_FILE @StartDate = '2025-01-01', @EndDate = '2025-01-31';`
2. SP export ke `C:\REKENINGKORAN\jurnal_{timestamp}.csv`
3. SP panggil `copy-rekeningkoran.bat` → xcopy ke `\\10.54.20.8\sap\shd\rekeningkoran`, move ke `uploadsuccess`/`uploadfailed`
4. SP panggil `copy-jurnal-terbaru-ke-hris.bat` (terakhir) → copy file terbaru ke `\\10.54.20.8\sap\shd\hris\sap_in\zaffie001\input`

## Parameter SP

- `@StartDate` – Filter document_date >= (format: 'YYYY-MM-DD')
- `@EndDate` – Filter document_date <= (format: 'YYYY-MM-DD')
- Kosongkan keduanya untuk export semua data.
