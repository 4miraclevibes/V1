# ✅ Checklist Langkah Selanjutnya Power Automate Flow

## 🔍 Status Saat Ini:

Dari screenshot, sudah dikonfigurasi:
- ✅ Trigger: "When Power Apps calls a flow (V2)" dengan 9 parameter
- ✅ SQL Action: "Execute stored procedure (V2)" dengan sebagian parameter

---

## ⚠️ Yang Perlu Diperbaiki:

### **1. Lengkapi Parameter ShowDebit**

**Masalah:** ShowDebit terlihat kosong di screenshot

**Solusi:**
- Klik field **ShowDebit**
- Isi dengan: `@{triggerBody()['ShowDebit']}`

---

### **2. Tambahkan Parameter IsApproved**

**Langkah:**
1. Di bagian "Advanced parameters", checklist **IsApproved**
2. Isi value dengan: `0` (hardcoded, tanpa dynamic content)

---

## 📋 Step Selanjutnya (Belum Dilakukan):

### **Step 3: Parse JSON Results**

**Action:** Data operation → **Parse JSON**

**Langkah:**
1. Klik **"Add an action"** (tombol biru di bawah SQL action)
2. Cari: **"Parse JSON"**
3. Pilih: **Data operation → Parse JSON**

**Configuration:**
- **Content:** 
  ```
  @body('Execute_stored_procedure_(V2)')?['ResultSets']?['Table1']
  ```
- **Schema:** 
  - Klik **"Generate from sample"**
  - Atau gunakan schema manual (lihat di bawah)

**Manual Schema:**
```json
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "ID": {"type": "integer"},
            "BatchID": {"type": "string"},
            "TransactionID": {"type": "integer"},
            "TransactionDate": {"type": "string"},
            "Description": {"type": "string"},
            "CustomerName": {"type": "string"},
            "BTP": {"type": "string"},
            "MatchPercentage": {"type": "number"},
            "MatchCount": {"type": "integer"},
            "TotalTransactions": {"type": "integer"},
            "Status": {"type": "string"},
            "Message": {"type": "string"},
            "BankType": {"type": "string"},
            "IsApproved": {"type": "boolean"},
            "Amount": {"type": "number"},
            "TransactionType": {"type": "string"},
            "UploadedBy": {"type": "string"},
            "UploadedAt": {"type": "string"},
            "ProcessedAt": {"type": "string"}
        }
    }
}
```

---

### **Step 4: Respond to Power Apps**

**Action:** PowerApps → **Respond to a PowerApp or flow**

**Langkah:**
1. Klik **"Add an action"** (tombol biru di bawah Parse JSON)
2. Cari: **"Respond to a PowerApp"**
3. Pilih: **PowerApps → Respond to a PowerApp or flow**

**Configuration:**
- **Response Body:** 
  ```json
  {
      "Success": true,
      "Data": "@{body('Parse_JSON')}",
      "RowCount": "@{length(body('Parse_JSON'))}"
  }
  ```

**Cara mengisi:**
1. Klik **"Add an input"** → Pilih **"Text"**
2. Nama: `Success`, Value: `true`
3. Klik **"Add an input"** → Pilih **"Text"**
4. Nama: `Data`, Value: `@{body('Parse_JSON')}`
5. Klik **"Add an input"** → Pilih **"Text"**
6. Nama: `RowCount`, Value: `@{length(body('Parse_JSON'))}`

**Atau gunakan Code View:**
- Klik tab **"Code view"**
- Paste JSON di atas

---

## ✅ Checklist Final:

- [ ] **ShowDebit** sudah diisi dengan `@{triggerBody()['ShowDebit']}`
- [ ] **IsApproved** sudah ditambahkan dengan value `0`
- [ ] **Parse JSON** action sudah ditambahkan dan dikonfigurasi
- [ ] **Respond to Power Apps** action sudah ditambahkan dan dikonfigurasi
- [ ] Flow sudah di-save
- [ ] Flow sudah di-test (Test → Manual → Run flow)

---

## 🧪 Testing Flow:

Setelah semua step selesai:

1. Klik **"Test"** di kanan atas
2. Pilih **"Manual"**
3. Klik **"Run flow"**
4. Isi parameter test:
   ```
   ShowReview: true
   ShowDebit: false
   SearchCustomer: ""
   SearchBatch: ""
   SearchDescription: ""
   SearchBankType: ""
   TransactionDate: ""
   UploadedAt: ""
   SearchBTP: ""
   ```
5. Klik **"Run flow"**
6. Cek hasil di **"Respond to a PowerApp or flow"** → harus ada data atau array kosong

---

## 📱 Setelah Flow Selesai:

Langkah berikutnya adalah menggunakan flow ini di Power Apps. Lihat file:
- `gallery_WITH_POWERAUTOMATE.c` untuk contoh implementasi di Power Apps

---

## 💡 Tips:

1. **Nama Action:** Power Automate akan auto-rename action jika ada duplikat. Pastikan nama yang digunakan di formula sesuai dengan nama di flow.

2. **Error Handling:** Bisa tambahkan action "Configure run after" untuk handle error jika diperlukan.

3. **Performance:** Parse JSON diperlukan karena SQL stored procedure return data dalam format khusus yang perlu di-parse sebelum dikirim ke Power Apps.
