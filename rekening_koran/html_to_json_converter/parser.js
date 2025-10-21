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

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = BCAStatementParser;
}

// Example usage in Node.js:
if (typeof require !== 'undefined' && require.main === module) {
    const fs = require('fs');
    
    if (process.argv.length < 3) {
        console.log('Usage: node parser.js <html_file>');
        console.log('Example: node parser.js 0053061777.html');
        process.exit(1);
    }

    const inputFile = process.argv[2];
    const htmlContent = fs.readFileSync(inputFile, 'utf8');
    
    const parser = new BCAStatementParser(htmlContent);
    const result = parser.parse();
    
    if (result.success) {
        console.log('\n✅ PARSING SUCCESS!\n');
        console.log('═══════════════════════════════════════════════════════');
        console.log('ACCOUNT INFORMATION');
        console.log('═══════════════════════════════════════════════════════');
        console.log(JSON.stringify(result.data.accountInfo, null, 2));
        
        console.log('\n═══════════════════════════════════════════════════════');
        console.log(`TRANSACTIONS (${result.data.transactions.length} found)`);
        console.log('═══════════════════════════════════════════════════════');
        console.log(JSON.stringify(result.data.transactions.slice(0, 3), null, 2));
        if (result.data.transactions.length > 3) {
            console.log(`... and ${result.data.transactions.length - 3} more transactions`);
        }
        
        console.log('\n═══════════════════════════════════════════════════════');
        console.log('SUMMARY');
        console.log('═══════════════════════════════════════════════════════');
        console.log(JSON.stringify(result.data.summary, null, 2));
        
        // Save full JSON
        const outputFile = inputFile.replace('.html', '_full.json');
        fs.writeFileSync(outputFile, JSON.stringify(result.data, null, 2));
        console.log(`\n✅ Full JSON saved to: ${outputFile}`);
        
        // Save SQL format (for stored procedure)
        const sqlOutputFile = inputFile.replace('.html', '_for_sp.json');
        fs.writeFileSync(sqlOutputFile, parser.toSQLFormat());
        console.log(`✅ SQL format saved to: ${sqlOutputFile}`);
    } else {
        console.error('❌ PARSING FAILED:', result.error);
        process.exit(1);
    }
}

