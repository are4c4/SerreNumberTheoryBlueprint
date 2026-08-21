#!/usr/bin/env python3
"""Sync Notion notes, then build MiniBlueprint HTML.

Authentication priority:
  1. NOTION_API_KEY / NOTION_TOKEN environment variable
  2. repository-local `.env.local` containing NOTION_API_KEY=...

If no token is present, the checked-in Notion snapshots are kept and the
Blueprint is still built. This makes CI/local builds deterministic while
allowing an authenticated local build to refresh Notion automatically.
"""

from __future__ import annotations

import html
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOTION_VERSION = "2026-03-11"
SECTION_PAGE_ID = "3b9db819351e80808a8bca912f2510a5"  # 1.1.1_有限体
COR01_PAGE_ID = "3b9db819351e80a2a54cf8f5b7d10a59"   # 1.1.1_Cor01
NOTION_LEAN_PATH = ROOT / "MiniBlueprint/Notion/Section010101FiniteFields.lean"
NOTION_HTML_PATH = ROOT / "MiniBlueprint/Notion/Section010101FiniteFields.html"


def load_local_env() -> None:
    path = ROOT / ".env.local"
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


load_local_env()
TOKEN = os.environ.get("NOTION_API_KEY") or os.environ.get("NOTION_TOKEN")
_page_title_cache: dict[str, str] = {}


def request_json(path: str, method: str = "GET", body: dict | None = None) -> dict:
    if not TOKEN:
        raise RuntimeError("NOTION_API_KEY is not set")
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        f"https://api.notion.com/v1/{path}",
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "Notion-Version": NOTION_VERSION,
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Notion API {exc.code}: {detail}") from exc


def page_title(page: dict) -> str:
    for prop in page.get("properties", {}).values():
        if prop.get("type") == "title":
            return rich_text_plain(prop.get("title", []))
    return ""


def retrieve_page(page_id: str) -> dict:
    return request_json(f"pages/{page_id}")


def resolve_page_title(page_id: str) -> str:
    normalized = page_id.replace("-", "")
    if normalized in _page_title_cache:
        return _page_title_cache[normalized]
    try:
        title = page_title(retrieve_page(page_id)) or "Notion page"
    except Exception:
        title = "Notion page"
    _page_title_cache[normalized] = title
    return title


def page_url_from_id(page_id: str) -> str:
    return f"https://www.notion.so/{page_id.replace('-', '')}"


def rich_text_plain(items: list[dict]) -> str:
    parts: list[str] = []
    for item in items:
        kind = item.get("type")
        if kind == "text":
            parts.append(item.get("plain_text") or item.get("text", {}).get("content", ""))
        elif kind == "equation":
            expr = item.get("equation", {}).get("expression", "")
            parts.append(f"\\({expr}\\)")
        elif kind == "mention":
            mention = item.get("mention", {})
            if mention.get("type") == "page":
                pid = mention.get("page", {}).get("id", "")
                parts.append(resolve_page_title(pid) if pid else "Notion page")
            else:
                parts.append(item.get("plain_text", ""))
        else:
            parts.append(item.get("plain_text", ""))
    return "".join(parts)


def rich_text_html(items: list[dict]) -> str:
    parts: list[str] = []
    for item in items:
        kind = item.get("type")
        if kind == "equation":
            expr = item.get("equation", {}).get("expression", "")
            piece = f"\\({html.escape(expr)}\\)"
        elif kind == "mention" and item.get("mention", {}).get("type") == "page":
            pid = item.get("mention", {}).get("page", {}).get("id", "")
            label = resolve_page_title(pid) if pid else (item.get("plain_text") or "Notion page")
            piece = (
                f'<a class="notion-mention" href="{html.escape(page_url_from_id(pid))}" '
                f'target="_blank" rel="noopener noreferrer">{html.escape(label)}</a>'
            )
        else:
            text = item.get("plain_text") or item.get("text", {}).get("content", "")
            piece = html.escape(text)
            href = item.get("href")
            if href:
                piece = f'<a class="notion-mention" href="{html.escape(href)}" target="_blank" rel="noopener noreferrer">{piece}</a>'

        ann = item.get("annotations", {})
        if ann.get("code"):
            piece = f"<code>{piece}</code>"
        if ann.get("bold"):
            piece = f"<strong>{piece}</strong>"
        if ann.get("italic"):
            piece = f"<em>{piece}</em>"
        if ann.get("strikethrough"):
            piece = f"<s>{piece}</s>"
        if ann.get("underline"):
            piece = f"<u>{piece}</u>"
        parts.append(piece)
    return "".join(parts)


def block_children(block_id: str) -> list[dict]:
    results: list[dict] = []
    cursor: str | None = None
    while True:
        suffix = "?page_size=100"
        if cursor:
            from urllib.parse import quote
            suffix += f"&start_cursor={quote(cursor)}"
        payload = request_json(f"blocks/{block_id}/children{suffix}")
        results.extend(payload.get("results", []))
        if not payload.get("has_more"):
            return results
        cursor = payload.get("next_cursor")


def render_children(block_id: str, depth: int = 0) -> str:
    return "\n".join(render_block(block, depth) for block in block_children(block_id))


