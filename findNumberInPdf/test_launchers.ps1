# Test script for the Windows launcher
# Run in PowerShell: .\test_launchers.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== Testing BAP Utils Launchers (Windows) ===" -ForegroundColor Cyan
Write-Host ""

function Pass($msg) {
    Write-Host "PASS" -ForegroundColor Green -NoNewline
    Write-Host ": $msg"
}

function Fail($msg) {
    Write-Host "FAIL" -ForegroundColor Red -NoNewline
    Write-Host ": $msg"
    exit 1
}

# Clean up any existing venv to test fresh setup
if (Test-Path ".venv") {
    Write-Host "Removing existing .venv for clean test..."
    Remove-Item -Recurse -Force .venv
}

# Create test PDF using fpdf2
Write-Host "Creating test PDF..."
pip install -q fpdf2 2>$null

python -c @"
from fpdf import FPDF
from fpdf.enums import XPos, YPos
import os

os.makedirs('test_data', exist_ok=True)

pdf = FPDF()
pdf.add_page()
pdf.set_font('Helvetica', size=12)

pdf.cell(0, 10, 'Test Patent Document', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 10, 'This document references SEQ ID NO: 1798', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 10, 'See also SEQ ID NOS: 1475-1826 for related sequences.', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 10, 'Additional reference: SEQ ID NO: 42', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.output('test_data/test_document.pdf')
print('Created test_data/test_document.pdf')
"@

Write-Host ""

# Test 1: Basic search with exact match
Write-Host "Test 1: Search for exact match (1798)..."
$output = & cmd /c "run.bat test_data\test_document.pdf 1798 2>&1"
if ($output -match "Exact match: 1798") {
    Pass "Found exact match for 1798"
} else {
    Write-Host $output
    Fail "Did not find exact match for 1798"
}

# Test 2: Search for number in range
Write-Host "Test 2: Search for number within range (1500)..."
$output = & cmd /c "run.bat test_data\test_document.pdf 1500 2>&1"
if ($output -match "Range:") {
    Pass "Found range containing 1500"
} else {
    Write-Host $output
    Fail "Did not find range containing 1500"
}

# Test 3: Search for number not in document
Write-Host "Test 3: Search for number not in document (9999)..."
$output = & cmd /c "run.bat test_data\test_document.pdf 9999 2>&1"
if ($output -match "No occurrences") {
    Pass "Correctly reported no matches for 9999"
} else {
    Write-Host $output
    Fail "Should have reported no matches for 9999"
}

# Test 4: File not found error
Write-Host "Test 4: Handle missing file..."
$output = & cmd /c "run.bat nonexistent.pdf 123 2>&1"
if ($output -match "not found|error") {
    Pass "Correctly handled missing file"
} else {
    Write-Host $output
    Fail "Should have reported file not found"
}

# Test 5: Verify venv was created
Write-Host "Test 5: Verify virtual environment was created..."
if (Test-Path ".venv\Scripts\activate.bat") {
    Pass "Virtual environment created successfully"
} else {
    Fail "Virtual environment not found"
}

# Cleanup
Write-Host ""
Write-Host "Cleaning up test data..."
Remove-Item -Recurse -Force test_data -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== All tests passed ===" -ForegroundColor Green
