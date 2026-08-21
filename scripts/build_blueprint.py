#!/usr/bin/env python3
"""Sync Notion notes, then build MiniBlueprint HTML.

Authentication priority:
  1. NOTION_API_KEY / NOTION_TOKEN environment variable
  2. repository-local `.env.local` containing NOTION_API_KEY=...

The script scans the whole Number Theory data source, selects pages in the
current section whose `Lean declarations` property is non-empty, and emits
Notion/Lean pairs automatically. If no token is present, checked-in snapshots
are kept so ordinary CI builds remain deterministic.
"""

from __future__ import annotations

import html
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOTION_VERSION = "2026-03-11"
DATA_SOURCE_ID = "3b9db819-351e-809f-9063-000b6cecd6de"  # 数論講義DB
SECTION_PAGE_ID = "3b9db819351e80808a8bca912f2510a5"     # 1.1.1_有限体
SECTION_PREFIX = "1.1.1"
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
    for prop in (page.get("properties") or {}).values():
        if (prop or {}).get("type") == "title":
            return rich_text_plain((prop or {}).get("title") or [])
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
    for item in items or []:
        item = item or {}
        kind = item.get("type")
        if kind == "text":
            text_data = item.get("text") or {}
            parts.append(item.get("plain_text") or text_data.get("content", ""))
        elif kind == "equation":
            expr = (item.get("equation") or {}).get("expression", "")
            parts.append(f"\\({expr}\\)")
        elif kind == "mention":
            mention = item.get("mention") or {}
            if mention.get("type") == "page":
                pid = (mention.get("page") or {}).get("id", "")
                parts.append(resolve_page_title(pid) if pid else "Notion page")
            else:
                parts.append(item.get("plain_text", ""))
        else:
            parts.append(item.get("plain_text", ""))
    return "".join(parts)


def rich_text_html(items: list[dict]) -> str:
    parts: list[str] = []
    for item in items or []:
        item = item or {}
        kind = item.get("type")
        mention = item.get("mention") or {}
        if kind == "equation":
            expr = (item.get("equation") or {}).get("expression", "")
            piece = f"\\({html.escape(expr)}\\)"
        elif kind == "mention" and mention.get("type") == "page":
            pid = (mention.get("page") or {}).get("id", "")
            label = resolve_page_title(pid) if pid else (item.get("plain_text") or "Notion page")
            piece = (
                f'<a class="notion-mention" href="{html.escape(page_url_from_id(pid))}" '
                f'target="_blank" rel="noopener noreferrer">{html.escape(label)}</a>'
            )
        else:
            text_data = item.get("text") or {}
            text = item.get("plain_text") or text_data.get("content", "")
            piece = html.escape(text)
            href = item.get("href")
            if href:
                piece = f'<a class="notion-mention" href="{html.escape(href)}" target="_blank" rel="noopener noreferrer">{piece}</a>'

        ann = item.get("annotations") or {}
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
        results.extend(payload.get("results") or [])
        if not payload.get("has_more"):
            return results
        cursor = payload.get("next_cursor")


def render_children(block_id: str, depth: int = 0) -> str:
    return "\n".join(render_block(block, depth) for block in block_children(block_id))


