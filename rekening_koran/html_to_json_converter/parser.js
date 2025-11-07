/**
 * BCA HTML to JSON Converter
 * Converts BCA bank statement HTML to JSON format
 * Compatible with Power Apps and SQL Server Stored Procedures
 */

class BCAStatementParser {
    constructor(htmlContent) {
        this.htmlContent = htmlContent;
        this.result = {
            accountInfo: {},
            transactions: [],
            summary: {}
        };
    }

    /**
     * Main parsing function
     */
    parse() {
        try {
            // Parse account information
            this.parseAccountInfo();
            
            // Parse transactions
            this.parseTransactions();
            
            // Parse summary
            this.parseSummary();
            
            return {
                success: true,
                data: this.result
            };
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Parse account information (No. Rekening, Nama, Periode, Mata Uang)
     */
    parseAccountInfo() {
        // Extract account number
        const accountNumberMatch = this.htmlContent.match(/<B>No\. rekening<\/B>.*?<B>(\d+)<\/B>/i);
        if (accountNumberMatch) {
            this.result.accountInfo.accountNumber = accountNumberMatch[1].trim();
        }

        // Extract account name
        const accountNameMatch = this.htmlContent.match(/<B>Nama<\/B>.*?<B>([^<]+)<\/B>/i);
        if (accountNameMatch) {
            this.result.accountInfo.accountName = accountNameMatch[1].trim();
        }

        // Extract period
        const periodMatch = this.htmlContent.match(/<B>Periode<\/B>.*?<B>([^<]+)<\/B>/i);
        if (periodMatch) {
            this.result.accountInfo.period = periodMatch[1].trim();
        }

        // Extract currency
        const currencyMatch = this.htmlContent.match(/<B>Kode Mata Uang<\/B>.*?<B>([^<]+)<\/B>/i);
        if (currencyMatch) {
            this.result.accountInfo.currency = currencyMatch[1].trim();
        }
    }

    /**
     * Parse transaction table
     */
    parseTransactions() {
        // Find transaction table (the one with Tanggal Transaksi header)
        const tableMatch = this.htmlContent.match(
            /<TABLE[^>]*>.*?Tanggal Transaksi.*?<\/TABLE>/is
        );

        if (!tableMatch) {
            console.warn('Transaction table not found');
            return;
        }

        const tableContent = tableMatch[0];
        
        // Extract all transaction rows
        // Pattern: <TR><TD ...>DATE</TD><TD ...>DESCRIPTION</TD><TD ...>BRANCH</TD><TD ...>AMOUNT</TD><TD ...>BALANCE</TD></TR>
        const rowRegex = /<TR><TD[^>]*><FONT[^>]*>([^<]+)<\/FONT><\/TD><TD[^>]*><FONT[^>]*>(.*?)<\/FONT><\/TD><TD[^>]*><FONT[^>]*>([^<]+)<\/FONT><\/TD><TD[^>]*><FONT[^>]*>([^<]+)<\/FONT><\/TD><TD[^>]*><FONT[^>]*>([^<]+)<\/FONT><\/TD><\/TR>/gi;
        
        let match;
        let transactionId = 1;
        
        while ((match = rowRegex.exec(tableContent)) !== null) {
            const [, date, description, branch, amount, balance] = match;
            
            // Skip header row
            if (date.includes('Tanggal') || description.includes('Keterangan')) {
                continue;
            }

            // Clean up description (remove extra whitespace)
            const cleanDescription = description.replace(/\s+/g, ' ').trim();

            // Parse amount and determine type (CR/DB)
            const amountStr = amount.trim();
            const isCredit = amountStr.includes('CR');
            const isDebit = amountStr.includes('DB');
            const cleanAmount = amountStr
                .replace(/CR|DB/g, '')
                .replace(/,/g, '')
                .trim();

            // Parse balance
            const cleanBalance = balance
                .replace(/,/g, '')
                .trim();

            const transaction = {
                TransactionID: transactionId++,
                TransactionDate: date.trim(),
                Description: cleanDescription,
                Branch: branch.trim(),
                Amount: parseFloat(cleanAmount) || 0,
                AmountFormatted: amountStr,
                TransactionType: isCredit ? 'CR' : (isDebit ? 'DB' : 'UNKNOWN'),
                Balance: parseFloat(cleanBalance) || 0,
                BalanceFormatted: balance.trim()
            };

            this.result.transactions.push(transaction);
        }
    }

    /**
     * Parse summary table (Saldo Awal, Mutasi, Saldo Akhir)
     */
    parseSummary() {
        // Extract Saldo Awal
        const saldoAwalMatch = this.htmlContent.match(/<B>Saldo Awal<\/B>.*?<B>([0-9,.]+)<\/B>/i);
        if (saldoAwalMatch) {
            const value = saldoAwalMatch[1].replace(/,/g, '');
            this.result.summary.saldoAwal = parseFloat(value) || 0;
            this.result.summary.saldoAwalFormatted = saldoAwalMatch[1];
        }

        // Extract Mutasi Debet
        const mutasiDebetMatch = this.htmlContent.match(/<B>Mutasi Debet<\/B>.*?<B>([0-9,.]+)<\/B>/i);
        if (mutasiDebetMatch) {
            const value = mutasiDebetMatch[1].replace(/,/g, '');
            this.result.summary.mutasiDebet = parseFloat(value) || 0;
            this.result.summary.mutasiDebetFormatted = mutasiDebetMatch[1];
        }

        // Extract Mutasi Kredit
        const mutasiKreditMatch = this.htmlContent.match(/<B>Mutasi Kredit<\/B>.*?<B>([0-9,.]+)<\/B>/i);
        if (mutasiKreditMatch) {
            const value = mutasiKreditMatch[1].replace(/,/g, '');
            this.result.summary.mutasiKredit = parseFloat(value) || 0;
            this.result.summary.mutasiKreditFormatted = mutasiKreditMatch[1];
        }

        // Extract Saldo Akhir
        const saldoAkhirMatch = this.htmlContent.match(/<B>Saldo Akhir<\/B>.*?<B>([0-9,.]+)<\/B>/i);
        if (saldoAkhirMatch) {
            const value = saldoAkhirMatch[1].replace(/,/g, '');
            this.result.summary.saldoAkhir = parseFloat(value) || 0;
            this.result.summary.saldoAkhirFormatted = saldoAkhirMatch[1];
        }

        // Count transactions
        const countMatch = this.htmlContent.match(/<B>Mutasi Kredit<\/B>.*?<B>&nbsp;(\d+)<\/B>/i);
        if (countMatch) {
            this.result.summary.totalTransactions = parseInt(countMatch[1]) || 0;
        }
    }

    /**
     * Get transactions in format for SQL Stored Procedure
     * Returns JSON string compatible with OPENJSON in SQL Server
     */
    getTransactionsForStoredProcedure() {
        return this.result.transactions.map(t => ({
            TransactionID: t.TransactionID,
            TransactionDate: t.TransactionDate,
            Description: t.Description
        }));
    }

    /**
     * Export to SQL Server compatible JSON format
     */
    toSQLFormat() {
        return JSON.stringify(this.getTransactionsForStoredProcedure(), null, 2);
    }
}

/**
 * RPT (TXT) Statement Parser
 * Mengkonversi laporan RPT berbasis teks (mis. GREENFIELD) ke JSON
 */
class RPTStatementParser {
    constructor(textContent) {
        this.textContent = textContent;
        this.lines = textContent.split(/\r?\n/);
        this.result = {
            headerInfo: {},
            transactions: [],
            summary: {}
        };
    }

    parse() {
        try {
            this.parseHeader();
            this.parseTransactions();
            this.parseSummary();

            return {
                success: true,
                data: this.result
            };
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }

    parseHeader() {
        for (const line of this.lines) {
            if (!line) continue;

            const namaPerusahaanMatch = line.match(/NAMA PERUSAHAAN\s*:\s*(.+)$/i);
            if (namaPerusahaanMatch) {
                this.result.headerInfo.companyName = namaPerusahaanMatch[1].trim();
            }

            const tanggalMatch = line.match(/TANGGAL\s*:\s*([0-9/]+)/i);
            if (tanggalMatch) {
                this.result.headerInfo.reportDate = tanggalMatch[1].trim();
            }

            const laporanMatch = line.match(/LAPORAN\s*:\s*([^\s]+)\s+/i);
            if (laporanMatch) {
                this.result.headerInfo.reportCode = laporanMatch[1].trim();
            }

            const cabangMatch = line.match(/CABANG\s*:\s*(.+?)\s+HALAMAN/i);
            if (cabangMatch) {
                this.result.headerInfo.branch = cabangMatch[1].trim();
            }

            const halamanMatch = line.match(/HALAMAN\s*:\s*(\d+)/i);
            if (halamanMatch) {
                this.result.headerInfo.page = parseInt(halamanMatch[1], 10);
            }

            const frekwensiMatch = line.match(/FREKWENSI\s*:\s*(.+)$/i);
            if (frekwensiMatch) {
                this.result.headerInfo.frequency = frekwensiMatch[1].trim();
            }
        }
    }

    parseTransactions() {
        const transactionLines = this.lines.filter(line => {
            if (!line) return false;
            const trimmed = line.trim();
            if (!trimmed) return false;
            return /^\d+\s+\d{6,}/.test(trimmed);
        });

        transactionLines.forEach(line => {
            const trimmed = line.trim();
            const tokens = trimmed.split(/\s+/);
            if (tokens.length < 6) {
                return;
            }

            const idMatch = trimmed.match(/^(\d+)/);
            if (!idMatch) {
                return;
            }
            const sequence = parseInt(idMatch[1], 10);

            const btp = tokens[1];
            const idrIndex = tokens.indexOf('IDR');
            if (idrIndex === -1) {
                return;
            }

            const customerNameTokens = tokens.slice(2, idrIndex);
            const customerName = customerNameTokens.join(' ').replace(/\s+/g, ' ').trim();

            const amountRaw = tokens[idrIndex + 1] || '0';
            const amountValue = parseFloat(amountRaw.replace(/,/g, '')) || 0;

            const transactionDate = tokens[idrIndex + 2] || '';
            const transactionTime = tokens[idrIndex + 3] || '';
            const location = tokens[idrIndex + 4] || '';

            let keterangan1 = '';
            let keterangan2 = '';

            if (location) {
                const locationIndex = line.indexOf(location, line.indexOf(transactionTime));
                if (locationIndex !== -1) {
                    const remainder = line.slice(locationIndex + location.length).trim();
                    if (remainder) {
                        const parts = remainder.split(/\s{2,}/).map(part => part.trim()).filter(Boolean);
                        if (parts.length > 0) {
                            keterangan1 = parts[0];
                        }
                        if (parts.length > 1) {
                            keterangan2 = parts[1];
                        }
                    }
                }
            }

            this.result.transactions.push({
                transactionId: sequence,
                btp: btp,
                customerName: customerName,
                amount: amountValue,
                amountFormatted: amountRaw,
                transactionDate: transactionDate,
                transactionTime: transactionTime,
                location: location,
                keterangan1: keterangan1 || '-',
                keterangan2: keterangan2 || '-',
                description: `RPT: ${customerName || '-' } | ${keterangan1 || '-' } | ${keterangan2 || '-' }`,
                rawLine: line
            });
        });
    }

    parseSummary() {
        const subTotalTransaksiMatch = this.lines.find(line => line.includes('SUB TOTAL TRANSAKSI'));
        if (subTotalTransaksiMatch) {
            const jumlahMatch = subTotalTransaksiMatch.match(/SUB TOTAL TRANSAKSI\s+IDR\s*:\s*(\d+)/i);
            if (jumlahMatch) {
                this.result.summary.subTotalTransactions = parseInt(jumlahMatch[1], 10);
            }
        }

        const subTotalNilaiMatch = this.lines.find(line => line.includes('SUB TOTAL NILAI TRANSAKSI'));
        if (subTotalNilaiMatch) {
            const nilaiMatch = subTotalNilaiMatch.match(/IDR\s+([0-9,.]+)/i);
            if (nilaiMatch) {
                this.result.summary.subTotalAmount = this.parseAmount(nilaiMatch[1]);
                this.result.summary.subTotalAmountFormatted = nilaiMatch[1].trim();
            }
        }

        const totalTransaksiMatch = this.lines.find(line => line.includes('TOTAL TRANSAKSI'));
        if (totalTransaksiMatch) {
            const jumlahMatch = totalTransaksiMatch.match(/TOTAL TRANSAKSI\s+IDR\s*:\s*(\d+)/i);
            if (jumlahMatch) {
                this.result.summary.totalTransactions = parseInt(jumlahMatch[1], 10);
            }
        }

        const totalNilaiMatch = this.lines.find(line => line.includes('TOTAL NILAI TRANSAKSI'));
        if (totalNilaiMatch) {
            const nilaiMatch = totalNilaiMatch.match(/IDR\s+([0-9,.]+)/i);
            if (nilaiMatch) {
                this.result.summary.totalAmount = this.parseAmount(nilaiMatch[1]);
                this.result.summary.totalAmountFormatted = nilaiMatch[1].trim();
            }
        }

        if (typeof this.result.summary.totalTransactions === 'undefined') {
            this.result.summary.totalTransactions = this.result.transactions.length;
        }
    }

    parseAmount(value) {
        if (!value) return 0;
        const sanitized = value.replace(/,/g, '').trim();
        return parseFloat(sanitized) || 0;
    }

    getTransactionsForStoredProcedure() {
        return this.result.transactions.map(t => ({
            transaction_id: t.transactionId,
            btp: t.btp,
            customer_name: t.customerName,
            transaction_date: t.transactionDate,
            transaction_time: t.transactionTime,
            amount: t.amount,
            location: t.location,
            keterangan1: t.keterangan1,
            keterangan2: t.keterangan2,
            description: t.description,
            bank_type: 'VA'
        }));
    }

    toSQLFormat() {
        return JSON.stringify(this.getTransactionsForStoredProcedure(), null, 2);
    }
}

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        BCAStatementParser,
        RPTStatementParser
    };
}

// Example usage in Node.js:
if (typeof require !== 'undefined' && require.main === module) {
    const fs = require('fs');
    
    if (process.argv.length < 4) {
        console.log('Usage: node parser.js <mode> <input_file>');
        console.log('Modes: html | rpt');
        console.log('Example: node parser.js html 0053061777.html');
        console.log('         node parser.js rpt rpt_example.txt');
        process.exit(1);
    }

    const mode = process.argv[2];
    const inputFile = process.argv[3];
    const content = fs.readFileSync(inputFile, 'utf8');
    
    const parser = mode === 'rpt'
        ? new RPTStatementParser(content)
        : new BCAStatementParser(content);

    const result = parser.parse();
    
    if (result.success) {
        console.log('\n✅ PARSING SUCCESS!\n');
        console.log('═══════════════════════════════════════════════════════');
        console.log('RESULT');
        console.log('═══════════════════════════════════════════════════════');
        console.log(JSON.stringify(result.data, null, 2));

        const baseName = inputFile.replace(/\.[^.]+$/, '');
        const fullOutput = `${baseName}_${mode}_full.json`;
        fs.writeFileSync(fullOutput, JSON.stringify(result.data, null, 2));
        console.log(`\n✅ Full JSON saved to: ${fullOutput}`);
        
        const sqlOutput = `${baseName}_${mode}_for_sp.json`;
        fs.writeFileSync(sqlOutput, parser.toSQLFormat());
        console.log(`✅ SQL format saved to: ${sqlOutput}`);
    } else {
        console.error('❌ PARSING FAILED:', result.error);
        process.exit(1);
    }
}

