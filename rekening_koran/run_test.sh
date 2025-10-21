#!/bin/bash

# Script untuk menjalankan BTP Pattern Testing Tool
# Usage: ./run_test.sh

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║           BTP PATTERN MATCHING - QUICK START                     ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Working directory: $SCRIPT_DIR"
echo ""
echo "📝 Tips sebelum mulai:"
echo "   • Buka file test_samples.txt untuk contoh deskripsi testing"
echo "   • Pilih master data file yang ingin digunakan (70% atau 80%)"
echo "   • Gunakan option 5 untuk lihat statistik master data"
echo ""
echo "🚀 Starting program..."
echo ""

./test_btp_pattern

echo ""
echo "👋 Testing selesai!"
echo ""

