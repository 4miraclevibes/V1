# 📋 Tambah Convert ke Excel - Step by Step

## 🎯 Tujuan

Menambahkan convert CSV ke Excel pada flow yang sudah ada, **tanpa mengubah flow CSV yang sudah bekerja**.

**Flow CSV yang sudah ada:**
```
Query → Parse JSON → Create CSV → Compose → Initialize variable → Create file (CSV) → Compose DownloadLink → Respond
```

**Flow baru (dengan Excel):**
```
Query → Parse JSON → Create CSV → Compose → Initialize variable → Create file (CSV) → Create Excel → Convert Data → Add Data ke Excel → Get Excel Link → Update Respond
```

**Keuntungan:**
- ✅ **Minimal perubahan** - hanya tambah step setelah "Create file" (CSV)
- ✅ **CSV tetap dibuat** sebagai backup
- ✅ **Excel juga dibuat** dari data yang sama
- ✅ **Tidak perlu read CSV file** - langsung pakai data dari memory

---

## ✅ Flow yang Sudah Ada (JANGAN DIUBAH)

**Action yang sudah ada dan bekerja:**
1. ✅ **Execute stored procedure (V2)** - Query database
2. ✅ **Parse JSON** - Parse hasil query
3. ✅ **Create CSV table** - Convert ke CSV
4. ✅ **Compose** - Convert ke Base64
5. ✅ **Initialize variable** - Set file name (CSV)
6. ✅ **Create file** - Upload CSV ke SharePoint
7. ✅ **Compose DownloadLink** - Generate CSV download link
8. ✅ **Respond to PowerApps** - Return CSV link

**Action ini JANGAN DIUBAH, hanya perlu dicek apakah sudah benar!**

---

## 🔧 Action yang Perlu DITAMBAHKAN

### **ACTION BARU 1: Create Excel Worksheet**

**Lokasi:** Setelah "Create file" (CSV), sebelum "Compose DownloadLink"

**💡 PENTING:**
- **"Create worksheet"** MEMBUTUHKAN FILE EXCEL (.xlsx) yang sudah ada!
- ⚠️ **MASALAH:** "Create file" membuat CSV file (.csv), bukan Excel file (.xlsx)
- ✅ **SOLUSI:** Ada 3 opsi:
  1. **Pakai file Excel yang sudah ada** di folder (paling mudah untuk test)
  2. **Create Excel file kosong dulu** sebelum "Create worksheet" (RECOMMENDED - lebih fleksibel!)
  3. **Create Excel file dengan data langsung** (skip "Create worksheet", langsung pakai "Add rows")

**⚠️ PENTING:** 
- **Error "ItemAlreadyExists"** terjadi jika worksheet "Data" sudah ada di file Excel yang sama!
- **SOLUSI:** Selalu create file Excel baru setiap kali flow run (dengan timestamp)!

**ACTION BARU 1A: Create Excel File Kosong (TAMBAH INI DULU!)**

**Lokasi:** Setelah "Create file" (CSV), sebelum "Create worksheet"

**Cara tambah:**
1. Scroll ke action **"Create file"** (yang upload CSV ke SharePoint)
2. Klik **"+"** (plus sign) di bawah "Create file"
3. Pilih **"Add an action"**
4. Search: **"Create file"**
5. Pilih: **SharePoint → Create file**

**⚠️ PENTING - RENAME ACTION:**
- Setelah action ditambahkan, **rename action ini** agar tidak bingung dengan "Create file" (CSV) yang sudah ada!
- **Cara rename:** Klik **"..."** (three dots) di kanan atas action → Pilih **"Rename"** → Ketik: **"Create Excel File Kosong"** atau **"Create file (Excel)"**
- **Nama yang disarankan:** `Create Excel File Kosong` atau `Create file (Excel)`

**Configuration:**
- **Site Address:** Pilih SharePoint site yang sama (Dairy Sharepoint)
- **Folder Path:** `/Power Apps/Customer Profile/RK_EXPORT` (sama dengan CSV file)
- **File Name:** 
  - Klik icon **fx** (expression)
  - Ketik: `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')`
  - Klik **OK**
  - **PENTING:** Timestamp akan membuat file Excel baru setiap kali flow run, jadi tidak akan conflict!
- **File Content:** 
  - **CARA 1 (RECOMMENDED - PAKAI VARIABLE!):** Buat Variable dulu untuk Base64 string
    - **Step 1: Buat Variable untuk Base64 String**
      - Scroll ke **sebelum** action "Create Excel File Kosong"
      - Klik **"+"** (plus sign) → Pilih **"Add an action"**
      - Search: **"Initialize variable"**
      - Pilih: **"Initialize variable"**
      - **Name:** `varExcelBase64`
      - **Type:** String
      - **Value:** 
        - Buka file `base64Excel.txt` di folder ini
        - Copy seluruh isi file (Base64 string saja, tanpa `base64ToBinary()`)
        - Paste di field **Value** (langsung paste, tidak perlu expression)
        - Klik **OK**
    - **Step 2: Pakai Variable di File Content**
      - Kembali ke action "Create Excel File Kosong"
      - Klik icon **fx** (expression) di field **File Content**
      - Ketik: `base64ToBinary(variables('varExcelBase64'))`
      - Klik **OK**
    - **💡 KEUNTUNGAN:** 
      - Lebih mudah di-manage (Base64 string terpisah dari expression)
      - Tidak membuat expression field terlalu panjang
      - Lebih mudah di-debug jika ada masalah
  
  - **CARA 2 (ALTERNATIF - LANGSUNG PASTE):** Langsung paste expression lengkap
    - **Step 1:** Buka file `excelFileContentExpression.txt` di folder ini
    - **Step 2:** Copy seluruh isi file tersebut (sudah berisi expression lengkap `base64ToBinary('...')`)
    - **Step 3:** Klik icon **fx** (expression) di field File Content
    - **Step 4:** Paste expression yang sudah di-copy dari `excelFileContentExpression.txt`
    - **Step 5:** Klik **OK**
    - **⚠️ CATATAN:** Expression akan sangat panjang karena Base64 string-nya panjang!
  
  - **CARA 3:** Skip action ini, langsung pakai "Create worksheet" dengan expression (tapi sering error)

**💡 PENTING:**
- **File Excel akan selalu baru** karena ada timestamp di nama file
- **Tidak akan ada conflict** karena setiap flow run membuat file Excel baru
- **Worksheet "Data" bisa selalu dibuat** karena file Excel selalu baru

---

**ACTION BARU 1B: Create Excel Worksheet (OPSIONAL - BISA SKIP!)**

**Lokasi:** Setelah "Create Excel File Kosong" (OPSIONAL! Bisa skip jika file Excel sudah memiliki worksheet)

**❓ KENAPA PERLU "CREATE WORKSHEET"?**
- **"Create Excel File Kosong"** membuat **file Excel kosong** (.xlsx), tapi biasanya sudah memiliki worksheet default (biasanya "Sheet1" atau "Data")
- **"Create worksheet"** menambahkan **worksheet baru** bernama "Data" ke dalam file Excel tersebut (jika belum ada)
- **Setelah itu baru bisa menambahkan data** ke worksheet menggunakan action "Add rows"

**✅ REKOMENDASI: SKIP "CREATE WORKSHEET"!**
- **File Excel kosong yang dibuat biasanya sudah memiliki worksheet default** (misalnya "Sheet1" atau "Data")
- **Langsung skip action "Create worksheet"** dan lanjut ke action "Add rows"
- Di action "Add rows", pilih worksheet yang sudah ada (misalnya "Sheet1" atau "Data")
- **Lebih simple dan tidak akan error "ItemAlreadyExists"!**

