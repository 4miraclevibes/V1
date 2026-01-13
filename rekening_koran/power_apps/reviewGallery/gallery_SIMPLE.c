// =====================================================
// Format Paling Sederhana - Hanya Memanggil Data
// =====================================================
// 
// ⚠️ PENTING: SP HARUS ditambahkan sebagai Data Source dulu!
// 1. Power Apps Studio → Data → Add data source
// 2. Pilih "SQL Server" atau "SQL Database"  
// 3. Pilih stored procedure: POWERAPPS3.dboSPBTPREVIEWFilterComplete
// 4. Setelah ditambahkan, gunakan format di bawah
// =====================================================

// =====================================================
// OPSI 1: Langsung nama SP (Setelah ditambahkan sebagai Data Source) ⭐
// =====================================================
// Items Property Gallery:
POWERAPPS3.dboSPBTPREVIEWFilterComplete

// Catatan: 
// - SP akan menggunakan default parameter
// - Untuk filter, gunakan variable + Refresh() di tombol


// =====================================================
// OPSI 2: Dengan Variable (Jika perlu parameter)
// =====================================================
// 
// Step 1: Di OnStart atau OnVisible screen, set variable:
// Set(varSPResult, POWERAPPS3.dboSPBTPREVIEWFilterComplete({}));
//
// Step 2: Items Property Gallery:
varSPResult

// Catatan: Variable harus di-set dulu sebelum gallery load


// =====================================================
// OPSI 3: Melalui Collection (Paling Fleksibel)
// =====================================================
//
// Step 1: Di OnStart atau OnVisible, atau di tombol:
// Clear(colBTPReview);
// Collect(colBTPReview, POWERAPPS3.dboSPBTPREVIEWFilterComplete({}));
//
// Step 2: Items Property Gallery:
colBTPReview

