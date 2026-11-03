// Visible mouse cursor for Playwright recordings (headless video does not draw one).
//
//   const cursor = require(`${process.env.HOME}/.local/share/pr-media/cursor.js`);
//   await cursor.install(context);          // before the first page.goto
//   await cursor.click(page, locator);      // glide to the element, pause, click
//   await cursor.fill(page, locator, text); // glide, click, type at a readable pace
//   await cursor.moveTo(page, locator);     // glide only (also accepts {x, y})
//
// Every glide takes the same time and the same number of equal steps, whatever the
// distance or direction: constant speed, no easing, no CSS transition. The dot is
// placed exactly where the mouse is at each step.

const DURATION_MS = 500;
const STEPS = 30;
const PAUSE_BEFORE_CLICK_MS = 300;
const PAUSE_AFTER_CLICK_MS = 600;
const TYPE_DELAY_MS = 60;

const positions = new WeakMap();

function drawCursor() {
  if (window.__prMediaCursor) return;
  window.__prMediaCursor = true;
  const SIZE = 18;
  const PRESSED = 26;
  const NORMAL_COLOR = 'rgba(255, 60, 60, 0.6)';
  const PRESSED_COLOR = 'rgba(255, 190, 0, 0.85)';
  let last = 'translate(-100px, -100px)';
  const setSize = (dot, size, color) => {
    Object.assign(dot.style, {
      width: `${size}px`,
      height: `${size}px`,
      margin: `-${size / 2}px 0 0 -${size / 2}px`,
      background: color,
    });
  };
  // Re-created whenever it is missing (a page can replace the whole document).
  const ensureDot = () => {
    let dot = document.getElementById('__pr_media_cursor');
    if (dot || !document.documentElement) return dot;
    dot = document.createElement('div');
    dot.id = '__pr_media_cursor';
    Object.assign(dot.style, {
      position: 'fixed',
      left: '0',
      top: '0',
      borderRadius: '50%',
      border: '2px solid #fff',
      boxShadow: '0 0 3px rgba(0, 0, 0, 0.6)',
      pointerEvents: 'none',
      zIndex: '2147483647',
      transform: last,
    });
    setSize(dot, SIZE, NORMAL_COLOR);
    document.documentElement.appendChild(dot);
    return dot;
  };
  window.addEventListener('mousemove', (e) => {
    last = `translate(${e.clientX}px, ${e.clientY}px)`;
    const dot = ensureDot();
    if (dot) dot.style.transform = last;
  }, true);
  window.addEventListener('mousedown', () => {
    const dot = ensureDot();
    if (dot) setSize(dot, PRESSED, PRESSED_COLOR);
  }, true);
  window.addEventListener('mouseup', () => {
    setTimeout(() => {
      const dot = ensureDot();
      if (dot) setSize(dot, SIZE, NORMAL_COLOR);
    }, 150);
  }, true);
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', ensureDot);
  } else {
    ensureDot();
  }
}

async function install(context) {
  await context.addInitScript(drawCursor);
}

async function targetPoint(target) {
  if (typeof target.x === 'number' && typeof target.y === 'number') return target;
  await target.scrollIntoViewIfNeeded();
  const box = await target.boundingBox();
  if (!box) throw new Error('cursor: target is not visible');
  return { x: box.x + box.width / 2, y: box.y + box.height / 2 };
}

async function moveTo(page, target) {
  const to = await targetPoint(target);
  const viewport = page.viewportSize() || { width: 1280, height: 800 };
  const from = positions.get(page) || { x: viewport.width / 2, y: viewport.height / 2 };
  // Show the dot where the mouse already is (a new page starts with it hidden).
  await page.mouse.move(from.x, from.y);
  for (let i = 1; i <= STEPS; i += 1) {
    const t = i / STEPS;
    await page.mouse.move(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t);
    await page.waitForTimeout(DURATION_MS / STEPS);
  }
  positions.set(page, to);
}

async function click(page, target) {
  await moveTo(page, target);
  await page.waitForTimeout(PAUSE_BEFORE_CLICK_MS);
  if (typeof target.click === 'function') {
    await target.click();
  } else {
    await page.mouse.down();
    await page.mouse.up();
  }
  await page.waitForTimeout(PAUSE_AFTER_CLICK_MS);
}

async function fill(page, target, text) {
  await click(page, target);
  await page.keyboard.type(text, { delay: TYPE_DELAY_MS });
  await page.waitForTimeout(PAUSE_AFTER_CLICK_MS);
}

module.exports = { install, moveTo, click, fill, DURATION_MS, STEPS };
