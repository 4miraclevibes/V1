# Filter Stored Procedures untuk BTP_REVIEW

Stored procedure ini dibuat untuk menghindari delegation data di Power Apps ketika melakukan filter pada tabel BTP_REVIEW.

## 📋 Daftar Stored Procedures

### 1. SP_BTP_REVIEW_FilterByTransactionDate
Stored procedure sederhana untuk filter berdasarkan TransactionDate saja.

**Parameter:**
- `@TransactionDate` (DATE, nullable) - Jika NULL, return semua data

**Contoh penggunaan:**
```sql
-- Filter berdasarkan tanggal tertentu
EXEC SP_BTP_REVIEW_FilterByTransactionDate @TransactionDate = '2025-12-15';

-- Return semua data
EXEC SP_BTP_REVIEW_FilterByTransactionDate @TransactionDate = NULL;
```

### 2. SP_BTP_REVIEW_FilterComplete
Stored procedure lengkap untuk menangani semua filter dari gallery Power Apps.

**Parameter:**
- `@ShowReview` (BIT) - 1 = show review status, 0 = show approved status
- `@IsApproved` (BIT) - Filter IsApproved
- `@TransactionDate` (DATE, nullable) - Filter TransactionDate
- `@UploadedAt` (DATE, nullable) - Filter UploadedAt
- `@SearchCustomer` (NVARCHAR(200), nullable) - Filter CustomerName
- `@SearchBatch` (NVARCHAR(100), nullable) - Filter BatchID
- `@SearchDescription` (NVARCHAR(MAX), nullable) - Filter Description
- `@SearchBankType` (NVARCHAR(50), nullable) - Filter BankType
- `@SearchBTP` (NVARCHAR(50), nullable) - Filter BTP
- `@ShowDebit` (BIT, nullable) - NULL = all, 1 = DB only, 0 = CR only
- `@SortBy` (NVARCHAR(50)) - MatchPercentage, CreatedAt, TransactionDate
- `@SortOrder` (NVARCHAR(10)) - ASC, DESC

**Contoh penggunaan:**
```sql
-- Filter untuk review dengan TransactionDate tertentu
EXEC SP_BTP_REVIEW_FilterComplete
    @ShowReview = 1,
    @IsApproved = 0,
    @TransactionDate = '2025-12-15',
    @SearchCustomer = 'JOHN',
    @SortBy = 'MatchPercentage',
    @SortOrder = 'ASC';
```

## 🔧 Cara Menggunakan di Power Apps

### ⚠️ PENTING: Filter dengan Stored Procedure

**Ya, filter dengan stored procedure HARUS menggunakan tombol submit** karena:
- Parameter perlu dikirim ke stored procedure terlebih dahulu
- Stored procedure tidak bisa membaca nilai langsung dari control Power Apps
- Perlu variable sebagai perantara antara control dan parameter SP

### Opsi 1: Menggunakan sebagai Data Source (RECOMMENDED) ⭐
1. Di Power Apps Studio, tambahkan data source baru
2. Pilih "SQL Server" atau "SQL Database"
3. Pilih stored procedure yang diinginkan
4. Buat variable untuk menyimpan nilai filter
5. Buat tombol "Apply Filter" yang:
   - Menyimpan nilai dari controls ke variable
   - Memanggil `Refresh(SP_BTP_REVIEW_FilterComplete)`
6. Gallery Items: `SP_BTP_REVIEW_FilterComplete`

**Lihat file:**
- `variables.c` - Setup variables
- `btnApplyFilter.c` - Implementasi tombol submit
- `galleryWithSP.c` - Implementasi gallery

### Opsi 2: Menggunakan melalui Power Automate Flow
1. Buat flow yang memanggil stored procedure dengan parameter dari Power Apps
2. Buat tombol "Apply Filter" yang memanggil flow dengan parameter
3. Simpan hasil ke variable `varFilteredData`
4. Gallery Items: `varFilteredData`

**Lihat file:**
- `btnApplyFilter.c` - Contoh dengan Power Automate Flow

### Contoh di Gallery Power Apps

**Sebelum (dengan delegation warning):**
```powerappsfx
Filter(
    BTP_REVIEW,
    (IsBlank(TrxDpRvRk.SelectedDate) || DateValue(TransactionDate) = TrxDpRvRk.SelectedDate)
)
```

**Sesudah (menggunakan stored procedure):**
```powerappsfx
// Jika menggunakan sebagai data source
SP_BTP_REVIEW_FilterByTransactionDate
// Dengan parameter @TransactionDate = TrxDpRvRk.SelectedDate
```

## ⚠️ Catatan Penting

1. **Delegation**: Filter dengan `DateValue()` di Power Apps akan menyebabkan delegation warning. Gunakan stored procedure untuk menghindari masalah ini.

2. **Performance**: Stored procedure akan lebih cepat karena filtering dilakukan di database server, bukan di Power Apps.

3. **Indexing**: Pastikan ada index pada kolom yang sering digunakan untuk filter (TransactionDate, UploadedAt, Status, dll).

## 📝 Mapping Filter dari Gallery.c

Filter di `reviewGallery/gallery.c` dapat dipetakan ke parameter stored procedure:

| Filter Power Apps | Parameter SP |
|------------------|--------------|
| `TrxDpRvRk.SelectedDate` | `@TransactionDate` |
| `UaDpRvRk.SelectedDate` | `@UploadedAt` |
| `searchCustomerRv.Text` | `@SearchCustomer` |
| `searchBatchRv.Text` | `@SearchBatch` |
| `searchDescRv.Text` | `@SearchDescription` |
| `searchBtRv.Text` | `@SearchBankType` |
| `searchBtpRv.Text` | `@SearchBTP` |
| `rkToggleRv.Checked` | `@ShowReview` |
| `rkToggleRvCd.Checked` | `@ShowDebit` |
| `IsApproved = false` | `@IsApproved = 0` |

