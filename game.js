(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const statsEl = document.getElementById('stats');
  const timerEl = document.getElementById('timer');
  const healthEl = document.getElementById('health');
  const dashBtn = document.getElementById('dash');
  const joystickBase = document.getElementById('joystickBase');
  const joystickKnob = document.getElementById('joystickKnob');
  const overlay = document.getElementById('overlay');
  const resultEl = document.getElementById('result');
  const restartBtn = document.getElementById('restart');

  const TAU = Math.PI * 2;
  const WORLD = 2200;
  const input = { x: 0, y: 0, keys: new Set(), joystickId: null };
  let dpr = 1;
  let width = 0;
  let height = 0;
  let lastTime = performance.now();
  let game;

  function newGame() {
    game = {
      over: false,
      elapsed: 0,
      spawnTimer: 0,
      kills: 0,
      level: 1,
      nextLevelKills: 8,
      bullets: [],
      enemies: [],
      particles: [],
      player: {
        x: WORLD / 2,
        y: WORLD / 2,
        r: 18,
        speed: 250,
        hp: 100,
        maxHp: 100,
        damage: 34,
        fireRate: 0.42,
        fireTimer: 0,
        dashCooldown: 1.9,
        dashTimer: 0,
        dashDuration: 0,
        invulnerable: 0
      }
    };
    overlay.style.display = 'none';
    dashBtn.disabled = false;
    lastTime = performance.now();
    updateHud();
  }

  function resize() {
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    width = window.innerWidth;
    height = window.innerHeight;
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function normalize(x, y) {
    const length = Math.hypot(x, y);
    return length > 0 ? { x: x / length, y: y / length } : { x: 0, y: 0 };
  }

  function keyboardVector() {
    let x = 0;
    let y = 0;
    if (input.keys.has('KeyA') || input.keys.has('ArrowLeft')) x -= 1;
    if (input.keys.has('KeyD') || input.keys.has('ArrowRight')) x += 1;
    if (input.keys.has('KeyW') || input.keys.has('ArrowUp')) y -= 1;
    if (input.keys.has('KeyS') || input.keys.has('ArrowDown')) y += 1;
    return normalize(x, y);
  }

  function moveVector() {
    const keyboard = keyboardVector();
    if (keyboard.x !== 0 || keyboard.y !== 0) return keyboard;
    return normalize(input.x, input.y);
  }

  function activateDash() {
    if (!game || game.over) return;
    const p = game.player;
    if (p.dashTimer > 0) return;
    const move = moveVector();
    if (move.x === 0 && move.y === 0) return;
    p.dashTimer = p.dashCooldown;
    p.dashDuration = 0.18;
    p.invulnerable = Math.max(p.invulnerable, 0.24);
    dashBtn.disabled = true;
  }

  function spawnEnemy() {
    const p = game.player;
    const angle = Math.random() * TAU;
    const distance = Math.max(width, height) * 0.65 + 150 + Math.random() * 220;
    const difficulty = 1 + game.elapsed / 75;
    const typeRoll = Math.random();
    let r = 17;
    let speed = 85 + Math.random() * 24;
    let hp = 52;
    let damage = 14;
    let color = '#ff5d73';

    if (typeRoll > 0.84) {
      r = 25;
      speed = 58;
      hp = 145;
      damage = 24;
      color = '#c77dff';
    } else if (typeRoll > 0.58) {
      r = 13;
      speed = 132;
      hp = 34;
      damage = 10;
      color = '#ffb347';
    }

    game.enemies.push({
      x: clamp(p.x + Math.cos(angle) * distance, 40, WORLD - 40),
      y: clamp(p.y + Math.sin(angle) * distance, 40, WORLD - 40),
      r,
      speed: speed * difficulty,
      hp: hp * (0.9 + difficulty * 0.12),
      damage,
      color,
      hitFlash: 0
    });
  }

  function nearestEnemy() {
    const p = game.player;
    let target = null;
    let best = Infinity;
    for (const enemy of game.enemies) {
      const dx = enemy.x - p.x;
      const dy = enemy.y - p.y;
      const distanceSq = dx * dx + dy * dy;
      if (distanceSq < best) {
        best = distanceSq;
        target = enemy;
      }
    }
    return target;
  }

  function fireAt(target) {
    const p = game.player;
    const direction = normalize(target.x - p.x, target.y - p.y);
    game.bullets.push({
      x: p.x + direction.x * (p.r + 8),
      y: p.y + direction.y * (p.r + 8),
      vx: direction.x * 680,
      vy: direction.y * 680,
      r: 6,
      life: 1.15,
      damage: p.damage
    });
  }

  function burst(x, y, color, count = 8) {
    for (let i = 0; i < count; i += 1) {
      const angle = Math.random() * TAU;
      const speed = 45 + Math.random() * 150;
      game.particles.push({
        x, y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: 0.25 + Math.random() * 0.35,
        maxLife: 0.6,
        r: 2 + Math.random() * 3,
        color
      });
    }
  }

  function levelUpIfNeeded() {
    if (game.kills < game.nextLevelKills) return;
    game.level += 1;
    game.nextLevelKills += 7 + game.level * 3;
    const p = game.player;
    const cycle = game.level % 3;
    if (cycle === 0) {
      p.damage += 12;
    } else if (cycle === 1) {
      p.fireRate = Math.max(0.14, p.fireRate * 0.86);
    } else {
      p.maxHp += 16;
      p.hp = Math.min(p.maxHp, p.hp + 24);
    }
    burst(p.x, p.y, '#7df9ff', 24);
  }

  function update(dt) {
    if (game.over) return;
    const p = game.player;
    game.elapsed += dt;
    p.fireTimer -= dt;
    p.dashTimer = Math.max(0, p.dashTimer - dt);
    p.dashDuration = Math.max(0, p.dashDuration - dt);
    p.invulnerable = Math.max(0, p.invulnerable - dt);
    if (p.dashTimer <= 0) dashBtn.disabled = false;

    const move = moveVector();
    const speed = p.speed * (p.dashDuration > 0 ? 3.4 : 1);
    p.x = clamp(p.x + move.x * speed * dt, p.r, WORLD - p.r);
    p.y = clamp(p.y + move.y * speed * dt, p.r, WORLD - p.r);

    game.spawnTimer -= dt;
    const spawnDelay = Math.max(0.23, 1.05 - game.elapsed / 125);
    if (game.spawnTimer <= 0 && game.enemies.length < 90) {
      spawnEnemy();
      if (game.elapsed > 35 && Math.random() < 0.25) spawnEnemy();
      game.spawnTimer = spawnDelay;
    }

    const target = nearestEnemy();
    if (target && p.fireTimer <= 0) {
      fireAt(target);
      p.fireTimer = p.fireRate;
    }

    for (let i = game.bullets.length - 1; i >= 0; i -= 1) {
      const bullet = game.bullets[i];
      bullet.x += bullet.vx * dt;
      bullet.y += bullet.vy * dt;
      bullet.life -= dt;
      let removed = bullet.life <= 0;

      if (!removed) {
        for (let j = game.enemies.length - 1; j >= 0; j -= 1) {
          const enemy = game.enemies[j];
          if (Math.hypot(bullet.x - enemy.x, bullet.y - enemy.y) <= bullet.r + enemy.r) {
            enemy.hp -= bullet.damage;
            enemy.hitFlash = 0.08;
            burst(bullet.x, bullet.y, '#ffffff', 4);
            removed = true;
            if (enemy.hp <= 0) {
              burst(enemy.x, enemy.y, enemy.color, 12);
              game.enemies.splice(j, 1);
              game.kills += 1;
              levelUpIfNeeded();
            }
            break;
          }
        }
      }

      if (removed) game.bullets.splice(i, 1);
    }

    for (const enemy of game.enemies) {
      enemy.hitFlash = Math.max(0, enemy.hitFlash - dt);
      const direction = normalize(p.x - enemy.x, p.y - enemy.y);
      enemy.x += direction.x * enemy.speed * dt;
      enemy.y += direction.y * enemy.speed * dt;
      const overlap = p.r + enemy.r;
      const distance = Math.hypot(p.x - enemy.x, p.y - enemy.y);
      if (distance < overlap) {
        if (p.invulnerable <= 0) {
          p.hp -= enemy.damage;
          p.invulnerable = 0.55;
          burst(p.x, p.y, '#ff3f5f', 18);
          if (p.hp <= 0) endGame();
        }
        const push = normalize(enemy.x - p.x, enemy.y - p.y);
        enemy.x += push.x * (overlap - distance + 4);
        enemy.y += push.y * (overlap - distance + 4);
      }
    }

    for (let i = game.particles.length - 1; i >= 0; i -= 1) {
      const particle = game.particles[i];
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
      particle.vx *= 0.96;
      particle.vy *= 0.96;
      particle.life -= dt;
      if (particle.life <= 0) game.particles.splice(i, 1);
    }

    updateHud();
  }

  function endGame() {
    game.over = true;
    const minutes = Math.floor(game.elapsed / 60);
    const seconds = Math.floor(game.elapsed % 60).toString().padStart(2, '0');
    resultEl.textContent = `${minutes}:${seconds} 생존 · ${game.kills}킬 · 레벨 ${game.level}`;
    overlay.style.display = 'grid';
  }

  function updateHud() {
    if (!game) return;
    const p = game.player;
    statsEl.textContent = `LV ${game.level} · ${game.kills} KILLS`;
    const minutes = Math.floor(game.elapsed / 60).toString().padStart(2, '0');
    const seconds = Math.floor(game.elapsed % 60).toString().padStart(2, '0');
    timerEl.textContent = `${minutes}:${seconds}`;
    healthEl.style.width = `${Math.max(0, p.hp / p.maxHp) * 100}%`;
  }

  function drawGrid(cameraX, cameraY) {
    const size = 80;
    const startX = -((cameraX - width / 2) % size);
    const startY = -((cameraY - height / 2) % size);
    ctx.strokeStyle = 'rgba(130,160,220,.09)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = startX; x <= width; x += size) {
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
    }
    for (let y = startY; y <= height; y += size) {
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
    }
    ctx.stroke();
  }

  function drawCircle(x, y, r, color) {
    ctx.beginPath();
    ctx.arc(x, y, r, 0, TAU);
    ctx.fillStyle = color;
    ctx.fill();
  }

  function render() {
    if (!game) return;
    const p = game.player;
    const cameraX = clamp(p.x, width / 2, WORLD - width / 2);
    const cameraY = clamp(p.y, height / 2, WORLD - height / 2);
    const sx = x => x - cameraX + width / 2;
    const sy = y => y - cameraY + height / 2;

    ctx.clearRect(0, 0, width, height);
    const gradient = ctx.createRadialGradient(width / 2, height / 2, 20, width / 2, height / 2, Math.max(width, height));
    gradient.addColorStop(0, '#17203a');
    gradient.addColorStop(1, '#080b14');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
    drawGrid(cameraX, cameraY);

    ctx.strokeStyle = 'rgba(140,175,255,.35)';
    ctx.lineWidth = 3;
    ctx.strokeRect(sx(0), sy(0), WORLD, WORLD);

    for (const particle of game.particles) {
      ctx.globalAlpha = clamp(particle.life / particle.maxLife, 0, 1);
      drawCircle(sx(particle.x), sy(particle.y), particle.r, particle.color);
    }
    ctx.globalAlpha = 1;

    for (const bullet of game.bullets) {
      drawCircle(sx(bullet.x), sy(bullet.y), bullet.r + 5, 'rgba(115,245,255,.18)');
      drawCircle(sx(bullet.x), sy(bullet.y), bullet.r, '#9cfaff');
    }

    for (const enemy of game.enemies) {
      const ex = sx(enemy.x);
      const ey = sy(enemy.y);
      drawCircle(ex, ey, enemy.r + 5, 'rgba(255,60,100,.12)');
      drawCircle(ex, ey, enemy.r, enemy.hitFlash > 0 ? '#ffffff' : enemy.color);
      drawCircle(ex - enemy.r * 0.28, ey - 2, 2.5, '#12141f');
      drawCircle(ex + enemy.r * 0.28, ey - 2, 2.5, '#12141f');
    }

    const playerAlpha = p.invulnerable > 0 && Math.floor(p.invulnerable * 24) % 2 === 0 ? 0.38 : 1;
    ctx.globalAlpha = playerAlpha;
    drawCircle(sx(p.x), sy(p.y), p.r + 9, 'rgba(68,235,255,.16)');
    drawCircle(sx(p.x), sy(p.y), p.r, '#62e7ff');
    drawCircle(sx(p.x) - 5, sy(p.y) - 3, 3, '#07111c');
    drawCircle(sx(p.x) + 5, sy(p.y) - 3, 3, '#07111c');
    ctx.globalAlpha = 1;

    if (p.dashDuration > 0) {
      ctx.strokeStyle = 'rgba(100,225,255,.8)';
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.arc(sx(p.x), sy(p.y), p.r + 15, 0, TAU);
      ctx.stroke();
    }
  }

  function loop(now) {
    const dt = Math.min(0.033, (now - lastTime) / 1000);
    lastTime = now;
    update(dt);
    render();
    requestAnimationFrame(loop);
  }

  function setJoystick(clientX, clientY) {
    const rect = joystickBase.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    let dx = clientX - centerX;
    let dy = clientY - centerY;
    const max = rect.width * 0.34;
    const length = Math.hypot(dx, dy);
    if (length > max) {
      dx = dx / length * max;
      dy = dy / length * max;
    }
    input.x = dx / max;
    input.y = dy / max;
    joystickKnob.style.transform = `translate(${dx}px, ${dy}px)`;
  }

  function resetJoystick() {
    input.x = 0;
    input.y = 0;
    input.joystickId = null;
    joystickKnob.style.transform = 'translate(0px, 0px)';
  }

  window.addEventListener('resize', resize, { passive: true });
  window.addEventListener('keydown', event => {
    input.keys.add(event.code);
    if (event.code === 'Space') {
      event.preventDefault();
      activateDash();
    }
    if (event.code === 'KeyR' && game.over) newGame();
  });
  window.addEventListener('keyup', event => input.keys.delete(event.code));

  window.addEventListener('pointerdown', event => {
    if (event.target === dashBtn || event.target === restartBtn) return;
    const rect = joystickBase.getBoundingClientRect();
    const nearJoystick = event.clientX < rect.right + 60 && event.clientY > rect.top - 60;
    if (nearJoystick && input.joystickId === null) {
      input.joystickId = event.pointerId;
      setJoystick(event.clientX, event.clientY);
    }
  });
  window.addEventListener('pointermove', event => {
    if (event.pointerId === input.joystickId) setJoystick(event.clientX, event.clientY);
  });
  window.addEventListener('pointerup', event => {
    if (event.pointerId === input.joystickId) resetJoystick();
  });
  window.addEventListener('pointercancel', event => {
    if (event.pointerId === input.joystickId) resetJoystick();
  });

  dashBtn.addEventListener('pointerdown', event => {
    event.preventDefault();
    activateDash();
  });
  restartBtn.addEventListener('click', newGame);

  resize();
  newGame();
  requestAnimationFrame(loop);
})();
