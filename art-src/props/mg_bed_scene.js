// Potato bed minigame (scripts/colony/minigames/bed.gd): a cross-section of a hydroponic grow bed under a red/blue
// LED grow light. Each tap waters it, the plant grows a stage and the potatoes under the soil line swell.
// Everything is drawn from the top-left (origin 0, 0) except the plant, can and potato, whose origins the skin uses.
const MGB = {
  wall: '#3b3150', cone: '#55406a', housing: '#3d4250', housingLit: '#555a68', red: '#ff5a6a', blue: '#5a8cff',
  lit: '#a9bcc4', dark: '#6b818c', soil: '#5a4034', soilDark: '#3b2a26', root: '#c9b48a',
  leaf: '#5fbf45', leafDark: '#2e7d3d', flower: '#f2eef5', flowerDark: '#b9a7d6', yellow: '#f2c230',
  spud: '#c9945a', spudDark: '#8a5a33', can: '#d9774a', canDark: '#a3502f', water: '#7fc8f0', waterDark: '#4a8cc4',
  btn: '#e1e8ef', btnDark: '#a9b6c7', btnLip: '#66768c',
  w: 240, h: 150, soilY: 92, bandY: 128, plantX: 120,
};

function mgbEll(cx, cy, rx, ry, n = 24) {
  const out = [];
  for (let i = 0; i < n; i++) { const t = i / n * 2 * Math.PI; out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); }
  return out;
}

function mgbScene() {
  const S = MGB;
  seed = 3001;
  const sil = shape(rounded(rect(2, 2, S.w - 2, S.h - 2), 7), S.wall, 0, AMP);
  clipTo(sil, () => {
    blob([[62, 16], [178, 16], [232, S.soilY], [8, S.soilY]], S.cone);
    for (const x of [70, 170]) pen([[x, 0], [x, 8]], DETAIL, INK, AMP);
    const bar = shape(rounded(rect(52, 6, 188, 18), 4), S.housing, 0, AMP);
    clipTo(bar, () => blob(rect(50, 4, 190, 10), S.housingLit));
    path(bar, true); stroke(DETAIL);
    for (let i = 0; i < 12; i++) {
      const led = mgbEll(61 + i * 10.7, 14.5, 2.4, 2.4, 12);
      blob(led, i % 2 ? S.blue : S.red); path(led, true); stroke(1.2);
    }

    const trough = shape(rounded(rect(10, S.soilY - 6, S.w - 10, S.h + 6), 4), S.lit, 0, AMP);
    clipTo(trough, () => {
      blob(rect(0, S.bandY + 3, S.w, S.h + 8), S.dark);
      const top = [];
      for (let x = 16; x <= S.w - 16; x += 8) top.push([x, S.soilY + rr(-1, 1)]);
      const soil = smooth([[16, S.soilY], ...top, [S.w - 16, S.soilY], [S.w - 16, S.bandY - 2], [16, S.bandY - 2]], true, 2);
      blob(soil, S.soil);
      clipTo(soil, () => {
        blob(rect(0, S.bandY - 13, S.w, S.h), S.soilDark);
        for (let i = 0; i < 26; i++) {
          const y = rr(S.soilY + 4, S.bandY - 4);
          blob(mgbEll(rr(20, S.w - 20), y, rr(0.8, 1.6), rr(0.6, 1.1), 8), y > S.bandY - 13 ? S.soil : S.soilDark);
        }
      });
      path(soil, true); stroke(DETAIL);
      pen([[10, S.bandY + 3], [S.w - 10, S.bandY + 3]], DETAIL, INK, AMP);
      for (const x of [22, S.w - 22]) {
        const bolt = mgbEll(x, S.bandY + 11, 2.2, 2.2, 12);
        blob(bolt, S.lit); path(bolt, true); stroke(1.2);
      }
    });
    path(trough, true); stroke(LINE);
  });
  path(sil, true); stroke(LINE);
}

