#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
from urllib.parse import quote

TOKEN = "__ASSET_VERSION__"


def stamp(path: Path, version: str) -> None:
    text = path.read_text(encoding="utf-8")
    if TOKEN not in text:
        raise SystemExit(f"{path}: asset version token is missing")
    path.write_text(text.replace(TOKEN, quote(version, safe="")), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("html")
    parser.add_argument("version")
    args = parser.parse_args()
    stamp(Path(args.html), args.version)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
