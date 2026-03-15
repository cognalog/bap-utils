# BAP Utilities

Utility scripts for patent specialists.

## Available Tools

### Find Sequence ID Number in PDF

Searches a PDF document for a specific sequence ID number, finding both exact matches (e.g., "SEQ ID NO: 1798") and numeric ranges that contain the number (e.g., "SEQ ID NOS: 1475-1826"). Only matches that appear in a sequence ID context are returned—random numbers elsewhere in the document are filtered out.

---

## Quick Start (Easiest Method)

### Mac

1. **Install Python** (one-time setup):
   - Download from [python.org/downloads](https://www.python.org/downloads/)
   - Run the installer and follow the prompts

2. **Run the tool**:
   - Double-click `run_find_number.command`
   - If prompted about security, go to System Preferences > Security & Privacy and click "Open Anyway"
   - On first run, the tool will automatically set up its environment (this takes a moment)
   - Follow the prompts to enter your PDF path and search number

### Windows

1. **Install Python** (one-time setup):
   - Download from [python.org/downloads](https://www.python.org/downloads/)
   - **Important**: Check the box "Add Python to PATH" during installation

2. **Run the tool**:
   - Double-click `run_find_number.bat`
   - On first run, the tool will automatically set up its environment (this takes a moment)
   - Follow the prompts to enter your PDF path and search number

**Tip**: You can drag and drop a PDF file into the terminal window instead of typing the path.

---

## How It Works

The launcher scripts automatically:
1. Create an isolated Python environment (`.venv` folder) on first run
2. Install all required dependencies into that environment
3. Run the tool using the isolated environment

This keeps everything self-contained and won't interfere with other Python installations on your computer.

---

## Command Line Usage (Advanced)

You can also run the launchers with arguments to skip the interactive prompts:

```bash
# Mac
./run_find_number.command "path/to/document.pdf" 1798
./run_find_number.command "path/to/document.pdf" 1798 --ocr

# Windows
run_find_number.bat "path\to\document.pdf" 1798
run_find_number.bat "path\to\document.pdf" 1798 --ocr
```

### Direct Python Usage

If you prefer to run the Python script directly:

```bash
# Activate the virtual environment first
source .venv/bin/activate   # Mac/Linux
.venv\Scripts\activate      # Windows

# Then run the script
python findNumberInPdf/find_number_in_pdf.py "path/to/document.pdf" 1798
```

### Command Options

| Option | Description |
|--------|-------------|
| `--ocr` | Use OCR for scanned PDFs (requires Tesseract) |
| `--pages START-END` | Search only specific pages (e.g., `--pages 1-50`) |
| `-w N` | Number of parallel workers for OCR (default: auto) |
| `-v` | Verbose mode - show progress |

---

## OCR Setup (For Scanned PDFs)

If your PDFs are scanned images rather than text-based, you'll need OCR support.

### Mac

```bash
brew install tesseract
```

If you don't have Homebrew, install it first from [brew.sh](https://brew.sh/).

### Windows

1. Download the installer from [UB-Mannheim/tesseract](https://github.com/UB-Mannheim/tesseract/wiki)
2. Run the installer
3. Add Tesseract to your PATH (the installer can do this automatically)

---

## Example Output

```
Found 3 occurrence(s) of 1798 in patent_application.pdf
  - 3 likely match(es)
  - 0 likely noise

============================================================
LIKELY MATCHES
============================================================

1. [Page 45] Exact match: 1798
   Context: ...any of SEQ ID NOS: 1798 is paired with...

2. [Page 112] Range: 1475 to 1826 (matched: "1475-1826")
   Context: ...any of SEQ ID NOS: 1475-1826 and variable...
```

---

## Troubleshooting

### "Python is not installed" error

- Download Python from [python.org/downloads](https://www.python.org/downloads/)
- On Windows, make sure to check "Add Python to PATH" during installation

### Mac: "Cannot be opened because it is from an unidentified developer"

- Go to System Preferences > Security & Privacy > General
- Click "Open Anyway" next to the message about the blocked file

### First run is slow

This is normal. The tool is setting up its environment and downloading dependencies. Subsequent runs will be fast.

### Need to reset the environment

If something goes wrong with the setup, delete the `.venv` folder and run the tool again. It will recreate the environment from scratch.

### OCR not working

Make sure Tesseract is installed (see OCR Setup section above).
