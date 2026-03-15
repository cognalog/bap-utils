#!/usr/bin/env python3
"""
Find a number in a PDF file, including detection of numeric ranges that contain the number.
Supports both text-based PDFs and scanned PDFs (via OCR).
Supports parallel OCR processing for faster results.
"""

import argparse
import os
import re
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed

try:
    import pdfplumber
except ImportError:
    print("Error: pdfplumber not installed. Run: pip install pdfplumber")
    sys.exit(1)

# Optional OCR support
try:
    from pdf2image import convert_from_path
    import pytesseract
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False


def ocr_single_page(args: tuple) -> tuple[int, str]:
    """OCR a single page. Designed to be called in parallel."""
    pdf_path, page_num = args
    images = convert_from_path(pdf_path, first_page=page_num, last_page=page_num)
    if images:
        text = pytesseract.image_to_string(images[0])
        return (page_num, text)
    return (page_num, "")


def extract_text_from_pdf(pdf_path: str, use_ocr: bool = False,
                          page_range: tuple = None, verbose: bool = False,
                          workers: int = 4) -> list[tuple[int, str]]:
    """Extract text from PDF, returning list of (page_num, text) tuples."""
    pages = []

    with pdfplumber.open(pdf_path) as pdf:
        total_pages = len(pdf.pages)
        start_page = (page_range[0] - 1) if page_range else 0
        end_page = page_range[1] if page_range else total_pages

        # First try extracting embedded text
        has_text = False
        for i in range(start_page, min(end_page, total_pages)):
            page = pdf.pages[i]
            text = page.extract_text() or ""
            if text.strip():
                has_text = True
            pages.append((i + 1, text))

        # If no text found and OCR is available and requested, use OCR
        if not has_text and use_ocr:
            if not OCR_AVAILABLE:
                print("Warning: OCR requested but pdf2image/pytesseract not installed.")
                print("Install with: pip install pdf2image pytesseract")
                print("Also install tesseract: brew install tesseract")
                return pages

            page_count = end_page - start_page
            if verbose:
                print(f"No embedded text found. Using OCR on {page_count} pages with {workers} workers...", file=sys.stderr)

            pages = []
            page_nums = list(range(start_page + 1, end_page + 1))

            # Parallel OCR processing
            completed = 0
            with ProcessPoolExecutor(max_workers=workers) as executor:
                # Submit all tasks
                futures = {
                    executor.submit(ocr_single_page, (pdf_path, pn)): pn
                    for pn in page_nums
                }

                # Collect results as they complete
                results = {}
                for future in as_completed(futures):
                    page_num, text = future.result()
                    results[page_num] = text
                    completed += 1
                    if verbose:
                        print(f"  OCR progress: {completed}/{page_count} pages completed", end='\r', file=sys.stderr)

            if verbose:
                print(file=sys.stderr)  # Clear the progress line

            # Sort results by page number
            for pn in page_nums:
                pages.append((pn, results.get(pn, "")))

    return pages


def find_exact_matches(text: str, target: float, page_num: int) -> list[dict]:
    """Find exact occurrences of the target number."""
    results = []
    # Format target: use integer string if it's a whole number
    target_str = str(int(target)) if target == int(target) else str(target)
    # Match the number as a standalone value (not part of a larger number)
    # Also match comma-formatted numbers like 1,798
    target_with_commas = format(int(target), ',') if target == int(target) else target_str

    patterns = [
        rf'(?<![0-9.,-]){re.escape(target_str)}(?![0-9.,-])',
    ]
    if target_with_commas != target_str:
        patterns.append(rf'(?<![0-9.,-]){re.escape(target_with_commas)}(?![0-9.,-])')

    for pattern in patterns:
        for match in re.finditer(pattern, text):
            # Get surrounding context
            start = max(0, match.start() - 30)
            end = min(len(text), match.end() + 30)
            context = text[start:end].replace('\n', ' ')

            results.append({
                'type': 'exact',
                'page': page_num,
                'match': match.group(),
                'context': f"...{context}..."
            })

    return results


