// Visible mouse cursor for Playwright recordings (headless video does not draw one).
//
//   const cursor = require(`${process.env.HOME}/.local/share/pr-media/cursor.js`);
//   await cursor.install(context);          // before the first page.goto
//   await cursor.click(page, locator);      // glide to the element, pause, click
//   await cursor.fill(page, locator, text); // glide, click, type at a readable pace
//   await cursor.moveTo(page, locator);     // glide only (also accepts {x, y})
//   await cursor.screenshot(page, 'shot.png', locator); // current viewport, locator in view
//
// The pointer is an arrow like the OS one; a click shows a slow ripple (1 s) that
// keeps playing if the click loads another page of the same site.
// Every glide takes the same time and the same number of equal steps, whatever the
// distance or direction: constant speed, no easing, no CSS transition. The arrow is
// placed exactly where the mouse is at each step.

const DURATION_MS = 500;
const STEPS = 30;
const PAUSE_BEFORE_CLICK_MS = 300;
const PAUSE_AFTER_CLICK_MS = 1100; // lets the 1 s click ripple finish
const TYPE_DELAY_MS = 60;

const positions = new WeakMap();

function drawCursor() {
  if (window.__prMediaCursor) return;
  window.__prMediaCursor = true;
  const RIPPLE_MS = 1000;
  const RIPPLE_SIZE = 96;
  const KEY = '__pr_media_cursor';
  const ARROW =
    '<svg xmlns="http://www.w3.org/2000/svg" width="22" height="30" viewBox="0 0 22 30">' +
    '<path d="M1 1 L1 24 L7 18.5 L11 28 L15 26.3 L11 17 L19 17 Z" ' +
    'fill="#111" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/></svg>';

  // Last position and an in-flight click survive navigations within the tab, so the
  // arrow shows where it was and a click's ripple keeps playing on the next page.
  const load = () => {
    try { return JSON.parse(sessionStorage.getItem(KEY)) || {}; } catch (e) { return {}; }
  };
  const save = (state) => {
    try { sessionStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { /* ignore */ }
  };
  let state = load();

  const ensure = (id, build) => {
    let el = document.getElementById(id);
    if (el || !document.documentElement) return el;
    el = build();
    el.id = id;
    document.documentElement.appendChild(el);
    return el;
  };
  const arrow = () => ensure('__pr_media_arrow', () => {
    const el = document.createElement('div');
    el.innerHTML = ARROW;
    Object.assign(el.style, {
      position: 'fixed', left: '0', top: '0', width: '22px', height: '30px',
      pointerEvents: 'none', zIndex: '2147483647',
      filter: 'drop-shadow(0 1px 2px rgba(0, 0, 0, 0.45))',
      transform: state.x === undefined ? 'translate(-100px, -100px)' : `translate(${state.x}px, ${state.y}px)`,
    });
    return el;
  });
  const ripple = (x, y, elapsed) => {
    if (!document.documentElement) return;
    const el = document.createElement('div');
    Object.assign(el.style, {
      position: 'fixed', left: `${x}px`, top: `${y}px`,
      width: `${RIPPLE_SIZE}px`, height: `${RIPPLE_SIZE}px`,
      margin: `-${RIPPLE_SIZE / 2}px 0 0 -${RIPPLE_SIZE / 2}px`,
      borderRadius: '50%', border: '4px solid rgba(255, 140, 0, 1)',
      background: 'rgba(255, 140, 0, 0.22)', boxSizing: 'border-box',
      pointerEvents: 'none', zIndex: '2147483646',
    });
    document.documentElement.appendChild(el);
    const anim = el.animate(
      [
        { transform: 'scale(0.1)', opacity: 1 },
        { transform: 'scale(0.7)', opacity: 0.85, offset: 0.6 },
        { transform: 'scale(1)', opacity: 0 },
      ],
      { duration: RIPPLE_MS, easing: 'linear', fill: 'forwards' },
    );
    anim.currentTime = elapsed;
    anim.onfinish = () => el.remove();
  };

  window.addEventListener('mousemove', (e) => {
    state = { ...state, x: e.clientX, y: e.clientY };
    save(state);
    const el = arrow();
    if (el) el.style.transform = `translate(${e.clientX}px, ${e.clientY}px)`;
  }, true);
  window.addEventListener('mousedown', (e) => {
    state = { ...state, x: e.clientX, y: e.clientY, clickAt: Date.now() };
    save(state);
    ripple(e.clientX, e.clientY, 0);
  }, true);

  const onReady = () => {
    arrow();
    const elapsed = state.clickAt ? Date.now() - state.clickAt : RIPPLE_MS;
    if (elapsed < RIPPLE_MS && state.x !== undefined) ripple(state.x, state.y, elapsed);
  };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', onReady);
  } else {
    onReady();
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

// A screenshot of exactly what the browser window shows at its current viewport size
// (1280x720 desktop by default, or whatever the flow set, e.g. a narrow mobile width
// to check responsiveness), never the whole scrolling page. With a target, it is
// scrolled into view first (near the top, with some page above it for context).
async function screenshot(page, path, target) {
  const viewport = page.viewportSize() || { width: 1280, height: 720 };
  if (target) {
    await target.scrollIntoViewIfNeeded();
    await target.evaluate((el) => {
      const top = el.getBoundingClientRect().top + window.scrollY;
      window.scrollTo(0, Math.max(0, top - 120));
    });
    await page.waitForTimeout(300);
  }
  // The cursor belongs in videos, not in screenshots.
  const toggle = (show) => page.evaluate((visible) => {
    const el = document.getElementById('__pr_media_arrow');
    if (el) el.style.visibility = visible ? 'visible' : 'hidden';
  }, show).catch(() => {});
  await toggle(false);
  try {
    await page.screenshot({
      path,
      fullPage: false,
      clip: { x: 0, y: 0, width: viewport.width, height: viewport.height },
    });
  } finally {
    await toggle(true);
  }
}

module.exports = { install, moveTo, click, fill, screenshot, DURATION_MS, STEPS };
