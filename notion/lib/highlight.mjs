import { escapeHtml } from "./html.mjs";

const leanKeywords = new Set(["import","open","namespace","section","end","variable","variables","universe","include","omit","where","by","fun","in","let","if","then","else","match","with","theorem","lemma","def","abbrev","example","instance","structure","class","inductive","noncomputable","private","protected","local","exact","intro","apply","rw","simp","constructor","rcases","rintro","have","show","from","calc","using","at"]);
const leanTypes = new Set(["Type","Prop","Sort","Nat","Int","Rat","Bool","String","Unit","Fin","Field","Fintype","CharP","DecidableEq","MvPolynomial","Polynomial","Module","ZMod","Set","List","Option","Subtype","Fact","Prime","ℕ","ℤ","ℚ","ℝ","ℂ"]);
const leanLiterals = new Set(["true","false"]);
const leanTokenPattern = /:=|=>|->|<-|≤|≥|≠|⊢|∀|∃|λ|[\p{L}_][\p{L}\p{N}_']*(?:\.[\p{L}_][\p{L}\p{N}_']*)*|\d+|[()[\]{}:,.^=+\-*\/|]/gu;
const punctuationPattern = /^(?::=|=>|->|<-|≤|≥|≠|⊢|∀|∃|λ|[()[\]{}:,.^=+\-*\/|])$/u;
const bracketTokens = new Set(["(", ")", "[", "]", "{", "}"]);
const openingBrackets = new Set(["(", "[", "{"]);
const closingBrackets = new Set([")", "]", "}"]);

export function classifyLeanWord(token) {
  if (leanKeywords.has(token)) return "keyword";
  if (leanTypes.has(token) || /^(?:Type|Sort)_?u?_?\d*$/.test(token)) return "type";
  if (leanLiterals.has(token) || /^\d+$/.test(token)) return "literal";
  if (/^inst/.test(token)) return "implicit";
  if (/^[\p{L}_][\p{L}\p{N}_']*$/u.test(token) && /^[a-z_]/.test(token)) return "var";
  if (/^[\p{Lu}][\p{L}\p{N}_']*(?:\.[\p{L}_][\p{L}\p{N}_']*)*$/u.test(token)) return "const";
  return "ident";
}

function mapTokens(raw, renderToken) {
  const text = String(raw ?? "");
  let out = "";
  let last = 0;
  for (const match of text.matchAll(leanTokenPattern)) {
    const token = match[0];
    const index = match.index ?? 0;
    out += escapeHtml(text.slice(last, index));
    out += renderToken(token);
    last = index + token.length;
  }
  return out + escapeHtml(text.slice(last));
}

export function bracketDepthClass(token, state) {
  if (!bracketTokens.has(token)) return "";
  const holder = state || {depth:0};
  if (closingBrackets.has(token)) holder.depth = Math.max(0, holder.depth - 1);
  const depthClass = "bracket-depth-" + (holder.depth % 3);
  if (openingBrackets.has(token)) holder.depth += 1;
  return depthClass;
}

function isDeclarationToken(token, declarationName) {
  const name = String(declarationName || "").trim();
  if (!name) return false;
  const shortName = name.split(".").at(-1) || name;
  return token === name || token === shortName || name.endsWith("." + token);
}

function fallbackTokenHtml(token, bracketState, declarationName) {
  if (bracketTokens.has(token)) {
    const depthClass = bracketDepthClass(token, bracketState);
    return '<span class="lean-token bracket ' + depthClass + '">' + escapeHtml(token) + "</span>";
  }
  if (isDeclarationToken(token, declarationName)) {
    return '<span class="lean-token declaration definition-site">' + escapeHtml(token) + "</span>";
  }
  const cls = punctuationPattern.test(token) ? "punct" : classifyLeanWord(token);
  if (cls === "keyword") return '<span class="lean-token keyword">' + escapeHtml(token) + "</span>";
  if (cls === "type") return '<span class="lean-token type-like">' + escapeHtml(token) + "</span>";
  if (cls === "literal") return '<span class="lean-token literal">' + escapeHtml(token) + "</span>";
  if (cls === "var") return '<span class="lean-token var">' + escapeHtml(token) + "</span>";
  if (cls === "implicit") return '<span class="lean-token variable-token">' + escapeHtml(token) + "</span>";
  if (cls === "const") return '<span class="lean-token const">' + escapeHtml(token) + "</span>";
  if (cls === "punct") return '<span class="lean-token operator">' + escapeHtml(token) + "</span>";
  return '<span class="lean-token">' + escapeHtml(token) + "</span>";
}

export function highlightLeanText(text, options = {}) {
  const bracketState = {depth:0};
  return mapTokens(text, token => fallbackTokenHtml(token, bracketState, options.declarationName));
}

export function highlightLeanSignature(text, declarationName) {
  return highlightLeanText(text, {declarationName});
}

export function highlightLeanDocCommentLine(text) {
  const raw = String(text ?? "");
  let html = "";
  let last = 0;
  for (const match of raw.matchAll(/`[^`]*`/g)) {
    const index = match.index ?? 0;
    html += escapeHtml(raw.slice(last, index));
    html += '<span class="doc-comment-code">' + escapeHtml(match[0]) + "</span>";
    last = index + match[0].length;
  }
  return html + escapeHtml(raw.slice(last));
}

export function syntaxHighlightLeanLine(text) {
  const raw = String(text ?? "");
  if (!raw) return "";
  const commentStart = raw.indexOf("--");
  const code = commentStart >= 0 ? raw.slice(0, commentStart) : raw;
  const comment = commentStart >= 0 ? raw.slice(commentStart) : "";
  const bracketState = {depth:0};
  const highlighted = mapTokens(code, token => fallbackTokenHtml(token, bracketState, ""));
  return comment ? highlighted + '<span class="lean-token comment">' + escapeHtml(comment) + "</span>" : highlighted;
}
