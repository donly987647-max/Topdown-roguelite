(() => {
  if (window.__LM_DOM_CONTROLS_INSTALLED) return;
  window.__LM_DOM_CONTROLS_INSTALLED = true;

  const style = document.createElement('style');
  style.textContent = `
    html, body { overscroll-behavior:none !important; touch-action:none !important; }
    #canvas { touch-action:none !important; }
    #lm-dom-controls { position:fixed; inset:0; z-index:2147483000; pointer-events:none; font-family:Arial,sans-serif; user-select:none; -webkit-user-select:none; display:none; }
    #lm-dom-controls * { box-sizing:border-box; }
    .lm-pad { position:absolute; width:132px; height:132px; bottom:calc(22px + env(safe-area-inset-bottom)); border:2px solid rgba(205,230,255,.48); border-radius:50%; background:rgba(35,50,70,.52); pointer-events:auto; touch-action:none; }
    #lm-move { left:18px; }
    #lm-aim { right:18px; }
    .lm-knob { position:absolute; left:36px; top:36px; width:56px; height:56px; border-radius:50%; pointer-events:none; transform:translate(0,0); }
    #lm-move .lm-knob { background:rgba(120,213,255,.82); }
    #lm-aim .lm-knob { background:rgba(255,145,82,.86); }
    .lm-caption { position:absolute; width:100%; bottom:-22px; text-align:center; color:rgba(230,240,255,.86); font-size:11px; font-weight:700; pointer-events:none; }
    .lm-btn { position:absolute; height:54px; min-width:104px; padding:0 15px; border:2px solid rgba(220,235,255,.45); border-radius:16px; color:#f5f8ff; font-size:14px; font-weight:800; pointer-events:auto; touch-action:none; }
    #lm-dodge { left:50%; transform:translateX(-112px); bottom:calc(166px + env(safe-area-inset-bottom)); background:rgba(36,103,145,.88); }
    #lm-reload { left:50%; transform:translateX(8px); bottom:calc(166px + env(safe-area-inset-bottom)); background:rgba(90,67,126,.90); }
    #lm-build { right:14px; top:calc(112px + env(safe-area-inset-top)); background:rgba(62,82,110,.94); min-width:92px; }
    #lm-status { position:absolute; left:50%; transform:translateX(-50%); bottom:calc(102px + env(safe-area-inset-bottom)); color:#78ff9a; background:rgba(0,0,0,.68); border:1px solid rgba(120,255,154,.5); border-radius:10px; padding:5px 9px; font:700 11px monospace; pointer-events:none; white-space:nowrap; }
    @media (max-width:420px) {
      .lm-pad { width:116px; height:116px; }
      .lm-knob { left:31px; top:31px; width:50px; height:50px; }
      #lm-move { left:12px; } #lm-aim { right:12px; }
      #lm-dodge { transform:translateX(-102px); bottom:calc(150px + env(safe-area-inset-bottom)); min-width:94px; }
      #lm-reload { transform:translateX(6px); bottom:calc(150px + env(safe-area-inset-bottom)); min-width:94px; }
      #lm-status { bottom:calc(88px + env(safe-area-inset-bottom)); }
    }
  `;
  document.head.appendChild(style);

  const root = document.createElement('div');
  root.id = 'lm-dom-controls';
  root.innerHTML = `
    <div id="lm-move" class="lm-pad"><div class="lm-knob"></div><div class="lm-caption">MOVE</div></div>
    <div id="lm-aim" class="lm-pad"><div class="lm-knob"></div><div class="lm-caption">AIM / FIRE</div></div>
    <button id="lm-dodge" class="lm-btn">DODGE</button>
    <button id="lm-reload" class="lm-btn">RELOAD</button>
    <button id="lm-build" class="lm-btn">BUILD</button>
    <div id="lm-status">WEB LIVE V6</div>
  `;
  document.body.appendChild(root);

  let touchCount = 0;
  const status = root.querySelector('#lm-status');
  const mark = () => {
    touchCount += 1;
    status.textContent = `WEB LIVE V6 #${touchCount}`;
  };

  const send = (kind, ...args) => {
    const cb = window.__lastMagazineControlCallback;
    if (typeof cb !== 'function') return false;
    cb(kind, ...args);
    return true;
  };

  const revealWhenGameIsReady = () => {
    if (window.__LM_GODOT_READY === true && typeof window.__lastMagazineControlCallback === 'function') {
      root.style.display = 'block';
      status.textContent = 'WEB LIVE V6';
      return;
    }
    window.setTimeout(revealWhenGameIsReady, 60);
  };
  revealWhenGameIsReady();

  function bindPad(el, kind) {
    const knob = el.querySelector('.lm-knob');
    let active = null;

    const update = (e) => {
      const r = el.getBoundingClientRect();
      const cx = r.left + r.width / 2;
      const cy = r.top + r.height / 2;
      const radius = Math.max(1, r.width * 0.42);
      let dx = (e.clientX - cx) / radius;
      let dy = (e.clientY - cy) / radius;
      const len = Math.hypot(dx, dy);
      if (len > 1) { dx /= len; dy /= len; }
      if (len < 0.12) { dx = 0; dy = 0; }
      const visual = Math.min(1, len) * radius * 0.62;
      const ang = Math.atan2(dy, dx);
      knob.style.transform = `translate(${Math.cos(ang) * visual}px, ${Math.sin(ang) * visual}px)`;
      if (kind === 'move') send('move', dx, dy);
      else send('aim', dx, dy, len >= 0.12);
    };

    const release = (e) => {
      if (active !== e.pointerId) return;
      active = null;
      knob.style.transform = 'translate(0,0)';
      if (kind === 'move') send('move', 0, 0);
      else send('aim', 0, 0, false);
      try { el.releasePointerCapture(e.pointerId); } catch (_) {}
      e.preventDefault();
    };

    el.addEventListener('pointerdown', (e) => {
      if (active !== null) return;
      active = e.pointerId;
      mark();
      try { el.setPointerCapture(e.pointerId); } catch (_) {}
      update(e);
      e.preventDefault();
    }, { passive:false });
    el.addEventListener('pointermove', (e) => {
      if (active !== e.pointerId) return;
      update(e);
      e.preventDefault();
    }, { passive:false });
    el.addEventListener('pointerup', release, { passive:false });
    el.addEventListener('pointercancel', release, { passive:false });
  }

  bindPad(root.querySelector('#lm-move'), 'move');
  bindPad(root.querySelector('#lm-aim'), 'aim');

  const bindButton = (selector, kind) => {
    root.querySelector(selector).addEventListener('pointerdown', (e) => {
      mark();
      send(kind);
      e.preventDefault();
    }, { passive:false });
  };
  bindButton('#lm-dodge', 'dodge');
  bindButton('#lm-reload', 'reload');
  bindButton('#lm-build', 'build');

  const clear = () => {
    send('move', 0, 0);
    send('aim', 0, 0, false);
    send('clear');
  };
  window.addEventListener('blur', clear);
  document.addEventListener('visibilitychange', () => { if (document.hidden) clear(); });
})();
