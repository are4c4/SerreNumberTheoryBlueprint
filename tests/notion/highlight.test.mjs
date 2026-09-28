import test from "node:test";
import assert from "node:assert/strict";
import { highlightLeanText, syntaxHighlightLeanLine } from "../../notion/lib/highlight.mjs";

test("shared highlighter escapes HTML", () => {
  assert.match(highlightLeanText("Nat < Nat"), /&lt;/);
});
test("viewer fallback and infoview share keyword classification", () => {
  assert.match(highlightLeanText("theorem"), /lean-hl-keyword/);
  assert.match(syntaxHighlightLeanLine("theorem x -- docs"), /lean-token keyword/);
  assert.match(syntaxHighlightLeanLine("theorem x -- docs"), /lean-token comment/);
});
