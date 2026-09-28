function param(params, name) {
  if (params && typeof params.get === "function") return params.get(name);
  const value = params ? params[name] : null;
  return value == null ? null : String(value);
}

export function itemAtLine(manifest, file, line) {
  const ids = manifest.files?.[file] || [];
  const candidates = ids.map(id => manifest.items?.[id]).filter(Boolean);
  const containing = candidates.filter(item => item.startLine <= line && line <= item.endLine)
    .sort((a, b) => (a.endLine - a.startLine) - (b.endLine - b.startLine))[0];
  if (containing) return containing;
  return candidates.filter(item => item.startLine <= line)
    .sort((a, b) => b.startLine - a.startLine)[0] || null;
}

export function resolveItem(manifest, params) {
  const decl = param(params, "decl");
  const file = param(params, "file");
  const line = Number(param(params, "line"));
  const legacy = [["section",param(params,"section")],["namespace",param(params,"namespace")],["command",param(params,"command")]].filter(([, value]) => value);
  if (legacy.length > 1) throw new Error("Specify only one legacy target: section, namespace, or command.");
  if (legacy.length === 1) {
    const [kind, name] = legacy[0];
    const suffix = "\u001f" + kind + "\u001f" + name;
    const candidates = Object.entries(manifest.legacyTargets || {}).filter(([key, item]) => key.endsWith(suffix) && (!file || item.file === file)).map(([, item]) => item);
    if (candidates.length === 1) return candidates[0];
    if (!candidates.length) throw new Error(kind + ' "' + name + '" was not found.');
    throw new Error(kind + ' "' + name + '" is ambiguous; include ?file=... in the URL.');
  }
  if (decl) {
    let id = manifest.declarations?.[decl];
    if (!id && !decl.includes(".")) {
      const candidates = manifest.shortNames?.[decl] || [];
      const filtered = file ? candidates.filter(candidate => manifest.items?.[candidate]?.file === file) : candidates;
      if (filtered.length === 1) id = filtered[0];
    }
    if (!id) throw new Error('Declaration "' + decl + '" was not found or was ambiguous.');
    return manifest.items[id];
  }
  if (file && Number.isInteger(line) && line > 0) {
    const item = itemAtLine(manifest, file, line);
    if (item) return item;
    throw new Error("No Lean item was found near " + file + ":" + line + ".");
  }
  throw new Error("Specify ?decl=Full.Name, ?file=...&line=..., or a legacy section/namespace/command target.");
}

export function displayKind(item) {
  const semanticKind = String(item.displayKind || "").trim();
  if (semanticKind) return semanticKind;
  const raw = String(item.kind || "").trim();
  if (raw === "Lean.Parser.Command.declaration") return "Declaration";
  if (raw === "local instance") return "instance";
  if (raw.startsWith("Lean.Parser.Command.")) return raw.slice("Lean.Parser.Command.".length);
  return raw || "Lean";
}

export function githubUrl(manifest, item) {
  const repo = manifest.github?.repository;
  const ref = manifest.github?.ref || "main";
  if (!repo) return "";
  return "https://github.com/" + repo + "/blob/" + encodeURIComponent(ref) + "/" + item.file + "#L" + item.startLine;
}
