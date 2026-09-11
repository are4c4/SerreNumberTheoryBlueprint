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

  close.addEventListener('click', () => { panel.hidden = true; });

  const selector = '.lean-token[data-signature],.lean-token[data-docs],.lean-token[data-const-name]';
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
    panel.hidden = false;
  }

  function showGoals(marker) {
    let goals = [];
    try { goals = JSON.parse(marker.dataset.goals || '[]'); } catch {}
    kind.textContent = 'Goal';
    title.textContent = goals.length <= 1 ? 'Proof state' : `${goals.length} goals`;
    body.replaceChildren();
    if (!goals.length) { pre('ゴール情報を読み取れませんでした．'); panel.hidden = false; return; }
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
    panel.hidden = false;
  }

  let hovered = null;
  document.addEventListener('mouseover', event => {
    const target = event.target.closest?.(selector);
    if (!target || target === hovered) return;
    hovered = target;
    const name = decodeMeta(target.dataset.constName || target.textContent.trim());
    const signature = target.dataset.signature ? decodeMeta(target.dataset.signature) : '';
    const docs = target.dataset.docs ? decodeMeta(target.dataset.docs) : '';
    tooltip.textContent = [name, signature, docs].filter(Boolean).join('\n\n');
    tooltip.hidden = false;
  });
  document.addEventListener('mousemove', event => {
    if (!hovered || tooltip.hidden) return;
    const x = Math.max(10, Math.min(event.clientX + 14, innerWidth - tooltip.offsetWidth - 10));
    const y = Math.max(10, Math.min(event.clientY + 18, innerHeight - tooltip.offsetHeight - 10));
    tooltip.style.left = `${x}px`;
    tooltip.style.top = `${y}px`;
  });
  document.addEventListener('mouseout', event => {
    if (!hovered) return;
    if (event.relatedTarget && hovered.contains(event.relatedTarget)) return;
    hovered = null;
    tooltip.hidden = true;
  });
  document.addEventListener('click', event => {
    const marker = event.target.closest?.('.lean-goal-marker');
    if (marker) { event.preventDefault(); showGoals(marker); return; }
    const target = event.target.closest?.(selector);
    if (target) { event.preventDefault(); showToken(target); }
  });
  document.addEventListener('keydown', event => {
    if (!['Enter', ' '].includes(event.key)) return;
    const marker = event.target.closest?.('.lean-goal-marker');
    if (!marker) return;
    event.preventDefault();
    showGoals(marker);
  });
})();
