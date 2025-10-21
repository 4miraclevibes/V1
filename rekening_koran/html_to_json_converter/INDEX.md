# 📚 BCA Statement Converter - Documentation Hub

Selamat datang! Ini adalah pusat dokumentasi untuk BCA Statement HTML to JSON Converter.

---

## 🎯 Apa Ini?

Tool untuk **mengkonversi file HTML rekening koran BCA** menjadi **JSON format** yang bisa langsung digunakan dengan:
- ✅ Power Apps
- ✅ SQL Server Stored Procedures
- ✅ Power Automate Flow
- ✅ Azure Functions

---

## 🚀 Mulai Dari Mana?

### Baru Pertama Kali?
👉 **[QUICK_START.md](QUICK_START.md)** - Panduan 5 menit! ⚡

### Mau Pakai Web Interface?
👉 **Buka `converter.html`** - Drag & drop, done! 🎨

### Butuh Detail Lengkap?
👉 **[README.md](README.md)** - Dokumentasi komprehensif 📖

### Mau Integrasikan dengan Power Apps?
👉 **[POWER_APPS_GUIDE.md](POWER_APPS_GUIDE.md)** - Step-by-step integration 📱

### Mau Test & Demo?
👉 **[TEST_DEMO.md](TEST_DEMO.md)** - Test scenarios & examples 🧪

---

## 📋 Table of Contents

### 1️⃣ Getting Started

| Document | Description | Time |
|----------|-------------|------|
| **[QUICK_START.md](QUICK_START.md)** | Panduan super cepat untuk mulai | 5 min ⚡ |
| **[README.md](README.md)** | Dokumentasi lengkap semua fitur | 15 min 📖 |

### 2️⃣ Core Documentation

| Document | Description | Audience |
|----------|-------------|----------|
| **[parser.js](parser.js)** | Core parser logic (JavaScript) | Developers 💻 |
| **[converter.html](converter.html)** | Web interface | Everyone 🎨 |

### 3️⃣ Integration Guides

| Document | Description | Platform |
|----------|-------------|----------|
| **[POWER_APPS_GUIDE.md](POWER_APPS_GUIDE.md)** | Power Apps integration | Power Platform 📱 |
| **[TEST_DEMO.md](TEST_DEMO.md)** | Test & demo scenarios | SQL Server 🧪 |

### 4️⃣ Examples

| File | Description | Usage |
|------|-------------|-------|
| `examples/0053061777.html` | Sample BCA statement (43 trans) | Test input 📄 |
| `examples/0053061777_full.json` | Full JSON output | Reference ✅ |
| `examples/0053061777_for_sp.json` | SQL SP format | SQL Server 🔄 |

---

## 🎯 Quick Navigation by Use Case

### Use Case 1: Manual Conversion
**Goal:** Convert 1 HTML file → Download JSON

**Steps:**
1. Open `converter.html`
2. Upload HTML file
3. Download JSON
4. Done!

**Time:** 2 minutes  
**Doc:** [QUICK_START.md](QUICK_START.md)

---

### Use Case 2: Batch Processing
**Goal:** Convert multiple HTML files automatically

**Steps:**
1. Install Node.js
2. Run: `node parser.js file1.html`
3. Run: `node parser.js file2.html`
4. Or use shell script for batch

**Time:** 30 seconds per file  
**Doc:** [README.md](README.md) → "Command Line" section

---

### Use Case 3: SQL Server Integration
**Goal:** HTML → JSON → Stored Procedure → BTP Results

**Steps:**
1. Convert HTML to JSON (use converter.html)
2. Copy JSON content
3. Paste to SQL query with SP
4. Execute & get results

**Time:** 3 minutes  
**Doc:** [TEST_DEMO.md](TEST_DEMO.md) → "Test dengan Stored Procedure"

---

### Use Case 4: Power Apps Integration
**Goal:** Full automation - Upload → Process → Display

**Steps:**
1. Deploy Azure Function (parser.js)
2. Create Power Automate Flow
3. Build Power Apps UI
4. Test end-to-end

**Time:** 2-3 hours (one-time setup)  
**Doc:** [POWER_APPS_GUIDE.md](POWER_APPS_GUIDE.md)

---

## 📊 Feature Matrix

| Feature | Web Interface | Command Line | Power Apps |
|---------|---------------|--------------|------------|
| Parse HTML | ✅ | ✅ | ✅ |
| Extract account info | ✅ | ✅ | ✅ |
| Extract transactions | ✅ | ✅ | ✅ |
| Calculate summary | ✅ | ✅ | ✅ |
| Download JSON | ✅ | ✅ | ✅ |
| Copy to clipboard | ✅ | ❌ | N/A |
| Batch processing | ❌ | ✅ | ✅ |
| Auto-upload | ❌ | ❌ | ✅ |
| Real-time preview | ✅ | ❌ | ✅ |
| SQL integration | Manual | Manual | Automatic |

---

