# 📄 Folder `RPT`

Folder ini menyimpan artefak untuk pemrosesan file RPT (TXT) Greenfields yang berisi daftar transaksi virtual account. Flow-nya:

1. Converter Power Apps (`converter.html`) mengubah file TXT menjadi JSON dengan kolom `btp`, `customer_name`, `transaction_date`, dll.
2. JSON tersebut dieksekusi ke stored procedure `SP_RPT_FindBTP_Batch` untuk mencari BTP yang valid.
3. Stored procedure melakukan lookup ke `MASTER_CUSTOMER_BTP_PATTERN` dan fallback ke `MP_CUSTOMER_NEW`.
4. Hasil SP akan dipakai oleh `SP_MASTER_FindBTP_SaveToReview` dengan bank type `VA`.

## Isi Folder

- `SP_RPT_FindBTP_Batch.sql` → SP utama untuk matching BTP dari data TXT.
- `QUICK_START.md` → Ringkasan langkah eksekusi & contoh script (lihat file).
- `INDEX.md` → Daftar referensi & dependensi (lihat file).

> Catatan: struktur dokumentasi mengikuti pola folder bank lain (mis. `GREENFIEL`) agar konsisten.


