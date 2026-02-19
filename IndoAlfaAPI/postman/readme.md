# Postman - Alfamart B2B Auto Download API

Folder ini berisi collection Postman untuk **API Auto Download B2B Alfamart**.

## File

| File | Keterangan |
|------|------------|
| `Alfamart_B2B_Auto_Download.postman_collection.json` | Collection Postman siap import; credential dan checksum sudah dikonfigurasi. |

## Cara import

1. Buka **Postman**
2. **Import** → pilih file `Alfamart_B2B_Auto_Download.postman_collection.json`
3. Collection akan muncul di sidebar

## Isi collection

- **Alfamart Fresh (GI)** – Key: `YJWWACKN2HRMOUZR`  
  Request: PO, POBKL, LPB, LPBBKL
- **Alfamart UHT** – Key: `MRXVD6IAGTCQQ36N`  
  Request: PO, POBKL, LPB, LPBBKL

Checksum dihitung otomatis di Pre-request Script; tidak perlu isi manual. Variabel `day` (default: `1`) dapat diubah di collection variables untuk mengatur periode data.

## Dokumentasi API

Lihat `../document/README_Auto_Download_API.md` untuk detail endpoint, parameter, dan response.
