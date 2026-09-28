#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
const require = createRequire(import.meta.url);
const vsctm = require("vscode-textmate");
const oniguruma = require("vscode-oniguruma");

const FONT_STYLE_MASK = 0x00007800;
const FOREGROUND_MASK = 0x00ff8000;
const FONT_STYLE_OFFSET = 11;
const FOREGROUND_OFFSET = 15;

const FontStyle = Object.freeze({ Italic: 1, Bold: 2, Underline: 4, Strikethrough: 8 });

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function escapeAttribute(value) {
  return escapeHtml(value);
}

function decodeEntities(value) {
  return String(value ?? "")
    .replaceAll("&quot;", '"')
    .replaceAll("&gt;", ">")
    .replaceAll("&lt;", "<")
    .replaceAll("&amp;", "&");
}

function decodeMeta(value) {
  const decoded = decodeEntities(value);
  try { return decodeURIComponent(decoded); } catch { return decoded; }
}

export function parseJsonc(text) {
  let out = "";
  let inString = false;
  let escaped = false;
  let lineComment = false;
  let blockComment = false;
  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    const next = text[i + 1] || "";
    if (lineComment) {
      if (ch === "\n") { lineComment = false; out += ch; }
      continue;
    }
    if (blockComment) {
      if (ch === "*" && next === "/") { blockComment = false; i += 1; }
      else if (ch === "\n") out += ch;
      continue;
    }
    if (inString) {
      out += ch;
      if (escaped) escaped = false;
      else if (ch === "\\") escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') { inString = true; out += ch; continue; }
    if (ch === "/" && next === "/") { lineComment = true; i += 1; continue; }
    if (ch === "/" && next === "*") { blockComment = true; i += 1; continue; }
    out += ch;
  }
  let normalized = "";
  inString = false;
  escaped = false;
  for (let i = 0; i < out.length; i += 1) {
    const ch = out[i];
    if (inString) {
      normalized += ch;
      if (escaped) escaped = false;
      else if (ch === "\\") escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') {
      inString = true;
      normalized += ch;
      continue;
    }
    if (ch === ",") {
      let j = i + 1;
      while (j < out.length && /\s/.test(out[j])) j += 1;
      if (out[j] === "}" || out[j] === "]") continue;
    }
    normalized += ch;
  }
  return JSON.parse(normalized);
}

async function loadTheme(themePath) {
  const absolute = path.resolve(themePath);
  const current = parseJsonc(await fs.readFile(absolute, "utf8"));
  let inherited = { colors: {}, tokenColors: [] };
  if (current.include) inherited = await loadTheme(path.resolve(path.dirname(absolute), current.include));
  return {
    colors: { ...inherited.colors, ...(current.colors || {}) },
    tokenColors: [...inherited.tokenColors, ...(Array.isArray(current.tokenColors) ? current.tokenColors : [])],
    semanticTokenColors: { ...inherited.semanticTokenColors, ...(current.semanticTokenColors || {}) },
  };
}

function rawTextMateTheme(theme) {
  const foreground = theme.colors["editor.foreground"] || "#D4D4D4";
  const background = theme.colors["editor.background"] || "#1E1E1E";
  return {
    name: "VS Code Dark+",
    settings: [
      { settings: { foreground, background } },
      ...theme.tokenColors.map(rule => ({ scope: rule.scope, settings: rule.settings || {} })),
    ],
  };
}

