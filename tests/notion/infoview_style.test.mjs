import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";

test("inline goal markers stay zero-width and render no turnstile glyph", () => {
  const css = fs.readFileSync("notion/infoview.css", "utf8");
  assert.match(css, /\.lean-proof-start,\.lean-proof-end\{[^}]*width:0[^}]*pointer-events:none/);
  assert.doesNotMatch(css, /\.lean-goal-marker::before/);
  assert.doesNotMatch(css, /content:"⊢"/);
});
