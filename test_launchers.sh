#!/bin/bash
# Test script for the launcher scripts
# Run: ./test_launchers.sh

set -e
cd "$(dirname "$0")"

echo "=== Testing BAP Utils Launchers ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    exit 1
}

# Clean up any existing venv to test fresh setup
if [[ -d ".venv" ]]; then
    echo "Removing existing .venv for clean test..."
    rm -rf .venv
fi

# Create test PDF using fpdf2 (install in temp venv for test setup)
echo "Creating test PDF..."
python3 -m pip install -q fpdf2 2>/dev/null || pip install -q fpdf2 2>/dev/null

python3 - << 'EOF'
from fpdf import FPDF
from fpdf.enums import XPos, YPos
import os

os.makedirs("test_data", exist_ok=True)

pdf = FPDF()
pdf.add_page()
pdf.set_font("Helvetica", size=12)

pdf.cell(0, 10, "Test Patent Document", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 10, "This document references SEQ ID NO: 1798", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 10, "See also SEQ ID NOS: 1475-1826 for related sequences.", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 10, "Additional reference: SEQ ID NO: 42", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.output("test_data/test_document.pdf")
print("Created test_data/test_document.pdf")
EOF

echo ""

# Test 1: Basic search with exact match
echo "Test 1: Search for exact match (1798)..."
output=$(./run_find_number.command test_data/test_document.pdf 1798 2>&1)
if echo "$output" | grep -q "Exact match: 1798"; then
    pass "Found exact match for 1798"
else
    echo "$output"
    fail "Did not find exact match for 1798"
fi

# Test 2: Search for number in range
echo "Test 2: Search for number within range (1500)..."
output=$(./run_find_number.command test_data/test_document.pdf 1500 2>&1)
if echo "$output" | grep -q "Range:"; then
    pass "Found range containing 1500"
else
    echo "$output"
    fail "Did not find range containing 1500"
fi

# Test 3: Search for number not in document
echo "Test 3: Search for number not in document (9999)..."
output=$(./run_find_number.command test_data/test_document.pdf 9999 2>&1)
if echo "$output" | grep -q "No occurrences"; then
    pass "Correctly reported no matches for 9999"
else
    echo "$output"
    fail "Should have reported no matches for 9999"
fi

# Test 4: File not found error
echo "Test 4: Handle missing file..."
output=$(./run_find_number.command nonexistent.pdf 123 2>&1) || true
if echo "$output" | grep -qi "not found\|error"; then
    pass "Correctly handled missing file"
else
    echo "$output"
    fail "Should have reported file not found"
fi

# Test 5: Check exit code on success
echo "Test 5: Check exit code on success..."
./run_find_number.command test_data/test_document.pdf 1798 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    pass "Exit code 0 on success"
else
    fail "Expected exit code 0"
fi

# Test 6: Verify venv was created
echo "Test 6: Verify virtual environment was created..."
if [[ -d ".venv" && -f ".venv/bin/activate" ]]; then
    pass "Virtual environment created successfully"
else
    fail "Virtual environment not found"
fi

# Cleanup
echo ""
echo "Cleaning up test data..."
rm -rf test_data

echo ""
echo "=== All tests passed ==="