export async function createHighlighter({ grammarPath, markdownGrammarPath, themePath }) {
  const grammarText = await fs.readFile(grammarPath, "utf8");
  const markdownGrammarText = await fs.readFile(markdownGrammarPath, "utf8");
  const rawGrammar = vsctm.parseRawGrammar(grammarText, grammarPath);
  const rawMarkdownGrammar = vsctm.parseRawGrammar(markdownGrammarText, markdownGrammarPath);
  const theme = await loadTheme(themePath);
  const wasmPath = require.resolve("vscode-oniguruma/release/onig.wasm");
  const wasm = await fs.readFile(wasmPath);
  await oniguruma.loadWASM(wasm.buffer.slice(wasm.byteOffset, wasm.byteOffset + wasm.byteLength));

  const registry = new vsctm.Registry({
    onigLib: Promise.resolve({
      createOnigScanner(patterns) { return new oniguruma.OnigScanner(patterns); },
      createOnigString(value) { return new oniguruma.OnigString(value); },
    }),
    loadGrammar: async scopeName => {
      if (scopeName === rawGrammar.scopeName) return rawGrammar;
      if (scopeName === rawMarkdownGrammar.scopeName) return rawMarkdownGrammar;
      return null;
    },
  });
  registry.setTheme(rawTextMateTheme(theme));
  const grammar = await registry.loadGrammar(rawGrammar.scopeName);
  if (!grammar) throw new Error(`Unable to load TextMate grammar ${rawGrammar.scopeName}`);
  const colorMap = registry.getColorMap();

  function tokenizeLine(line, ruleStack = vsctm.INITIAL) {
    const result = grammar.tokenizeLine2(line, ruleStack);
    const encoded = result.tokens;
    const segments = [];
    for (let i = 0; i < encoded.length; i += 2) {
      const start = encoded[i];
      const metadata = encoded[i + 1];
      const end = i + 2 < encoded.length ? encoded[i + 2] : line.length;
      if (end <= start) continue;
      const foregroundIndex = (metadata & FOREGROUND_MASK) >>> FOREGROUND_OFFSET;
      const fontStyle = (metadata & FONT_STYLE_MASK) >>> FONT_STYLE_OFFSET;
      segments.push({
        start,
        end,
        text: line.slice(start, end),
        color: colorMap[foregroundIndex] || theme.colors["editor.foreground"] || "#D4D4D4",
        fontStyle,
      });
    }
    return { segments, ruleStack: result.ruleStack };
  }

  function tokenizeSnippet(text) {
    const lines = String(text ?? "").split("\n");
    let stack = vsctm.INITIAL;
    return lines.map(line => {
      const result = tokenizeLine(line, stack);
      stack = result.ruleStack;
      return result.segments;
    });
  }

  return { tokenizeLine, tokenizeSnippet, theme };
}

function styleForSegment(segment) {
  const styles = [];
  if (segment?.color) styles.push(`color:${segment.color}`);
  const fontStyle = Number(segment?.fontStyle || 0);
  if (fontStyle & FontStyle.Italic) styles.push("font-style:italic");
  if (fontStyle & FontStyle.Bold) styles.push("font-weight:bold");
  const decorations = [];
  if (fontStyle & FontStyle.Underline) decorations.push("underline");
  if (fontStyle & FontStyle.Strikethrough) decorations.push("line-through");
  if (decorations.length) styles.push(`text-decoration:${decorations.join(" ")}`);
  return styles.join(";");
}

function renderStyledText(text, segment) {
  if (!text) return "";
  const style = styleForSegment(segment);
  return style
    ? `<span class="tm-token" style="${escapeAttribute(style)}">${escapeHtml(text)}</span>`
    : `<span class="tm-token">${escapeHtml(text)}</span>`;
}

export function renderTextMateLine(text, segments) {
  if (!segments?.length) return escapeHtml(text);
  return segments.map(segment => renderStyledText(segment.text, segment)).join("");
}

function parseSemanticLine(html) {
  const raw = String(html ?? "");
  const spans = [];
  const markers = [];
  let visible = "";
  let sourceCursor = 0;
  let textPos = 0;
  const re = /<span\b([^>]*)>(.*?)<\/span>/gs;
  for (const match of raw.matchAll(re)) {
    const before = raw.slice(sourceCursor, match.index);
    const beforeText = decodeEntities(before);
    visible += beforeText;
    textPos += beforeText.length;

    const inner = decodeEntities(match[2]);
    const open = `<span${match[1]}>`;
    if (inner.length === 0) markers.push({ pos: textPos, html: match[0] });
    else {
      spans.push({ start: textPos, end: textPos + inner.length, open, close: "</span>" });
      visible += inner;
      textPos += inner.length;
    }
    sourceCursor = (match.index ?? 0) + match[0].length;
  }
  const after = decodeEntities(raw.slice(sourceCursor));
  visible += after;
  textPos += after.length;
  return { visible, spans, markers, length: textPos };
}

function covering(items, position, startIndex = 0) {
  for (let i = startIndex; i < items.length; i += 1) {
    const item = items[i];
    if (item.end <= position) continue;
    if (item.start <= position && position < item.end) return [item, i];
    if (item.start > position) break;
  }
  return [null, startIndex];
}

