#!/bin/bash
# Mac launcher for find_number_in_pdf
# Double-click this file to run interactively, or run from command line with arguments
#
# Usage:
#   Interactive:  ./run_find_number.command
#   With args:    ./run_find_number.command <pdf_path> <number> [--ocr]

cd "$(dirname "$0")"

echo "=== Find Sequence ID Number in PDF ==="
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed."
    echo "Please install Python from https://www.python.org/downloads/"
    echo ""
    if [[ -z "$1" ]]; then
        read -p "Press Enter to exit..."
    fi
    exit 1
fi

# Set up virtual environment if it doesn't exist
VENV_DIR=".venv"
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Setting up virtual environment (one-time setup)..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip -q
    pip install -r requirements.txt
    echo "Setup complete."
    echo ""
else
    source "$VENV_DIR/bin/activate"
fi

# Check if arguments were provided (non-interactive mode)
if [[ -n "$1" && -n "$2" ]]; then
    pdf_path="$1"
    search_number="$2"
    ocr_flag=""
    if [[ "$3" == "--ocr" ]]; then
        ocr_flag="--ocr"
    fi
else
    # Interactive prompts
    read -p "Enter the path to your PDF file (or drag and drop): " pdf_path
    # Remove quotes that may be added by drag-and-drop
    pdf_path="${pdf_path//\'/}"
    pdf_path="${pdf_path//\"/}"
    # Trim whitespace
    pdf_path="${pdf_path## }"
    pdf_path="${pdf_path%% }"

    read -p "Enter the number to search for: " search_number

    read -p "Use OCR for scanned PDFs? (y/n, default: n): " use_ocr
    if [[ "$use_ocr" =~ ^[Yy] ]]; then
        ocr_flag="--ocr"
        # Check for tesseract
        if ! command -v tesseract &> /dev/null; then
            echo ""
            echo "WARNING: Tesseract OCR is not installed."
            echo "Install with: brew install tesseract"
            echo ""
            read -p "Continue without OCR? (y/n): " continue_choice
            if [[ ! "$continue_choice" =~ ^[Yy] ]]; then
                exit 1
            fi
            ocr_flag=""
        fi
    else
        ocr_flag=""
    fi
fi

echo ""
echo "Searching..."
echo ""

python findNumberInPdf/find_number_in_pdf.py "$pdf_path" "$search_number" $ocr_flag -v
exit_code=$?

echo ""
# Only pause if running interactively (no arguments provided)
if [[ -z "$1" ]]; then
    read -p "Press Enter to exit..."
fi

exit $exit_code