def render_block(block: dict, depth: int = 0) -> str:
    block = block or {}
    kind = block.get("type", "")
    data = (block.get(kind) or {}) if kind else {}
    bid = block.get("id", "")
    content = rich_text_html(data.get("rich_text") or [])
    children = render_children(bid, depth + 1) if block.get("has_children") else ""

    if kind == "paragraph":
        return (f"<p>{content}</p>" if content else "") + children
    if kind == "equation":
        expr = data.get("expression", "") or ""
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
        icon = data.get("icon") or {}
        emoji = icon.get("emoji", "") if icon.get("type") == "emoji" else ""
        return f'<div class="notion-callout">{html.escape(emoji)} {content}{children}</div>'
    if kind == "synced_block":
        return children
    if kind == "divider":
        return "<hr>"
    if kind in {"bulleted_list_item", "numbered_list_item"}:
        bullet = "•" if kind == "bulleted_list_item" else "1."
        return f'<div class="notion-list-item">{bullet} {content}{children}</div>'
    if kind == "quote":
        return f"<blockquote>{content}{children}</blockquote>"
    if kind == "code":
        language = html.escape(data.get("language", "") or "")
        return f'<pre><code data-language="{language}">{html.escape(rich_text_plain(data.get("rich_text") or []))}</code></pre>'
    if kind in {"bookmark", "link_preview"}:
        url = data.get("url", "") or ""
        return f'<p><a class="notion-mention" href="{html.escape(url)}" target="_blank" rel="noopener noreferrer">{html.escape(url)}</a></p>'
    if kind in {"child_page", "child_database"}:
        title = data.get("title", kind) or kind
        return f"<p>{html.escape(title)}</p>"
    return children


def property_text(page: dict, name: str) -> str:
    prop = (page.get("properties") or {}).get(name) or {}
    typ = prop.get("type")
    if typ == "rich_text":
        return rich_text_plain(prop.get("rich_text") or [])
    if typ == "title":
        return rich_text_plain(prop.get("title") or [])
    return ""


def property_multi_select(page: dict, name: str) -> list[str]:
    prop = (page.get("properties") or {}).get(name) or {}
    if prop.get("type") != "multi_select":
        return []
    return [str(item.get("name", "")) for item in (prop.get("multi_select") or []) if item]


def first_statement(page_id: str) -> str:
    """Return the first substantial paragraph-like statement from a page."""
    def walk(blocks: list[dict]) -> str:
        for block in blocks:
            block = block or {}
            kind = block.get("type", "")
            data = (block.get(kind) or {}) if kind else {}
            if kind == "paragraph":
                text = rich_text_plain(data.get("rich_text") or []).strip()
                if text:
                    return text
            if block.get("has_children"):
                found = walk(block_children(block.get("id", "")))
                if found:
                    return found
        return ""
    return walk(block_children(page_id))


def query_data_source_pages() -> list[dict]:
    """Query every row in the Number Theory data source with pagination."""
    pages: list[dict] = []
    cursor: str | None = None
    while True:
        body: dict[str, object] = {"page_size": 100}
        if cursor:
            body["start_cursor"] = cursor
        payload = request_json(
            f"data_sources/{DATA_SOURCE_ID}/query",
            method="POST",
            body=body,
        )
        pages.extend(page for page in (payload.get("results") or []) if (page or {}).get("object") == "page")
        if not payload.get("has_more"):
            return pages
        cursor = payload.get("next_cursor")


def section_linked_pages() -> list[dict]:
    """Scan the whole DB, then keep linked pages belonging to this section."""
    linked: list[dict] = []
    for page in query_data_source_pages():
        title = page_title(page)
        declaration_text = property_text(page, "Lean declarations").strip()
        if not declaration_text:
            continue
        if not (title == SECTION_PREFIX or title.startswith(SECTION_PREFIX + "_")):
            continue
        linked.append(page)
    linked.sort(key=lambda page: page_title(page))
    return linked


def lean_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def lean_array(values: list[str]) -> str:
    return "#[" + ", ".join(lean_string(value) for value in values) + "]"


def marker_for_page(page_id: str) -> str:
    compact = re.sub(r"[^A-Za-z0-9]", "", page_id)
    return f"__NOTION_LINKED_{compact}__"


