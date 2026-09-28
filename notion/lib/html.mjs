export function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function decodeMeta(value) {
  const text = String(value ?? "");
  try { return decodeURIComponent(text); } catch { return text; }
}
