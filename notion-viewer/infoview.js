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
    lastFollowMarker = null;
  });

  const selector = '.lean-token[data-signature],.lean-token[data-docs],.lean-token[data-const-name]';
  const tacticSelector = '.lean-token.keyword[data-syntax-name^="Lean.Parser.Tactic."],.lean-token.keyword[data-syntax-name="Lean.Parser.Term.byTactic"]';
  const decodeMeta = value => {
    const text = String(value ?? '');
    try { return decodeURIComponent(text); } catch { return text; }
  };
  const label = text => {
    const node = document.createElement('div');
    node.className = 'lean-infoview-label';
    node.textContent = text;
    body.appendChild(node);
  };
  const pre = text => {
    const node = document.createElement('pre');
    node.className = 'lean-infoview-pre';
    node.textContent = String(text ?? '');
    body.appendChild(node);
  };

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

  function showGoals(marker, sourceLabel = 'Proof state', mode = 'fixed') {
    let goals = [];
    try { goals = JSON.parse(marker.dataset.goals || '[]'); } catch {}
    kind.textContent = 'Goal';
    title.textContent = goals.length > 1 ? `${sourceLabel} · ${goals.length} goals` : sourceLabel;
    body.replaceChildren();
    if (!goals.length) {
      pre('ゴールはありません．');
      panel.dataset.mode = mode;
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
        row.className = 'lean-infoview-hyp';
        const names = Array.isArray(h.names) ? h.names.join(' ') : '';
        row.textContent = `${names}${names ? ' : ' : ''}${h.type || ''}`;
        block.appendChild(row);
      });
      const conclusion = document.createElement('div');
      conclusion.className = 'lean-infoview-turnstile';
      conclusion.textContent = `${goal.goalPrefix || '⊢'} ${goal.conclusion || ''}`;
      block.appendChild(conclusion);
      body.appendChild(block);
    });
    panel.dataset.mode = mode;
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
  const codePre = document.querySelector('.code-pre');
  if (codeWrap) {
    new MutationObserver(() => stripNativeTitles(codeWrap)).observe(codeWrap, { childList: true, subtree: true });
  }

  let hovered = null;
  let lastFollowMarker = null;
  let followFrame = 0;
  let followPoint = null;

  function scheduleProofFollow(event) {
    const activeCodePre = document.querySelector('.code-pre');
    if (!activeCodePre || !activeCodePre.contains(event.target)) return;
    followPoint = { x: event.clientX, y: event.clientY };
    if (followFrame) return;
    followFrame = requestAnimationFrame(() => {
      followFrame = 0;
      if (!followPoint) return;
      const marker = proofMarkerAtPoint(followPoint.x, followPoint.y);
      followPoint = null;
      if (!marker || marker === lastFollowMarker) return;
      lastFollowMarker = marker;
      showGoals(marker, 'カーソル位置の証明状態', 'follow');
    });
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
      ? 'カーソルを証明内で動かすと証明状態が追従します．クリックでもこの位置の証明状態を表示できます．'
      : '';
    tooltip.textContent = [name, signature, docs, proofHint].filter(Boolean).join('\n\n');
    tooltip.hidden = false;
  });
  document.addEventListener('mousemove', event => {
    if (hovered && !tooltip.hidden) {
      const x = Math.max(10, Math.min(event.clientX + 14, innerWidth - tooltip.offsetWidth - 10));
      const y = Math.max(10, Math.min(event.clientY + 18, innerHeight - tooltip.offsetHeight - 10));
      tooltip.style.left = `${x}px`;
      tooltip.style.top = `${y}px`;
    }
    scheduleProofFollow(event);
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
      lastFollowMarker = marker;
      showGoals(marker, 'クリック位置の証明状態', 'fixed');
      return;
    }
    const tactic = event.target.closest?.(tacticSelector);
    if (tactic) {
      const proofMarker = proofMarkerAtPoint(event.clientX, event.clientY) || nearestGoalMarker(tactic);
      if (proofMarker) {
        event.preventDefault();
        lastFollowMarker = proofMarker;
        showGoals(proofMarker, `${tactic.textContent.trim()} の証明状態`, 'fixed');
        return;
      }
    }
    const target = event.target.closest?.(selector);
    if (target) { event.preventDefault(); showToken(target); }
  });
  document.addEventListener('keydown', event => {
    if (!['Enter', ' '].includes(event.key)) return;
    const marker = event.target.closest?.('.lean-goal-marker');
    if (!marker) return;
    event.preventDefault();
    lastFollowMarker = marker;
    showGoals(marker, 'キーボード選択位置の証明状態', 'fixed');
  });
})();