function mgbLeaf(b, [dx, dy, w]) {
  const t = [b[0] + dx, b[1] + dy];
  const L = Math.hypot(dx, dy);
  const d = [dx / L, dy / L];
  let n = [-d[1], d[0]];
  if (n[0] + 1.5 * n[1] < 0) n = [-n[0], -n[1]];
  const at = (k, o) => [b[0] + d[0] * L * k + n[0] * o, b[1] + d[1] * L * k + n[1] * o];
  const outline = wobble(smooth([at(0, 0), at(0.45, w * 0.6), at(1.06, 0), at(0.45, -w * 0.6)], true, 4), AMP, 4, true);
  return { outline, shade: [at(-0.2, 0), at(1.2, 0), at(1.2, w), at(-0.2, w)] };
}

// Same kidney-bean tuber as item_potato.js: fuller lower half, a dent in the top edge, tilted, resting on y=0.
function mgbKidney(a, bTop, bBot, dent, tilt) {
  const pts = [];
  for (let i = 0; i < 28; i++) {
    const t = (i / 28) * Math.PI * 2, x = a * Math.cos(t), sn = Math.sin(t);
    let y = sn * (sn < 0 ? bTop : bBot);
    if (sn < 0) y += dent * Math.exp(-((x / (a * 0.4)) ** 2)) * -sn;
    pts.push([x * Math.cos(tilt) - y * Math.sin(tilt), x * Math.sin(tilt) + y * Math.cos(tilt)]);
  }
  const bottom = Math.max(...pts.map((q) => q[1]));
  return pts.map(([x, y]) => [x, y - bottom]);
}

// One tuber, `k` times item size, its bottom-centre at (x, y).
function mgbSpud(x, y, k, tilt, w = LINE) {
  const S = MGB;
  const sil = shape(smooth(mgbKidney(10.5 * k, 5.6 * k, 7.2 * k, 2.2 * k, tilt).map(([a, b]) => [a + x, b + y]), true, 2), S.spud, 0, AMP);
  clipTo(sil, () => {
    const horizon = smooth([[-12, -4.5], [-4, -4.2], [4, -5.6], [12, -7.8]].map(([a, b]) => [x + a * k, y + b * k]), false, 2);
    blob([...horizon, [x + 12 * k, y + 3], [x - 12 * k, y + 3]], S.spudDark);
    pen(horizon, 1.2, INK, AMP);
    if (k > 0.5) for (const [a, b] of [[-6, -8.2], [5.5, -10.2], [-3, -2.4]]) {
      const ex = x + a * k, ey = y + b * k;
      blob(rounded(rect(ex - 0.9, ey - 0.7, ex + 0.9, ey + 0.7), 0.6), INK);
    }
  });
  path(sil, true); stroke(w);
}

// [x, y below the soil line, first stage it shows, tilt]
const MGB_TUBERS = [[-22, 15, 1, -0.2], [19, 19, 2, 0.15], [-3, 29, 3, 0.05], [34, 11, 4, -0.1]];
const MGB_HEIGHT = [9, 20, 30, 40, 50, 59, 67];

