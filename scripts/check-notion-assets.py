#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

MODULE_IMPORT_RE = re.compile(
    r"(?:import|export)\s+(?:[^\"']*?\s+from\s+)?[\"']([^\"']+)[\"']"
)


class AssetParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.refs: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag in {"script", "img", "source"} and values.get("src"):
            self.refs.append(values["src"] or "")
        if tag == "link" and values.get("href"):
            self.refs.append(values["href"] or "")


def local_path(root: Path, source: Path, raw: str) -> Path | None:
    raw = raw.strip()
    if not raw or raw.startswith("#"):
        return None
    parts = urlsplit(raw)
    if parts.scheme or parts.netloc:
        return None
    path = unquote(parts.path)
    if not path:
        return None
    if path.startswith("/"):
        return (root / path.lstrip("/")).resolve()
    return (source.parent / path).resolve()


def find_missing_assets(root: Path) -> list[str]:
    root = root.resolve()
    missing: list[str] = []
    for html in root.rglob("*.html"):
        parser = AssetParser()
        parser.feed(html.read_text(encoding="utf-8"))
        for raw in parser.refs:
            target = local_path(root, html, raw)
            if target is not None and not target.is_file():
                missing.append(f"{html.relative_to(root)} -> {raw}")

    for module in root.rglob("*.mjs"):
        for raw in MODULE_IMPORT_RE.findall(module.read_text(encoding="utf-8")):
            if not raw.startswith((".", "/")):
                continue
            target = local_path(root, module, raw)
            if target is not None and not target.is_file():
                missing.append(f"{module.relative_to(root)} -> {raw}")
    return sorted(set(missing))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root")
    args = parser.parse_args()
    root = Path(args.root)
    missing = find_missing_assets(root)
    if missing:
        print("Missing local Notion Viewer assets:")
        for entry in missing:
            print(" -", entry)
        return 1
    print(f"Notion Viewer asset check passed: {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
