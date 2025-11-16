# 🔗 Setup SharePoint Link - Step by Step

## ✅ Cara Ambil Link dari "Create file"

Setelah action **"Create file"** di SharePoint, kita perlu ambil link untuk download.

---

## 🎯 3 Cara (Pilih yang Paling Sederhana)

### **CARA 1: Langsung dari Output "Create file" (PALING SIMPLE!)**

**Step:**
1. Setelah action **"Create file"**, tambahkan **Compose**
2. **Input:**
   ```
   body('Create_file')?['Path']
   ```
   **Atau coba:**
   ```
   body('Create_file')?['{Link}']
   ```
   **Atau:**
   ```
   body('Create_file')?['{WebUrl}']
   ```

**Cara test:**
- Run flow secara manual
- Klik output dari action "Create file"
- Lihat properties yang tersedia
- Gunakan property yang ada link-nya

---

### **CARA 2: Buat Download Link Manual**

**Step:**
1. Setelah action **"Create file"**, tambahkan **Compose**
2. **Input:**
   ```
   concat(
       'https://yourcompany.sharepoint.com/sites/YourSite/_layouts/15/download.aspx?SourceUrl=',
       encodeUriComponent(body('Create_file')?['Path']),
       '&download=1'
   )
   ```

**Note:** 
- Ganti `yourcompany.sharepoint.com` dengan SharePoint site kamu
- Ganti `YourSite` dengan nama site kamu
- Contoh: `https://greenfieldsdairy.sharepoint.com/sites/dairy/...`

---

### **CARA 3: Gunakan "Create sharing link" (Paling Reliable)**

**Step:**
1. Setelah action **"Create file"**, tambahkan:
   - **Action:** SharePoint → **Create sharing link for a file or folder**
   
2. **Configuration:**
   - **Site Address:** Same as "Create file"
   - **File Identifier:** `@{body('Create_file')?['Id']}`
   - **Link Type:** `View` (atau `Edit` jika perlu)
   - **Scope:** `Organization` (atau `Anonymous` jika perlu public)

3. Tambahkan **Compose** untuk ambil link:
   ```
   body('Create_sharing_link_for_a_file_or_folder')?['link']?['webUrl']
   ```

**Note:** 
- Nama action bisa berbeda tergantung Power Automate version
- Check output untuk property yang tepat (bisa `link.webUrl` atau `{Link}`)

---

## 🧪 Testing

### Test Output "Create file"

1. Run flow secara manual
2. Klik output dari action "Create file"
3. Lihat semua properties yang tersedia:
   - `Path` → biasanya ada
   - `{Link}` → mungkin ada
   - `{WebUrl}` → mungkin ada
   - `Id` → pasti ada (untuk Create sharing link)

### Test Link

1. Copy link dari Compose output
2. Paste di browser baru
3. Check apakah file bisa di-download langsung

---

## ✅ Checklist

- [ ] Action "Create file" sudah dibuat
- [ ] Test output "Create file" untuk lihat properties
- [ ] Pilih cara yang paling sederhana (CARA 1 dulu!)
- [ ] Compose sudah dibuat dengan link yang benar
- [ ] Test link di browser
- [ ] Link bisa di-download langsung

---

## 💡 Tips

1. **CARA 1 paling simple** - coba dulu ini!
2. Jika CARA 1 tidak bekerja, coba CARA 3 (Create sharing link)
3. Pastikan link format benar: harus bisa diakses di browser
4. Test link sebelum return ke Power Apps

---

**Pilih CARA 1 dulu, paling simple! 🎯**

