"""Preview or prune old Claude Code diagnostic logs on a local user profile."""
import argparse
import os
from pathlib import Path
import re
import stat
import sys
import time

LOG_NAME = re.compile(r"[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}\.txt", re.I)


def is_link(info):
    return stat.S_ISLNK(info.st_mode) or bool(
        getattr(info, "st_file_attributes", 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--days", type=int, default=30, help="minimum age in days (default 30)")
    parser.add_argument("--apply", action="store_true", help="delete matching files")
    args = parser.parse_args()
    if args.days < 1 or args.days > 36500:
        parser.error("--days must be between 1 and 36500")

    profile = Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude")
    if not profile.is_absolute() or ".." in profile.parts:
        parser.error("config directory must be an absolute path without '..'")
    directory = profile / "debug"
    for part in (*reversed(directory.parents), directory):
        try:
            info = part.lstat()
        except FileNotFoundError:
            print("No debug directory.")
            return 0
        if is_link(info) or not stat.S_ISDIR(info.st_mode):
            sys.exit("Skipped: directory path contains a link or a non-directory.")

    cutoff = time.time() - args.days * 86400
    count = size = 0
    for path in directory.iterdir():
        if not LOG_NAME.fullmatch(path.name):
            continue
        try:
            info = path.lstat()
            if is_link(info) or not stat.S_ISREG(info.st_mode) or info.st_mtime >= cutoff:
                continue
            if args.apply:
                path.unlink()
        except FileNotFoundError:
            continue
        count += 1
        size += info.st_size
    print(f"{'Removed' if args.apply else 'Would remove'}: {count} files, {size} bytes.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except OSError as error:
        sys.exit(f"File operation failed ({type(error).__name__}).")
