#!/bin/bash

# Quick test script untuk Pattern Generator v2

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║        PATTERN GENERATOR v2 - QUICK TEST                         ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Compile test tool
echo "🔨 Compiling test_btp_pattern.c..."
gcc -o test_btp_pattern test_btp_pattern.c

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed!"
    exit 1
fi

echo "✅ Compilation successful!"
echo ""

# Run test dengan 50k samples
echo "🎯 Running test dengan 50,000 samples..."
echo ""

echo "8
0" | ./test_btp_pattern

echo ""
echo "✅ Test complete!"
echo ""

