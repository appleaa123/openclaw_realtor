#!/usr/bin/env python3
"""
Fill Ontario LTB forms (N4, N9, N12) using pypdf.
Supports field inspection and field filling from JSON data.

Usage:
    # Inspect available fields in a PDF form
    python fill_ltb_form.py --form assets/N4-blank.pdf --inspect

    # Fill a form with data
    python fill_ltb_form.py \
        --form assets/N4-blank.pdf \
        --output /data/workspace/forms/tenant123_N4.pdf \
        --fields '{"tenant_name": "Jane Doe", "address": "123 Main St"}'
"""

import argparse
import json
import sys
from pathlib import Path

try:
    from pypdf import PdfReader, PdfWriter
except ImportError:
    print("ERROR: pypdf not installed. Run: pip install pypdf", file=sys.stderr)
    sys.exit(1)


def inspect_fields(form_path: Path) -> None:
    """Print all fillable field names in the PDF form."""
    reader = PdfReader(str(form_path))
    fields = reader.get_form_text_fields()

    if not fields:
        print("No fillable text fields found in this PDF.")
        print("The form may use non-standard field types or be a scanned image.")
        return

    print(f"Fillable fields in {form_path.name}:")
    print("=" * 50)
    for name, value in fields.items():
        current = f' (current: "{value}")' if value else ""
        print(f"  {name!r}{current}")
    print(f"\nTotal: {len(fields)} fields")


def fill_form(form_path: Path, output_path: Path, field_data: dict) -> None:
    """Fill form fields and write to output path."""
    reader = PdfReader(str(form_path))
    writer = PdfWriter()

    for page in reader.pages:
        writer.add_page(page)

    available_fields = reader.get_form_text_fields() or {}
    unmatched = []

    writer.update_page_form_field_values(
        writer.pages[0], field_data, auto_regenerate=False
    )

    for key in field_data:
        if key not in available_fields:
            unmatched.append(key)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "wb") as f:
        writer.write(f)

    print(f"Form filled: {output_path}")

    if unmatched:
        print(f"\nWARNING: {len(unmatched)} field(s) not found in form:")
        for field in unmatched:
            print(f"  - {field!r}")
        print("Use --inspect to see available field names.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Fill Ontario LTB PDF forms.")
    parser.add_argument("--form", required=True, type=Path, help="Path to blank PDF form")
    parser.add_argument("--output", type=Path, help="Output path for filled PDF")
    parser.add_argument("--fields", type=str, help="JSON object of field_name: value pairs")
    parser.add_argument(
        "--inspect",
        action="store_true",
        help="List all fillable fields instead of filling",
    )

    args = parser.parse_args()

    ALLOWED_OUTPUT_DIR = Path("/data/workspace/forms").resolve()

    if args.output:
        resolved_output = args.output.resolve()
        if not str(resolved_output).startswith(str(ALLOWED_OUTPUT_DIR)):
            print(
                f"ERROR: Output path must be within {ALLOWED_OUTPUT_DIR}",
                file=sys.stderr,
            )
            sys.exit(1)

    if not args.form.exists():
        print(f"ERROR: Form not found: {args.form}", file=sys.stderr)
        sys.exit(1)

    if args.inspect:
        inspect_fields(args.form)
        return

    if not args.output:
        print("ERROR: --output required when filling a form.", file=sys.stderr)
        sys.exit(1)

    if not args.fields:
        print("ERROR: --fields required when filling a form.", file=sys.stderr)
        sys.exit(1)

    try:
        field_data = json.loads(args.fields)
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON in --fields: {e}", file=sys.stderr)
        sys.exit(1)

    fill_form(args.form, args.output, field_data)


if __name__ == "__main__":
    main()
