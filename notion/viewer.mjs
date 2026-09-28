import { escapeHtml } from "./lib/html.mjs";
import { bracketDepthClass, highlightLeanDocCommentLine, syntaxHighlightLeanLine } from "./lib/highlight.mjs";
import { getBuildVersion, getJson } from "./lib/data.mjs";
import { displayKind, githubUrl, resolveItem } from "./lib/manifest.mjs";
import { proofStateForItem, renderProofGutterRows } from "./lib/proof.mjs";

const params = new URLSearchParams(location.search);
const codeWrap = document.getElementById("codeWrap");
const copyBtn = document.getElementById("copyBtn");
const fileName = document.getElementById("fileName");
const githubBtn = document.getElementById("githubBtn");
const targetRow = document.getElementById("targetRow");
const targetBadge = document.getElementById("targetBadge");
const targetName = document.getElementById("targetName");
const scopeWrap = document.getElementById("scopeWrap");
const scopeRow = document.getElementById("scopeRow");
let displayedCode = "";
let currentBuildVersion = null;

const qualifiedIdentifierPattern = /^[A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)+$/;

function isConstantLikeToken(token, semantic) {
  return semantic === "const" || semantic === "constructor" || token.classList.contains("function-like") || token.classList.contains("const") || token.classList.contains("member-like") || token.classList.contains("declaration");
}

function classifyLeanToken(token) {
  const semantic = token.dataset.semantic || "";
  if (semantic) token.classList.add("semantic-" + semantic);
  if (semantic === "variable") token.classList.add("variable-token");
  const text = token.textContent || "";
  const constantLike = isConstantLikeToken(token, semantic);
  if (constantLike) token.classList.add("constant-like");
  if (constantLike && token.dataset.definitionSite === "true") token.classList.add("definition-site");
  if (constantLike && qualifiedIdentifierPattern.test(text)) {
    const lastDot = text.lastIndexOf(".");
    const prefix = document.createElement("span");
    prefix.className = "lean-qualified-prefix";
    prefix.textContent = text.slice(0, lastDot);
    const dot = document.createElement("span");
    dot.className = "lean-qualified-dot";
    dot.textContent = ".";
    const member = document.createElement("span");
    member.className = "lean-qualified-member";
    member.textContent = text.slice(lastDot + 1);
    token.classList.add("qualified-const");
    token.replaceChildren(prefix, dot, member);
    return;
  }
  if (constantLike && /^[A-ZΑ-Ω]/u.test(text)) token.classList.add("type-const");
}

function improveLeanTokenHtml(html, bracketState) {
  const template = document.createElement("template");
  template.innerHTML = html;
  template.content.querySelectorAll(".lean-token").forEach(classifyLeanToken);
  template.content.querySelectorAll(".lean-token.bracket").forEach(token => {
    const depthClass = bracketDepthClass(token.textContent || "", bracketState);
    if (depthClass) token.classList.add(depthClass);
  });
  return template.innerHTML;
}

function rowHtml(row, bracketState) {
  const rendered = String(row.html || "");
  const html = rendered.includes("lean-token") ? rendered : syntaxHighlightLeanLine(row.text || "");
  return improveLeanTokenHtml(html, bracketState);
}

function updateScopes(scopes) {
  if (!scopes?.length) {
    scopeWrap.hidden = true;
    scopeRow.replaceChildren();
    return;
  }
  scopeWrap.hidden = false;
  scopeRow.innerHTML = scopes.map((scope, index) => {
    const separator = index ? '<span class="scope-sep">›</span>' : "";
    return separator + '<span class="scope-chip"><span class="scope-kind">' + escapeHtml(scope.kind) + "</span>" + escapeHtml(scope.name) + "</span>";
  }).join("");
}

function lockReadonlyCaret(codePre) {
  if (!codePre) return;
  const allowedKeys = new Set(["ArrowLeft","ArrowRight","ArrowUp","ArrowDown","Home","End","PageUp","PageDown","Shift","Control","Alt","Meta","Escape","Tab"]);
  codePre.addEventListener("beforeinput", event => event.preventDefault());
  codePre.addEventListener("paste", event => event.preventDefault());
  codePre.addEventListener("drop", event => event.preventDefault());
  codePre.addEventListener("keydown", event => {
    if (event.metaKey || event.ctrlKey || event.altKey || allowedKeys.has(event.key)) return;
    event.preventDefault();
  });
  codePre.addEventListener("click", () => codePre.focus({preventScroll:true}));
}

function renderCodeRows(rows) {
  let inDocComment = false;
  const bracketState = {depth:0};
  return rows.map(row => {
    const text = String(row.text || "");
    const trimmed = text.trim();
    const startsDocComment = trimmed.startsWith("/--") || trimmed.startsWith("/-!");
    const isDocComment = inDocComment || startsDocComment;
    if (startsDocComment) inDocComment = true;
    const classes = [];
    if (row.context) classes.push("context-line");
    if (isDocComment) classes.push("doc-comment-line");
    const rendered = isDocComment
      ? highlightLeanDocCommentLine(text)
      : rowHtml(row, bracketState);
    const line = classes.length ? '<span class="' + classes.join(" ") + '">' + rendered + "</span>" : rendered;
    if (isDocComment && trimmed.endsWith("-/")) inDocComment = false;
    return line;
  }).join("\n");
}

function render(item, manifest, statuses) {
  fileName.textContent = item.file;
  targetRow.hidden = false;
  targetBadge.textContent = displayKind(item);
  targetName.textContent = item.primaryDeclaration || item.module + ":" + item.startLine;
  updateScopes(item.scopes);
  const gh = githubUrl(manifest, item);
  githubBtn.hidden = !gh;
  if (gh) githubBtn.href = gh;
  const rows = item.rows || [];
  const proofState = proofStateForItem(item, statuses);
  displayedCode = item.plainText || rows.map(row => row.text || "").join("\n");
  copyBtn.disabled = false;
  codeWrap.innerHTML = '<div class="code-grid"><pre class="proof-gutter" aria-hidden="true">' +
    renderProofGutterRows(item, rows, proofState) + '</pre><pre class="line-nos">' +
    rows.map(row => row.line ?? "").join("\n") +
    '</pre><pre class="code-pre" tabindex="0" contenteditable="plaintext-only" spellcheck="false" aria-label="Lean source code">' +
    renderCodeRows(rows) + "</pre></div>";
  lockReadonlyCaret(codeWrap.querySelector(".code-pre"));
}

async function load() {
  codeWrap.innerHTML = '<div class="empty">Loading…</div>';
  try {
    const [manifest, statuses] = await Promise.all([getJson("data/manifest.json"),getJson("proof-status.json").catch(() => ({theorems:[]}))]);
    render(resolveItem(manifest, params), manifest, statuses);
  } catch (error) {
    codeWrap.innerHTML = '<div class="error">' + escapeHtml(error.message || error) + "</div>";
  }
}

async function initAutoRefresh() {
  currentBuildVersion = await getBuildVersion();
  setInterval(async () => {
    const next = await getBuildVersion();
    if (next && currentBuildVersion && next !== currentBuildVersion) location.reload();
    else if (next && !currentBuildVersion) currentBuildVersion = next;
  }, 30000);
}

document.getElementById("reloadBtn").addEventListener("click", () => location.reload());
copyBtn.addEventListener("click", async () => {
  if (!displayedCode) return;
  await navigator.clipboard.writeText(displayedCode);
  copyBtn.textContent = "Copied!";
  setTimeout(() => { copyBtn.textContent = "Copy"; }, 1200);
});
load();
initAutoRefresh();
