#!/usr/bin/env python3
"""
GDScript Error Checker
Checks all .gd files for syntax errors, style issues, and common mistakes
"""

import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

# Colors for terminal output (avoid emojis for Windows compatibility)
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"


def run_gdlint(file_path: Path) -> Tuple[bool, List[str]]:
    """Run gdlint on a single file and return (success, messages)"""
    try:
        result = subprocess.run(
            ["gdlint", str(file_path)], capture_output=True, text=True, timeout=10
        )

        if result.returncode == 0:
            return True, []
        else:
            # Parse gdlint output
            messages = []
            for line in result.stdout.split("\n") + result.stderr.split("\n"):
                line = line.strip()
                if line and not line.startswith("Checking"):
                    messages.append(line)
            return False, messages
    except FileNotFoundError:
        return False, ["gdlint not found. Install with: pip install gdtoolkit"]
    except Exception as e:
        return False, [f"Error running gdlint: {e}"]


def check_syntax(file_path: Path) -> Tuple[bool, List[str]]:
    """Basic syntax check for common GDScript issues"""
    issues = []

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            lines = content.split("\n")
    except Exception as e:
        return False, [f"Cannot read file: {e}"]

    # Check for common issues
    for i, line in enumerate(lines, 1):
        # Check for TODO/FIXME comments
        if "TODO" in line.upper() or "FIXME" in line.upper():
            issues.append(f"Line {i}: {YELLOW}Found TODO/FIXME comment{RESET}")

        # Check for print statements (potential debug code)
        if line.strip().startswith("print(") and "print_debug" not in line:
            issues.append(f"Line {i}: {YELLOW}Found print() statement{RESET}")

    return len(issues) == 0, issues


def main():
    """Main function to check all GDScript files"""
    project_root = Path(__file__).parent
    gd_files = list(project_root.rglob("*.gd"))

    if not gd_files:
        print(f"{YELLOW}No .gd files found in {project_root}{RESET}")
        return 0

    print(f"{BLUE}Checking {len(gd_files)} GDScript file(s)...{RESET}\n")

    total_errors = 0
    total_warnings = 0
    files_with_issues = 0

    for gd_file in gd_files:
        rel_path = gd_file.relative_to(project_root)
        print(f"{BLUE}Checking:{RESET} {rel_path}")

        # Run gdlint
        gdlint_ok, gdlint_messages = run_gdlint(gd_file)

        # Run syntax check
        syntax_ok, syntax_messages = check_syntax(gd_file)

        # Display results
        if not gdlint_ok:
            files_with_issues += 1
            total_errors += 1
            print(f"  {RED}[FAIL] Lint errors:{RESET}")
            for msg in gdlint_messages:
                print(f"     {RED}-{RESET} {msg}")

        if syntax_messages:
            for msg in syntax_messages:
                if "TODO" in msg or "print()" in msg:
                    total_warnings += 1
                else:
                    total_errors += 1
                print(f"  {YELLOW}[WARN]{RESET}  {msg}")

        if gdlint_ok and not syntax_messages:
            print(f"  {GREEN}[OK]{RESET}")

        print()

    # Summary
    print("=" * 60)
    print(f"{BLUE}Summary:{RESET}")
    print(f"  Files checked: {len(gd_files)}")
    print(f"  Files with issues: {files_with_issues}")
    print(f"  {RED}Errors: {total_errors}{RESET}")
    print(f"  {YELLOW}Warnings: {total_warnings}{RESET}")
    print("=" * 60)

    if total_errors == 0:
        print(f"\n{GREEN}All files passed!{RESET}")
        return 0
    else:
        print(f"\n{RED}Found {total_errors} error(s){RESET}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
