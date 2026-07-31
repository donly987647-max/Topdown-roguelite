import fs from 'node:fs';
import { chromium } from 'playwright';

fs.mkdirSync('builds/tutorial-android-smoke', { recursive: true });
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
const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, isMobile: true, hasTouch: true });
const errors = [];
page.on('pageerror', error => errors.push(String(error)));

try {
  await page.goto('http://127.0.0.1:4173/?tutorialAndroid=1', { waitUntil: 'networkidle' });
  await page.waitForSelector('#tutorialStartBtn', { state: 'visible' });
  await page.tap('#tutorialStartBtn');
  await page.waitForSelector('#tutorialCoach:not(.hidden)', { state: 'visible' });

  const state = () => page.evaluate(() => window.LM_TUTORIAL?.state());
  if ((await state())?.id !== 'move') throw new Error('Tutorial did not start at movement.');
  await page.evaluate(() => { run.player.x += 80; });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'fire');
  await page.evaluate(() => { run.player.ammo -= 1; });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'reload');
  await page.evaluate(() => { run.player.reloading = true; });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'dash');
  await page.evaluate(() => { run.player.rollCd = 0.8; });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'telegraph');
  await page.evaluate(() => window.LM_TUTORIAL.next());
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'clear');
  await page.evaluate(() => { run.roomClear = true; show('reward'); });
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'reward');
  await page.waitForTimeout(100);
  await page.evaluate(() => show('inventory'));
  await page.waitForFunction(() => window.LM_TUTORIAL?.state().id === 'assembly');
  for (const id of ['grid','shop','miniboss']) {
    await page.evaluate(() => window.LM_TUTORIAL.next());
    await page.waitForFunction(expected => window.LM_TUTORIAL?.state().id === expected, id);
  }
  await page.evaluate(() => window.LM_TUTORIAL.next());
  const final = await page.evaluate(() => ({ tutorial: window.LM_TUTORIAL?.state(), saved: save.tutorial }));
  if (!final.tutorial?.completed || !final.saved?.completed) throw new Error(`Tutorial completion did not persist: ${JSON.stringify(final)}`);

  await page.evaluate(() => renderSettings(document.querySelector('#overlayModal')));
  await page.waitForSelector('#replayTutorial');
  if (!(await page.locator('[data-setting="tutorialMessages"]').count())) throw new Error('Tutorial settings toggle is missing.');
  await page.screenshot({ path: 'builds/tutorial-android-smoke/tutorial-1280x720.png', fullPage: true });
  if (errors.length) throw new Error(errors.join('\n'));
  console.log('Android tutorial smoke test passed.');
} finally {
  await browser.close();
}
