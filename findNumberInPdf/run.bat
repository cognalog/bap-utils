@echo off
REM Windows launcher for find_number_in_pdf
REM Double-click this file to run interactively, or run from command line with arguments
REM
REM Usage:
REM   Interactive:  run.bat
REM   With args:    run.bat <pdf_path> <number> [--ocr]

cd /d "%~dp0"

echo === Find Sequence ID Number in PDF ===
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed.
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    if "%~1"=="" pause
    exit /b 1
)

REM Set up virtual environment if it doesn't exist
set VENV_DIR=.venv
if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo Setting up virtual environment (one-time setup^)...
    python -m venv %VENV_DIR%
    call %VENV_DIR%\Scripts\activate.bat
    pip install --upgrade pip -q
    pip install -r requirements.txt
    echo Setup complete.
    echo.
) else (
    call %VENV_DIR%\Scripts\activate.bat
)

REM Check if arguments were provided (non-interactive mode)
if not "%~1"=="" if not "%~2"=="" (
    set "pdf_path=%~1"
    set "search_number=%~2"
    set "ocr_flag="
    if /i "%~3"=="--ocr" set "ocr_flag=--ocr"
    goto :run_search
)

REM Interactive prompts
set /p pdf_path="Enter the path to your PDF file (or drag and drop): "
REM Remove surrounding quotes if present
set pdf_path=%pdf_path:"=%

set /p search_number="Enter the number to search for: "

set /p use_ocr="Use OCR for scanned PDFs? (y/n, default: n): "
set ocr_flag=
if /i "%use_ocr%"=="y" (
    set ocr_flag=--ocr
    where tesseract >nul 2>&1
    if errorlevel 1 (
        echo.
        echo WARNING: Tesseract OCR is not installed.
        echo Download from: https://github.com/UB-Mannheim/tesseract/wiki
        echo.
        set /p continue_choice="Continue without OCR? (y/n): "
        if /i not "%continue_choice%"=="y" exit /b 1
        set ocr_flag=
    )
)

:run_search
echo.
echo Searching...
echo.

python find_number_in_pdf.py "%pdf_path%" %search_number% %ocr_flag% -v
set exit_code=%errorlevel%

echo.
REM Only pause if running interactively (no arguments provided)
if "%~1"=="" pause

exit /b %exit_code%
