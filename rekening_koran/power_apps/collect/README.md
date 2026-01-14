# Collection untuk BTP_REVIEW

## Apa itu Collection?
Collection adalah data yang disimpan di memory Power Apps. Sekali load dari database, pakai terus tanpa hit database lagi.

## File dalam folder ini:

| File | Fungsi | Taruh di |
|------|--------|----------|
| `onStart.c` | Load data pertama kali | App.OnStart |
| `refreshBtn.c` | Refresh data manual | Button.OnSelect |

## Cara Pakai:

### 1. Setup OnStart
Copy isi `onStart.c` ke **App.OnStart** property

### 2. Ganti Gallery Items
Ganti dari:
```
Filter(BTP_REVIEW, ...)
```
Jadi:
```
Filter(colBtpReview, ...)
```

### 3. Ganti Label Count
Ganti dari:
```
First(VW_BTP_REVIEW_COUNT).TotalRows
```
Jadi:
```
First(colBtpCount).TotalRows
```

### 4. Tambah Button Refresh
Copy isi `refreshBtn.c` ke button untuk refresh data

## Collection yang tersedia:

| Collection | Isi | Sumber |
|------------|-----|--------|
| `colBtpReview` | Semua data BTP_REVIEW | BTP_REVIEW table |
| `colBtpCount` | Total rows (TotalRows, TotalCR, TotalDB) | VW_BTP_REVIEW_COUNT view |

## Keuntungan:
- Lebih cepat (data di memory)
- Tidak hit database berulang kali
- Filter tidak kena delegation

## Kekurangan:
- Data bisa stale (perlu refresh manual)
- Memory usage tinggi kalau data besar