**⚠️ JIKA TETAP MAU PAKAI "CREATE WORKSHEET":**
- **Masalah:** Akan error "ItemAlreadyExists" jika worksheet "Data" sudah ada
- **Solusi:** Gunakan nama worksheet yang unik dengan timestamp:
  - Di field "Name", klik icon **fx** (expression)
  - Ketik: `concat('Data_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'))`
  - Setiap flow run akan membuat worksheet baru dengan nama berbeda
  - **⚠️ CATATAN:** Akan membuat banyak worksheet jika flow di-run berkali-kali

**📋 FLOW LENGKAP (RECOMMENDED):**
1. ✅ **Create Excel File Kosong** → Membuat file `.xlsx` kosong (sudah ada worksheet default)
2. ⏭️ **Create worksheet** → **SKIP!** (worksheet sudah ada, tidak perlu create lagi)
3. ✅ **Add rows** → Menambahkan data ke worksheet yang sudah ada (akan dilakukan di step berikutnya)

**⚠️ PENTING:** 
- **Action ini OPSIONAL!** Bisa skip jika file Excel sudah memiliki worksheet
- **Jika tetap mau pakai:** Harus setelah "Create Excel File Kosong" agar menggunakan file Excel yang baru dibuat
- **Jika skip:** Langsung lanjut ke action "Add rows" dan pakai worksheet yang sudah ada

**💡 CATATAN PENTING:**
- **Action ini OPSIONAL!** File Excel kosong biasanya sudah memiliki worksheet default
- **Rekomendasi:** Skip action ini dan langsung lanjut ke "Add rows"
- **Jika tetap mau pakai:** Ikuti langkah di bawah ini

**Cara tambah (JIKA TETAP MAU PAKAI):**
1. Scroll ke action sebelumnya
2. Klik **"+"** (plus sign) di bawah action sebelumnya
3. Pilih **"Add an action"**
4. Search: **"Create worksheet"**
5. Pilih: **Excel Online (Business) → Create worksheet**

**⚠️ PENTING:** Jika belum ada Excel Online (Business) connector:
- Klik **"New connection"** atau **"Add new connection"**
- Pilih **"Excel Online (Business)"**
- Login dengan akun Office 365 kamu
- Authorize permission

**✅ JIKA SKIP ACTION INI:**
- Langsung lanjut ke **ACTION BARU 2: Compose Excel Data** (step berikutnya)
- Setelah itu **ACTION BARU 3: Add rows into a table**
- Di action "Add rows", pilih worksheet yang sudah ada (misalnya "Sheet1" atau "Data")

---

## 🎯 TUTORIAL SINGKAT - ISI APA DI SCREENSHOT

Berdasarkan screenshot kamu dan `createFile.txt`, berikut yang perlu diisi:

**✅ Yang Sudah Benar di Screenshot Kamu:**
- ✅ Location: **"SharePoint Site - Dairy Sharepoint"** (sudah benar!)

**✅ Document Library:**
- ✅ **"Power Apps"** adalah Document Library yang benar!
- ✅ **Cara:** Klik dropdown Document Library → Pilih **"Power Apps"**
- ✅ Setelah pilih "Power Apps", folder "Customer Profile" akan muncul di File field saat browse

**❌ Yang Perlu Diisi:**

**1. File:**
- ⚠️ **PENTING:** Untuk menghindari error "ItemAlreadyExists", pakai file Excel yang baru dibuat!
- ✅ **Solusi:** Pakai output dari action "Create Excel File Kosong" (file Excel baru dengan timestamp)

**CARA 1: Pakai File Excel yang Baru Dibuat (RECOMMENDED! - PAKAI DYNAMIC CONTENT!):**
- ✅ **Solusi:** Pakai output dari action "Create Excel File Kosong" agar otomatis target file yang baru dibuat!
- Klik field **"File"** (yang ada placeholder "Select an Excel file through File Browse.")
- **CARA A (PAKAI DYNAMIC CONTENT - PALING MUDAH & RECOMMENDED!):**
  - Klik field "File" → Pilih **Dynamic content** (atau klik icon **{}** di kanan field)
  - Scroll ke action **"Create Excel File Kosong"** (atau nama action Create file Excel kamu)
  - **Pilih output berikut (sesuai urutan prioritas):**
    1. **`body/Id`** ← **INI YANG PALING RELIABLE & RECOMMENDED!**
       - **Di Dynamic Content akan muncul sebagai:** `body/Id` (dengan label "The unique id of the file or folder.")
       - **Output:** Encoded identifier dari file (contoh: `"%252fPower%2bApps%252fCustomer%2bProfile%252fRK_EXPORT%252fRekeningKoran_Export_20251116_114430.xlsx"`)
       - **💡 INI YANG PALING RELIABLE!** Excel Online connector biasanya lebih suka pakai `Id` daripada `Path`
       - **✅ COBA INI DULU!** Klik `body/Id` dari action "Create file (Excel)"
    2. **`body/Path`** ← Alternatif jika "body/Id" tidak bekerja
       - **Di Dynamic Content akan muncul sebagai:** `body/Path` (dengan label "The path of the file or folder.")
       - **Output:** `"/Power Apps/Customer Profile/RK_EXPORT/RekeningKoran_Export_20251116_114430.xlsx"`
       - **⚠️ CATATAN:** Kadang Excel Online connector tidak bisa resolve `Path` dengan benar, jadi coba `body/Id` dulu!
    3. **`body/Name`** ← ❌ **JANGAN PAKAI INI!** (hanya nama file, bukan path lengkap)
       - **Di Dynamic Content akan muncul sebagai:** `body/Name` (dengan label "The name of the file or folder.")
       - Output: hanya nama file tanpa path lengkap (misalnya "RekeningKoran_Export_20251116_114430.xlsx")
       - **⚠️ ERROR:** Jika pakai `body/Name`, akan error "itemNotFound"!
  - File Excel yang baru dibuat akan otomatis digunakan dengan nama file yang sesuai timestamp!
- **💡 KEUNTUNGAN:**
  - ✅ Otomatis pakai file Excel yang baru dibuat (dengan timestamp)
  - ✅ Tidak perlu browse manual atau ketik nama file
  - ✅ Selalu pakai file yang benar karena langsung dari output action sebelumnya
  - ✅ Tidak akan error "ItemAlreadyExists" karena selalu pakai file baru
- **📋 CONTOH OUTPUT DARI "CREATE EXCEL FILE KOSONG":**
  ```json
  {
    "Path": "/Power Apps/Customer Profile/RK_EXPORT/RekeningKoran_Export_20251116_114430.xlsx",
    "Name": "RekeningKoran_Export_20251116_114430.xlsx",
    "Id": "%252fPower%2bApps%252fCustomer%2bProfile%252fRK_EXPORT%252fRekeningKoran_Export_20251116_114430.xlsx"
  }
  ```
  - **Gunakan `Path`** di Dynamic Content untuk field "File"!

**CARA B (BROWSE MANUAL - TIDAK DISARANKAN):**
- Klik **folder icon** (📁) di kanan field
- **PENTING:** Setelah pilih Document Library "Power Apps", akan muncul folder "Customer Profile" di dropdown
- Browse ke folder yang sama dengan CSV file:
  - Klik folder **"Customer Profile"** di dropdown
  - Klik folder **"RK_EXPORT"**
  - **Pilih file Excel yang baru dibuat** (dengan timestamp terbaru)
  - **⚠️ MASALAH:** Harus manual pilih file, bisa salah pilih file lama → error "ItemAlreadyExists"!
- **Setelah berhasil, worksheet "Data" akan ditambahkan ke file Excel baru ini**