def find_ranges_containing(text: str, target: float, page_num: int) -> list[dict]:
    """Find numeric ranges that contain the target number."""
    results = []

    # Patterns for ranges: "X to Y", "X - Y", "X-Y", "X through Y", "X–Y" (en-dash), "X—Y" (em-dash)
    # Also handles "from X to Y", "between X and Y"
    range_patterns = [
        # "X to Y", "X through Y"
        r'(\d+(?:,\d{3})*(?:\.\d+)?)\s*(?:to|through)\s*(\d+(?:,\d{3})*(?:\.\d+)?)',
        # "X-Y", "X - Y", "X–Y", "X—Y" (various dashes)
        r'(\d+(?:,\d{3})*(?:\.\d+)?)\s*[-–—]\s*(\d+(?:,\d{3})*(?:\.\d+)?)',
        # "from X to Y"
        r'from\s+(\d+(?:,\d{3})*(?:\.\d+)?)\s+to\s+(\d+(?:,\d{3})*(?:\.\d+)?)',
        # "between X and Y"
        r'between\s+(\d+(?:,\d{3})*(?:\.\d+)?)\s+and\s+(\d+(?:,\d{3})*(?:\.\d+)?)',
        # "X up to Y"
        r'(\d+(?:,\d{3})*(?:\.\d+)?)\s+up\s+to\s+(\d+(?:,\d{3})*(?:\.\d+)?)',
    ]

    for pattern in range_patterns:
        for match in re.finditer(pattern, text, re.IGNORECASE):
            try:
                # Remove commas before converting to float
                low = float(match.group(1).replace(',', ''))
                high = float(match.group(2).replace(',', ''))

                # Ensure low <= high (swap if needed)
                if low > high:
                    low, high = high, low

                # Check if target is within range
                if low <= target <= high:
                    # Get surrounding context
                    start = max(0, match.start() - 20)
                    end = min(len(text), match.end() + 20)
                    context = text[start:end].replace('\n', ' ')

                    results.append({
                        'type': 'range',
                        'page': page_num,
                        'range': f"{low} to {high}",
                        'match': match.group(),
                        'context': f"...{context}..."
                    })
            except ValueError:
                continue

    return results


def is_sequence_id(result: dict) -> bool:
    """Check if the match appears to be a sequence ID based on surrounding context."""
    context = result.get('context', '').lower()

    # Keywords that indicate sequence IDs
    seq_keywords = [
        'seq id no',
        'seq id nos',
        'seq. id no',
        'seq. id nos',
        'sequence id',
        'sequence number',
        'sequence no',
        'seq no',
        'seq nos',
        'seqid',
    ]

    return any(kw in context for kw in seq_keywords)


def classify_match(result: dict) -> str:
    """Classify a match as 'likely' or 'noise' based on heuristics."""
    context = result.get('context', '').lower()
    match_text = result.get('match', '')

    # Exact matches are always likely
    if result['type'] == 'exact':
        return 'likely'

    # For ranges, apply heuristics
    range_str = result.get('range', '')
    if range_str:
        parts = range_str.split(' to ')
        if len(parts) == 2:
            try:
                low, high = float(parts[0]), float(parts[1])

                # Noise indicators:

                # 1. Very large numbers (likely document/docket numbers)
                if high > 100000:
                    return 'noise'

                # 2. Huge disparity in magnitude (e.g., 32 to 63299)
                if high > 0 and low > 0:
                    ratio = high / low
                    if ratio > 100:
                        return 'noise'

                # 3. Context contains document identifiers
                noise_keywords = ['dkt', 'attorney', 'pct/', 'wo 20', 'patent',
                                  'publication no', 'application']
                if any(kw in context for kw in noise_keywords):
                    return 'noise'

                # 4. Match contains newlines (OCR artifacts from page headers)
                if '\n' in match_text and not is_sequence_id(result):
                    return 'noise'

                # 5. Small number paired with what looks like a page number pattern
                if low < 100 and high > 10000:
                    return 'noise'

            except (ValueError, ZeroDivisionError):
                pass

    return 'likely'


