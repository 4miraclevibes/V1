# ⚡ Quick Start - 5 Menit!

Panduan super cepat untuk mulai menggunakan BCA Statement Converter.

---

## 🎯 Goal

Convert file HTML rekening koran BCA → JSON → Stored Procedure → BTP Matching

---

## 📦 Yang Dibutuhkan

✅ **Browser modern** (Chrome, Firefox, Safari, Edge)  
✅ **File HTML rekening koran dari BCA**  
✅ **SQL Server** (untuk testing SP - optional)  
✅ **Node.js** (untuk command line - optional)

---

## 🚀 Method 1: Web Interface (Tercepat!)

### Step 1: Buka Converter

```bash
# Double-click file ini:
converter.html
```

Atau dari terminal:
```bash
open converter.html  # Mac
start converter.html # Windows
```

### Step 2: Upload File

**Drag & drop** file HTML rekening koran ke area upload

Atau klik **"Pilih File HTML"**

### Step 3: Lihat Hasil

Parser akan otomatis proses dan tampilkan:
- ✅ Info rekening (No. Rek, Nama, Periode)
- ✅ Summary (Saldo Awal, Mutasi, Saldo Akhir)
- ✅ Tabel transaksi lengkap
- ✅ Preview JSON

### Step 4: Download JSON

Klik salah satu tombol:
- **💾 Download Full JSON** → Semua data lengkap
- **🔄 Download untuk Stored Procedure** → Format khusus SP
- **📋 Copy JSON ke Clipboard** → Copy langsung

**DONE!** File JSON siap digunakan untuk Power Apps atau SQL Server!

---

## 💻 Method 2: Command Line (Untuk Developer)

### Step 1: Install Node.js

Download dari: https://nodejs.org/

### Step 2: Run Parser

```bash
cd html_to_json_converter
node parser.js examples/0053061777.html
```

### Step 3: Hasil

File otomatis di-generate:
- `examples/0053061777_full.json` ← Full data
- `examples/0053061777_for_sp.json` ← Untuk SP

---

## 🔗 Cara Menggunakan di SQL Server

### Step 1: Copy JSON

Dari web interface, klik **"Download untuk Stored Procedure"**

Atau copy dari `*_for_sp.json` file

### Step 2: Paste ke SQL Query

```sql
-- 1. Declare JSON variable
DECLARE @JSON NVARCHAR(MAX) = N'[paste JSON here]';

-- 2. Execute stored procedure
EXEC SP_TRSF_FindBTP_Batch @TransactionsJSON = @JSON;
```

### Step 3: Lihat Hasil

SQL akan return hasil matching:
```
TransactionID | Description       | CustomerName    | BTP        | MatchPercentage | Status
1             | TRSF E-BANKING... | ELLA CAROLINE  | 2300014094 | 100.00          | EXCELLENT
2             | TRSF E-BANKING... | PANNA BERKAT   | 2300015239 | 100.00          | EXCELLENT
```

---

## 📱 Cara Menggunakan di Power Apps

### Option A: Manual Import

1. Upload JSON ke SharePoint
2. Gunakan `ParseJSON()` di Power Apps
3. Display di Gallery

### Option B: Via Flow (Recommended)

1. **Create Flow**
   - Trigger: PowerApps (Manual)
   - Input: HTML file content

2. **Add HTTP Action**
   - URL: Azure Function endpoint
   - Body: `{ "htmlContent": "@{triggerBody()['file']}" }`

3. **Add SQL Action**
   - Execute: `SP_FindBTP_Batch`
   - Parameter: `@{body('HTTP')['sqlFormat']}`

4. **Return to PowerApps**
   - Output: SQL results

5. **Display di Gallery**
   - Items: `FlowOutput.value`

---

## 🧪 Test dengan Sample Data

### Sample File Tersedia

`examples/0053061777.html`
- 43 transaksi
- Mix: TRSF, BI-FAST, MANDIRI
- Periode: 08/10/2025 - 09/10/2025

### Test Sekarang

1. Buka `converter.html`
2. Upload `examples/0053061777.html`
3. Verify: "43 transactions found" ✅
4. Download JSON
5. Test di SQL Server

---

## 📊 Format Output

### Full JSON Format

```json
{
  "accountInfo": {
    "accountNumber": "0053061777",
    "accountName": "GREENFIELDS DAIRY I PT",
    "period": "08/10/2025 - 09/10/2025"
  },
  "transactions": [
    {
      "TransactionID": 1,
      "Description": "TRSF E-BANKING CR...",
      "Amount": 911040.00,
      "TransactionType": "CR"
    }
  ],
  "summary": {
    "saldoAwal": 8664208326.51,
    "mutasiKredit": 1228017153.00,
    "saldoAkhir": 9892225479.51
  }
}
```

### SQL SP Format

```json
[
  {
    "TransactionID": 1,
    "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00 ELLA CAROLINE"
  },
  {
    "TransactionID": 2,
    "Description": "TRSF E-BANKING CR 0810/FTSCY/WS95051 455520.00 inv tgl 16-09-25 PANNA BERKAT MANDI"
  }
]
```

---

## 🎯 Bank-Specific Stored Procedures

Gunakan SP yang sesuai dengan jenis transaksi:

### TRSF Transactions
```sql
EXEC SP_TRSF_FindBTP_Batch @TransactionsJSON = @JSON;
```
Pattern: `TRSF E-BANKING...`

### BI-FAST Transactions
```sql
EXEC SP_BIFAST_FindBTP_Batch @TransactionsJSON = @JSON;
```
Pattern: `BI-FAST CR TRANSFER...`

### MANDIRI Transactions
```sql
EXEC SP_MANDIRI_FindBTP_Batch @TransactionsJSON = @JSON;
```
Pattern: `KR OTOMATIS LLG-MANDIRI...`

---

## ✅ Validation

Parser berhasil jika:
- ✅ Account number extracted
- ✅ Account name extracted
- ✅ Transaction count matches summary
- ✅ Saldo calculation correct
- ✅ JSON valid (test di jsonlint.com)

---

## 🐛 Troubleshooting

### "Transaction table not found"

**Solusi:** HTML mungkin bukan dari BCA atau format berbeda

### "Cannot parse JSON in SQL"

**Solusi:** 
1. Validate JSON di jsonlint.com
2. Escape single quotes (`'` → `''`)
3. Use NVARCHAR(MAX) untuk @JSON variable

### "No transactions found"

**Solusi:**
1. Check HTML file valid
2. Verify file dari BCA
3. Try with sample file: `examples/0053061777.html`

---

## 📚 More Documentation

- **Full README:** [README.md](README.md)
- **Power Apps Guide:** [POWER_APPS_GUIDE.md](POWER_APPS_GUIDE.md)
- **Test & Demo:** [TEST_DEMO.md](TEST_DEMO.md)
- **Stored Procedures:** [../stored_procedures/README.md](../stored_procedures/README.md)

---

## 🎉 You're Done!

Parser siap digunakan! 🚀

**Next Steps:**
1. ✅ Test dengan file HTML real
2. ✅ Integrate dengan Power Apps (optional)
3. ✅ Deploy Azure Function (optional)
4. ✅ Automate dengan Flow (optional)

---

**Need Help?**
- Check [README.md](README.md) untuk detail lengkap
- Lihat [TEST_DEMO.md](TEST_DEMO.md) untuk test scenarios
- Review [POWER_APPS_GUIDE.md](POWER_APPS_GUIDE.md) untuk integration

---

**Version:** 1.0.0  
**Status:** ✅ Production Ready  
**Time to Start:** 5 minutes! ⚡