**CARA 2: Create File Baru dengan Expression (SERING ERROR!):**
- ⚠️ **PENTING:** Expression untuk create file baru sering error "Item not found"
- ⚠️ **RECOMMENDED:** Pakai CARA 1 (file yang sudah ada) dulu untuk test
- Jika tetap mau coba create file baru:
  - Klik field **"File"**
  - Klik icon **fx** (expression) langsung (tidak perlu klik folder icon dulu)
  - **Coba format path ini:**
    - `concat('Customer Profile/RK_EXPORT/RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')` (tanpa `/` di awal)
    - Atau: `concat('/sites/dairy/Power Apps/Customer Profile/RK_EXPORT/RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')` (dengan site path)
  - Klik **OK**
  - **Jika masih error:** Pakai CARA 1 (file yang sudah ada) saja!

**2. Name (Worksheet name):**
- **⚠️ PENTING:** Jika error "ItemAlreadyExists", berarti worksheet "Data" sudah ada di file Excel!
- **SOLUSI 1 (RECOMMENDED - SKIP CREATE WORKSHEET):**
  - **Skip action "Create worksheet"** jika error "ItemAlreadyExists"
  - File Excel kosong biasanya sudah memiliki worksheet default (misalnya "Sheet1" atau "Data")
  - Langsung lanjut ke action "Add rows" dan pakai worksheet yang sudah ada
  - Di action "Add rows", pilih worksheet yang sudah ada:
    - Buka file Excel di SharePoint untuk cek worksheet apa yang ada
    - Biasanya ada "Sheet1" atau "Data" (jika sudah ada)
    - Pilih worksheet tersebut di field "Worksheet" di action "Add rows"
- **SOLUSI 2 (ALTERNATIF - NAMA UNIK DENGAN TIMESTAMP):**
  - Gunakan nama worksheet yang unik setiap kali (dengan timestamp)
  - Klik icon **fx** (expression) di field "Name"
  - Ketik: `concat('Data_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'))`
  - Setiap flow run akan membuat worksheet baru dengan nama berbeda (contoh: "Data_20251116_120533")
  - **⚠️ CATATAN:** Akan membuat banyak worksheet jika flow di-run berkali-kali
- **Jika tidak pakai SOLUSI 2 dan tidak error:**
  - Klik field **"Name"** (yang ada placeholder "Worksheet name.")
  - Ketik: `Data`
  - Tekan Enter atau klik di luar field

**⚠️ CEK CODE VIEW SETELAH KONFIGURASI:**
- Setelah konfigurasi, klik tab **"Code view"** untuk memastikan field "File" menggunakan `body/Id` atau `body/Path`
- **✅ BENAR (RECOMMENDED):** `"file": "@outputs('Create_file_(Excel)')?['body/Id']"` ← Pakai ini dulu!
- **✅ BENAR (ALTERNATIF):** `"file": "@outputs('Create_file_(Excel)')?['body/Path']"`
- **❌ SALAH:** `"file": "@outputs('Create_file_(Excel)')?['body/Name']"` ← Jika muncul ini, berarti salah pilih!
- **❌ SALAH:** `"file": "Data_20251116_120252"` ← Jika muncul ini, berarti dynamic content tidak ter-resolve!
- Jika salah, kembali ke field "File" dan pilih `body/Id` dari Dynamic Content (coba ini dulu!)

**⚠️ JIKA ERROR "itemNotFound":**
- **Masalah:** Field "file" tidak ter-resolve dengan benar atau format tidak sesuai
- **Solusi 1:** Coba pakai `body/Id` daripada `body/Path` (lebih reliable untuk Excel Online connector)
- **Solusi 2:** Pastikan action "Create_file_(Excel)" sudah berhasil sebelum action "Create worksheet" dijalankan
- **Solusi 3:** Cek di Run History apakah output dari "Create_file_(Excel)" memiliki `body/Id` atau `body/Path` yang valid

**✅ Selesai! Klik Save di kanan atas.**

---

## 🧪 TEST ACTION INI DULU (SEBELUM LANJUT KE STEP BERIKUTNYA)

**Bisa langsung test action "Create Excel Worksheet" ini dulu sebelum lanjut ke step berikutnya!**

**Cara Test:**
1. Klik **"Save"** di kanan atas flow
2. Klik **"Test"** → Pilih **"Manually"** atau **"Run flow"**
3. Tunggu sampai flow selesai

**Yang Harus Dicek Setelah Test:**
- ✅ Action "Create Excel Worksheet" berhasil (ada tanda centang hijau)
- ✅ Status code: **201** (Created - berhasil!)
- ✅ Output menunjukkan:
  - `"name": "Data"` → Worksheet "Data" sudah ter-create!
  - `"id": "{0C250706-70A6-4130-8BA2-147D3A36A29D}"` → Worksheet ID (akan dipakai di step berikutnya)
  - `"position": 1` → Worksheet di posisi pertama
- ✅ Cek di SharePoint: 
  - **File CSV sudah ter-create** (dari action "Create file") → Contoh: `RekeningKoran_Export_20251116_110157.csv`
  - **File Excel kosong sudah ter-create** (dari action "Create Excel File Kosong")
  - **File Excel sudah ada worksheet "Data"** (dari action "Create worksheet")
- ✅ File Excel bisa dibuka → Buka file Excel → Lihat worksheet "Data" sudah ada (masih kosong, belum ada data - itu normal!)

**⚠️ PENTING - PENJELASAN:**
- **"Create file"** membuat **CSV file** (.csv) - ini normal dan tetap dibuat sebagai backup!
- **"Create worksheet"** menambahkan worksheet ke **file Excel** (.xlsx) yang sudah ada - ini juga normal!
- **CSV dan Excel adalah file terpisah:**
  - CSV file: `RekeningKoran_Export_20251116_110157.csv` (dari "Create file")
  - Excel file: File Excel yang kamu pilih di "Create worksheet" (misalnya `REKENING_KORAN.xlsx`)
- **"Create worksheet" TIDAK bisa pakai output dari "Create file"** karena itu CSV, bukan Excel!

**Jika Berhasil (Status Code 201):**
- ✅ **SUKSES!** Worksheet "Data" sudah ter-create di Excel file!
- ✅ Output menunjukkan `"name": "Data"` dan `"id": "{...}"` → Ini berarti berhasil!
- ✅ **Lanjut ke step berikutnya:** ACTION BARU 2: Compose Excel Data
- ✅ Setelah itu ACTION BARU 3: Add rows into a table (untuk populate data ke Excel)

**Jika Error "ItemAlreadyExists" (Status Code 400):**
- ❌ **Masalah:** Worksheet "Data" sudah ada di file Excel yang sama!
- ✅ **Solusi:** Selalu create file Excel baru setiap kali flow run (dengan timestamp)
  - Pastikan di action "Create Excel File Kosong", File Name menggunakan timestamp:
    ```
    concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')
    ```
  - Timestamp akan membuat file Excel baru setiap kali flow run
  - Tidak akan ada conflict karena file Excel selalu baru
- ✅ **Atau:** Pakai file Excel yang berbeda setiap kali (dengan timestamp di nama file)

**Jika Error "Item not found":**

**✅ SOLUSI STEP-BY-STEP:**

**1. Pastikan Document Library = "Power Apps":**
- Klik dropdown Document Library
- Pilih **"Power Apps"** (ini Document Library yang benar!)
- **PENTING:** Setelah pilih "Power Apps", folder "Customer Profile" akan muncul saat browse File

**2. File field - PAKAI FILE EXCEL YANG SUDAH ADA (RECOMMENDED - PALING RELIABLE!):**
- ⚠️ **PENTING:** Expression untuk create file baru sering error "Item not found"!
- ✅ **SOLUSI:** Pakai file Excel yang sudah ada dulu (seperti yang kamu test berhasil!)
- Klik field **"File"**
- Klik **folder icon** (📁) di kanan field
- **PENTING:** Browse ke folder yang sama dengan CSV file:
  - Setelah pilih Document Library "Power Apps", akan muncul folder **"Customer Profile"** di dropdown
  - Klik folder **"Customer Profile"** 
  - Klik folder **"RK_EXPORT"** (atau folder tempat file Excel berada)
  - **Pilih file Excel yang sudah ada** (contoh: `REKENING_KORAN.xlsx` atau file Excel lain yang sudah ada)
  - **Setelah berhasil test dengan file yang sudah ada, baru bisa coba create file baru (tapi sering error)**

