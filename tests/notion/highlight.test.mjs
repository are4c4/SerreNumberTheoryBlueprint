import test from "node:test";
import assert from "node:assert/strict";
import { bracketDepthClass, highlightLeanDocCommentLine, highlightLeanSignature, highlightLeanText, syntaxHighlightLeanLine } from "../../notion/lib/highlight.mjs";

test("shared highlighter escapes HTML", () => {
  assert.match(highlightLeanText("Nat < Nat"), /&lt;/);
});

test("viewer fallback and infoview use the same Lean token classes", () => {
  assert.match(highlightLeanText("theorem"), /lean-token keyword/);
  assert.match(syntaxHighlightLeanLine("theorem x -- docs"), /lean-token keyword/);
  assert.match(syntaxHighlightLeanLine("theorem x -- docs"), /lean-token comment/);
});

test("signature highlighter marks the declaration name like source declarations", () => {
  const html = highlightLeanSignature("Foo.bar.{u_1} (x : Nat) : Nat", "Foo.bar");
  assert.match(html, /lean-token declaration definition-site/);
  assert.match(html, /lean-token bracket bracket-depth-0/);
  assert.match(html, /lean-token type-like/);
});

test("unicode Lean types are tokenized", () => {
  assert.match(highlightLeanText("(p : ℕ)"), /lean-token type-like[^>]*>ℕ</);
});

test("doc comments render backtick spans with the VS Code inline-code class", () => {
  const html = highlightLeanDocCommentLine("`p`乗写像は `0` を `0` に送る。");
  assert.equal((html.match(/doc-comment-code/g) || []).length, 3);
  assert.match(html, /<span class="doc-comment-code">`p`<\/span>/);
});

test("bracket pair depth cycles like VS Code bracket pair colorization", () => {
  const state = {depth:0};
  assert.equal(bracketDepthClass("(", state), "bracket-depth-0");
  assert.equal(bracketDepthClass("(", state), "bracket-depth-1");
  assert.equal(bracketDepthClass(")", state), "bracket-depth-1");
  assert.equal(bracketDepthClass(")", state), "bracket-depth-0");
});

test("popup highlighter adds bracket depth classes using source token classes", () => {
  const html = highlightLeanText("F (G (x))");
  assert.match(html, /lean-token bracket bracket-depth-0/);
  assert.match(html, /lean-token bracket bracket-depth-1/);
});
