#!/usr/bin/env python3
"""
Auto-format GDScript files
Removes trailing whitespace and fixes common formatting issues
"""

import sys
from pathlib import Path


def format_file(file_path: Path) -> bool:
    """Format a single GDScript file"""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        lines = content.split("\n")
        formatted_lines = []
        changes = []

        for i, line in enumerate(lines, 1):
            original = line
            # Remove trailing whitespace
            line = line.rstrip()

            if original != line:
                changes.append(f"Line {i}: Removed trailing whitespace")

            formatted_lines.append(line)

        # Join lines back
        formatted_content = "\n".join(formatted_lines)

        # Ensure file ends with newline
        if not formatted_content.endswith("\n"):
            formatted_content += "\n"
            changes.append("Added final newline")

        # Write back if changed
        if changes:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(formatted_content)
            return True, changes

        return False, []

    except Exception as e:
        return False, [f"Error: {e}"]


def main():
    """Main function to format all GDScript files"""
    project_root = Path(__file__).parent
    gd_files = list(project_root.rglob("*.gd"))

    if not gd_files:
        print("No .gd files found")
        return 0

    print(f"Formatting {len(gd_files)} GDScript file(s)...\n")

    files_changed = 0

    for gd_file in gd_files:
        rel_path = gd_file.relative_to(project_root)
        changed, changes = format_file(gd_file)

        if changed:
            files_changed += 1
            print(f"[FIXED] {rel_path}")
            for change in changes[:5]:  # Show first 5 changes
                print(f"  - {change}")
            if len(changes) > 5:
                print(f"  ... and {len(changes) - 5} more changes")

    print(f"\n{'=' * 60}")
    print(f"Formatted {files_changed} file(s)")
    print("=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())