**3. Jika masih error:**
- Pastikan Document Library = **"Power Apps"** (bukan "Documents" atau yang lain!)
- Pastikan sudah browse ke folder "Customer Profile" → "RK_EXPORT" dulu sebelum ketik nama file

**Jika Error Lain:**
- ❌ Cek error message
- ❌ Pastikan Location = "SharePoint Site - Dairy Sharepoint"
- ❌ Pastikan Document Library = **"Power Apps"** (ini yang benar!)
- ❌ Pastikan sudah browse ke folder "Customer Profile" → "RK_EXPORT" dulu sebelum ketik nama file
- ❌ Pastikan File name expression benar
- ❌ Pastikan Name = "Data"

---

**Configuration (Detail - Baca Jika Perlu):**

**STEP 1: Cek Location CSV File (PENTING!)**

Sebelum mengisi Location, cek dulu di action **"Create file"** (CSV) untuk melihat location yang dipakai:

1. Scroll ke action **"Create file"** (yang upload CSV)
2. Klik action **"Create file"** untuk melihat konfigurasinya
3. Lihat field **"Site Address"**:
   - **Contoh yang kamu lihat:** `Dairy Sharepoint - https://greenfieldsdairy.sharepoint.com/sites/dairy`
   - Ini menunjukkan CSV ada di **SharePoint** (bukan OneDrive!)
   - **Catat:** Location untuk Excel harus **"SharePoint"** juga!
4. Lihat field **"Folder Path"**:
   - **Contoh yang kamu lihat:** `/Power Apps/Customer Profile/RK_EXPORT`
   - Ini adalah path lengkap folder di SharePoint
   - **Catat** path ini untuk reference!

---

**STEP 2: Isi Location**

- **Location:** 
  - Klik dropdown **"Location"**
  - **PENTING:** Pilih location yang **SAMA** dengan CSV file!
  - Jika CSV di **SharePoint** → Pilih **"SharePoint"** dari dropdown (bukan OneDrive for Business!)
  - Jika CSV di **OneDrive** → Pilih **"OneDrive for Business"**
  - **Jangan pilih berbeda**, agar Excel dan CSV di folder yang sama

**💡 Contoh:**
- CSV file di: `https://greenfieldsdairy.sharepoint.com/sites/dairy`
- Maka Location Excel: 
  - Klik dropdown Location
  - Pilih **"SharePoint"** (bukan "OneDrive for Business"!)
  - Setelah pilih SharePoint, akan muncul field "Document Library"

**⚠️ CATATAN:**
- Di screen kamu mungkin melihat default "OneDrive for Business" dan "OneDrive"
- **Jangan pakai default ini** jika CSV file ada di SharePoint!
- **Harus pilih "SharePoint"** dari dropdown jika CSV di SharePoint!

---

**STEP 3: Isi Document Library**

- **Document Library:** 
  - **Jika Location = SharePoint:**
    - Field **"Document Library"** akan muncul setelah pilih SharePoint
    - Klik dropdown **"Document Library"**
    - **Cara menentukan Document Library berdasarkan Folder Path CSV:**
      - Lihat di action "Create file" (CSV), field **"Folder Path"**
      - **Contoh Folder Path kamu:** `/Power Apps/Customer Profile/RK_EXPORT`
      - **⚠️ PENTING:** Folder Path di SharePoint biasanya **TIDAK** menunjukkan Document Library di awal path!
      - "Power Apps" adalah **folder** di dalam Document Library, bukan Document Library itu sendiri!
    - **Cara menentukan Document Library:**
      - **Option 1:** Coba pilih dari dropdown yang muncul:
        - `Shared Documents` (paling umum - coba ini dulu!)
        - `Documents` (jika Shared Documents tidak ada)
        - Atau library lain yang muncul di dropdown
      - **Option 2:** Klik folder icon (📁) di Document Library untuk browse
      - **Option 3:** Cek di SharePoint site langsung (`https://greenfieldsdairy.sharepoint.com/sites/dairy`) untuk melihat library name
  - **Jika Location = OneDrive for Business:**
    - Field akan otomatis jadi **"OneDrive"** (tidak perlu pilih)

**💡 Contoh Berdasarkan Parameter CSV Kamu:**
- **Site Address CSV:** `Dairy Sharepoint - https://greenfieldsdairy.sharepoint.com/sites/dairy`
- **Folder Path CSV:** `/Power Apps/Customer Profile/RK_EXPORT`
- **Document Library untuk Excel:**
  - Kemungkinan besar: **`Shared Documents`** (paling umum)
  - Atau: **`Documents`** (jika Shared Documents tidak ada)
  - **Cara cek:** Klik dropdown Document Library dan lihat pilihan yang muncul, atau klik folder icon untuk browse

**⚠️ CATATAN PENTING:**
- Folder Path `/Power Apps/...` **BUKAN** berarti Document Library = "Power Apps"!
- "Power Apps" adalah **folder** di dalam Document Library, bukan Document Library itu sendiri!
- Document Library adalah root library di SharePoint (biasanya "Shared Documents" atau "Documents")
- **Cara terbaik:** 
  1. Pilih Location = "SharePoint" dulu
  2. Klik dropdown Document Library
  3. Pilih yang paling umum (biasanya "Shared Documents")
  4. Atau klik folder icon untuk browse dan pilih library yang sesuai

**⚠️ CATATAN:**
- Jika di screen kamu masih melihat "OneDrive" di Document Library, berarti Location belum dipilih "SharePoint"!
- Pastikan Location sudah dipilih "SharePoint" dulu, baru Document Library akan muncul dengan pilihan SharePoint libraries!

---

**STEP 4: Isi File**

- **File:** 
  - Klik field **"File"**
  - Pilih **"Create new file"** (icon + atau tombol "Create new file")
  - **Jangan** pilih file yang sudah ada!

---

**STEP 5: Isi File name**

- **File name:** 
  - Klik icon **fx** (expression) di kanan field
  - Ketik: `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')`
  - Klik **OK**
  - **Penjelasan:** File Excel akan punya nama dengan timestamp, berbeda dengan CSV
  - **Contoh hasil:** `RekeningKoran_Export_20250115_143022.xlsx`

---

**STEP 6: Isi Worksheet name**

- **Worksheet name:** 
  - Ketik: `Data`
  - Klik **OK**
  - **Penjelasan:** Ini adalah nama sheet di Excel file

---

**✅ Checklist Location & Document Library:**

- [ ] Sudah cek di action "Create file" (CSV) untuk melihat Location yang dipakai
- [ ] Location Excel = **SAMA** dengan Location CSV (SharePoint atau OneDrive)
- [ ] Document Library Excel = **SAMA** dengan Document Library CSV (jika SharePoint)
- [ ] File = Create new file (bukan file yang sudah ada)
- [ ] File name = expression dengan `.xlsx`
- [ ] Worksheet name = `Data`

**Urutan flow setelah ini:**
```
Create file (CSV) → Create Excel Worksheet (BARU!) → [Compose DownloadLink]
```

**💡 Catatan:**
- File Excel akan ter-create di SharePoint/OneDrive
- File Excel masih kosong (belum ada data)
- Data akan di-add di step berikutnya

---

## ✅ URUTAN FLOW SETELAH "CREATE FILE (EXCEL)":

```
Create file (Excel) → Create table → Apply to each (Parse JSON) → Add a row into a table → Get file properties → Compose DownloadLink → Respond
```

### **STEP 1: Create table (BUAT TABLE DULU!)**

