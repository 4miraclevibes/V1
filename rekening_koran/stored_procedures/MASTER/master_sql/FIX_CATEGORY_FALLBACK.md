# Fix: Category Fallback untuk Data 'NEW'

## Problem

Data master yang di-inject langsung dari CSV (DISTRIBUTOR, KARYAWAN, MODERN_MARKET) memiliki `category = 'NEW'`, sedangkan semua SP bank-specific hanya mencari berdasarkan category bank spesifik (misal `category = 'TRSF'`, `category = 'BIFAST'`, dll).

Akibatnya: Data dengan `category = 'NEW'` tidak akan ditemukan oleh SP bank-specific, meskipun customer name-nya match.

## Solution

Modifikasi WHERE clause di setiap SP bank-specific untuk juga mencari di `category = 'NEW'` sebagai fallback setelah mencari di category bank spesifik.

**Prioritas pencarian:**
1. `category = [BANK_TYPE]` (prioritas utama - data spesifik bank)
2. `category = 'NEW'` (fallback - data universal)

## Implementation

### Pattern untuk diubah:

**SEBELUM:**
```sql
WHERE m.category = 'TRSF'
    AND UPPER(m.customer_name) = UPPER(@CustomerName)
```

**SESUDAH:**
```sql
WHERE (m.category = 'TRSF' OR m.category = 'NEW')
    AND UPPER(m.customer_name) = UPPER(@CustomerName)
ORDER BY 
    CASE WHEN m.category = 'TRSF' THEN 1 ELSE 2 END,  -- Prioritas: bank-specific dulu
    m.match_percentage DESC,
    m.total_transactions DESC,
    m.last_line_number DESC
```

### Files yang perlu diubah:

#### GROUP 1: Array[3] + Array[4] Extraction
- `rekening_koran/stored_procedures/GROUP1/SP_BNI_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP1/SP_BTPN_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP1/SP_BRI_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP1/SP_MEGA_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP1/SP_PERMATA_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP1/SP_DANAMON_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP1/SP_CITIBANK_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP1/SP_SINARMAS_FindBTP_Batch.sql`

#### GROUP 2: Array[4] + Array[5] Extraction
- `rekening_koran/stored_procedures/GROUP2/SP_CIMB_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP2/SP_MAYBANK_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP2/SP_HSBC_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP2/SP_UOB_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP2/SP_MUAMALAT_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP2/SP_OCBC_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP2/SP_DBS_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP2/SP_CAPITAL_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/GROUP2/SP_WOORI_FindBTP_Batch.sql`

#### GROUP 3: Special Logic
- `rekening_koran/stored_procedures/TRSF/SP_TRSF_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/BIFAST/SP_BIFAST_FindBTP_Batch.sql`
- `rekening_koran/stored_procedures/MANDIRI/SP_MANDIRI_FindBTP_Batch.sql`

**Total: 20 SP files + 3 Single SP files (SP_TRSF_FindBTP_Single.sql, SP_BIFAST_FindBTP_Single.sql, SP_MANDIRI_FindBTP_Single.sql)**

## Example Fix untuk TRSF

```sql
-- BEFORE (line ~160-190):
SELECT @TotalOptions = COUNT(DISTINCT btp)
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE m.category = 'TRSF'
    AND UPPER(m.customer_name) = UPPER(@CustomerName);

-- AFTER:
SELECT @TotalOptions = COUNT(DISTINCT btp)
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE (m.category = 'TRSF' OR m.category = 'NEW')
    AND UPPER(m.customer_name) = UPPER(@CustomerName);
```

Dan di bagian INSERT ke @TempOptions:

```sql
-- BEFORE:
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE m.category = 'TRSF'
    AND UPPER(m.customer_name) = UPPER(@CustomerName);

-- AFTER:
FROM [dbo].[MASTER_CUSTOMER_BTP_PATTERN] m
WHERE (m.category = 'TRSF' OR m.category = 'NEW')
    AND UPPER(m.customer_name) = UPPER(@CustomerName)
ORDER BY 
    CASE WHEN m.category = 'TRSF' THEN 1 ELSE 2 END,  -- Bank-specific first
    m.match_percentage DESC,
    m.total_transactions DESC,
    m.last_line_number DESC;
```

## Testing

Setelah fix, test dengan:
1. Data dengan `category = 'TRSF'` → harus ditemukan (prioritas 1)
2. Data dengan `category = 'NEW'` → harus ditemukan (fallback)
3. Jika ada keduanya → yang `category = 'TRSF'` harus di-ranking lebih tinggi

## Notes

- Fix ini tidak breaking change, hanya menambahkan fallback
- Data bank-specific tetap prioritas utama
- Data 'NEW' hanya digunakan jika tidak ada match di category bank spesifik
