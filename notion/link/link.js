(() => {
  const input = document.getElementById('githubUrl');
  const error = document.getElementById('error');
  const result = document.getElementById('result');
  const meta = document.getElementById('meta');
  const output = document.getElementById('output');
  const openBtn = document.getElementById('openBtn');
  let generated = '';
  let manifestPromise = null;

  const manifest = () => manifestPromise ||= fetch('../data/manifest.json', {cache: 'no-store'}).then(r => {
    if (!r.ok) throw new Error(`manifest HTTP ${r.status}`);
    return r.json();
  });

  function parseGithub(raw) {
    const url = new URL(raw.trim());
    if (url.hostname !== 'github.com') throw new Error('github.com のURLを貼り付けてください。');
    const parts = url.pathname.split('/').filter(Boolean);
    if (parts.length < 5 || parts[2] !== 'blob') throw new Error('GitHubのファイル表示URLを使用してください。');
    const line = Number((url.hash.match(/L(\d+)/) || [])[1]);
    if (!line) throw new Error('GitHubで行番号をクリックし、#L120 のようなURLにしてください。');
    return {
      repository: `${parts[0]}/${parts[1]}`,
      blobTail: parts.slice(3).map(decodeURIComponent).join('/'),
      line,
    };
  }

  function itemAt(m, file, line) {
    const items = (m.files[file] || []).map(id => m.items[id]).filter(Boolean);
    return items.filter(x => x.startLine <= line && line <= x.endLine)
      .sort((a, b) => (a.endLine - a.startLine) - (b.endLine - b.startLine))[0]
      || items.filter(x => x.startLine <= line).sort((a, b) => b.startLine - a.startLine)[0]
      || null;
  }

  document.getElementById('makeBtn').addEventListener('click', async () => {
    generated = '';
    error.textContent = '';
    result.hidden = true;
    try {
      const x = parseGithub(input.value);
      const m = await manifest();
      if (m.github?.repository && x.repository !== m.github.repository) {
        throw new Error(`このViewerは ${m.github.repository} 用です。`);
      }
      const file = Object.keys(m.files || {})
        .filter(candidate => x.blobTail === candidate || x.blobTail.endsWith('/' + candidate))
        .sort((a, b) => b.length - a.length)[0];
      if (!file) throw new Error('URLに対応するLeanファイルがmanifestに見つかりませんでした。');
      const item = itemAt(m, file, x.line);
      if (!item) throw new Error('その行の近くに表示可能なLean項目が見つかりませんでした。');

      const viewer = new URL('../', location.href);
      if (item.primaryDeclaration) {
        viewer.searchParams.set('decl', item.primaryDeclaration);
      } else {
        viewer.searchParams.set('file', item.file);
        viewer.searchParams.set('line', String(item.startLine));
      }
      generated = viewer.toString();
      meta.textContent = `${item.kind || 'Lean'}: ${item.primaryDeclaration || item.module} | ${item.file}:${item.startLine}`;
      output.textContent = generated;
      openBtn.href = generated;
      result.hidden = false;
    } catch (e) {
      error.textContent = String(e.message || e);
    }
  });

  document.getElementById('clearBtn').addEventListener('click', () => {
    generated = '';
    input.value = '';
    error.textContent = '';
    output.textContent = '';
    result.hidden = true;
    input.focus();
  });

  document.getElementById('copyBtn').addEventListener('click', async event => {
    if (!generated) return;
    await navigator.clipboard.writeText(generated);
    const button = event.currentTarget;
    button.textContent = 'コピーしました';
    setTimeout(() => { button.textContent = 'コピー'; }, 1200);
  });
})();