**⚠️ PENTING:** Harus buat table dulu sebelum bisa add row!

**Cara tambah:**
1. Setelah "Create file (Excel)", klik **"+"**
2. Search: **"Create table"**
3. Pilih: **Excel Online (Business) → Create table**

**Configuration:**
- **Location:** "SharePoint Site - Dairy Sharepoint"
- **Document Library:** "Power Apps"
- **File:** `body/Path` dari "Create file (Excel)" (Dynamic content)
- **Worksheet:** `Sheet1` (ketik manual - worksheet default)
- **Address:** `A1` (ketik manual - mulai dari cell A1)
- **Has headers:** **Yes** (toggle ON)

**Output:** Table ID yang akan dipakai di step berikutnya

---

### **STEP 2: Apply to each (Parse JSON)**

**Cara tambah:**
1. Setelah "Create table", klik **"+"**
2. Search: **"Apply to each"**
3. Pilih: **Control → Apply to each**

**Configuration:**
- **Select an output from previous steps:**
  - Klik Dynamic content
  - Pilih output dari **"Parse JSON"** (yang `body('Parse_JSON')` sudah bekerja!)
  - **Atau pakai expression:** `body('ParseJson')`

---

### **STEP 3: Add a row into a table (DI DALAM Apply to each)**

**Cara tambah:**
1. Di dalam "Apply to each", klik **"+"**
2. Search: **"Add a row into a table"**
3. Pilih: **Excel Online (Business) → Add a row into a table**

**Configuration:**
- **Location:** "SharePoint Site - Dairy Sharepoint"
- **Document Library:** "Power Apps"
- **File:** `body/Path` dari "Create file (Excel)" (Dynamic content)
- **Table:** 
  - **⚠️ PENTING:** Pilih table yang sudah dibuat di STEP 1!
  - Klik dropdown "Table"
  - Pilih output dari **"Create table"** (Dynamic content)
  - **Atau:** Pilih nama table dari dropdown jika sudah muncul
  - **CATATAN:** Tidak bisa pakai `A1` langsung! Harus pilih table yang sudah dibuat!
- **Row:** Pakai Dynamic content (PALING MUDAH & PASTI BEKERJA!):
  - **CARA 1 (DYNAMIC CONTENT - RECOMMENDED & PASTI BEKERJA!):**
    - Klik field "Row"
    - Klik icon **⚡** (Dynamic content) di kanan field
    - Scroll ke action **"Apply to each"**
    - Pilih field dari "Apply to each" satu per satu (URUTAN PENTING!):
      1. Klik `Tanggal Transaksi` dari "Apply to each"
      2. Klik `Keterangan` dari "Apply to each"
      3. Klik `Jumlah` dari "Apply to each"
      4. Klik `DB/CR` dari "Apply to each"
      5. Klik `Bill To Party` dari "Apply to each"
      6. Klik `Bank Type` dari "Apply to each"
    - **Power Automate akan otomatis convert jadi array!** Tidak perlu expression!
  - **CARA 2 (EXPRESSION - JIKA DYNAMIC CONTENT TIDAK BEKERJA):**
    - Klik field "Row"
    - Klik icon **fx** (expression)
    - Ketik expression ini (PASTIKAN NAMA ACTION BENAR!):
      ```
      createArray(items('Apply_to_each')?['Tanggal Transaksi'], items('Apply_to_each')?['Keterangan'], items('Apply_to_each')?['Jumlah'], items('Apply_to_each')?['DB/CR'], items('Apply_to_each')?['Bill To Party'], items('Apply_to_each')?['Bank Type'])
      ```
    - **⚠️ PENTING:** 
      - Ganti `Apply_to_each` dengan nama action "Apply to each" kamu yang benar!
      - Cek nama action di Code View jika tidak yakin
      - Pakai `createArray()` bukan `[...]` untuk Power Automate!

---

### **STEP 3: Get file properties**

**Cara tambah:**
1. Setelah "Apply to each", klik **"+"**
2. Search: **"Get file properties"**
3. Pilih: **SharePoint → Get file properties**

**Configuration:**
- **Site Address:** "SharePoint Site - Dairy Sharepoint"
- **File Identifier:** `body/Id` dari "Create file (Excel)" (Dynamic content)

---

### **STEP 4: Compose DownloadLink**

**Cara tambah:**
1. Setelah "Get file properties", klik **"+"**
2. Search: **"Compose"**
3. Pilih: **Data operation → Compose**

**Rename:** `Compose DownloadLink`

**Configuration:**
- **Input:** `body/Path` dari "Get file properties" (Dynamic content)

---

### **STEP 5: Update Respond to PowerApps**

**Configuration:**
- **Parameter `sharePointLink`:** Output dari "Compose DownloadLink" (Dynamic content)
- Parameter lain tetap sama

---

## ❌ HAPUS ACTION INI (JIKA ADA):
- **Compose JSON Data** ← HAPUS!
- **Select Excel Data** ← HAPUS!
- **Compose Excel Data** ← HAPUS!

---

### **ACTION BARU 2: Compose Excel Data (Convert JSON to Excel Format) - OLD VERSION**

**⚠️ CATATAN:** Action ini tidak dipakai jika pakai flow terpisah di atas!

**Configuration:**
- **Input (Expression):**
  - Klik field **"Inputs"** (yang ada error "'Inputs' is required")
  - Klik icon **fx** (expression) di kanan field
  - **⚠️ PENTING:** Harus ketik expression lengkap, jangan pakai Dynamic content saja!
  - **EXPRESSION YANG BENAR (COPY-PASTE INI KE FX EXPRESSION EDITOR):**
    - **⚠️ PENTING:** Expression ini HARUS convert array of objects menjadi array of arrays!
    - **Copy expression ini saja (tanpa markdown formatting):**
    
    `map(body('ParseJson'), item => [item?['Tanggal Transaksi'], item?['Keterangan'], item?['Jumlah'], item?['DB/CR'], item?['Bill To Party'], item?['Bank Type']])`
    
    - **⚠️ PENTING:** 
      - Expression ini HARUS pakai `map()` untuk convert setiap object menjadi array!
      - `body('ParseJson')` → Akses output dari Parse JSON (sudah terbukti bekerja!)
      - `map(..., item => [...])` → Convert setiap object menjadi array of values
      - Hasil akhir HARUS array of arrays: `[["value1", "value2", ...], ["value1", "value2", ...]]`
      - BUKAN array of objects: `[{"field1": "value1", ...}, {"field1": "value1", ...}]`
    
    - **Atau pakai `createArray()` (ALTERNATIF - HASILNYA SAMA):**
    
    `map(body('ParseJson')?['body'], item => createArray(item?['Tanggal Transaksi'], item?['Keterangan'], item?['Jumlah'], item?['DB/CR'], item?['Bill To Party'], item?['Bank Type']))`
    
    - **⚠️ PENTING:** 
      - Dari `outputParseJson.txt` (baris 2), output Parse JSON adalah `{"body": [...]}`
      - Jadi harus pakai `body('ParseJson')?['body']` untuk akses array-nya!
      - Bukan `body('ParseJson')` saja (itu akan return object dengan key "body")
    
    - **Atau ketik manual dengan format yang lebih mudah dibaca:**
    
    `map(body('ParseJson')?['body'], item => [` (baris pertama)
    `item?['Tanggal Transaksi'],` (baris kedua)
    `item?['Keterangan'],` (baris ketiga)
    `item?['Jumlah'],` (baris keempat)
    `item?['DB/CR'],` (baris kelima)
    `item?['Bill To Party'],` (baris keenam)
    `item?['Bank Type']` (baris ketujuh)
    `])` (baris kedelapan - tutup dengan bracket dan kurung)
  - **✅ Field names sudah sesuai dengan schema:** `Tanggal Transaksi`, `Keterangan`, `Jumlah`, `DB/CR`, `Bill To Party`, `Bank Type`
  - **PENTING:** Setelah ketik expression, klik **"Update"** atau **"OK"** di expression editor (bukan hanya tutup!)
  - Error "'Inputs' is required" akan hilang setelah expression di-apply dan klik Update/OK