def render_block(block: dict, depth: int = 0) -> str:
    kind = block.get("type", "")
    data = block.get(kind, {}) if kind else {}
    bid = block.get("id", "")
    content = rich_text_html(data.get("rich_text", []))
    children = render_children(bid, depth + 1) if block.get("has_children") else ""

    if kind == "paragraph":
        return (f"<p>{content}</p>" if content else "") + children
    if kind == "equation":
        expr = data.get("expression", "")
        return f'<div class="notion-equation">\\[{html.escape(expr)}\\]</div>' + children
    if kind in {"heading_1", "heading_2", "heading_3"}:
        level = {"heading_1": 2, "heading_2": 3, "heading_3": 4}[kind]
        if data.get("is_toggleable") or children:
            return (
                '<details class="notion-toggle">'
                f"<summary>{content}</summary>"
                f'<div class="notion-toggle-body">{children}</div></details>'
            )
        return f"<h{level}>{content}</h{level}>"
    if kind == "toggle":
        return (
            '<details class="notion-toggle">'
            f"<summary>{content}</summary>"
            f'<div class="notion-toggle-body">{children}</div></details>'
        )
    if kind == "callout":
        icon = data.get("icon", {})
        emoji = icon.get("emoji", "") if icon.get("type") == "emoji" else ""
        return f'<div class="notion-callout">{html.escape(emoji)} {content}{children}</div>'
    if kind == "synced_block":
        return children
    if kind == "divider":
        return "<hr>"
    if kind in {"bulleted_list_item", "numbered_list_item"}:
        return f'<div class="notion-list-item">• {content}{children}</div>'
    if kind == "quote":
        return f"<blockquote>{content}{children}</blockquote>"
    if kind == "code":
        language = html.escape(data.get("language", ""))
        return f'<pre><code data-language="{language}">{html.escape(rich_text_plain(data.get("rich_text", [])))}</code></pre>'
    if kind in {"bookmark", "link_preview"}:
        url = data.get("url", "")
        return f'<p><a class="notion-mention" href="{html.escape(url)}" target="_blank">{html.escape(url)}</a></p>'
    if kind in {"child_page", "child_database"}:
        title = data.get("title", kind)
        return f"<p>{html.escape(title)}</p>"
    # Unsupported visual blocks are omitted, but their children are retained.
    return children


def property_text(page: dict, name: str) -> str:
    prop = page.get("properties", {}).get(name, {})
    typ = prop.get("type")
    if typ == "rich_text":
        return rich_text_plain(prop.get("rich_text", []))
    if typ == "title":
        return rich_text_plain(prop.get("title", []))
    return ""


def first_statement(page_id: str) -> str:
    """Return the first substantial paragraph-like statement from the page."""
    def walk(blocks: list[dict]) -> str:
        for block in blocks:
            kind = block.get("type", "")
            data = block.get(kind, {}) if kind else {}
            if kind == "paragraph":
                text = rich_text_plain(data.get("rich_text", [])).strip()
                if text:
                    return text
            if block.get("has_children"):
                found = walk(block_children(block.get("id", "")))
                if found:
                    return found
        return ""
    return walk(block_children(page_id))


def lean_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def generate_lean_snapshot(cor_page: dict) -> str:
    title = page_title(cor_page) or "1.1.1_Cor01"
    declaration_text = property_text(cor_page, "Lean declarations")
    declarations = [line.strip() for line in declaration_text.splitlines() if line.strip()]
    primary = declarations[0] if declarations else ""
    statement = first_statement(COR01_PAGE_ID)
    url = cor_page.get("public_url") or cor_page.get("url") or page_url_from_id(COR01_PAGE_ID)
    return f'''import MiniBlueprint.Entry\n\nset_option autoImplicit false\n\nnamespace MiniBlueprint.Notion.Section010101\n\n/-- Auto-generated from Notion by `scripts/build_blueprint.py`. -/\ndef pageUrl : String :=\n  {lean_string(page_url_from_id(SECTION_PAGE_ID))}\n\n/-- Notion theorem page linked to a Lean declaration. -/\ndef cor01PageUrl : String :=\n  {lean_string(url)}\n\ndef cor01Title : String :=\n  {lean_string(title)}\n\ndef cor01Statement : String :=\n  {lean_string(statement)}\n\ndef cor01LeanDeclarations : Array String :=\n  #[''' + ", ".join(lean_string(x) for x in declarations) + ''']\n\ndef cor01PrimaryLeanDeclaration : String :=\n  ''' + lean_string(primary) + '''\n\nend MiniBlueprint.Notion.Section010101\n'''


def generate_section_html(section_page: dict) -> str:
    title = page_title(section_page) or "1.1.1_有限体"
    url = section_page.get("public_url") or section_page.get("url") or page_url_from_id(SECTION_PAGE_ID)
    body = render_children(SECTION_PAGE_ID)
    return f'''<section class="notion-import" data-notion-page="{SECTION_PAGE_ID}">\n  <div class="notion-source-bar">\n    <span>Notion · auto synced</span>\n    <a href="{html.escape(url)}" target="_blank" rel="noopener noreferrer">{html.escape(title)} ↗</a>\n  </div>\n{body}\n</section>\n'''


def sync_notion() -> bool:
    if not TOKEN:
        print("[Notion] NOTION_API_KEY is not set; using checked-in snapshots.")
        return False
    print("[Notion] Fetching latest pages...")
    section_page = retrieve_page(SECTION_PAGE_ID)
    cor_page = retrieve_page(COR01_PAGE_ID)
    NOTION_LEAN_PATH.write_text(generate_lean_snapshot(cor_page), encoding="utf-8")
    NOTION_HTML_PATH.write_text(generate_section_html(section_page), encoding="utf-8")
    print(f"[Notion] Synced {page_title(section_page)}")
    print(
        "[Notion] Lean declarations: "
        + (property_text(cor_page, "Lean declarations") or "(none)")
    )
    return True


def build_blueprint() -> None:
    print("[Blueprint] Running lake exe miniblueprint-html ...")
    subprocess.run(
        ["lake", "exe", "miniblueprint-html"],
        cwd=ROOT,
        check=True,
    )


def main() -> int:
    try:
        sync_notion()
        build_blueprint()
        print(f"[Blueprint] Generated {ROOT / 'blueprint.html'}")
        return 0
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
