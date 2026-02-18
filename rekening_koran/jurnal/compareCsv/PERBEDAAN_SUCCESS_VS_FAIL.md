# Perbandingan success.csv vs fail.csv (SAP Import)

## Ringkasan

| File | Hasil di SAP |
|------|--------------|
| **success.csv** | ✅ Berhasil (file ditemukan) |
| **fail.csv** | ❌ File not found |

---

## Cek Aspek "Originalitas" File (encoding, format)

### File format / encoding – **SAMA**

| Aspek | success.csv | fail.csv | Keterangan |
|-------|-------------|----------|------------|
| **BOM** | Tidak ada | Tidak ada | Keduanya mulai langsung dengan data (byte 32 31 = "21") |
| **Encoding** | ASCII | ASCII | Tidak ada byte > 127 di kedua file |
| **Line ending** | CRLF (0D 0A) | CRLF (0D 0A) | Sama |
| **Karakter** | Pure ASCII | Pure ASCII | Keduanya kompatibel UTF-8 |

**Kesimpulan:** Dari sisi encoding, BOM, dan line ending, kedua file sama. "File not found" kemungkinan bukan karena format file mentah (originalitas file).

---

## Perbedaan Isi (yang bisa memicu SAP menolak file)

### 1. **company_code (kolom ke-3)**

| File | Nilai |
|------|--------|
| success.csv | `id93` (lowercase) |
| fail.csv | `ID93` (uppercase) |

### 2. **Jumlah kolom**

| File | Kolom | Akhir baris |
|------|-------|-------------|
| success.csv | 27 | `\|\|\|\|\|\|` (6 pipe) |
| fail.csv | 29 | `\|\|\|\|\|\|\|\|` (8 pipe) |

Fail punya 2 kolom kosong tambahan di akhir.

### 3. **Ukuran file**

- success.csv: 152.272 bytes  
- fail.csv: 154.004 bytes  

---

## Kemungkinan Penyebab "File not found" di SAP

1. **Validasi format:** SAP memeriksa jumlah kolom. Jika jumlah kolom tidak sesuai (27 vs 29), program bisa menganggap format file salah dan menolak file.
2. **Validasi company code:** Sebelum proses, SAP bisa memvalidasi company code. Jika `ID93` tidak ditemukan (case-sensitive) sementara `id93` ada, proses bisa gagal.
3. **Template/schema import:** Jika SAP memakai template dengan jumlah kolom tertentu, file fail bisa tidak cocok dan dianggap "file tidak valid / not found".

---

## Rekomendasi agar Export Cocok dengan success.csv

1. **company_code:** Hapus `UPPER()` di SP → pakai lowercase `id93`.
2. **Jumlah kolom:** Hilangkan 2 kolom kosong di akhir di SP agar sama dengan success (27 kolom).
