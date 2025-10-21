# 🏦 BCA Statement HTML to JSON Converter

Converter untuk mengkonversi file HTML rekening koran BCA menjadi JSON format yang compatible dengan Power Apps dan SQL Server Stored Procedures.

---

## 📋 Fitur Utama

✅ **Parse HTML rekening koran BCA**
- Ekstrak informasi rekening (No. Rekening, Nama, Periode, Mata Uang)
- Parse semua transaksi dengan detail lengkap
- Ekstrak ringkasan (Saldo Awal, Mutasi, Saldo Akhir)

✅ **Multiple Output Formats**
- Full JSON (semua data lengkap)
- SQL Format (khusus untuk Stored Procedure)
- Copy to clipboard

✅ **Web Interface yang Modern**
- Drag & drop file HTML
- Preview data real-time
- Download hasil dalam berbagai format

✅ **Command Line Interface (Node.js)**
- Batch processing
- Automation ready

---

## 🚀 Cara Penggunaan

### Option 1: Web Interface (Recommended)

1. **Buka file `converter.html` di browser**
   ```bash
   open converter.html
   ```
   Atau double-click file `converter.html`

2. **Upload file HTML**
   - Drag & drop file HTML ke area upload
   - Atau klik tombol "Pilih File HTML"

3. **Download hasil**
   - **Full JSON**: Semua data lengkap (untuk Power Apps)
   - **For Stored Procedure**: Format khusus untuk SQL Server
   - **Copy to Clipboard**: Copy JSON langsung

4. **Preview data**
   - Informasi rekening
   - Ringkasan transaksi
   - Tabel transaksi lengkap
   - Preview JSON code

### Option 2: Command Line (Node.js)

**Install Node.js** (jika belum ada):
- Download dari https://nodejs.org/

**Run parser dari terminal:**
```bash
node parser.js 0053061777.html
```

**Output:**
- `0053061777_full.json` - Full JSON
- `0053061777_for_sp.json` - Format untuk Stored Procedure

---

## 📊 Format Output

### 1. Full JSON Format

```json
{
  "accountInfo": {
    "accountNumber": "0053061777",
    "accountName": "GREENFIELDS DAIRY I PT",
    "period": "08/10/2025 - 09/10/2025",
    "currency": "Rp"
  },
  "transactions": [
    {
      "TransactionID": 1,
      "TransactionDate": "08/10/2025",
      "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE",
      "Branch": "0000",
      "Amount": 911040.00,
      "AmountFormatted": "911,040.00 CR",
      "TransactionType": "CR",
      "Balance": 8665119366.51,
      "BalanceFormatted": "8,665,119,366.51"
    }
  ],
  "summary": {
    "saldoAwal": 8664208326.51,
    "saldoAwalFormatted": "8,664,208,326.51",
    "mutasiDebet": 0.00,
    "mutasiDebetFormatted": "0.00",
    "mutasiKredit": 1228017153.00,
    "mutasiKreditFormatted": "1,228,017,153.00",
    "saldoAkhir": 9892225479.51,
    "saldoAkhirFormatted": "9,892,225,479.51",
    "totalTransactions": 43
  }
}
```

### 2. SQL Stored Procedure Format

Format ini sudah siap untuk digunakan dengan `OPENJSON` di SQL Server:

```json
[
  {
    "TransactionID": 1,
    "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE"
  },
  {
    "TransactionID": 2,
    "Description": "TRSF E-BANKING CR 0810/FTSCY/WS95051 455520.00  inv tgl 16-09-25 PANNA BERKAT MANDI"
  }
]
```

---

## 🔗 Integrasi dengan Stored Procedure

### Cara Menggunakan JSON di SQL Server

**1. Copy JSON dari converter**

Gunakan tombol "Download untuk Stored Procedure" atau "Copy JSON ke Clipboard"

**2. Panggil Stored Procedure**

```sql
-- Untuk TRSF
DECLARE @JSON NVARCHAR(MAX) = N'[
  {"TransactionID": 1, "Description": "TRSF E-BANKING CR 0710/FTSCY/WS95031 911040.00  ELLA CAROLINE"},
  {"TransactionID": 2, "Description": "TRSF E-BANKING CR 0810/FTSCY/WS95051 455520.00  inv tgl 16-09-25 PANNA BERKAT MANDI"}
]';

EXEC SP_TRSF_FindBTP_Batch @TransactionsJSON = @JSON;
```