**Penjelasan:**
- Expression ini convert array of objects (dari Parse JSON) ke array of arrays
- Setiap object di-convert ke array sesuai urutan kolom
- Format ini yang dibutuhkan Excel untuk "Add rows into a table"

**⚠️ TROUBLESHOOTING - ERROR "A value must be provided for item":**
- **Masalah:** Output "Compose Excel Data" masih array of objects, bukan array of arrays!
- **Penyebab:** Expression `map(...)` tidak bekerja atau tidak di-apply dengan benar
- **Solusi:**
  1. **Cek output "Compose Excel Data" di run history:**
     - Buka run history → Cek output "Compose Excel Data"
     - **SALAH (array of objects):**
       ```json
       [
         {"Tanggal Transaksi": "...", "Keterangan": "...", ...},
         {"Tanggal Transaksi": "...", "Keterangan": "...", ...}
       ]
       ```
     - **BENAR (array of arrays):**
       ```json
       [
         ["2025-12-11T00:00:00", "RPT: PT ERA KOPI", 1853078, "CR", "2300016953", "VA"],
         ["2025-12-11T00:00:00", "RPT: PT PALEM", 463269, "CR", "2300017975", "VA"]
       ]
       ```
  2. **Jika output masih array of objects (seperti di `outputComposeExcelData.txt`):**
     - **LANGKAH 1:** Buka action "Compose Excel Data"
     - **LANGKAH 2:** Klik field "Inputs"
     - **LANGKAH 3:** Klik icon **fx** (expression) di kanan field
     - **LANGKAH 4:** **HAPUS SEMUA** yang ada di expression editor (jika ada Dynamic content atau expression lain)
     - **LANGKAH 5:** Ketik ulang expression lengkap ini (COPY-PASTE):
       - **Copy expression ini (satu baris, tanpa markdown formatting):**
       
       `map(body('ParseJson'), item => [item?['Tanggal Transaksi'], item?['Keterangan'], item?['Jumlah'], item?['DB/CR'], item?['Bill To Party'], item?['Bank Type']])`
       
       - **Atau ketik manual baris per baris:**
       - Baris 1: `map(body('ParseJson'), item => [`
       - Baris 2: `item?['Tanggal Transaksi'],`
       - Baris 3: `item?['Keterangan'],`
       - Baris 4: `item?['Jumlah'],`
       - Baris 5: `item?['DB/CR'],`
       - Baris 6: `item?['Bill To Party'],`
       - Baris 7: `item?['Bank Type']`
       - Baris 8: `])`
     - **LANGKAH 6:** **PENTING!** Klik **"Update"** atau **"OK"** di expression editor (bukan hanya tutup!)
     - **LANGKAH 7:** Test lagi flow kamu
     - **LANGKAH 8:** Cek output "Compose Excel Data" di run history → Harus jadi array of arrays!
  3. **Jika masih error, cek:**
     - Apakah nama action Parse JSON sudah benar? (`ParseJson` sesuai Code View kamu)
     - Apakah sudah klik "Update" atau "OK" setelah ketik expression?
     - Apakah expression lengkap dengan `map(...)` dan `item => [...]`?

**Urutan flow setelah ini:**
```
Create Excel Worksheet → Compose Excel Data (BARU!) → [Add rows into a table]
```

---

### **ACTION BARU 3: Add rows into a table**

**Lokasi:** Setelah "Compose Excel Data", sebelum "Compose DownloadLink"

**Cara tambah:**
1. Scroll ke action **"Compose Excel Data"** (yang baru dibuat)
2. Klik **"+"** (plus sign) di bawah "Compose Excel Data"
3. Pilih **"Add an action"**
4. Search: **"Add rows into a table"**
5. Pilih: **Excel Online (Business) → Add rows into a table**

**Configuration:**

**1. Location:**
- Pilih **"SharePoint Site - Dairy Sharepoint"** (sama dengan "Create file (Excel)")

**2. Document Library:**
- Pilih **"Power Apps"** (sama dengan "Create file (Excel)")

**3. File:**
- Klik field → Pilih **Dynamic content**
- Scroll ke action **"Create file (Excel)"**
- Pilih **`body/Path`** ← INI YANG DIPILIH!
- Output: `"/Power Apps/Customer Profile/RK_EXPORT/RekeningKoran_Export_20251116_114430.xlsx"`

**4. Table:**
- **⚠️ PENTING:** Field ini TIDAK punya opsi "Create new table" atau "+" sign!
- Klik field **"Table"** (yang ada placeholder "Select a table from the drop-down.")
- **Ketik manual:** `A1` (alamat cell untuk mulai membuat tabel)
- **Penjelasan:** 
  - `A1` berarti mulai dari cell A1
  - Excel akan otomatis membuat tabel dari data yang di-add di field "Row"
  - Harus ketik manual, tidak bisa pakai dynamic content!
- **⚠️ CATATAN:** Jika file Excel sudah punya tabel yang sudah dibuat sebelumnya, bisa pilih dari dropdown. Tapi file Excel kosong biasanya tidak punya tabel, jadi ketik `A1`

**5. Row (atau Values):**
- **⚠️ PENTING:** Field ini muncul setelah Table diisi!
- **⚠️ ERROR "A value must be provided for item" berarti field ini belum diisi atau salah!**

**⚠️ JIKA SEMUA EXPRESSION TIDAK BEKERJA, PAKAI CARA INI:**

**CARA 1: Pakai "Apply to each" + "Add a row into a table" (SOLUSI JIKA `map()` TIDAK BEKERJA!)**
- **⚠️ CATATAN:** Cara ini akan add row satu per satu (lebih lambat tapi pasti bekerja!)
- **LANGKAH 1:** Skip atau hapus action "Compose Excel Data" (tidak dipakai!)
- **LANGKAH 2:** Tambahkan action **"Apply to each"** setelah "Create file (Excel)"
- **LANGKAH 3:** Di "Apply to each" → "Select an output from previous steps":
  - Klik Dynamic content
  - Pilih output dari **"Parse JSON"** (yang `body('Parse_JSON')` sudah terbukti bekerja!)
  - **Atau pakai expression:** `body('ParseJson')` (ketik di fx expression editor)
- **LANGKAH 4:** Di dalam "Apply to each", tambahkan action **"Add a row into a table"** (bukan "Add rows"!)
  - Search: "Add a row into a table"
  - Pilih: Excel Online (Business) → Add a row into a table
- **LANGKAH 5:** Konfigurasi "Add a row into a table":
  - **Location:** "SharePoint Site - Dairy Sharepoint"
  - **Document Library:** "Power Apps"
  - **File:** `body/Path` dari "Create file (Excel)" (Dynamic content)
  - **Table:** `A1` (ketik manual)
  - **Row:** Pakai expression di field "Row" (KLIK FX, BUKAN DYNAMIC CONTENT!):
    ```
    [items('Apply_to_each')?['Tanggal Transaksi'], items('Apply_to_each')?['Keterangan'], items('Apply_to_each')?['Jumlah'], items('Apply_to_each')?['DB/CR'], items('Apply_to_each')?['Bill To Party'], items('Apply_to_each')?['Bank Type']]
    ```
    - **Cara:** Klik field "Row" → Klik icon **fx** → Paste expression di atas → Klik "Update"
    - **Penjelasan:** Expression ini convert setiap object menjadi array untuk setiap row!

