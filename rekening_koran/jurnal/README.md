# Jurnal: MP_REKENING_KORAN → MP_JURNAL

Folder ini berisi **tabel jurnal** dan **stored procedure** untuk membuat jurnal dari rekening koran.

---

## Bisnis Proses (Singkat)

1. **Sumber data:** `MP_REKENING_KORAN`
2. **Aturan:** Setiap **1 baris** rekening koran → dibuat **2 baris** di tabel jurnal (`MP_JURNAL`).
3. **Nomor urut (`no_urut`):** Sama untuk kedua baris; dihitung per **trx_date** + **AccountName** (mulai 0001, 0002, …).
4. **Setelah insert:** Kolom `isJurnal` di `MP_REKENING_KORAN` di-update jadi **1** (sudah di-jurnal).

---

## File di Folder Ini

| File | Keterangan |
|------|------------|
| `flow.txt` | Spesifikasi bisnis & mapping kolom (baris 1 vs baris 2) |
| `[POWERAPPS].[dbo].[MP_JURNAL].sql` | Script **create table** MP_JURNAL |
| `SP_JURNAL_CreateFromRekeningKoran.sql` | **Stored procedure** yang baca RK → insert 2 baris jurnal + update isJurnal |
| `UTILITY_ExecCreateJurnal.sql` | Utility: **EXEC** SP_JURNAL_CreateFromRekeningKoran (jalankan proses jurnal) |
| `UTILITY_ResetJurnalForTesting.sql` | Utility: set `isJurnal = 0` di RK + **TRUNCATE** MP_JURNAL (untuk testing ulang) |
| `README.md` | Dokumen ini |

---

## Cara Pakai

### 1. Buat tabel MP_JURNAL (sekali saja)

Jalankan di SSMS:

```sql
-- Isi file: [POWERAPPS].[dbo].[MP_JURNAL].sql
-- Create table MP_JURNAL
```

### 2. Pastikan MP_REKENING_KORAN punya kolom yang dipakai

SP memakai kolom: `id`, `trx_date`, `AccountNumber`, `AccountName`, `btn`, `btp`, `desc`, `Amount`, `isJurnal`.

Jika belum ada **btn** atau **Amount**, jalankan dulu script ALTER di folder `stored_procedures/with_amount/` (mis. `ALTER_ADD_BTN_APPROVED_BY.sql`, script Amount).

### 3. Buat stored procedure

Jalankan:

```sql
-- Isi file: SP_JURNAL_CreateFromRekeningKoran.sql
```

### 4. Jalankan proses jurnal

Jalankan di SSMS:

```sql
-- Atau buka dan jalankan file: UTILITY_ExecCreateJurnal.sql
EXEC [dbo].[SP_JURNAL_CreateFromRekeningKoran];
```

- Hanya baris RK yang **memenuhi semua syarat** yang diproses; yang tidak memenuhi syarat **tidak** di-update isJurnal.
- Syarat: **isJurnal = 0/NULL**, **trx_date** tidak NULL, **Amount** tidak NULL, **btp** dan **btn** tidak NULL dan tidak kosong.
- Tiap baris RK yang lolos → 2 baris di MP_JURNAL (baris 1: posting_key 40, baris 2: posting_key 15).
- Setelah insert, baris RK yang diproses di-update **isJurnal = 1** (hanya yang benar-benar masuk jurnal).

### 5. Testing berulang (reset)

Agar bisa jalankan SP lagi dari awal (testing):

```sql
-- Isi file: UTILITY_ResetJurnalForTesting.sql
-- 1. Update MP_REKENING_KORAN SET isJurnal = 0
-- 2. TRUNCATE TABLE MP_JURNAL
```

Jalankan script utility tersebut, lalu jalankan lagi `SP_JURNAL_CreateFromRekeningKoran`.

---

## Mapping Kolom (Ringkas)

| Kolom Jurnal | Baris 1 | Baris 2 |
|--------------|---------|---------|
| document_date, posting_date, value_date | trx_date | trx_date |
| document_type | DZ | DZ |
| company_code | id93 jika AccountNumber = '0053061777', else id92 | sama |
| reference | ddmmyyyy-no_urut (no_urut per trx_date + AccountName) | sama |
| document_header_text | btn max 25 char (potong di space terakhir) | sama |
| posting_key | **40** | **15** |
| customer | NULL | **btp** |
| account | 1113030303 / 1113030300 (by AccountNumber) | NULL |
| amount | Amount | Amount |
| assignment | 3000 | 3000 |
| text | desc 50 char dari belakang (potong di space) | sama |
| profit_center | 9300DDJT0A / 9201DQDQ01 (by AccountNumber) | sama |
| customer2 | NULL | **btp** |

Detail lengkap ada di **flow.txt**.

---

## Nomor Urut (no_urut) & Reference

- **no_urut:** 4 digit (0001, 0002, …) per kombinasi **(trx_date, AccountName)**.
- **reference:** `{ddmmyyyy}-{no_urut}` contoh: `26012026-0001`.
- Tanggal sama + AccountName sama → no_urut berurutan.
- Tanggal sama + AccountName beda → no_urut mulai lagi dari 0001.
- Tanggal beda → no_urut mulai lagi per AccountName.

---

## Ringkasan Alur

```
MP_REKENING_KORAN (isJurnal = 0/NULL)
        │
        ▼
SP_JURNAL_CreateFromRekeningKoran
        │
        ├──► Insert baris 1 (posting_key 40, customer NULL, account isi)
        ├──► Insert baris 2 (posting_key 15, customer = btp, account NULL)
        └──► Update MP_REKENING_KORAN.isJurnal = 1
```

Untuk testing ulang: jalankan **UTILITY_ResetJurnalForTesting.sql** (isJurnal = 0 + TRUNCATE MP_JURNAL), lalu jalankan lagi SP.