export function mergeSemanticAndTextMate(text, semanticHtml, segments) {
  const source = String(text ?? "");
  if (!semanticHtml) return renderTextMateLine(source, segments);
  const semantic = parseSemanticLine(semanticHtml);
  if (semantic.visible !== source) return renderTextMateLine(source, segments);

  const boundaries = new Set([0, source.length]);
  semantic.spans.forEach(span => { boundaries.add(span.start); boundaries.add(span.end); });
  (segments || []).forEach(segment => { boundaries.add(segment.start); boundaries.add(segment.end); });
  semantic.markers.forEach(marker => boundaries.add(marker.pos));
  const ordered = [...boundaries].filter(x => x >= 0 && x <= source.length).sort((a, b) => a - b);
  const markersByPos = new Map();
  for (const marker of semantic.markers) {
    const list = markersByPos.get(marker.pos) || [];
    list.push(marker.html);
    markersByPos.set(marker.pos, list);
  }

  let out = "";
  let semanticIndex = 0;
  let tmIndex = 0;
  for (let i = 0; i < ordered.length - 1; i += 1) {
    const start = ordered[i];
    const end = ordered[i + 1];
    for (const marker of markersByPos.get(start) || []) out += marker;
    if (end <= start) continue;
    const [semanticSpan, nextSemanticIndex] = covering(semantic.spans, start, semanticIndex);
    const [tmSegment, nextTmIndex] = covering(segments || [], start, tmIndex);
    semanticIndex = nextSemanticIndex;
    tmIndex = nextTmIndex;
    const inner = renderStyledText(source.slice(start, end), tmSegment);
    out += semanticSpan ? semanticSpan.open + inner + semanticSpan.close : inner;
  }
  for (const marker of markersByPos.get(source.length) || []) out += marker;
  return out;
}

function encodeHtmlMeta(html) {
  return encodeURIComponent(String(html ?? ""));
}

function highlightSnippet(highlighter, text) {
  const lines = String(text ?? "").split("\n");
  const tokenLines = highlighter.tokenizeSnippet(text);
  return lines.map((line, index) => renderTextMateLine(line, tokenLines[index] || [])).join("\n");
}

function enrichTokenMetadata(html, highlighter) {
  return String(html ?? "").replace(/<span\b([^>]*)>/g, (whole, attrs) => {
    if (!/\bclass="[^"]*\blean-token\b/.test(attrs)) return whole;
    let extra = "";
    const signature = attrs.match(/\bdata-signature="([^"]*)"/);
    if (signature && !/\bdata-vscode-signature=/.test(attrs)) {
      const source = decodeMeta(signature[1]);
      extra += ` data-vscode-signature="${escapeAttribute(encodeHtmlMeta(highlightSnippet(highlighter, source)))}"`;
    }
    const constName = attrs.match(/\bdata-const-name="([^"]*)"/);
    if (constName && !/\bdata-vscode-name=/.test(attrs)) {
      const source = decodeEntities(constName[1]);
      extra += ` data-vscode-name="${escapeAttribute(encodeHtmlMeta(highlightSnippet(highlighter, source)))}"`;
    }
    return `<span${attrs}${extra}>`;
  });
}

function replaceAttribute(openTag, name, value) {
  const encoded = escapeAttribute(value);
  const re = new RegExp(`\\s${name}="[^"]*"`);
  if (re.test(openTag)) return openTag.replace(re, ` ${name}="${encoded}"`);
  return openTag.replace(/>$/, ` ${name}="${encoded}">`);
}

function enrichGoalMarker(markerHtml, highlighter) {
  if (!markerHtml.includes("lean-goal-marker") || !markerHtml.includes("data-goals=")) return markerHtml;
  const openMatch = markerHtml.match(/^<span\b[^>]*>/);
  if (!openMatch) return markerHtml;
  const dataMatch = openMatch[0].match(/\bdata-goals="([^"]*)"/);
  if (!dataMatch) return markerHtml;
  try {
    const goals = JSON.parse(decodeEntities(dataMatch[1]));
    for (const goal of goals) {
      for (const hypothesis of goal.hypotheses || []) {
        const namesText = Array.isArray(hypothesis.names) ? hypothesis.names.join(" ") : "";
        if (namesText) {
          const segments = highlighter.tokenizeSnippet(namesText)[0] || [];
          hypothesis.namesHtml = mergeSemanticAndTextMate(namesText, hypothesis.namesHtml || "", segments);
        }
        if (hypothesis.type) {
          const segments = highlighter.tokenizeSnippet(hypothesis.type)[0] || [];
          hypothesis.typeHtml = mergeSemanticAndTextMate(hypothesis.type, hypothesis.typeHtml || "", segments);
        }
      }
      if (goal.conclusion) {
        const segments = highlighter.tokenizeSnippet(goal.conclusion)[0] || [];
        goal.conclusionHtml = mergeSemanticAndTextMate(goal.conclusion, goal.conclusionHtml || "", segments);
      }
    }
    const newOpen = replaceAttribute(openMatch[0], "data-goals", JSON.stringify(goals));
    return newOpen + markerHtml.slice(openMatch[0].length);
  } catch {
    return markerHtml;
  }
}