**CARA 2: Pakai Dynamic Content dari Compose Excel Data (JIKA SUDAH BERHASIL)**
- Klik field **"Row"** (atau "Values" tergantung versi Power Automate)
- Klik icon **⚡** (lightning bolt) atau **Dynamic content** di kanan field
- Scroll ke action **"Compose Excel Data"**
- Pilih output dari **"Compose Excel Data"** ← INI YANG DIPILIH!
- **Pastikan:** Output yang dipilih adalah output dari "Compose Excel Data", bukan dari action lain!

**CARA 3: Pakai Expression (JIKA DYNAMIC CONTENT TIDAK MUNCUL)**
- Klik icon **fx** (function) di kanan field
- Ketik: `outputs('Compose_Excel_Data')`
- **⚠️ PENTING:** Ganti `Compose_Excel_Data` dengan nama action Compose Excel Data kamu yang benar!
- Contoh: Jika nama action adalah "Compose Excel Data", maka: `outputs('Compose_Excel_Data')`
- Klik **OK** atau **Update**

**Urutan flow setelah ini:**
```
Compose Excel Data → Add rows into a table (BARU!) → [Compose DownloadLink]
```

**💡 Catatan:**
- Excel akan otomatis detect headers dari baris pertama array
- Data rows akan di-add setelah headers
- Table akan ter-format otomatis oleh Excel

---

### **ACTION BARU 4: Get file properties (Excel)**

**Lokasi:** Setelah "Add rows into a table", sebelum "Compose DownloadLink"

**Cara tambah:**
1. Scroll ke action **"Add rows into a table"** (yang baru dibuat)
2. Klik **"+"** (plus sign) di bawah "Add rows into a table"
3. Pilih **"Add an action"**
4. Search: **"Get file properties"**
5. Pilih: **SharePoint → Get file properties**

**Configuration:**
- **Site Address:** 
  - Pilih SharePoint site yang sama dengan Create Excel Worksheet
  - Contoh: `https://greenfieldsdairy.sharepoint.com/sites/dairy`
- **File Identifier:** 
  - Klik field → Pilih **Dynamic content**
  - Scroll ke action **"Create Excel Worksheet"**
  - Pilih **`File`** atau **`File identifier`** ← INI YANG DIPILIH!
  - **Penjelasan:** Ini adalah file Excel yang baru dibuat

**Urutan flow setelah ini:**
```
Add rows into a table → Get file properties (BARU!) → [Compose DownloadLink]
```

**💡 Catatan:**
- Action ini akan mengambil properties file Excel (termasuk Path untuk download link)

---

### **ACTION BARU 5: Compose Excel DownloadLink**

**Lokasi:** Setelah "Get file properties", sebelum "Respond to PowerApps"

**Cara tambah:**
1. Scroll ke action **"Get file properties"** (yang baru dibuat)
2. Klik **"+"** (plus sign) di bawah "Get file properties"
3. Pilih **"Add an action"**
4. Search: **"Compose"**
5. Pilih: **Data operation → Compose**

**Rename action:**
- Klik **"..."** (three dots) di kanan atas action
- Pilih **"Rename"**
- Ketik: `Compose Excel DownloadLink`
- Klik **OK**

**Configuration:**
- **Input:**
  - **Cara 1 (Dynamic Content - PALING MUDAH):**
    - Klik field "Input"
    - Pilih **Dynamic content**
    - Scroll ke action **"Get file properties"**
    - Pilih **`body/Path`** ← INI YANG DIPILIH!
    - **Penjelasan:** `Path` adalah path lengkap file Excel di SharePoint untuk download
  - **Cara 2 (Expression):**
    - Klik icon **fx**
    - Ketik: `body('Get_file_properties')?['Path']`
    - **⚠️ PENTING:** Ganti `Get_file_properties` dengan nama action Get file properties kamu
    - Klik **OK**

**💡 PENTING:** Pilih **`body/Path`** (bukan `Id`, `Name`, atau yang lain!)

**Urutan flow setelah ini:**
```
Get file properties → Compose Excel DownloadLink (BARU!) → [Respond to PowerApps]
```

---

### **ACTION BARU 6: Update Respond to PowerApps**

**Lokasi:** Action "Respond to PowerApps" yang sudah ada (UPDATE, bukan tambah baru!)

**Cara update:**
1. Scroll ke action **"Respond to PowerApps"** (yang sudah ada)
2. Klik action **"Respond to PowerApps"** untuk edit

**Configuration - Update Parameter:**

**Parameter `sharePointLink` (UPDATE):**
- Klik parameter **`sharePointLink`** yang sudah ada
- **Hapus** value yang lama (CSV link)
- **Ganti** dengan:
  - Klik field → Pilih **Dynamic content**
  - Scroll ke action **"Compose Excel DownloadLink"**
  - Pilih output dari Compose Excel DownloadLink
  - **Atau klik fx** → Ketik: `outputs('Compose_Excel_DownloadLink')`
  - **⚠️ PENTING:** Ganti `Compose_Excel_DownloadLink` dengan nama action Compose Excel DownloadLink kamu

**Parameter `fileName` (UPDATE - OPSIONAL):**
- Jika mau return Excel filename (bukan CSV):
  - Klik parameter **`fileName`** yang sudah ada
  - **Ganti** value dengan:
    - Klik icon **fx**
    - Ketik: `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')`
    - Klik **OK**
  - **Atau** biarkan CSV filename (tidak masalah, karena link Excel sudah benar)

**Parameter lain (`rowCount`, `status`):**
- **TIDAK PERLU DIUBAH** - tetap sama

**Urutan flow setelah ini:**
```
Compose Excel DownloadLink → Respond to PowerApps (UPDATED!)
```

---

## 📊 Urutan Flow Lengkap (Final)

```
1. Execute stored procedure (V2)     ← SUDAH ADA
   ↓
2. Parse JSON                         ← SUDAH ADA
   ↓
3. Create CSV table                  ← SUDAH ADA
   ↓
4. Compose (Base64)                  ← SUDAH ADA
   ↓
5. Initialize variable (varFileName) ← SUDAH ADA
   ↓
6. Create file (CSV)                 ← SUDAH ADA
   ↓
7. Create Excel Worksheet            ← TAMBAH BARU!
   ↓
8. Compose Excel Data                ← TAMBAH BARU!
   ↓
9. Add rows into a table             ← TAMBAH BARU!
   ↓
10. Get file properties (Excel)      ← TAMBAH BARU!
   ↓
11. Compose Excel DownloadLink       ← TAMBAH BARU!
   ↓
12. Compose DownloadLink             ← SUDAH ADA (CSV link - bisa dihapus atau biarkan)
   ↓
13. Respond to PowerApps             ← SUDAH ADA (UPDATE sharePointLink ke Excel!)
```

---

## ✅ Checklist Setup

### Action yang Sudah Ada (Cek saja - JANGAN DIUBAH):
- [ ] Execute stored procedure (V2) - Sudah ada dan bekerja
- [ ] Parse JSON - Sudah ada dan bekerja
- [ ] Create CSV table - Sudah ada dan bekerja
- [ ] Compose (Base64) - Sudah ada dan bekerja
- [ ] Initialize variable `varFileName` - Sudah ada dan bekerja
- [ ] Create file (CSV) - Sudah ada dan bekerja
- [ ] Compose DownloadLink - Sudah ada (CSV link)
- [ ] Respond to PowerApps - Sudah ada (perlu UPDATE sharePointLink)

### Action yang Perlu Ditambahkan:
- [ ] Create Excel Worksheet - Setelah "Create file" (CSV)
- [ ] Compose Excel Data - Setelah "Create Excel Worksheet"
- [ ] Add rows into a table - Setelah "Compose Excel Data"
- [ ] Get file properties (Excel) - Setelah "Add rows into a table"
- [ ] Compose Excel DownloadLink - Setelah "Get file properties"

