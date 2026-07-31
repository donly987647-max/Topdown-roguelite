import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { chromium } from 'playwright';

const root = process.cwd();
const entry = path.join(root, 'index.html');
const outputDir = path.join(root, 'builds', 'original-web-smoke');
fs.mkdirSync(outputDir, { recursive: true });

const launchOptions = {
  headless: true,
  args: ['--disable-dev-shm-usage', '--no-sandbox'],
};
if (process.env.CHROME_PATH) {
  launchOptions.executablePath = process.env.CHROME_PATH;
}

const browser = await chromium.launch(launchOptions);
const context = await browser.newContext({
  viewport: { width: 1280, height: 720 },
  screen: { width: 1280, height: 720 },
  hasTouch: true,
  isMobile: true,
  deviceScaleFactor: 1,
  userAgent:
    'Mozilla/5.0 (Linux; Android 16; LAST MAGAZINE Smoke Test) ' +
    'AppleWebKit/537.36 Chrome/136.0 Mobile Safari/537.36',
});
const page = await context.newPage();
const pageErrors = [];

page.on('pageerror', error => pageErrors.push(error.message));
page.on('console', message => {
  if (message.type() === 'error') {
    pageErrors.push(`console: ${message.text()}`);
  }
});

try {
  await page.goto(pathToFileURL(entry).href, { waitUntil: 'load' });
  await page.waitForSelector('#titleScreen.active');
  await page.waitForFunction(() => window.LM_DATA && window.LM_DATA.weapons.length > 0);

  await page.locator('#startSetupBtn').tap();
  await page.waitForSelector('#setupScreen.active');
  await page.locator('#launchBtn').tap();
  await page.waitForFunction(() => !document.querySelector('#hud').classList.contains('hidden'));
  await page.waitForFunction(() => typeof run !== 'undefined' && run && screen === 'game');

  await page.evaluate(() => {
    run.enemies.length = 0;
    roomComplete(false);
  });
  await page.waitForSelector('#rewardScreen.active', { timeout: 5000 });

  const rewardCards = page.locator('#rewardCards [data-r]');
  assert.equal(await rewardCards.count(), 3, 'First room clear must show three reward cards');

  const viewport = page.viewportSize();
  assert.ok(viewport, 'Viewport must be available');
  for (let index = 0; index < 3; index += 1) {
    const card = rewardCards.nth(index);
    await card.waitFor({ state: 'visible' });
    const box = await card.boundingBox();
    assert.ok(box, `Reward card ${index + 1} must have a touch target`);
    assert.ok(box.width >= 120 && box.height >= 100, `Reward card ${index + 1} touch target is too small`);
    assert.ok(box.x >= 0 && box.y >= 0, `Reward card ${index + 1} starts outside the viewport`);
    assert.ok(
      box.x + box.width <= viewport.width + 1 && box.y + box.height <= viewport.height + 1,
      `Reward card ${index + 1} extends outside the viewport`,
    );
  }

  await page.screenshot({
    path: path.join(outputDir, 'first-room-reward-mobile.png'),
    fullPage: true,
  });

  await rewardCards.first().tap();
  await page.waitForFunction(() => !document.querySelector('#rewardScreen').classList.contains('active'));

  let currentScreen = await page.evaluate(() => screen);
  if (currentScreen === 'inventory') {
    await page.locator('#autoArrange').tap();
    await page.locator('#applyBag').tap();
    await page.waitForSelector('#routeScreen.active');
    currentScreen = await page.evaluate(() => screen);
  }
  assert.equal(currentScreen, 'route', 'Reward touch must advance to route selection');

  const routeCards = page.locator('#routeCards [data-route]');
  assert.ok((await routeCards.count()) >= 1, 'Route screen must expose a touch-selectable option');
  await routeCards.first().tap();
  await page.waitForFunction(() => screen !== 'route');
  assert.equal(await page.evaluate(() => run.routeHistory.length), 1, 'Route touch must be recorded');

  await page.evaluate(() => openInventory(false));
  await page.waitForSelector('#inventoryScreen.active');
  await page.locator('#applyBag').tap();
  await page.waitForFunction(() => screen === 'game');

  await page.evaluate(() => localStorage.setItem('lastMagazineAndroidSmoke', 'persisted'));
  await page.reload({ waitUntil: 'load' });
  assert.equal(
    await page.evaluate(() => localStorage.getItem('lastMagazineAndroidSmoke')),
    'persisted',
    'LocalStorage must persist across an offline app reload',
  );

  assert.deepEqual(pageErrors, [], `Original web build emitted errors: ${pageErrors.join(' | ')}`);
  console.log('[ORIGINAL MOBILE SMOKE] PASS');
} finally {
  await context.close();
  await browser.close();
}
