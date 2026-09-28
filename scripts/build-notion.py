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
    return path.relative_to(semantic_root).with_suffix(".lean")


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


def semantic_line_map(lines: list[str], raw_items: list[dict]) -> dict[int, str]:
    result: dict[int, str] = {}
    for raw in raw_items:
        start = int(raw.get("startLine") or 1)
        end = int(raw.get("endLine") or start)
        text_lines, html_lines = split_semantic(raw)
        source_segment = lines[start - 1 : end]
        if len(text_lines) == len(source_segment) and text_lines == source_segment:
            for offset, rendered in enumerate(html_lines):
                result[start + offset] = rendered
    return result


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
    for variable in variables:
        rows.append({
            "line": variable["line"],
            "html": html.escape(variable["text"]),
            "text": variable["text"],
            "context": True,
        })
        plain_parts.append(variable["text"])

    if variables:
        rows.append({"line": None, "html": "", "text": "", "context": True})
        plain_parts.append("")

    for line_no in range(display_start, end + 1):
        text = lines[line_no - 1] if 0 <= line_no - 1 < len(lines) else ""
        rows.append({
            "line": line_no,
            "html": semantic_by_line.get(line_no, html.escape(text)),
            "text": text,
            "context": line_no < start,
        })
        plain_parts.append(text)

    return rows, "\n".join(plain_parts)


def raw_rows(
    lines: list[str],
    start: int,
    end: int,
    semantic_by_line: dict[int, str],
) -> tuple[list[dict], str]:
    rows: list[dict] = []
    plain: list[str] = []
    for line_no in range(start, end + 1):
        text = lines[line_no - 1] if 0 <= line_no - 1 < len(lines) else ""
        rows.append({
            "line": line_no,
            "html": semantic_by_line.get(line_no, html.escape(text)),
            "text": text,
            "context": False,
        })
        plain.append(text)
    return rows, "\n".join(plain)


def legacy_key(file: str, kind: str, name: str) -> str:
    return "\x1f".join([file, kind, name])


def add_legacy_targets(
    legacy: dict[str, dict],
    rel_source: str,
    module: str,
    lines: list[str],
    raw_items: list[dict],
) -> None:
    semantic_by_line = semantic_line_map(lines, raw_items)
    scope_re = re.compile(r"^\s*(namespace|section)\s+([^\s]+)\b")
    end_re = re.compile(r"^\s*end(?:\s+[^\s]+)?\s*(?:--.*)?$")
    local_instance_re = re.compile(r"^\s*local\s+instance\b")
    top_command_re = re.compile(
        r"^\s*(?:@\[[^\]]*\]\s*)?"
        r"(?:(?:noncomputable|private|protected)\s+)?"
        r"(?:theorem|lemma|example|def|abbrev|instance|structure|class|inductive|"
        r"namespace|section|end|variable|variables|universe|open|export|include|"
        r"omit|attribute|set_option|local\s+instance)\b"
    )

    stack: list[dict] = []
    for index, line in enumerate(lines, start=1):
        match = scope_re.match(line)
        if match:
            parents = [{"kind": x["kind"], "name": x["name"]} for x in stack]
            stack.append({
                "kind": match.group(1),
                "name": match.group(2),
                "start": index,
                "parents": parents,
            })
            continue

        if end_re.match(line) and stack:
            scope = stack.pop()
            rows, plain = raw_rows(lines, scope["start"], index, semantic_by_line)
            item = {
                "id": f"legacy:{module}:{scope['kind']}:{scope['name']}:{scope['start']}",
                "module": module,
                "file": rel_source,
                "kind": scope["kind"],
                "defines": [],
                "primaryDeclaration": scope["name"],
                "startLine": scope["start"],
                "endLine": index,
                "scopes": scope["parents"],
                "rows": rows,
                "plainText": plain,
            }
            legacy.setdefault(legacy_key(rel_source, scope["kind"], scope["name"]), item)

    for index, line in enumerate(lines, start=1):
        if not local_instance_re.match(line):
            continue
        end = index
        while end < len(lines):
            next_line = lines[end]
            if not next_line.strip() or top_command_re.match(next_line):
                break
            end += 1
        scopes, _ = scope_and_variables(lines, index)
        rows, plain = raw_rows(lines, index, end, semantic_by_line)
        item = {
            "id": f"legacy:{module}:command:{index}",
            "module": module,
            "file": rel_source,
            "kind": "local instance",
            "defines": [],
            "primaryDeclaration": f"line {index}",
            "startLine": index,
            "endLine": end,
            "scopes": scopes,
            "rows": rows,
            "plainText": plain,
        }
        legacy[legacy_key(rel_source, "command", str(index))] = item


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--semantic-root", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--source-root", default=".")
    parser.add_argument("--config", required=True)
    args = parser.parse_args()

    semantic_root = Path(args.semantic_root)
    output = Path(args.output)
    source_root = Path(args.source_root)
    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    source_prefixes = [str(x) for x in config.get("sourcePrefixes", [])]
    output.joinpath("data").mkdir(parents=True, exist_ok=True)

    items: dict[str, dict] = {}
    declarations: dict[str, str] = {}
    short_names: dict[str, list[str]] = {}
    files: dict[str, list[str]] = {}
    legacy_targets: dict[str, dict] = {}

    for semantic_file in sorted(semantic_root.rglob("*.json")):
        rel_source = source_path_from_semantic(semantic_file, semantic_root)
        rel_source_text = str(rel_source)
        if source_prefixes and not any(rel_source_text.startswith(prefix) for prefix in source_prefixes):
            continue

        source_file = source_root / rel_source
        if not source_file.exists():
            continue

        module = str(rel_source.with_suffix("")).replace("/", ".")
        lines = source_file.read_text(encoding="utf-8").splitlines()
        data = json.loads(semantic_file.read_text(encoding="utf-8"))
        raw_items = list(data.get("items", []))

        for index, raw in enumerate(raw_items):
            start = int(raw.get("startLine") or 1)
            end = int(raw.get("endLine") or start)
            defines = [str(x) for x in raw.get("defines", [])]
            scopes, variables = scope_and_variables(lines, start)
            rows, plain_text = make_rows(lines, raw, variables)
            item_id = f"{module}:{index}"
            item = {
                "id": item_id,
                "module": module,
                "file": rel_source_text,
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
            files.setdefault(rel_source_text, []).append(item_id)

            for name in defines:
                declarations[name] = item_id
                short_names.setdefault(name.rsplit(".", 1)[-1], []).append(item_id)

        add_legacy_targets(legacy_targets, rel_source_text, module, lines, raw_items)

    manifest = {
        "schemaVersion": 3,
        "generator": "notion-viewer",
        "siteTitle": str(config.get("siteTitle", "Lean Notion Viewer")),
        "sourcePrefixes": source_prefixes,
        "github": {
            "repository": github_repository(),
            "ref": source_ref(),
        },
        "items": items,
        "declarations": declarations,
        "shortNames": short_names,
        "files": files,
        "legacyTargets": legacy_targets,
    }

    output.joinpath("data", "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
