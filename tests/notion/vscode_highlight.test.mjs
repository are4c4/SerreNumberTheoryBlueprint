import test from "node:test";
import assert from "node:assert/strict";

import {
  mergeSemanticAndTextMate,
  parseJsonc,
  renderTextMateLine,
} from "../../scripts/apply-vscode-highlighting.mjs";

test("JSONC parser keeps URL-like text while stripping comments", () => {
  const value = parseJsonc(`{
    // comment
    "url": "https://example.com/a//b",
    "value": 3 /* block */
  }`);
  assert.equal(value.url, "https://example.com/a//b");
  assert.equal(value.value, 3);
});

test("TextMate renderer emits theme styles", () => {
  const html = renderTextMateLine("theorem", [
    { start: 0, end: 7, text: "theorem", color: "#C586C0", fontStyle: 0 },
  ]);
  assert.match(html, /class="tm-token"/);
  assert.match(html, /color:#C586C0/);
});

test("semantic metadata survives TextMate color overlay", () => {
  const text = "theorem demo";
  const semantic =
    '<span class="lean-token keyword" data-semantic="keyword">theorem</span> ' +
    '<span class="lean-token const" data-semantic="const" data-const-name="demo">demo</span>';
  const segments = [
    { start: 0, end: 7, text: "theorem", color: "#C586C0", fontStyle: 0 },
    { start: 7, end: 8, text: " ", color: "#D4D4D4", fontStyle: 0 },
    { start: 8, end: 12, text: "demo", color: "#DCDCAA", fontStyle: 0 },
  ];
  const html = mergeSemanticAndTextMate(text, semantic, segments);
  assert.match(html, /data-semantic="keyword"/);
  assert.match(html, /data-const-name="demo"/);
  assert.match(html, /color:#C586C0/);
  assert.match(html, /color:#DCDCAA/);
});

test("proof markers survive TextMate overlay", () => {
  const text = "by";
  const semantic =
    '<span class="lean-proof-start lean-goal-marker" data-goals="[]" tabindex="0"></span>' +
    '<span class="lean-token keyword">by</span>' +
    '<span class="lean-proof-end"></span>';
  const segments = [
    { start: 0, end: 2, text: "by", color: "#C586C0", fontStyle: 0 },
  ];
  const html = mergeSemanticAndTextMate(text, semantic, segments);
  assert.match(html, /lean-goal-marker/);
  assert.match(html, /lean-proof-end/);
  assert.match(html, /tm-token/);
});
