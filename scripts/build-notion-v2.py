#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
import json
import os
import re
import subprocess
from pathlib import Path


def git_output(*args: str) -> str:
    try:
        return subprocess.check_output(["git", *args], text=True).strip()
    except Exception:
        return ""


def github_repository() -> str:
    value = os.environ.get("GITHUB_REPOSITORY", "").strip()
    if value:
        return value
    remote = git_output("config", "--get", "remote.origin.url")
    if remote.endswith(".git"):
        remote = remote[:-4]
    m = re.search(r"github\.com[:/](.+?/.+)$", remote)
    return m.group(1) if m else ""


def source_ref() -> str:
    return (
        os.environ.get("GITHUB_SHA")
        or os.environ.get("GITHUB_HEAD_REF")
        or git_output("branch", "--show-current")
        or "main"
    )


def source_path_from_semantic(path: Path, semantic_root: Path) -> Path:
    rel = path.relative_to(semantic_root)
    return rel.with_suffix(".lean")


def scope_and_variables(lines: list[str], before_line: int) -> tuple[list[dict], list[dict]]:
    frames: list[dict] = [{"scope": None, "variables": []}]
    scope_re = re.compile(r"^\s*(namespace|section)\s+([^\s]+)\b")
    end_re = re.compile(r"^\s*end(?:\s+[^\s]+)?\s*(?:--.*)?$")
    variable_re = re.compile(r"^\s*variables?\b")

    for index, line in enumerate(lines[: max(0, before_line - 1)], start=1):
        m = scope_re.match(line)
        if m:
            frames.append({
                "scope": {"kind": m.group(1), "name": m.group(2)},
                "variables": [],
            })
            continue
        if end_re.match(line):
            if len(frames) > 1:
                frames.pop()
            continue
        if variable_re.match(line):
            frames[-1]["variables"].append({"line": index, "text": line})

    scopes = [f["scope"] for f in frames if f["scope"]]
    variables = [v for f in frames for v in f["variables"]]
    return scopes, variables


def doc_start(lines: list[str], declaration_start: int) -> int:
    start = declaration_start - 1
    i = start - 1

    while i >= 0 and not lines[i].strip():
        i -= 1

    if i >= 0 and lines[i].strip().endswith("-/"):
        depth = 0
        j = i
        while j >= 0:
            text = lines[j]
            depth += text.count("-/")
            depth -= text.count("/-")
            if depth <= 0 and "/-" in text:
                start = j
                i = j - 1
                break
            j -= 1

    decorator_re = re.compile(r"^\s*(?:@\[.*\]|(?:include|omit)\b.*\bin\s*)$")
    while i >= 0 and decorator_re.match(lines[i]):
        start = i
        i -= 1

    return start + 1


def split_semantic(item: dict) -> tuple[list[str], list[str]]:
    return str(item.get("text", "")).split("\n"), str(item.get("html", "")).split("\n")


def make_rows(lines: list[str], item: dict, variables: list[dict]) -> tuple[list[dict], str]:
    start = int(item.get("startLine") or 1)
    end = int(item.get("endLine") or start)
    display_start = doc_start(lines, start)

    semantic_text, semantic_html = split_semantic(item)
    semantic_by_line: dict[int, str] = {}

    source_segment = lines[start - 1 : end]
    if len(semantic_text) == len(source_segment) and semantic_text == source_segment:
        for offset, rendered in enumerate(semantic_html):
            semantic_by_line[start + offset] = rendered

    rows: list[dict] = []
    plain_parts: list[str] = []

    for v in variables:
        rows.append({"line": v["line"], "html": html.escape(v["text"]), "text": v["text"], "context": True})
        plain_parts.append(v["text"])

    if variables:
        rows.append({"line": None, "html": "", "text": "", "context": True})
        plain_parts.append("")

    for line_no in range(display_start, end + 1):
        text = lines[line_no - 1] if 0 <= line_no - 1 < len(lines) else ""
        rendered = semantic_by_line.get(line_no, html.escape(text))
        rows.append({"line": line_no, "html": rendered, "text": text, "context": line_no < start})
        plain_parts.append(text)

    return rows, "\n".join(plain_parts)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--semantic-root", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--source-root", default=".")
    args = parser.parse_args()

    semantic_root = Path(args.semantic_root)
    output = Path(args.output)
    source_root = Path(args.source_root)
    output.joinpath("data").mkdir(parents=True, exist_ok=True)

    items: dict[str, dict] = {}
    declarations: dict[str, str] = {}
    short_names: dict[str, list[str]] = {}
    files: dict[str, list[str]] = {}

    semantic_files = sorted(semantic_root.rglob("*.json"))
    for semantic_file in semantic_files:
        rel_source = source_path_from_semantic(semantic_file, semantic_root)
        source_file = source_root / rel_source
        if not source_file.exists():
            continue

        module = str(rel_source.with_suffix("")).replace("/", ".")
        lines = source_file.read_text(encoding="utf-8").splitlines()
        data = json.loads(semantic_file.read_text(encoding="utf-8"))

        for index, raw in enumerate(data.get("items", [])):
            start = int(raw.get("startLine") or 1)
            end = int(raw.get("endLine") or start)
            defines = [str(x) for x in raw.get("defines", [])]
            scopes, variables = scope_and_variables(lines, start)
            rows, plain_text = make_rows(lines, raw, variables)
            item_id = f"{module}:{index}"
            item = {
                "id": item_id,
                "module": module,
                "file": str(rel_source),
                "kind": str(raw.get("kind", "")),
                "defines": defines,
                "primaryDeclaration": defines[0] if defines else None,
                "startLine": start,
                "endLine": end,
                "scopes": scopes,
                "rows": rows,
                "plainText": plain_text,
            }
            items[item_id] = item
            files.setdefault(str(rel_source), []).append(item_id)

            for name in defines:
                declarations[name] = item_id
                short = name.rsplit(".", 1)[-1]
                short_names.setdefault(short, []).append(item_id)

    manifest = {
        "schemaVersion": 2,
        "generator": "notion-viewer-v2",
        "github": {
            "repository": github_repository(),
            "ref": source_ref(),
        },
        "items": items,
        "declarations": declarations,
        "shortNames": short_names,
        "files": files,
    }

    output.joinpath("data", "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
