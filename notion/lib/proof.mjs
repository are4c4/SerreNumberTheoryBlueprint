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
    ? '<svg viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill-rule="evenodd" clip-rule="evenodd" d="m 16.211845,3.8542521 -7.8050002,9.2139999 -0.728,-0.033 -3.087,-4.3949999 0.754,-0.53 2.744,3.9069999 7.4190002,-8.7589999 z" transform="translate(-0.4018449,-0.16325205)"/><path fill-rule="evenodd" clip-rule="evenodd" d="m 7.8258448,9.0322521 4.3860002,-5.178 -0.703,-0.596 -4.2300002,4.994 z m -1.55,0.403 0.548,0.7799999 -0.547,-0.7799999 z m -1.617,1.9099999 0.547,0.78 -0.799,0.943 -0.728,-0.033 -3.087,-4.3949999 0.754,-0.53 2.744,3.9069999 0.57,-0.672 z" transform="translate(-0.4018449,-0.16325205)"/></svg>'
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
