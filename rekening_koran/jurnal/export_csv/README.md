# Export Jurnal ke CSV

Folder ini berisi script dan panduan untuk **export data MP_JURNAL ke CSV** via Power Automate (flow dipanggil dari Power Apps).

---

## ✅ Urutan flow yang benar (Jurnal CSV + SharePoint)

Urutan action di Power Automate **harus persis seperti ini**:

| # | Action | Keterangan |
|---|--------|------------|
| 1 | **When Power Apps calls a flow (V2)** | Trigger; input opsional: StartDate, EndDate |
| 2 | **Execute stored procedure (V2)** | Panggil `SP_EXPORT_JURNAL` |
| 3 | **Parse JSON** | Parse `ResultSets/Table1` dari output SP (kolom document data) |
| 4 | **Create CSV table** | Convert ke CSV (UTF-8, comma) |
| 5 | **Compose** | Base64: `base64(body('Create_CSV_table'))` |
| 6 | **Initialize variable** | `varFileName` = Jurnal_Export_yyyyMMdd_HHmmss.csv |
| 7 | **Create file** (SharePoint) | Simpan CSV; File Content = `base64ToBinary(body('Compose'))` |
| 8 | **Compose DownloadLink** | Input = `body('Create_file')?['Path']` |
| 9 | **Respond to a Power App or flow** | Output: fileName, sharePointLink, rowCount, status |

**Panduan lengkap:** `SETUP_LENGKAP_DARI_AWAL.md` (setup + Flow Steps step-by-step).

---

## File

| File | Keterangan |
|------|------------|
| `SP_EXPORT_JURNAL.sql` | Stored procedure untuk query data jurnal (hanya kolom document data). Filter: StartDate, EndDate. |
| `SP_EXPORT_JURNAL_CSV_PIPE.sql` | SP yang return **full CSV string** dengan separator **pipe (\|)**. Output 1 row, 1 column (CSVContent). Langsung copy dari SSMS & paste ke file .csv/.psv. |
| `UTILITY_ExecExportJurnalCSVPipe.sql` | Script untuk exec SP_EXPORT_JURNAL_CSV_PIPE di SSMS (testing / manual export). |
| `SETUP_CSV_PIPE_POWERAPPS.md` | Setup Power Apps + Power Automate flow untuk export CSV pipe (SP_EXPORT_JURNAL_CSV_PIPE). |
| `Parse_JSON_schema.json` | Schema untuk action **Parse JSON** di Power Automate (paste ke "Schema" atau generate from sample). |
| `SETUP_LENGKAP_DARI_AWAL.md` | Panduan step-by-step setup flow + Flow Steps (urutan 9 action di atas). |
| `SETUP_CSV_PIPE_SEPARATOR.md` | Opsi export dengan separator **pipe `|`** (bukan koma); dokumentasi terpisah. |
| `README.md` | Dokumen ini. |

## Cara pakai

1. **Database:** Jalankan `SP_EXPORT_JURNAL.sql` di SSMS (create/alter procedure).
2. **Power Automate:** Buat flow sesuai urutan di atas dan detail di `SETUP_LENGKAP_DARI_AWAL.md`.
3. **Power Apps:** Panggil flow; terima `fileName`, `sharePointLink`, `rowCount`, `status`.

## Parameter SP_EXPORT_JURNAL (opsional)

- `@StartDate` – filter document_date dari tanggal ini.
- `@EndDate` – filter document_date sampai tanggal ini.

Kosongkan = export semua data jurnal (tanpa filter tanggal).

---

## Export CSV langsung dari SP (separator pipe)

Untuk **coba-coba** export tanpa Power Automate, pakai `SP_EXPORT_JURNAL_CSV_PIPE`:

1. Jalankan di SSMS: `EXEC SP_EXPORT_JURNAL_CSV_PIPE;` (atau dengan @StartDate, @EndDate)
2. Hasil: 1 row, 1 column **CSVContent** = full CSV dengan separator **pipe (|)**
3. Copy nilai dari cell tersebut, paste ke Notepad, simpan sebagai `.csv` atau `.psv`

Parameter sama dengan SP_EXPORT_JURNAL.
