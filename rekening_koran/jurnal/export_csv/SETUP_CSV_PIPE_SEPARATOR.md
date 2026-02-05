# Export Jurnal ke CSV dengan Separator Pipe (|)

Dokumentasi ini untuk **opsi export yang memakai separator pipe `|`** (bukan koma). Gunakan ini jika sistem tujuan (mis. SAP, impor lain) mengharapkan file pipe-delimited.

**Dokumentasi utama (separator koma)** tetap di **`SETUP_LENGKAP_DARI_AWAL.md`** dan **`README.md`**. File ini hanya menambah opsi separator pipe.

---

## Perbedaan dengan setup standar

| Aspek | Setup standar (README / SETUP_LENGKAP) | Opsi pipe (dokumen ini) |
|-------|--------------------------------------|--------------------------|
| Separator | Comma (`,`) | **Pipe (`\|`)** |
| Nama file | `Jurnal_Export_yyyyMMdd_HHmmss.csv` | Bisa tetap `.csv` atau `.psv` |
| Urutan flow | Sama | Sama |

Urutan flow **dengan pipe:** Trigger → Execute SP → Parse JSON → Create CSV table → **Compose (Replace comma → pipe)** → Compose (Base64) → Initialize variable → Create file (SharePoint) → Compose DownloadLink → Respond to PowerApps.

---

## Batasan: Create CSV table tidak punya opsi Delimiter

Di action **Create CSV table** (Parameters tab), meskipun **Advanced parameters** sudah diklik **Show all**, **tidak ada opsi Delimiter / Custom delimiter** di UI. Jadi separator pipe tidak bisa di-set langsung di action ini.

**Solusi:** Buat CSV seperti biasa (koma), lalu **tambah satu action** untuk mengubah koma menjadi pipe.

---

## Konfigurasi: workaround dengan action tambahan

Urutan yang dipakai:

1. **Create CSV table** — tetap pakai default (From = Parse JSON, Columns = Auto-detect, delimiter koma).
2. **Compose (Replace comma → pipe)** — action **baru**, isi: ganti semua koma di output CSV menjadi pipe.
3. **Compose (Base64)** — input-nya pakai output **Compose (Replace comma → pipe)**, bukan output Create CSV table.
4. Langkah berikutnya (Initialize variable, Create file, Compose DownloadLink, Respond) sama seperti biasa.

### Action 1: Create CSV table (tidak berubah)

- **From:** `@body('Parse_JSON')`
- **Columns:** Auto-detect  
- Tidak perlu ubah apa pun; delimiter tetap koma.

### Action 2: Compose – Replace comma dengan pipe (BARU)

**Lokasi:** Sisipkan **setelah** Create CSV table, **sebelum** Compose (Base64).

- **Action:** Data operation → **Compose**
- **Rename** (opsional): `Compose_CSV_Pipe`
- **Input (Expression – klik fx):**
  ```
  replace(body('Create_CSV_table'), ',', '|')
  ```
  (Ganti `Create_CSV_table` dengan nama action Create CSV table di flow kamu.)

**Akibat:** Semua karakter koma di string CSV diganti pipe. Hasilnya format pipe-delimited.

**Peringatan:** Jika ada **nilai kolom yang mengandung koma** (mis. teks "PT A, B & C"), kolom itu akan berubah jadi beberapa kolom di file pipe. Aman dipakai jika data jurnal tidak ada koma di dalam nilai teks.

### Action 3: Compose (Base64) – pakai output pipe

- **Input (Expression):** Untuk action **Compose**, hasil keluarannya diambil pakai **`outputs(...)`**, bukan **`body(...)`**. Supaya isi file benar-benar pipe, pakai:
  ```
  base64(coalesce(outputs('Compose_CSV_Pipe'), body('Create_CSV_table'), ''))
  ```
  Arti: encode **output** dari Compose_CSV_Pipe (string yang sudah koma→pipe). Kalau null, fallback ke Create_CSV_table lalu string kosong.

- **Penting:** Kalau pakai `body('Compose_CSV_Pipe')`, bisa null atau salah; untuk Compose action selalu pakai **`outputs('Compose_CSV_Pipe')`** agar yang di-encode adalah string pipe-separated.

### Action 4: Create file (SharePoint)

- **File Content:** `base64ToBinary(body('Compose'))`  
  (Yang dipanggil adalah Compose Base64; input Compose Base64 sudah dari Compose_CSV_Pipe, jadi isi file sudah pipe-separated.)

---

## Nama file (opsional)

- Boleh tetap: **`Jurnal_Export_yyyyMMdd_HHmmss.csv`** (banyak sistem terima pipe-delimited dengan ekstensi .csv).
- Atau pakai ekstensi **.psv** (pipe-separated values) di **Initialize variable**:
  ```
  concat('Jurnal_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.psv')
  ```

---

## Contoh isi file (pipe-separated)

Baris header dan satu baris data (contoh):

```
DocumentDate|DocumentType|CompanyCode|PostingDate|Currency|...
2025-01-15|DZ|id93|2025-01-15|IDR|...
```

---

## Ringkasan

1. Di **Create CSV table** tidak ada opsi Delimiter di UI (termasuk setelah Show all).
2. **Workaround:** Setelah Create CSV table, tambah **Compose** dengan expression `replace(body('Create_CSV_table'), ',', '|')`, lalu Compose (Base64) dan Create file pakai output Compose tersebut.
3. Nama file bisa tetap `.csv` atau diganti `.psv` di variable `varFileName`.
4. Hati-hati jika data punya koma di dalam nilai kolom (bisa salah kolom); untuk data jurnal umumnya aman.