def find_number_in_pdf(pdf_path: str, target: float, use_ocr: bool = False,
                       page_range: tuple = None, verbose: bool = False,
                       workers: int = 4) -> list[dict]:
    """Main function to find a number in a PDF."""
    all_results = []

    pages = extract_text_from_pdf(pdf_path, use_ocr, page_range, verbose, workers)

    for page_num, text in pages:
        # Find exact matches
        exact_matches = find_exact_matches(text, target, page_num)
        all_results.extend(exact_matches)

        # Find ranges containing the number
        range_matches = find_ranges_containing(text, target, page_num)
        all_results.extend(range_matches)

    # Postfilter sequence ID matches (only keep sequence IDs)
    all_results = [r for r in all_results if is_sequence_id(r)]

    # Classify each result
    for result in all_results:
        result['classification'] = classify_match(result)

    return all_results


def main():
    parser = argparse.ArgumentParser(
        description='Find a number in a PDF file, including ranges that contain it.'
    )
    parser.add_argument('pdf_path', help='Path to the PDF file')
    parser.add_argument('number', type=float, help='The number to search for')
    parser.add_argument('--ocr', action='store_true',
                        help='Use OCR for scanned PDFs (requires tesseract)')
    parser.add_argument('--pages', type=str, metavar='START-END',
                        help='Page range to search, e.g., "1-50"')
    parser.add_argument('-w', '--workers', type=int, default=os.cpu_count() or 4,
                        help=f'Number of parallel OCR workers (default: {os.cpu_count() or 4})')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='Show progress and additional info')

    args = parser.parse_args()

    # Parse page range
    page_range = None
    if args.pages:
        try:
            parts = args.pages.split('-')
            page_range = (int(parts[0]), int(parts[1]))
        except (ValueError, IndexError):
            print(f"Error: Invalid page range format. Use START-END, e.g., '1-50'")
            sys.exit(1)

    try:
        results = find_number_in_pdf(args.pdf_path, args.number, args.ocr,
                                     page_range, args.verbose, args.workers)
    except FileNotFoundError:
        print(f"Error: File not found: {args.pdf_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading PDF: {e}")
        sys.exit(1)

    # Format number for display (no .0 for whole numbers)
    num_display = int(args.number) if args.number == int(args.number) else args.number

    if not results:
        print(f"No occurrences of {num_display} found in {args.pdf_path}")
        return

    # Separate results by classification
    likely_matches = [r for r in results if r.get('classification') == 'likely']
    noise_matches = [r for r in results if r.get('classification') == 'noise']

    print(f"Found {len(results)} occurrence(s) of {num_display} in {args.pdf_path}")
    print(f"  - {len(likely_matches)} likely match(es)")
    print(f"  - {len(noise_matches)} likely noise\n")

    def print_result(result, index):
        if result['type'] == 'exact':
            print(f"{index}. [Page {result['page']}] Exact match: {result['match']}")
        else:
            match_preview = result['match'].replace('\n', ' ')[:40]
            print(f"{index}. [Page {result['page']}] Range: {result['range']} (matched: \"{match_preview}\")")
        print(f"   Context: {result['context']}")
        print()

    if likely_matches:
        print("=" * 60)
        print("LIKELY MATCHES")
        print("=" * 60 + "\n")
        for i, result in enumerate(likely_matches, 1):
            print_result(result, i)

    if noise_matches:
        print("=" * 60)
        print("LIKELY NOISE (document numbers, page numbers, etc.)")
        print("=" * 60 + "\n")
        for i, result in enumerate(noise_matches, 1):
            print_result(result, i)


if __name__ == '__main__':
    main()