// Growth stage s (0..6), origin on the soil line under the stem. `tubers` false: the potatoes have been pulled.
function mgbPlant(s, tubers = true) {
  const S = MGB, H = MGB_HEIGHT[s];
  seed = 3100 + s;
  for (const [x, y] of [[-9, 10], [-3, 15], [6, 12], [11, 7]].slice(0, 1 + Math.min(3, s))) {
    pen([[0, 1], [x * 0.5, y * 0.6], [x * (0.6 + s * 0.08), y * (0.7 + s * 0.08)]], 1.3, S.root, AMP);
  }
  if (tubers) for (const [x, y, from, tilt] of MGB_TUBERS) {
    if (s < from) continue;
    const k = Math.min(1.1, 0.5 + 0.2 * (s - from));
    pen([[0, 3], [x * 0.5, y * 0.4 + 4], [x, y - 7 * k]], 1.3, S.root, AMP);
  }
  if (tubers) for (const [x, y, from, tilt] of MGB_TUBERS) {
    if (s >= from) mgbSpud(x, y, Math.min(1.1, 0.5 + 0.2 * (s - from)), tilt, s - from > 1 ? LINE : DETAIL);
  }

  const stem = smooth([[0, 1], [1.2, -H * 0.35], [-1.2, -H * 0.7], [0, -H]], false, 2);
  path(stem, false); stroke(s < 2 ? 4 : 5);
  path(stem, false); stroke(s < 2 ? 1.6 : 2.4, S.leafDark);

  const leaves = [];
  const n = s + 1;
  for (let k = 0; k < n; k++) {
    const f = n === 1 ? 1 : 0.25 + 0.75 * k / (n - 1);
    const side = k % 2 ? 1 : -1, grow = 1 - 0.35 * f;
    const len = (10 + s * 2.8) * grow, wid = (7 + s * 1.1) * grow;
    leaves.push(mgbLeaf([0, -H * f], [side * len, -len * 0.55, wid]));
    if (s === 0) leaves.push(mgbLeaf([0, -H * f], [-side * len, -len * 0.55, wid]));
  }
  if (s > 0) leaves.push(mgbLeaf([0, -H + 2], [0.5, -(7 + s), 5 + s * 0.6]));
  for (const l of leaves) { path(l.outline, true); stroke(2 * LINE - DETAIL); }
  for (const l of leaves) {
    blob(l.outline, S.leaf);
    clipTo(l.outline, () => blob(l.shade, S.leafDark));
    path(l.outline, true); stroke(DETAIL);
  }

  if (s >= 5) for (const [x, y] of s === 5 ? [[4, -H - 4]] : [[-5, -H - 3], [6, -H - 6], [12, -H + 6]]) {
    for (let i = 0; i < 5; i++) {
      const a = i / 5 * 2 * Math.PI - Math.PI / 2;
      const p = mgbEll(x + Math.cos(a) * 2.6, y + Math.sin(a) * 2.6, 2.2, 2.2, 10);
      blob(p, i > 2 ? S.flowerDark : S.flower); path(p, true); stroke(1.1);
    }
    const c = mgbEll(x, y, 1.3, 1.3, 8);
    blob(c, S.yellow); path(c, true); stroke(1);
  }
}

// Watering can seen from the side, spout to the right; origin under the middle of the body, tilted by `rot`.
function mgbCan(rot, x = 0, y = 0, k = 1, w = LINE) {
  const S = MGB;
  return () => {
    seed = 3301;
    ctx.save();
    ctx.translate(x, y); ctx.rotate(rot); ctx.scale(k, k);
    const handle = smooth([[-11, -9], [-14, -17], [-4, -21], [5, -15]], false, 2);
    path(handle, false); stroke(w + 2.4 * k);
    path(handle, false); stroke(2.4 * k, S.canDark);
    const spout = shape(rounded([[4, -6], [20, -17], [22.5, -14], [6, -1]], 1.5), S.can, 0, AMP);
    path(spout, true); stroke(DETAIL);
    const rose = shape(rounded([[18.5, -19.5], [25, -15.5], [22.5, -12], [17, -16]], 1.2), S.canDark, 0, AMP);
    path(rose, true); stroke(DETAIL);
    const body = shape(rounded(rect(-11, -15, 8, 0), 3.5), S.can, 0, AMP);
    clipTo(body, () => blob(rect(-14, -5, 12, 2), S.canDark));
    path(body, true); stroke(w);
    ctx.restore();
  };
}

function mgbDrop() {
  const S = MGB;
  const d = shape(smooth([[3.5, 0.5], [6, 5], [5.2, 8.2], [1.8, 8.2], [1, 5]], true, 2), S.water, 0, 0);
  clipTo(d, () => blob(rect(3.5, 0, 8, 9), S.waterDark));
  path(d, true); stroke(1.3);
}

