# Upload Check - Cek Tanggal yang Sudah Di-upload

Fitur untuk mengecek tanggal mana saja yang sudah ada di collection `colRk` berdasarkan range tanggal.

## Komponen

| Komponen | Tipe | Fungsi |
|----------|------|--------|
| `DateFrom` | DatePicker | Tanggal awal range |
| `DateTo` | DatePicker | Tanggal akhir range |
| `DateSubmitBtn` | Button | Tombol untuk cek |
| `ResultLabel` | Label | Tampilkan hasil tanggal |
| `SummaryLabel` | Label | Tampilkan summary count |

## Setup

### 1. DateSubmitBtn (OnSelect)

Copy dari `DateSubmitBtn_v2.c`:

```
ClearCollect(
    colUploadedDates,
    Distinct(
        Filter(
            colRk,
            DateValue(trx_date) >= DateFrom.SelectedDate &&
            DateValue(trx_date) <= DateTo.SelectedDate
        ),
        trx_date
    )
);

Set(
    varUploadedDatesText,
    If(
        CountRows(colUploadedDates) > 0,
        "Tanggal yang sudah di-upload (" & CountRows(colUploadedDates) & "):" &
        Char(10) &
        Concat(
            Sort(colUploadedDates, DateValue(Result), SortOrder.Ascending),
            Text(DateValue(Result), "dd/mm/yyyy"),
            Char(10)
        ),
        "Tidak ada data dalam range"
    )
);

Set(varUploadedCount, CountRows(colUploadedDates));
```

### 2. ResultLabel (Text)

```
varUploadedDatesText
```

### 3. SummaryLabel (Text) - Opsional

```
"Sudah upload: " & varUploadedCount & " hari"
```

## Hasil

Setelah klik DateSubmitBtn:

**ResultLabel:**
```
Tanggal yang sudah di-upload (5):
01/01/2025
02/01/2025
03/01/2025
05/01/2025
07/01/2025
```

**SummaryLabel:**
```
Sudah upload: 5 hari
```

## Catatan

- Collection `colRk` harus sudah di-load di OnStart
- Column `trx_date` harus ada di colRk
- Hasil disimpan di variable `varUploadedDatesText` dan `varUploadedCount`
