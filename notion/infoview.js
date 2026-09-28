(() => {
  const viewer = document.querySelector('.viewer');
  if (!viewer) return;

  const tooltip = document.createElement('div');
  tooltip.className = 'lean-infoview-tooltip';
  tooltip.hidden = true;
  document.body.appendChild(tooltip);

  const panel = document.createElement('section');
  panel.className = 'lean-infoview-panel';
  panel.hidden = true;
  viewer.appendChild(panel);

  const head = document.createElement('div');
  head.className = 'lean-infoview-head';
  const tabs = document.createElement('div');
  tabs.className = 'lean-infoview-tabs';
  const kind = document.createElement('span');
  kind.className = 'lean-infoview-kind';
  const title = document.createElement('span');
  title.className = 'lean-infoview-title';
  const close = document.createElement('button');
  close.className = 'lean-infoview-close';
  close.type = 'button';
  close.textContent = '×';
  close.setAttribute('aria-label', 'InfoViewを閉じる');
  tabs.append(kind, title);
  head.append(tabs, close);
  const body = document.createElement('div');
  body.className = 'lean-infoview-body';
  panel.append(head, body);

  close.addEventListener('click', () => {
    panel.hidden = true;
    lastGoalMarker = null;
  });

  const selector = '.lean-token[data-signature],.lean-token[data-docs],.lean-token[data-const-name]';
  const tacticSelector = '.lean-token.keyword[data-syntax-name^="Lean.Parser.Tactic."],.lean-token.keyword[data-syntax-name="Lean.Parser.Term.byTactic"]';
  const decodeMeta = value => {
    const text = String(value ?? '');
    try { return decodeURIComponent(text); } catch { return text; }
  };

  const escHtml = value => String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\"/g, '&quot;');

  const leanKeywords = new Set([
    'import', 'open', 'namespace', 'section', 'end', 'variable', 'variables', 'universe',
    'include', 'omit', 'where', 'by', 'fun', 'in', 'let', 'if', 'then', 'else', 'match', 'with',
    'theorem', 'lemma', 'def', 'abbrev', 'example', 'instance', 'structure', 'class', 'inductive',
    'noncomputable', 'private', 'protected', 'local', 'exact', 'intro', 'apply', 'rw', 'simp',
    'constructor', 'rcases', 'rintro', 'have', 'show', 'from', 'calc', 'using', 'at'
  ]);
  const leanTypes = new Set([
    'Type', 'Prop', 'Sort', 'Nat', 'Int', 'Rat', 'Bool', 'String', 'Unit', 'Fin',
    'Field', 'Fintype', 'CharP', 'DecidableEq', 'MvPolynomial', 'Polynomial', 'Module',
    'ZMod', 'Set', 'List', 'Option', 'Subtype', 'Fact', 'Prime'
  ]);
  const leanLiterals = new Set(['true', 'false']);
  const leanTokenPattern = /:=|=>|->|<-|≤|≥|≠|⊢|∀|∃|λ|[A-Za-z_][A-Za-z0-9_'.]*|\d+|[()\[\]{}:,.^=+\-*\/|]/g;

  function classifyLeanWord(token) {
    if (leanKeywords.has(token)) return 'keyword';
    if (leanTypes.has(token) || /^(?:Type|Sort)_?u?_?\d*$/.test(token)) return 'type';
    if (leanLiterals.has(token) || /^\d+$/.test(token)) return 'literal';
    if (/^inst/.test(token)) return 'implicit';
    if (/^[A-Za-z]$/.test(token) || /^[a-z][A-Za-z0-9_']*$/.test(token)) return 'var';
    if (/^[A-Z][A-Za-z0-9_']*(?:\.[A-Za-z0-9_']+)*$/.test(token)) return 'const';
    return 'ident';
  }

  function highlightLeanText(text) {
    const raw = String(text ?? '');
    let out = '';
    let last = 0;
    for (const match of raw.matchAll(leanTokenPattern)) {
      const token = match[0];
      const index = match.index ?? 0;
      out += escHtml(raw.slice(last, index));
      const cls = /^(?::=|=>|->|<-|≤|≥|≠|⊢|∀|∃|λ|[()\[\]{}:,.^=+\-*\/|])$/.test(token)
        ? 'punct'
        : classifyLeanWord(token);
      out += `<span class="lean-hl-${cls}">${escHtml(token)}</span>`;
      last = index + token.length;
    }
    out += escHtml(raw.slice(last));
    return out;
  }

  function label(text) {
    const node = document.createElement('div');
    node.className = 'lean-infoview-label';
    node.textContent = text;
    body.appendChild(node);
  }

  function pre(text, options = {}) {
    const node = document.createElement('pre');
    node.className = `lean-infoview-pre lean-code-highlight${options.className ? ` ${options.className}` : ''}`;
    node.innerHTML = options.highlight === false ? escHtml(text) : highlightLeanText(text);
    body.appendChild(node);
    return node;
  }

  function renderTooltip({ name, signature, docs, proofHint }) {
    const sections = [];
    if (name) sections.push(`<div class="lean-tooltip-title">${highlightLeanText(name)}</div>`);
    if (signature) sections.push(`<pre class="lean-tooltip-code lean-code-highlight">${highlightLeanText(signature)}</pre>`);
    if (docs) sections.push(`<div class="lean-tooltip-docs">${escHtml(docs)}</div>`);
    if (proofHint) sections.push(`<div class="lean-tooltip-hint">${escHtml(proofHint)}</div>`);
    return sections.join('');
  }

  function showToken(target) {
    kind.textContent = target.dataset.semantic || 'info';
    title.textContent = decodeMeta(target.dataset.constName || target.textContent.trim());
    body.replaceChildren();
    if (target.dataset.signature) { label('Type'); pre(decodeMeta(target.dataset.signature)); }
    if (target.dataset.docs) {
      label('Documentation');
      const docs = document.createElement('div');
      docs.className = 'lean-infoview-docs';
      docs.textContent = decodeMeta(target.dataset.docs);
      body.appendChild(docs);
    }
    if (!target.dataset.signature && !target.dataset.docs) pre(target.textContent.trim());
    panel.dataset.mode = 'info';
    panel.hidden = false;
  }

  function hypothesisHtml(h) {
    const names = Array.isArray(h.names) ? h.names.join(' ') : '';
    const type = h.type || '';
    const namesHtml = names
      ? `<span class="lean-hl-var lean-hl-hyp-name">${escHtml(names)}</span><span class="lean-hl-punct"> : </span>`
      : '';
    return `${namesHtml}${highlightLeanText(type)}`;
  }

  function showGoals(marker, sourceLabel = 'カーソル位置の証明状態') {
    let goals = [];
    try { goals = JSON.parse(marker.dataset.goals || '[]'); } catch {}
    kind.textContent = 'Goal';
    title.textContent = goals.length > 1 ? `${sourceLabel} · ${goals.length} goals` : sourceLabel;
    body.replaceChildren();
    if (!goals.length) {
      pre('ゴールはありません．', { highlight: false });
      panel.dataset.mode = 'fixed';
      panel.hidden = false;
      return;
    }
    goals.forEach((goal, index) => {
      const block = document.createElement('div');
      block.className = 'lean-infoview-goal';
      if (goals.length > 1 || goal.name) {
        const name = document.createElement('div');
        name.className = 'lean-infoview-label';
        name.textContent = goal.name || `Goal ${index + 1}`;
        block.appendChild(name);
      }
      (goal.hypotheses || []).forEach(h => {
        const row = document.createElement('div');
        row.className = 'lean-infoview-hyp lean-code-highlight';
        row.innerHTML = hypothesisHtml(h);
        block.appendChild(row);
      });
      const conclusion = document.createElement('div');
      conclusion.className = 'lean-infoview-turnstile lean-code-highlight';
      conclusion.innerHTML = `<span class="lean-hl-turnstile">${escHtml(goal.goalPrefix || '⊢')}</span> ${highlightLeanText(goal.conclusion || '')}`;
      block.appendChild(conclusion);
      body.appendChild(block);
    });
    panel.dataset.mode = 'fixed';
    panel.hidden = false;
  }

  function nearestGoalMarker(target) {
    const markers = Array.from(document.querySelectorAll('.lean-goal-marker'));
    let found = null;
    for (const marker of markers) {
      if (marker === target || (marker.compareDocumentPosition(target) & Node.DOCUMENT_POSITION_FOLLOWING)) {
        found = marker;
      }
    }
    return found;
  }

  function stripNativeTitles(root = document) {
    root.querySelectorAll?.('.lean-token[title],.lean-goal-marker[title]').forEach(el => el.removeAttribute('title'));
  }

  function caretRangeFromPoint(x, y) {
    if (document.caretPositionFromPoint) {
      const pos = document.caretPositionFromPoint(x, y);
      if (!pos) return null;
      const range = document.createRange();
      try {
        range.setStart(pos.offsetNode, pos.offset);
        range.collapse(true);
        return range;
      } catch { return null; }
    }
    if (document.caretRangeFromPoint) {
      const range = document.caretRangeFromPoint(x, y);
      if (!range) return null;
      range.collapse(true);
      return range;
    }
    return null;
  }

  function markerBoundary(marker, after = false) {
    const range = document.createRange();
    try {
      if (after) range.setStartAfter(marker);
      else range.setStartBefore(marker);
      range.collapse(true);
      return range;
    } catch { return null; }
  }

  function boundaryBeforeOrEqual(a, b) {
    return a.compareBoundaryPoints(Range.START_TO_START, b) <= 0;
  }

  function matchingProofEnd(startMarker) {
    const start = startMarker.dataset.proofStart;
    const end = startMarker.dataset.proofEnd;
    if (start == null || end == null) return null;
    const candidates = document.querySelectorAll('.lean-proof-end');
    for (const marker of candidates) {
      if (marker.dataset.proofStart !== start || marker.dataset.proofEnd !== end) continue;
      if (startMarker.compareDocumentPosition(marker) & Node.DOCUMENT_POSITION_FOLLOWING) return marker;
    }
    return null;
  }

  function proofMarkerAtPoint(x, y) {
    const point = caretRangeFromPoint(x, y);
    if (!point) return null;
    let found = null;
    for (const start of document.querySelectorAll('.lean-proof-start')) {
      const end = matchingProofEnd(start);
      if (!end) continue;
      const startBoundary = markerBoundary(start, false);
      const endBoundary = markerBoundary(end, true);
      if (!startBoundary || !endBoundary) continue;
      if (boundaryBeforeOrEqual(startBoundary, point) && boundaryBeforeOrEqual(point, endBoundary)) {
        found = start;
      }
    }
    return found;
  }

  stripNativeTitles();
  const codeWrap = document.querySelector('.code-wrap');
  if (codeWrap) {
    new MutationObserver(() => stripNativeTitles(codeWrap)).observe(codeWrap, { childList: true, subtree: true });
  }

  let hovered = null;
  let lastGoalMarker = null;

  function showGoalsFromPoint(event, sourceLabel = 'クリック位置の証明状態') {
    const activeCodePre = document.querySelector('.code-pre');
    if (!activeCodePre || !activeCodePre.contains(event.target)) return false;
    const marker = proofMarkerAtPoint(event.clientX, event.clientY);
    if (!marker) return false;
    event.preventDefault();
    lastGoalMarker = marker;
    showGoals(marker, sourceLabel);
    return true;
  }

  document.addEventListener('mouseover', event => {
    const target = event.target.closest?.(selector);
    if (!target || target === hovered) return;
    target.removeAttribute('title');
    hovered = target;
    const name = decodeMeta(target.dataset.constName || target.textContent.trim());
    const signature = target.dataset.signature ? decodeMeta(target.dataset.signature) : '';
    const docs = target.dataset.docs ? decodeMeta(target.dataset.docs) : '';
    const proofHint = target.matches(tacticSelector) && nearestGoalMarker(target)
      ? 'クリックするとこの位置の証明状態を固定表示します．マウス移動では切り替わりません．'
      : '';
    tooltip.innerHTML = renderTooltip({ name, signature, docs, proofHint });
    tooltip.hidden = false;
  });
  document.addEventListener('mousemove', event => {
    if (hovered && !tooltip.hidden) {
      const x = Math.max(10, Math.min(event.clientX + 14, innerWidth - tooltip.offsetWidth - 10));
      const y = Math.max(10, Math.min(event.clientY + 18, innerHeight - tooltip.offsetHeight - 10));
      tooltip.style.left = `${x}px`;
      tooltip.style.top = `${y}px`;
    }
  });
  document.addEventListener('mouseout', event => {
    if (!hovered) return;
    if (event.relatedTarget && hovered.contains(event.relatedTarget)) return;
    hovered = null;
    tooltip.hidden = true;
  });
  document.addEventListener('click', event => {
    const marker = event.target.closest?.('.lean-goal-marker');
    if (marker) {
      event.preventDefault();
      lastGoalMarker = marker;
      showGoals(marker, 'クリック位置の証明状態');
      return;
    }
    const tactic = event.target.closest?.(tacticSelector);
    if (tactic) {
      const proofMarker = proofMarkerAtPoint(event.clientX, event.clientY) || nearestGoalMarker(tactic);
      if (proofMarker) {
        event.preventDefault();
        lastGoalMarker = proofMarker;
        showGoals(proofMarker, `${tactic.textContent.trim()} の証明状態`);
        return;
      }
    }
    const target = event.target.closest?.(selector);
    if (target) { event.preventDefault(); showToken(target); return; }
    showGoalsFromPoint(event);
  });
  document.addEventListener('keydown', event => {
    if (!['Enter', ' '].includes(event.key)) return;
    const marker = event.target.closest?.('.lean-goal-marker');
    if (!marker) return;
    event.preventDefault();
    lastGoalMarker = marker;
    showGoals(marker, 'キーボード選択位置の証明状態');
  });
})();