## 🔗 Related Documentation

### Stored Procedures
- [../stored_procedures/README.md](../stored_procedures/README.md) - Main SP documentation
- [../stored_procedures/TRSF/](../stored_procedures/TRSF/) - TRSF stored procedures
- [../stored_procedures/BIFAST/](../stored_procedures/BIFAST/) - BI-FAST stored procedures
- [../stored_procedures/MANDIRI/](../stored_procedures/MANDIRI/) - MANDIRI stored procedures

### Pattern Generators
- [../pattern_documentation/documentation.txt](../pattern_documentation/documentation.txt) - All banks patterns

---

## 🎓 Learning Path

### For Non-Technical Users 👤
1. Read: [QUICK_START.md](QUICK_START.md)
2. Try: Open `converter.html`, upload sample file
3. Learn: [README.md](README.md) - "Web Interface" section
4. Practice: Convert your own HTML files

### For Developers 💻
1. Read: [README.md](README.md) - Full doc
2. Study: `parser.js` source code
3. Test: `node parser.js examples/0053061777.html`
4. Extend: Customize for other banks (if needed)

### For Power Platform Developers 📱
1. Read: [POWER_APPS_GUIDE.md](POWER_APPS_GUIDE.md)
2. Deploy: Azure Function with parser.js
3. Create: Power Automate Flow
4. Build: Power Apps UI
5. Test: End-to-end integration

### For Database Admins 🗄️
1. Read: [TEST_DEMO.md](TEST_DEMO.md)
2. Study: Stored procedures in `../stored_procedures/`
3. Test: SQL queries with sample JSON
4. Deploy: Create SPs in your database

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        INPUT SOURCES                            │
│                                                                 │
│  [BCA HTML File] → Manual Upload / SharePoint / File System    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CONVERSION LAYER                           │
│                                                                 │
│  Option A: Web Interface (converter.html)                      │
│  Option B: Command Line (parser.js)                            │
│  Option C: Azure Function (parser.js)                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       JSON OUTPUT                               │
│                                                                 │
│  • Full JSON (all data)                                         │
│  • SQL SP JSON (TransactionID + Description)                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     INTEGRATION LAYER                           │
│                                                                 │
│  [SQL Server] → Execute Stored Procedures                      │
│  [Power Apps] → Display in Gallery                             │
│  [Excel] → Export for analysis                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BTP MATCHING RESULTS                        │
│                                                                 │
│  • Customer Name extracted                                      │
│  • BTP code matched                                             │
│  • Confidence score calculated                                  │
│  • Multiple options flagged (BEST/LATEST)                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📞 Support & Resources

### Documentation
- ✅ All docs in this folder
- ✅ Stored procedures docs in `../stored_procedures/`
- ✅ Examples in `examples/` folder

### Testing
- ✅ Sample HTML: `examples/0053061777.html`
- ✅ Sample JSON: `examples/0053061777_for_sp.json`
- ✅ Test scenarios: [TEST_DEMO.md](TEST_DEMO.md)

### Troubleshooting
- Check [README.md](README.md) → "Troubleshooting" section
- Check [TEST_DEMO.md](TEST_DEMO.md) → "Known Issues"
- Review error messages in console

---

## 🎉 Quick Reference

### Files to Open First
1. **`converter.html`** - Main web interface
2. **`QUICK_START.md`** - 5-minute guide
3. **`examples/0053061777.html`** - Sample data

### Common Commands
```bash
# Test parser
node parser.js examples/0053061777.html

# Open web interface
open converter.html

# View documentation
cat QUICK_START.md
```

### Common SQL Queries
```sql
-- TRSF
EXEC SP_TRSF_FindBTP_Batch @TransactionsJSON = @JSON;

-- BI-FAST
EXEC SP_BIFAST_FindBTP_Batch @TransactionsJSON = @JSON;

-- MANDIRI
EXEC SP_MANDIRI_FindBTP_Batch @TransactionsJSON = @JSON;
```

---

## 📊 Status

| Component | Status | Tested |
|-----------|--------|--------|
| HTML Parser | ✅ Production | ✅ Yes |
| Web Interface | ✅ Production | ✅ Yes |
| Command Line | ✅ Production | ✅ Yes |
| SQL Integration | ✅ Production | ✅ Yes |
| Power Apps Guide | ✅ Ready | ⏳ Pending |
| Azure Function | 📝 Template | ⏳ Pending |

---

## 🚀 Next Steps

1. **Start Now:** Open [QUICK_START.md](QUICK_START.md)
2. **Try Demo:** Open `converter.html`, upload `examples/0053061777.html`
3. **Read Full Doc:** [README.md](README.md) for all details
4. **Integrate:** Follow [POWER_APPS_GUIDE.md](POWER_APPS_GUIDE.md) for automation

---

**Version:** 1.0.0  
**Last Updated:** October 21, 2025  
**Status:** ✅ Production Ready

**Happy Converting! 🎉**