function enrichMarkers(html, highlighter) {
  return String(html ?? "").replace(/<span\b[^>]*><\/span>/g, marker => enrichGoalMarker(marker, highlighter));
}

async function tokenizeSourceFile(highlighter, sourcePath) {
  const raw = await fs.readFile(sourcePath, "utf8");
  const lines = raw.replace(/\r\n/g, "\n").split("\n");
  const byLine = new Map();
  let stack = vsctm.INITIAL;
  for (let index = 0; index < lines.length; index += 1) {
    const result = highlighter.tokenizeLine(lines[index], stack);
    stack = result.ruleStack;
    byLine.set(index + 1, { text: lines[index], segments: result.segments });
  }
  return byLine;
}

function allItems(manifest) {
  return [
    ...Object.values(manifest.items || {}),
    ...Object.values(manifest.legacyTargets || {}),
  ];
}

async function applyToManifest({ manifestPath, sourceRoot, highlighter }) {
  const manifest = JSON.parse(await fs.readFile(manifestPath, "utf8"));
  const fileCache = new Map();
  let themedRows = 0;
  let semanticRows = 0;
  let fallbackRows = 0;

  async function rowsForFile(file) {
    if (!fileCache.has(file)) {
      const absolute = path.join(sourceRoot, file);
      fileCache.set(file, await tokenizeSourceFile(highlighter, absolute));
    }
    return fileCache.get(file);
  }

  for (const item of allItems(manifest)) {
    if (!item?.file || !Array.isArray(item.rows)) continue;
    const sourceRows = await rowsForFile(item.file);
    for (const row of item.rows) {
      const text = String(row.text ?? "");
      let segments = [];
      const sourceRow = Number.isInteger(row.line) ? sourceRows.get(row.line) : null;
      if (sourceRow && sourceRow.text === text) segments = sourceRow.segments;
      else segments = highlighter.tokenizeSnippet(text)[0] || [];
      const semantic = String(row.html || "");
      const merged = mergeSemanticAndTextMate(text, semantic, segments);
      if (semantic.includes("lean-token")) semanticRows += 1;
      if (!merged.includes("tm-token") && text) fallbackRows += 1;
      else if (text) themedRows += 1;
      row.html = enrichTokenMetadata(enrichMarkers(merged, highlighter), highlighter);
    }
  }

  manifest.highlighting = {
    engine: "vscode-textmate",
    theme: "Dark+",
    grammar: "Lean 4 official TextMate grammar",
    semanticOverlay: "SubVerso",
  };
  await fs.writeFile(manifestPath, JSON.stringify(manifest), "utf8");
  return { themedRows, semanticRows, fallbackRows };
}

function parseArgs(argv) {
  const result = {};
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    if (!key.startsWith("--")) continue;
    result[key.slice(2)] = argv[i + 1];
    i += 1;
  }
  return result;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const manifestPath = args.manifest;
  const sourceRoot = args["source-root"] || ".";
  const grammarPath = args.grammar || "notion/vendor/lean4.json";
  const markdownGrammarPath = args["markdown-grammar"] || "notion/vendor/lean4-markdown.json";
  const themePath = args.theme || "notion/vendor/dark_plus.json";
  if (!manifestPath) throw new Error("Usage: apply-vscode-highlighting.mjs --manifest PATH [--source-root .]");
  const highlighter = await createHighlighter({ grammarPath, markdownGrammarPath, themePath });
  const stats = await applyToManifest({ manifestPath, sourceRoot, highlighter });
  console.log(`VS Code highlighting: ${stats.themedRows} themed rows, ${stats.semanticRows} semantic rows, ${stats.fallbackRows} fallbacks`);
  if (stats.fallbackRows) console.warn(`VS Code highlighting fallback rows: ${stats.fallbackRows}`);
}

const invokedAsScript = process.argv[1] && path.resolve(process.argv[1]) === path.resolve(fileURLToPath(import.meta.url));
if (invokedAsScript) main().catch(error => { console.error(error); process.exitCode = 1; });
