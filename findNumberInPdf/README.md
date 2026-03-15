# Find Sequence ID Number in PDF

Searches a PDF document for a specific sequence ID number, finding both exact matches (e.g., "SEQ ID NO: 1798") and numeric ranges that contain the number (e.g., "SEQ ID NOS: 1475-1826"). Only matches that appear in a sequence ID context are returned—random numbers elsewhere in the document are filtered out.

---

## Running the Tool

### Windows

1. Double-click **`run.bat`**
2. On first run, the tool will set up its environment (this takes a moment)
3. Follow the prompts to enter your PDF path and search number

### Mac

1. Double-click **`run.command`**
2. If prompted about security, go to System Settings > Privacy & Security and click "Open Anyway"
3. On first run, the tool will set up its environment (this takes a moment)
4. Follow the prompts to enter your PDF path and search number

**Tip**: You can drag and drop a PDF file into the terminal window instead of typing the path.

---

## Command Line Usage

You can run the launchers with arguments to skip the interactive prompts:

**Windows:**
```
run.bat "C:\path\to\document.pdf" 1798
run.bat "C:\path\to\document.pdf" 1798 --ocr
```

**Mac:**
```bash
./run.command "/path/to/document.pdf" 1798
./run.command "/path/to/document.pdf" 1798 --ocr
```

### Options

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

## How It Works

The launcher scripts automatically:
1. Create an isolated Python environment (`.venv` folder) on first run
2. Install all required dependencies into that environment
3. Run the tool using the isolated environment

This keeps everything self-contained and won't interfere with other Python installations.

---

## Troubleshooting

### First run is slow
Normal—the tool is setting up its environment. Subsequent runs are fast.

### Need to reset the environment
Delete the `.venv` folder and run again.

### OCR not working
Make sure Tesseract is installed (see above).
