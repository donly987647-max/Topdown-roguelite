'use strict';
(() => {
  const root = document.documentElement;
  const body = document.body;

  function viewportBox() {
    const viewport = window.visualViewport;
    return {
      width: Math.max(1, Math.round(viewport?.width || window.innerWidth)),
      height: Math.max(1, Math.round(viewport?.height || window.innerHeight)),
      left: Math.round(viewport?.offsetLeft || 0),
      top: Math.round(viewport?.offsetTop || 0)
    };
  }

  function fitViewportFullBleed() {
    const view = viewportBox();
    root.style.setProperty('--app-width', `${view.width}px`);
    root.style.setProperty('--app-height', `${view.height}px`);
    root.style.setProperty('--viewport-left', `${view.left}px`);
    root.style.setProperty('--viewport-top', `${view.top}px`);

    body.classList.remove('portrait-layout', 'run-active');

    if (typeof canvas === 'undefined' || typeof ctx === 'undefined') return;

    DPR = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(W * DPR);
    canvas.height = Math.round(H * DPR);
    canvas.style.width = `${view.width}px`;
    canvas.style.height = `${view.height}px`;
    canvas.style.left = `${view.left}px`;
    canvas.style.top = `${view.top}px`;
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }

  function loadTutorialLayer() {
    if (!document.querySelector('link[href="tutorial.css"]')) {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = 'tutorial.css';
      document.head.appendChild(link);
    }
    if (!document.querySelector('script[src="tutorial.js"]')) {
      const script = document.createElement('script');
      script.src = 'tutorial.js';
      script.defer = true;
      document.body.appendChild(script);
    }
  }

  resize = fitViewportFullBleed;
  window.addEventListener('resize', fitViewportFullBleed, { passive: true });
  window.addEventListener('orientationchange', () => {
    window.setTimeout(fitViewportFullBleed, 60);
    window.setTimeout(fitViewportFullBleed, 280);
  }, { passive: true });
  window.visualViewport?.addEventListener('resize', fitViewportFullBleed, { passive: true });
  window.visualViewport?.addEventListener('scroll', fitViewportFullBleed, { passive: true });

  fitViewportFullBleed();
  window.setTimeout(fitViewportFullBleed, 100);
  loadTutorialLayer();
})();