def linked_page_record(page: dict) -> dict[str, object]:
    page_id = str(page.get("id", ""))
    title = page_title(page) or page_id
    declaration_text = property_text(page, "Lean declarations")
    declarations = [line.strip() for line in declaration_text.splitlines() if line.strip()]
    types = property_multi_select(page, "タイプ")
    kind = "Definition" if "Definition" in types else "Theorem"
    statement = first_statement(page_id)
    url = page.get("public_url") or page.get("url") or page_url_from_id(page_id)
    body = render_children(page_id)
    page_html = f'''<section class="notion-linked-entry" id="notion-{html.escape(page_id.replace('-', ''))}">
  <div class="notion-linked-header">
    <span>{html.escape(kind)}</span>
    <a href="{html.escape(str(url))}" target="_blank" rel="noopener noreferrer">{html.escape(title)} ↗</a>
  </div>
{body}
</section>'''
    return {
        "id": page_id,
        "title": title,
        "url": str(url),
        "statement": statement,
        "kind": kind,
        "declarations": declarations,
        "marker": marker_for_page(page_id),
        "html": page_html,
    }


def generate_lean_snapshot(linked_pages: list[dict]) -> str:
    records = [linked_page_record(page) for page in linked_pages]
    items: list[str] = []
    for record in records:
        declarations = list(record["declarations"])
        primary = declarations[0] if declarations else ""
        items.append(
            "  { pageId := " + lean_string(str(record["id"]))
            + ", title := " + lean_string(str(record["title"]))
            + ", pageUrl := " + lean_string(str(record["url"]))
            + ", statement := " + lean_string(str(record["statement"]))
            + ", kind := " + lean_string(str(record["kind"]))
            + ", leanDeclarations := " + lean_array(declarations)
            + ", primaryLeanDeclaration := " + lean_string(primary)
            + ", htmlMarker := " + lean_string(str(record["marker"]))
            + ", html := " + lean_string(str(record["html"]))
            + " }"
        )
    items_text = "#[\n" + ",\n".join(items) + "\n]" if items else "#[]"
    return f'''import MiniBlueprint.Entry

set_option autoImplicit false

namespace MiniBlueprint.Notion.Section010101

structure LinkedPage where
  pageId : String
  title : String
  pageUrl : String
  statement : String
  kind : String
  leanDeclarations : Array String
  primaryLeanDeclaration : String
  htmlMarker : String
  html : String
deriving Repr

/-- Auto-generated from the Notion Number Theory database. -/
def pageUrl : String :=
  {lean_string(page_url_from_id(SECTION_PAGE_ID))}

/-- Pages in section 1.1.1 whose `Lean declarations` property is non-empty. -/
def linkedPages : Array LinkedPage :=
  {items_text}

end MiniBlueprint.Notion.Section010101
'''


def generate_section_html(section_page: dict) -> str:
    title = page_title(section_page) or "1.1.1_有限体"
    url = section_page.get("public_url") or section_page.get("url") or page_url_from_id(SECTION_PAGE_ID)
    body = render_children(SECTION_PAGE_ID)
    return f'''<section class="notion-import" data-notion-page="{SECTION_PAGE_ID}">
  <div class="notion-source-bar">
    <span>Notion · auto synced</span>
    <a href="{html.escape(str(url))}" target="_blank" rel="noopener noreferrer">{html.escape(title)} ↗</a>
  </div>
{body}
</section>
'''


def sync_notion() -> bool:
    if not TOKEN:
        print("[Notion] NOTION_API_KEY is not set; using checked-in snapshots.")
        return False
    print("[Notion] Fetching latest pages...")
    section_page = retrieve_page(SECTION_PAGE_ID)
    linked_pages = section_linked_pages()
    NOTION_LEAN_PATH.write_text(generate_lean_snapshot(linked_pages), encoding="utf-8")
    NOTION_HTML_PATH.write_text(generate_section_html(section_page), encoding="utf-8")
    print(f"[Notion] Synced {page_title(section_page)}")
    print(f"[Notion] Linked pages detected: {len(linked_pages)}")
    for page in linked_pages:
        print(
            f"  - {page_title(page)} -> "
            + property_text(page, "Lean declarations").replace("\n", ", ")
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
