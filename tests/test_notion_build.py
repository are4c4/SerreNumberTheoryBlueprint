from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_module(name: str, relative: str):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


build = load_module("build_notion", "scripts/build-notion.py")
assets = load_module("check_notion_assets", "scripts/check-notion-assets.py")


class BuildNotionTests(unittest.TestCase):
    def test_doc_comment_is_included(self):
        lines = ["/-- docs -/", "theorem demo : True := by", "  trivial"]
        self.assertEqual(build.doc_start(lines, 2), 1)

    def test_declaration_line_skips_attached_doc_comment(self):
        lines = [
            "/--",
            "docs",
            "-/",
            "private theorem demo : True := by",
            "  trivial",
        ]
        self.assertEqual(build.declaration_line(lines, 1, 5, "theorem"), 4)

    def test_declaration_line_handles_attributes_and_modifiers(self):
        lines = [
            "/-- docs -/",
            "@[simp] protected theorem demo : True := by",
            "  trivial",
        ]
        self.assertEqual(build.declaration_line(lines, 1, 3, "theorem"), 2)

    def test_semantic_rows_align_after_whitespace_normalization(self):
        lines = ["theorem demo : True := by", "  trivial"]
        item = {
            "startLine": 1,
            "endLine": 2,
            "text": "theorem  demo : True := by\ntrivial\n",
            "html": "<span>A</span>\n<span>B</span>\n",
        }
        mapped = build.semantic_by_line_for_range(lines, item)
        self.assertEqual(mapped[1], "<span>A</span>")
        self.assertEqual(mapped[2], "<span>B</span>")


class AssetCheckTests(unittest.TestCase):
    def test_checks_html_and_module_imports(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "index.html").write_text(
                '<link rel="stylesheet" href="viewer.css?v=abc">'
                '<script type="module" src="viewer.mjs?v=abc"></script>',
                encoding="utf-8",
            )
            (root / "viewer.css").write_text("", encoding="utf-8")
            (root / "viewer.mjs").write_text('import "./lib/helper.mjs";', encoding="utf-8")
            (root / "lib").mkdir()
            (root / "lib" / "helper.mjs").write_text("export const ok = true;", encoding="utf-8")
            self.assertEqual(assets.find_missing_assets(root), [])

    def test_reports_missing_asset(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "index.html").write_text('<script src="missing.js"></script>', encoding="utf-8")
            self.assertEqual(assets.find_missing_assets(root), ["index.html -> missing.js"])


if __name__ == "__main__":
    unittest.main()
