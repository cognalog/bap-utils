# BAP Utilities

Utility scripts for patent specialists.

## Available Tools

### Find Sequence ID Number in PDF

Searches a PDF document for a specific sequence ID number, finding both exact matches (e.g., "SEQ ID NO: 1798") and numeric ranges that contain the number (e.g., "SEQ ID NOS: 1475-1826"). Only matches that appear in a sequence ID context are returned—random numbers elsewhere in the document are filtered out.

---

## Download

1. Go to [github.com/cognalog/bap-utils](https://github.com/cognalog/bap-utils)
2. Click the green **Code** button
3. Click **Download ZIP**
4. Extract the ZIP file to a folder on your computer (e.g., Desktop or Documents)

---

## Setup

### Install Python (one-time)

Download Python from [python.org/downloads](https://www.python.org/downloads/) and run the installer.

| Platform | Notes |
|----------|-------|
| **Windows** | Check the box **"Add Python to PATH"** during installation |
| **Mac** | Run the installer and follow the prompts |

---

## Running the Tool

### Windows

1. Open the extracted `bap-utils` folder
2. Double-click **`run_find_number.bat`**
3. On first run, the tool will set up its environment (this takes a moment)
4. Follow the prompts to enter your PDF path and search number

### Mac

1. Open the extracted `bap-utils` folder
2. Double-click **`run_find_number.command`**
3. If prompted about security, go to System Settings > Privacy & Security and click "Open Anyway"
4. On first run, the tool will set up its environment (this takes a moment)
5. Follow the prompts to enter your PDF path and search number

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

You can run the launchers with arguments to skip the interactive prompts:

**Windows:**
```
run_find_number.bat "C:\path\to\document.pdf" 1798
run_find_number.bat "C:\path\to\document.pdf" 1798 --ocr
```

**Mac:**
```bash
./run_find_number.command "/path/to/document.pdf" 1798
./run_find_number.command "/path/to/document.pdf" 1798 --ocr
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

If your PDFs are scanned images rather than searchable text, you'll need to install Tesseract OCR.

**Windows:**
1. Download the installer from [UB-Mannheim/tesseract](https://github.com/UB-Mannheim/tesseract/wiki)
2. Run the installer
3. Check the box to add Tesseract to your PATH

**Mac:**
```bash
brew install tesseract
```
If you don't have Homebrew, install it first from [brew.sh](https://brew.sh/).

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
Download Python from [python.org/downloads](https://www.python.org/downloads/). On Windows, make sure to check "Add Python to PATH" during installation.

### Windows: "Windows protected your PC" (SmartScreen)
Click "More info" then "Run anyway".

### Mac: "Cannot be opened because it is from an unidentified developer"
Go to System Settings > Privacy & Security, scroll down, and click "Open Anyway" next to the blocked file message.

### First run is slow
This is normal. The tool is setting up its environment and downloading dependencies. Subsequent runs will be fast.

### Need to reset the environment
Delete the `.venv` folder inside `bap-utils` and run the tool again. It will recreate the environment from scratch.

### OCR not working
Make sure Tesseract is installed (see OCR Setup section above).
