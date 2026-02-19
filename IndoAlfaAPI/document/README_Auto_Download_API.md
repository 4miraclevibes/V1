# Auto Download by API JSON - AlfaMart B2B

Ringkasan dokumentasi API Auto Download untuk integrasi B2B AlfaMart.

---

## 1. Informasi Umum

| Item | Nilai |
|------|-------|
| **Base URL** | `https://b2b-ap.alfamart.co.id/auto-download` |
| **Endpoint** | `POST /auto-download` (1 endpoint, response berbeda sesuai parameter) |
| **Format** | JSON |

---

## 2. Autentikasi (Checksum)

API memakai **checksum SHA256** untuk autentikasi. Checksum wajib disertakan di body setiap request.

### Formula Checksum

```
checksum = SHA256(method#key#opt#day#jenis_data#datetime)
```

- **method**: `B2B-AUTO-DOWNLOAD` (konstanta)
- **key**: Kode unik user B2B
- **opt**: `JSON`
- **day**: Periode tanggal (contoh: `1`)
- **jenis_data**: `PO` | `POBKL` | `LPB` | `LPBBKL`
- **datetime**: Format `YYYY-MM-DD HH:mm:ss` (waktu request)

### Contoh

```
Input:  B2B-AUTO-DOWNLOAD#xxxxxxxxxxxx#JSON#1#POBKL#2024-09-03 15:46:42
Output: f2a09202dc0f2c1ff74f384c186fb99e435b9de32fd8f1667ece05f5eaf60838
```

### Error Autentikasi

- Checksum salah/tidak ada → **Unauthorized**
- Header tidak lengkap → **Unauthorized**

---

## 3. Request Body

### Parameter (raw JSON)

| Parameter | Wajib | Deskripsi |
|-----------|-------|-----------|
| `key` | ✅ | Kode unik user B2B (saat pendaftaran) |
| `opt` | ✅ | Jenis output: `JSON` |
| `day` | ✅ | Periode tanggal data (misal: `1` = 1 hari) |
| `jenis_data` | ✅ (jika opt=JSON) | `PO` \| `POBKL` \| `LPB` \| `LPBBKL` |
| `datetime` | ✅ | Waktu request, format `YYYY-MM-DD HH:mm:ss` |
| `checksum` | ✅ | SHA256 sesuai formula di atas |

### Contoh Body

```json
{
  "key": "********",
  "opt": "JSON",
  "day": "1",
  "jenis_data": "PO",
  "datetime": "2024-09-03 15:46:42",
  "checksum": "f2a09202dc0f2c1ff74f384c186fb99e435b9de32fd8f1667ece05f5eaf60838"
}
```

---

## 4. Jenis Data (jenis_data)

| Nilai | Keterangan |
|-------|------------|
| `PO` | Purchase Order (standar) |
| `POBKL` | Purchase Order BKL (BKL Nestle dll) |
| `LPB` | Laporan Penerimaan Barang |
| `LPBBKL` | LPB BKL |

---

## 5. Response Structure

### 200 OK – Ada Data (PO/LPB)

```json
{
  "status_code": 200,
  "status": "T",
  "message": "Success",
  "result": [
    {
      "header": {
        "rec_tag": "POHDR",
        "po_no": "XXXPOI24000XXX",
        "po_date": "20240903",
        "exp_date": "20240903",
        "proc_date": "20240903",
        "dlv_code": "XXXX",
        "dlv_name": "DC. SAT XXXXX",
        "dlv_town": "SEMARANG",
        "sup_code": "XXXX.S.8888.1.X",
        "sup_name": "SENTRAL SUPXXX",
        "sup_add": "JL.MH.XXXXX NO.9",
        "sup_phone": "021-000000",
        "sup_fax": "021-000000"
      },
      "detail": [
        {
          "rec_tag": "LIN",
          "desc": "PLU K XXXXXXXXXXX",
          "qty_crt": 0.0,
          "qty_pcs": 20.0,
          "plu": 8932952,
          "barcode": "89329528",
          "price": 1.0,
          "uom": "CDU",
          "cnv": "1",
          "disc_a": "0.00%",
          "remark": "",
          "net": 1.0,
          "ppnbm": 0.0,
          "total": 20.0,
          "plu_b": 0.0,
          "qty_b": 0.0,
          "price_b": 0.0,
          "disc_b": "0.00%"
        }
      ],
      "trl": {
        "rec_tag": "TRL",
        "tot_purchase": 20.0,
        "tot_disc": 0.0,
        "tot_aft_disc": 0.0,
        "tot_ppn": 0.0,
        "tot_aft_ppn": 20.0,
        "total_fpp": 20.0,
        "amount_in_words": "DUAPULUH",
        "contact": "HPP",
        "supp_accno": "000.000.000",
        "supp_accnm": "SUMBER ALFARIA TRIJAYA PT",
        "supp_bank": "BCA",
        "barcode_in": "0"
      }
    }
  ]
}
```

### POBKL / LPBBKL – Kolom Tambahan di header

- `kd_toko`: Kode toko  
- `nama_toko`: Nama toko  

### 204 Success, No Data

```json
{
  "status_code": 204,
  "status": "T",
  "message": "Success, No Data",
  "result": []
}
```

### 400 Error

| Kondisi | Message |
|---------|---------|
| Parameter tidak lengkap (key, opt, day, datetime, checksum) | `"Parameter tidak lengkap"` |
| `jenis_data` kosong saat `opt` = JSON | `"Parameter Jenis Data tidak ditemukan"` |

---

## 6. Mapping Data

- **header**: Info PO/LPB (nomor, tanggal, supplier, delivery)
- **detail**: Array item (PLU, qty, price, disc, total)
- **trl** (trailer): Total pembelian, PPN, amount in words, rekening supplier

---

## 7. Poin Penting

1. **Checksum wajib** – Tanpa checksum atau salah → Unauthorized  
2. **`datetime` di body** – Harus sama dengan yang dipakai saat generate checksum  
3. **`jenis_data`** – Wajib jika `opt` = `JSON`  
4. **`day`** – Menentukan periode data yang diambil  
5. **Satu endpoint** – Semua jenis data lewat `POST /auto-download`  
6. **Format tanggal di response** – `YYYYMMDD` (misal: `20240903`)

---

## 8. Referensi

- Dokumen asli: `Auto Download by API JSON.pdf`
- Mapping detail: `auto-download-po` (sesuai dokumen)
