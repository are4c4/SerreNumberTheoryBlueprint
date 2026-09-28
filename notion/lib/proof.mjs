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
  const symbol = proved ? "✓" : "!";
  const label = proved ? "Proved" : "Incomplete";
  return '<span class="proof-gutter-marker ' + className + '" title="' + escapeHtml(title) + '" aria-label="' + escapeHtml(label) + '">' + symbol + "</span>";
}

export function proofGutterCells(item, rows, proofState) {
  let markerRendered = false;
  return rows.map(row => {
    if (proofState && !markerRendered && row.line === item.startLine) {
      markerRendered = true;
      return proofGutterMarker(proofState);
    }
    return '<span class="proof-gutter-spacer" aria-hidden="true"></span>';
  });
}

export function renderProofGutterRows(item, rows, proofState) {
  return proofGutterCells(item, rows, proofState).join("\n");
}
