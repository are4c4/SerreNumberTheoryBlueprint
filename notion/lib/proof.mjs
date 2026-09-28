import { escapeHtml } from "./html.mjs";

export function proofStateForItem(item, statuses) {
  const names = item.defines || [];
  return (statuses.theorems || []).find(entry => names.includes(entry.name)) || null;
}

export function proofGutterMarker(proofState) {
  if (!proofState) return "";
  const proved = proofState.status === "proved";
  const className = proved ? "proved" : "incomplete";
  const title = proved ? "Proved: Lean kernel dependency check detected no sorryAx dependency." : "Incomplete: this theorem transitively depends on sorryAx.";
  const label = proved ? "Proved" : "Incomplete";
  const mark = proved
    ? '<svg viewBox="0 0 24 16" aria-hidden="true" focusable="false"><path d="M1.5 8.2 5.1 11.8 10.8 5.4"/><path d="M8.6 8.1 13.0 12.5 22.5 2.2"/></svg>'
    : "!";
  return '<span class="proof-gutter-marker ' + className + '" title="' + escapeHtml(title) + '" aria-label="' + escapeHtml(label) + '">' + mark + "</span>";
}

export function proofGutterCells(item, rows, proofState) {
  let markerRendered = false;
  const markerLine = item.declarationLine ?? item.startLine;
  return rows.map(row => {
    if (proofState && !markerRendered && row.line === markerLine) {
      markerRendered = true;
      return proofGutterMarker(proofState);
    }
    return '<span class="proof-gutter-spacer" aria-hidden="true"></span>';
  });
}

export function renderProofGutterRows(item, rows, proofState) {
  return proofGutterCells(item, rows, proofState).join("\n");
}
