// Captures app screens from the local web build (localhost:5173) for the promo.
// Usage: node capture.mjs <step-script.json>  — or edit STEPS below.
import puppeteer from 'puppeteer-core';
import fs from 'node:fs';

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const steps = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const browser = await puppeteer.launch({executablePath: CHROME, headless: 'new',
  args: ['--force-device-scale-factor=3']});
const page = await browser.newPage();
await page.setViewport({width: 390, height: 844, deviceScaleFactor: 3, isMobile: true, hasTouch: false});
await page.goto('http://localhost:5173', {waitUntil: 'networkidle0'});
await sleep(4500);
for (const s of steps) {
  if (s.click) { await page.mouse.click(s.click[0], s.click[1]); }
  if (s.hold) { await page.mouse.move(s.hold[0], s.hold[1]); await page.mouse.down(); await sleep(s.ms ?? 800); await page.mouse.up(); }
  if (s.hash) { await page.evaluate((h) => { location.hash = h; }, s.hash); }
  if (s.scroll) { await page.mouse.move(195, 420); await page.mouse.wheel({deltaY: s.scroll}); }
  await sleep(s.wait ?? 1500);
  if (s.shot) { await page.screenshot({path: `public/screens/${s.shot}.png`}); console.log('saved', s.shot); }
}
await browser.close();