### Action yang Perlu Diupdate:
- [ ] Respond to PowerApps - Update parameter `sharePointLink` ke Excel link

### Configuration yang Perlu Dicek:

**Create Excel Worksheet:**
- [ ] Location dipilih (OneDrive/SharePoint)
- [ ] Document Library dipilih (jika SharePoint)
- [ ] File = Create new file
- [ ] File name = expression dengan timestamp dan `.xlsx`
- [ ] Worksheet name = `Data`

**Compose Excel Data:**
- [ ] Rename = `Compose Excel Data`
- [ ] Input = expression `map(body('Parse_JSON'), ...)`
- [ ] Field names sesuai dengan Parse JSON kamu

**Add rows into a table:**
- [ ] Location sama dengan Create Excel Worksheet
- [ ] File = dari Create Excel Worksheet (dynamic content)
- [ ] Worksheet = `Data`
- [ ] Table = Create new table
- [ ] Address = `A1`
- [ ] Has headers = Yes
- [ ] Values = dari Compose Excel Data (dynamic content)

**Get file properties:**
- [ ] Site Address = SharePoint site yang sama
- [ ] File Identifier = dari Create Excel Worksheet (dynamic content)

**Compose Excel DownloadLink:**
- [ ] Rename = `Compose Excel DownloadLink`
- [ ] Input = Path dari Get file properties (dynamic content)

**Respond to PowerApps:**
- [ ] Parameter `sharePointLink` = dari Compose Excel DownloadLink (UPDATED!)
- [ ] Parameter `fileName` = bisa tetap CSV atau update ke Excel (opsional)
- [ ] Parameter `rowCount` = tetap sama
- [ ] Parameter `status` = tetap sama

---

## 🔍 Detail Setiap Action Baru

### 1. Create Excel Worksheet

**Lokasi:** Setelah "Create file" (CSV)

**Setup:**
- **Location:** OneDrive for Business atau SharePoint (sama dengan CSV file)
- **Document Library:** Pilih library (jika SharePoint)
- **File:** Create new file
- **File name:** `concat('RekeningKoran_Export_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.xlsx')`
- **Worksheet name:** `Data`

**Output yang penting:**
- `File` atau `File identifier` - akan dipakai di step berikutnya

---

### 2. Compose Excel Data

**Lokasi:** Setelah "Create Excel Worksheet"

**Setup:**
- **Rename:** `Compose Excel Data`
- **Input (Expression):**
```
map(body('Parse_JSON'), item => [
    item?['Tanggal Transaksi'],
    item?['Keterangan'],
    item?['Jumlah'],
    item?['DB/CR'],
    item?['Bill To Party'],
    item?['Bank Type']
])
```

**⚠️ PENTING:** 
- Ganti `Parse_JSON` dengan nama action Parse JSON kamu
- Sesuaikan field names dengan field yang ada di Parse JSON kamu
- Urutan field menentukan urutan kolom di Excel

**Output:**
- Array of arrays (siap untuk Excel)

---

### 3. Add rows into a table

**Lokasi:** Setelah "Compose Excel Data"

**Setup:**
- **Location:** Sama dengan Create Excel Worksheet
- **File:** Dari Create Excel Worksheet (dynamic content `File`)
- **Worksheet:** `Data`
- **Table:** Create new table
- **Address:** `A1`
- **Has headers:** Yes
- **Values:** Dari Compose Excel Data (dynamic content)

**Penjelasan:**
- Excel akan otomatis create table dengan headers dari baris pertama
- Data rows akan di-add setelah headers

---

### 4. Get file properties (Excel)

**Lokasi:** Setelah "Add rows into a table"

**Setup:**
- **Site Address:** SharePoint site yang sama
- **File Identifier:** Dari Create Excel Worksheet (dynamic content `File`)

**Output yang penting:**
- `Path` - akan dipakai untuk download link

---

### 5. Compose Excel DownloadLink

**Lokasi:** Setelah "Get file properties"

**Setup:**
- **Rename:** `Compose Excel DownloadLink`
- **Input:** Path dari Get file properties (dynamic content `body/Path`)

**Output:**
- Excel file path untuk download link

---

### 6. Update Respond to PowerApps

**Lokasi:** Action yang sudah ada (UPDATE!)

**Setup:**
- **Parameter `sharePointLink`:** Update ke output dari Compose Excel DownloadLink
- **Parameter `fileName`:** Bisa tetap CSV atau update ke Excel (opsional)
- **Parameter lain:** Tetap sama

---

## 🎯 Summary: Yang Perlu Dilakukan

1. **TAMBAH** Create Excel Worksheet setelah "Create file" (CSV)
2. **TAMBAH** Compose Excel Data setelah "Create Excel Worksheet"
3. **TAMBAH** Add rows into a table setelah "Compose Excel Data"
4. **TAMBAH** Get file properties setelah "Add rows into a table"
5. **TAMBAH** Compose Excel DownloadLink setelah "Get file properties"
6. **UPDATE** Respond to PowerApps - ganti `sharePointLink` ke Excel link
7. **CEK** semua action yang sudah ada (jangan diubah, hanya dicek)

---

## ⚠️ Troubleshooting

### Error: "Excel Online (Business) connector tidak ditemukan"
**Solusi:**
- Klik "New connection" saat add action
- Pilih "Excel Online (Business)"
- Login dengan akun Office 365
- Authorize permission

### Error: "File identifier tidak ditemukan"
**Solusi:**
- Pastikan di "Add rows into a table" dan "Get file properties", pilih `File` dari Create Excel Worksheet
- Jangan pilih `File name` atau field lain

### Error: "Table tidak bisa dibuat"
**Solusi:**
- Pastikan "Has headers" = Yes
- Pastikan "Address" = A1
- Pastikan Values dari Compose Excel Data adalah array of arrays

### Error: "Path tidak ditemukan"
**Solusi:**
- Pastikan di Compose Excel DownloadLink, pilih `body/Path` dari Get file properties
- Jangan pilih `Id` atau field lain

### Excel file kosong (tidak ada data)
**Solusi:**
- Cek Compose Excel Data - pastikan expression benar
- Cek Add rows into a table - pastikan Values dari Compose Excel Data
- Cek field names di Compose Excel Data sesuai dengan Parse JSON

### CSV link masih dikembalikan (bukan Excel link)
**Solusi:**
- Pastikan di Respond to PowerApps, parameter `sharePointLink` sudah di-update ke Compose Excel DownloadLink
- Jangan pakai Compose DownloadLink (yang CSV)

---

## 🧪 Testing

1. **Run flow manual** di Power Automate
2. **Check di SharePoint:**
   - ✅ CSV file ter-create (file lama)
   - ✅ Excel file ter-create (file baru dengan extension `.xlsx`)
3. **Download Excel file** → Buka di Excel
4. **Verify:**
   - ✅ File format Excel (.xlsx)
   - ✅ Data benar (sama dengan CSV)
   - ✅ Headers ada (baris pertama)
   - ✅ Bisa di-edit di Excel
5. **Check Respond to PowerApps:**
   - ✅ `sharePointLink` = Excel file path
   - ✅ `fileName` = Excel filename (jika sudah di-update)
   - ✅ `rowCount` = jumlah rows
   - ✅ `status` = success

---

## 💡 Tips

1. **File Excel dan CSV akan ter-create di folder yang sama** (jika location sama)
2. **Excel file akan punya nama berbeda** dengan CSV (karena timestamp)
3. **CSV tetap dibuat** sebagai backup (tidak dihapus)
4. **Jika mau hapus CSV step**, bisa hapus action "Create file" (CSV) dan "Compose DownloadLink" (CSV), tapi tidak direkomendasikan (biarkan sebagai backup)

---

**Ikuti urutan ini step by step, flow akan bekerja dengan benar! 🎯**

**Flow CSV tetap bekerja, Excel juga dibuat! 📊**

