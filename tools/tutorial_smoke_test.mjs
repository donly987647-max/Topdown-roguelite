import fs from 'node:fs';
import { chromium } from 'playwright-core';

const chromeCandidates = [
  process.env.CHROME_PATH,
  '/usr/bin/google-chrome',
  '/usr/bin/google-chrome-stable',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser'
].filter(Boolean);
const executablePath = chromeCandidates.find(path => fs.existsSync(path));
if (!executablePath) throw new Error('System Chrome/Chromium was not found.');

const browser = await chromium.launch({ executablePath, headless: true, args: ['--no-sandbox', '--disable-dev-shm-usage'] });
const page = await browser.newPage({ viewport: { width: 960, height: 540 }, isMobile: true, hasTouch: true });
const pageErrors = [];
page.on('pageerror', error => pageErrors.push(String(error)));

try {
  await page.goto('http://127.0.0.1:4173/?tutorialSmoke=1', { waitUntil: 'networkidle' });
  await page.waitForSelector('#tutorialStartBtn', { state: 'visible' });
  await page.tap('#tutorialStartBtn');
  await page.waitForSelector('#tutorialCoach:not(.hidden)', { state: 'visible' });

  const first = await page.evaluate(() => window.LM_TUTORIAL?.state());
  if (!first?.active || first.id !== 'move') throw new Error(`Tutorial did not start at movement step: ${JSON.stringify(first)}`);

  await page.evaluate(() => { run.player.x += 80; });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'fire');
  await page.evaluate(() => { run.player.ammo -= 1; });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'reload');
  await page.evaluate(() => { run.player.reloading = true; });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'dash');
  await page.evaluate(() => { run.player.rollCd = 0.7; });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'telegraph');

  await page.evaluate(() => window.LM_TUTORIAL.next());
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'clear');
  await page.evaluate(() => { run.roomClear = true; show('reward'); });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'reward');
  await page.evaluate(() => { show('inventory'); });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'assembly');

  await page.evaluate(() => window.LM_TUTORIAL.next());
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'grid');
  await page.evaluate(() => window.LM_TUTORIAL.next());
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'shop');
  await page.evaluate(() => window.LM_TUTORIAL.next());
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'miniboss');
  await page.evaluate(() => window.LM_TUTORIAL.next());

  const finished = await page.evaluate(() => ({ state: window.LM_TUTORIAL?.state(), save: save.tutorial }));
  if (!finished.state?.completed || !finished.save?.completed) throw new Error(`Tutorial completion was not stored: ${JSON.stringify(finished)}`);

  await page.evaluate(() => { renderSettings(document.querySelector('#overlayModal')); });
  await page.waitForSelector('#replayTutorial');
  const toggleExists = await page.locator('[data-setting="tutorialMessages"]').count();
  if (!toggleExists) throw new Error('Tutorial message toggle is missing from settings.');

  await page.screenshot({ path: 'tutorial-smoke-960x540.png', fullPage: true });
  if (pageErrors.length) throw new Error(`Page errors: ${pageErrors.join('\n')}`);
  console.log('Tutorial smoke test passed.');
} finally {
  await browser.close();
}