**3. Untuk BI-FAST**

```sql
EXEC SP_BIFAST_FindBTP_Batch @TransactionsJSON = @JSON;
```

**4. Untuk MANDIRI**

```sql
EXEC SP_MANDIRI_FindBTP_Batch @TransactionsJSON = @JSON;
```

---

## 🎯 Integrasi dengan Power Apps

### Option 1: Direct JSON Import

1. Upload JSON ke SharePoint/OneDrive
2. Gunakan `ParseJSON()` function di Power Apps
3. Bind data ke Gallery atau Table control

```javascript
// Power Apps Formula
Set(
    TransactionData,
    ParseJSON(JSONString)
);
```

### Option 2: Via Flow (Power Automate)

1. **Trigger**: File upload ke SharePoint
2. **Action**: Parse HTML menggunakan JavaScript
3. **Action**: Call SQL Stored Procedure dengan JSON
4. **Action**: Return hasil ke Power Apps

### Option 3: Via API (Custom Connector)

Buat Azure Function atau Web API yang:
1. Receive HTML file
2. Parse menggunakan `parser.js`
3. Call SQL Stored Procedure
4. Return BTP matching results

---

## 📁 File Structure

```
html_to_json_converter/
├── converter.html          # Web interface
├── parser.js               # Core parser logic
├── README.md               # Documentation (this file)
├── POWER_APPS_GUIDE.md     # Power Apps integration guide
└── examples/
    ├── 0053061777.html                 # Sample input
    ├── 0053061777_full.json           # Sample full output
    └── 0053061777_for_sp.json         # Sample SP output
```

---

## 🧪 Testing

### Test dengan file sample:

**Web Interface:**
```bash
open converter.html
# Upload: ../base_file_bank/0053061777.html
```

**Command Line:**
```bash
cd html_to_json_converter
node parser.js ../base_file_bank/0053061777.html
```

**Expected Output:**
- ✅ 43 transactions parsed
- ✅ Account info extracted
- ✅ Summary calculated correctly

---

## 🔧 Customization

### Menambah Bank Lain

Parser ini dirancang untuk BCA. Untuk bank lain:

1. **Analisa format HTML** dari bank tersebut
2. **Buat parser class baru** (copy dari `BCAStatementParser`)
3. **Adjust regex patterns** sesuai format HTML bank
4. **Test dengan sample file**

Example untuk bank lain:
```javascript
class MandiriStatementParser extends BCAStatementParser {
    parseTransactions() {
        // Custom parsing logic untuk Mandiri
    }
}
```

---

## 🐛 Troubleshooting

### ❌ Parser tidak menemukan transaksi

**Solusi:**
- Pastikan file HTML benar-benar dari BCA
- Check apakah ada format baru dari BCA
- Lihat console log untuk error details

### ❌ JSON tidak bisa di-parse di SQL Server

**Solusi:**
- Pastikan menggunakan format "For Stored Procedure"
- Escape single quotes (`'`) dengan double (`''`)
- Check JSON validity: https://jsonlint.com/

### ❌ Web interface tidak bisa upload

**Solusi:**
- Pastikan file berekstensi `.html` atau `.htm`
- Check browser console untuk errors
- Try with different browser

---

## 📚 Related Documentation

- [Stored Procedures README](../stored_procedures/README.md)
- [TRSF Quick Start](../stored_procedures/TRSF/QUICK_START.md)
- [BIFAST Quick Start](../stored_procedures/BIFAST/QUICK_START.md)
- [MANDIRI Quick Start](../stored_procedures/MANDIRI/QUICK_START.md)

---

## 🎉 Production Ready!

Converter ini sudah siap production dan telah ditest dengan:
- ✅ 43 transaksi dari file sample
- ✅ Multiple transaction types (CR/DB)
- ✅ Special characters dalam description
- ✅ Large amounts & balances
- ✅ Browser compatibility (Chrome, Firefox, Safari, Edge)

---

## 📞 Support

Jika ada masalah atau pertanyaan:
1. Check documentation ini
2. Test dengan sample file terlebih dahulu
3. Check browser console untuk error messages
4. Verify HTML format dari BCA

---

**Version:** 1.0.0  
**Last Updated:** October 21, 2025  
**Status:** ✅ Production Ready

