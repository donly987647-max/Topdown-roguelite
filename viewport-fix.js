'use strict';
(() => {
  const root = document.documentElement;
  const body = document.body;
  const rotateNotice = document.getElementById('rotateNotice');

  function viewportBox() {
    const viewport = window.visualViewport;
    return {
      width: Math.max(1, Math.round(viewport?.width || window.innerWidth)),
      height: Math.max(1, Math.round(viewport?.height || window.innerHeight)),
      left: Math.round(viewport?.offsetLeft || 0),
      top: Math.round(viewport?.offsetTop || 0)
    };
  }

  function syncRunState() {
    const controls = document.getElementById('mobileControls');
    body.classList.toggle('run-active', Boolean(controls && !controls.classList.contains('hidden')));
  }

  function fitViewport() {
    const view = viewportBox();
    root.style.setProperty('--app-width', `${view.width}px`);
    root.style.setProperty('--app-height', `${view.height}px`);
    root.style.setProperty('--viewport-left', `${view.left}px`);
    root.style.setProperty('--viewport-top', `${view.top}px`);
    body.classList.toggle('portrait-layout', view.height > view.width);
    syncRunState();

    if (typeof canvas === 'undefined' || typeof ctx === 'undefined') return;

    DPR = Math.min(window.devicePixelRatio || 1, 2);
    const scale = Math.min(view.width / W, view.height / H);
    const cssWidth = Math.max(1, Math.round(W * scale));
    const cssHeight = Math.max(1, Math.round(H * scale));
    const left = view.left + Math.round((view.width - cssWidth) / 2);
    const top = view.top + Math.round((view.height - cssHeight) / 2);

    canvas.width = Math.round(W * DPR);
    canvas.height = Math.round(H * DPR);
    canvas.style.width = `${cssWidth}px`;
    canvas.style.height = `${cssHeight}px`;
    canvas.style.left = `${left}px`;
    canvas.style.top = `${top}px`;
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }

  resize = fitViewport;

  const controls = document.getElementById('mobileControls');
  if (controls) {
    new MutationObserver(syncRunState).observe(controls, {
      attributes: true,
      attributeFilter: ['class']
    });
  }

  window.addEventListener('resize', fitViewport, { passive: true });
  window.addEventListener('orientationchange', () => {
    window.setTimeout(fitViewport, 80);
    window.setTimeout(fitViewport, 350);
  }, { passive: true });
  window.visualViewport?.addEventListener('resize', fitViewport, { passive: true });
  window.visualViewport?.addEventListener('scroll', fitViewport, { passive: true });

  rotateNotice?.addEventListener('click', () => {
    if (document.documentElement.requestFullscreen) {
      document.documentElement.requestFullscreen().catch(() => {});
    }
  });

  fitViewport();
  window.setTimeout(fitViewport, 120);
})();
