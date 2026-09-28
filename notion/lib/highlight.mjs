import { escapeHtml } from "./html.mjs";

const leanKeywords = new Set(["import","open","namespace","section","end","variable","variables","universe","include","omit","where","by","fun","in","let","if","then","else","match","with","theorem","lemma","def","abbrev","example","instance","structure","class","inductive","noncomputable","private","protected","local","exact","intro","apply","rw","simp","constructor","rcases","rintro","have","show","from","calc","using","at"]);
const leanTypes = new Set(["Type","Prop","Sort","Nat","Int","Rat","Bool","String","Unit","Fin","Field","Fintype","CharP","DecidableEq","MvPolynomial","Polynomial","Module","ZMod","Set","List","Option","Subtype","Fact","Prime"]);
const leanLiterals = new Set(["true","false"]);
const leanTokenPattern = /:=|=>|->|<-|≤|≥|≠|⊢|∀|∃|λ|[A-Za-z_][A-Za-z0-9_'.]*|\d+|[()[\]{}:,.^=+\-*\/|]/g;
const punctuationPattern = /^(?::=|=>|->|<-|≤|≥|≠|⊢|∀|∃|λ|[()[\]{}:,.^=+\-*\/|])$/;

export function classifyLeanWord(token) {
  if (leanKeywords.has(token)) return "keyword";
  if (leanTypes.has(token) || /^(?:Type|Sort)_?u?_?\d*$/.test(token)) return "type";
  if (leanLiterals.has(token) || /^\d+$/.test(token)) return "literal";
  if (/^inst/.test(token)) return "implicit";
  if (/^[A-Za-z]$/.test(token) || /^[a-z][A-Za-z0-9_']*$/.test(token)) return "var";
  if (/^[A-Z][A-Za-z0-9_']*(?:\.[A-Za-z0-9_']+)*$/.test(token)) return "const";
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

export function highlightLeanText(text) {
  return mapTokens(text, token => {
    const cls = punctuationPattern.test(token) ? "punct" : classifyLeanWord(token);
    return '<span class="lean-hl-' + cls + '">' + escapeHtml(token) + "</span>";
  });
}

export function syntaxHighlightLeanLine(text) {
  const raw = String(text ?? "");
  if (!raw) return "";
  const commentStart = raw.indexOf("--");
  const code = commentStart >= 0 ? raw.slice(0, commentStart) : raw;
  const comment = commentStart >= 0 ? raw.slice(commentStart) : "";
  const highlighted = mapTokens(code, token => {
    const cls = classifyLeanWord(token);
    if (cls === "keyword") return '<span class="lean-token keyword">' + escapeHtml(token) + "</span>";
    if (cls === "type") return '<span class="lean-token type-like">' + escapeHtml(token) + "</span>";
    if (cls === "literal") return '<span class="lean-token literal">' + escapeHtml(token) + "</span>";
    return escapeHtml(token);
  });
  return comment ? highlighted + '<span class="lean-token comment">' + escapeHtml(comment) + "</span>" : highlighted;
}