// Progress pip on the trough's front band: a leaf, dull steel until that stage has grown.
function mgbPip(on) {
  return () => {
    const S = MGB;
    seed = 3401;
    const l = mgbLeaf([2, 11], [10, -9, 7]);
    blob(l.outline, on ? S.leaf : S.dark);
    if (on) clipTo(l.outline, () => blob(l.shade, S.leafDark));
    path(l.outline, true); stroke(1.4);
  };
}

// The big round minigame button (as workstation.html's bigButton) with a pouring watering can instead of a word.
function mgbButton(pressed) {
  return () => {
    const S = MGB, k = 1.5, cx = 38 * k, cy = 36 * k, R = 34 * k, dy = pressed ? 4 * k : 0;
    seed = 611;
    const lip = shape(mgbEll(cx, cy + 6 * k, R, R, 64), S.btnLip, 0, AMP);
    path(lip, true); stroke(LINE);
    const face = shape(mgbEll(cx, cy + dy, R, R, 64), S.btn, 0, AMP);
    clipTo(face, () => blob([...smooth([[cx + 40 * k, cy + dy - 6 * k], [cx + 18 * k, cy + dy + 22 * k], [cx - 12 * k, cy + dy + 30 * k],
      [cx - 40 * k, cy + dy + 22 * k]], false, 3), [cx - 40 * k, cy + 60 * k], [cx + 40 * k, cy + 60 * k]], S.btnDark));
    path(face, true); stroke(LINE);
    mgbCan(0.45, cx - 8, cy + dy + 6, 1.75)();
    for (const [x, y] of [[cx + 22, cy + dy + 14], [cx + 30, cy + dy + 22], [cx + 21, cy + dy + 28]]) {
      const d = shape(smooth([[x, y - 4], [x + 3, y + 1.5], [x, y + 4], [x - 3, y + 1.5]], true, 2), S.water, 0, 0);
      path(d, true); stroke(1.4);
    }
  };
}

const mgbPal = () => Object.entries(MGB).filter(([, v]) => typeof v === 'string').map(([, v]) => v).concat([INK]);
registerProp('mg_bed_scene', { w: MGB.w, h: MGB.h, ox: 0, oy: 0, draw: mgbScene, pal: mgbPal });
for (let s = 0; s <= 6; s++) registerProp('mg_bed_plant_' + s, { w: 120, h: 112, ox: 60, oy: 76, draw: () => mgbPlant(s), pal: mgbPal });
registerProp('mg_bed_plant_picked', { w: 120, h: 112, ox: 60, oy: 76, draw: () => mgbPlant(6, false), pal: mgbPal });
registerProp('mg_bed_potato', { w: 30, h: 22, ox: 15, oy: 19, draw: () => { seed = 1331; mgbSpud(0, 0, 1.25, -0.14); }, pal: mgbPal });
registerProp('mg_bed_can', { w: 52, h: 36, ox: 20, oy: 28, draw: mgbCan(0), pal: mgbPal });
registerProp('mg_bed_can_pour', { w: 52, h: 36, ox: 20, oy: 28, draw: mgbCan(0.6), pal: mgbPal });
registerProp('mg_bed_drop', { w: 7, h: 9, ox: 0, oy: 0, draw: mgbDrop, pal: mgbPal });
registerProp('mg_bed_pip_off', { w: 14, h: 13, ox: 0, oy: 0, draw: mgbPip(false), pal: mgbPal });
registerProp('mg_bed_pip_on', { w: 14, h: 13, ox: 0, oy: 0, draw: mgbPip(true), pal: mgbPal });
registerProp('mg_bed_button', { w: 114, h: 120, ox: 0, oy: 0, draw: mgbButton(false), pal: mgbPal });
registerProp('mg_bed_button_pressed', { w: 114, h: 120, ox: 0, oy: 0, draw: mgbButton(true), pal: mgbPal });
