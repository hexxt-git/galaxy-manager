// Solar minigame (scripts/colony/minigames/solar.gd): a close-up of a panel caked in moondust, wiped row by row.
// Everything here is drawn from the top-left (origin 0, 0); the skin mirrors MGS's row geometry.
const MGS = {
  cell: '#3d78c4', cellDark: '#25497f', frame: '#bcd0cd', frameDark: '#86a1a2',
  dust: '#a9a49a', dustDark: '#86817a', yellow: '#f2c230', yellowDark: '#b8862a', rubber: '#3d4250', pole: '#8a909c',
  btn: '#e1e8ef', btnDark: '#a9b6c7', btnLip: '#66768c',
  w: 240, h: 148, x0: 9, x1: 231, y0: 9, rowH: 18, gap: 3, rows: 6, cols: 5,
};

function mgsCircle(cx, cy, r, n = 48) {
  const out = [];
  for (let i = 0; i < n; i++) out.push([cx + r * Math.cos(i / n * 2 * Math.PI), cy + r * Math.sin(i / n * 2 * Math.PI)]);
  return out;
}

function mgsPanel() {
  const S = MGS;
  seed = 1201;
  const sil = shape(rounded(rect(2, 2, S.w - 2, S.h - 2), 7), S.frame, 0, AMP);
  clipTo(sil, () => {
    blob(rect(0, S.h - 12, S.w, S.h), S.frameDark);
    const cw = (S.x1 - S.x0 - S.gap * (S.cols - 1)) / S.cols;
    for (let j = 0; j < S.rows; j++) for (let i = 0; i < S.cols; i++) {
      const cx = S.x0 + i * (cw + S.gap), cy = S.y0 + j * (S.rowH + S.gap);
      const cell = rounded(rect(cx, cy, cx + cw, cy + S.rowH), 2);
      blob(cell, S.cellDark);
      clipTo(cell, () => {
        blob([[cx - 1, cy - 1], [cx + cw * 0.7, cy - 1], [cx + cw * 0.35, cy + S.rowH + 1], [cx - 1, cy + S.rowH + 1]], S.cell);
        for (const f of [0.33, 0.66]) blob(rect(cx + cw * f - 0.6, cy, cx + cw * f + 0.6, cy + S.rowH), S.cellDark);
      });
    }
    path(wobble(rounded(rect(S.x0 - 1.5, S.y0 - 1.5, S.x1 + 1.5, S.y0 + S.rows * (S.rowH + S.gap) - S.gap + 1.5), 3), AMP, 4, true), true);
    stroke(DETAIL);
    pen([[2, S.h - 12], [S.w - 2, S.h - 12]], DETAIL, INK, AMP);
    for (const x of [20, S.w - 20]) {
      const bolt = mgsCircle(x, S.h - 6, 2.2, 12);
      blob(bolt, S.frame); path(bolt, true); stroke(1.2);
    }
  });
  path(sil, true); stroke(LINE);
}

// One row's worth of the dust blanket: flat regolith grey with a few speckles and no outline, so stacked rows
// merge into one sheet. Spans the cell area plus a pixel and one row step, so neighbours butt together.
const DUST_W = MGS.x1 - MGS.x0 + 2, DUST_H = MGS.rowH + MGS.gap;
function mgsDust(s) {
  const S = MGS, w = DUST_W, h = DUST_H;
  return () => {
    seed = s;
    blob(rect(0, 0, w, h), S.dust);
    for (let i = 0; i < 14; i++) blob(mgsCircle(rr(4, w - 4), rr(3, h - 3), rr(0.7, 1.3), 8), S.dustDark);
  };
}

// The ridge the squeegee pushes up along the wiped edge: a lumpy darker lip sitting on the blanket's top edge.
const LIP_H = 9;
function mgsLip() {
  const S = MGS, w = DUST_W;
  seed = 1601;
  const top = [];
  for (let x = 0; x <= w; x += 6) top.push([x, 2 + rr(0, 2.5)]);
  const bot = [];
  for (let x = w; x >= 0; x -= 8) bot.push([x, LIP_H - 1.5 - rr(0, 1.5)]);
  const ridge = smooth([[-2, top[0][1]], ...top, [w + 2, top[top.length - 1][1]], [w + 2, LIP_H - 2], ...bot, [-2, LIP_H - 2]], true, 2);
  blob(ridge, S.dustDark);
  path(smooth(top, false, 2), false); stroke(1.4);
}

// A yellow squeegee seen from the front, blade upright; (0, 0) is the middle of the blade.
function mgsSqueegee() {
  const S = MGS;
  seed = 1301;
  const pole = shape(rounded([[2, -10], [16, -30], [21, -26], [8, -7]], 2), S.pole, 0, AMP);
  path(pole, true); stroke(DETAIL);
  const grip = shape(rounded([[12, -24], [19, -35], [25, -30], [18, -20]], 2.5), S.yellowDark, 0, AMP);
  path(grip, true); stroke(DETAIL);
  const holder = shape(rounded(rect(-4, -14, 7, 14), 3), S.yellow, 0, AMP);
  clipTo(holder, () => blob(rect(3, -17, 10, 17), S.yellowDark));
  path(holder, true); stroke(LINE);
  const blade = shape(rounded(rect(-9, -12, -3, 12), 2), S.rubber, 0, AMP);
  path(blade, true); stroke(DETAIL);
}

function mgsPuff() {
  seed = 1401;
  const S = MGS;
  const pts = [];
  for (let i = 0; i < 9; i++) {
    const a = i / 9 * 2 * Math.PI, r = i % 2 ? 7 : 9.5;
    pts.push([12 + Math.cos(a) * r * 1.15, 10 + Math.sin(a) * r * 0.85]);
  }
  const sil = shape(smooth(pts, true, 2), S.dust, 0, AMP);
  clipTo(sil, () => blob(smooth([[0, 12], [12, 14], [24, 11], [24, 22], [0, 22]], false, 2), S.dustDark));
  path(sil, true); stroke(DETAIL);
}

function mgsSparkle() {
  const c = 6.5, l = 5.8, t = 1.6;
  const star = [];
  for (let i = 0; i < 8; i++) {
    const a = i / 8 * 2 * Math.PI - Math.PI / 2, r = i % 2 ? t : l;
    star.push([c + Math.cos(a) * r, c + Math.sin(a) * r]);
  }
  path(star, true); ctx.fillStyle = '#ffffff'; ctx.fill(); stroke(1.4);
}

// The big round minigame button (as workstation.html's bigButton) with a squeegee icon instead of a word.
function mgsButton(pressed) {
  return () => {
    const S = MGS, k = 1.5, cx = 38 * k, cy = 36 * k, R = 34 * k, dy = pressed ? 4 * k : 0;
    seed = 611;
    const lip = shape(mgsCircle(cx, cy + 6 * k, R, 64), S.btnLip, 0, AMP);
    path(lip, true); stroke(LINE);
    const face = shape(mgsCircle(cx, cy + dy, R, 64), S.btn, 0, AMP);
    clipTo(face, () => blob([...smooth([[cx + 40 * k, cy + dy - 6 * k], [cx + 18 * k, cy + dy + 22 * k], [cx - 12 * k, cy + dy + 30 * k],
      [cx - 40 * k, cy + dy + 22 * k]], false, 3), [cx - 40 * k, cy + 60 * k], [cx + 40 * k, cy + 60 * k]], S.btnDark));
    path(face, true); stroke(LINE);
    const ix = cx - 4, iy = cy + dy - 2;
    const pole = shape(rounded([[ix - 3, iy - 4], [ix + 15, iy - 30], [ix + 22, iy - 25], [ix + 4, iy + 1]], 2), S.pole, 0, AMP);
    path(pole, true); stroke(DETAIL);
    const holder = shape(rounded([[ix - 26, iy - 2], [ix + 14, iy - 2], [ix + 14, iy + 9], [ix - 26, iy + 9]], 3), S.yellow, 0, AMP);
    clipTo(holder, () => blob(rect(ix - 30, iy + 5, ix + 18, iy + 12), S.yellowDark));
    path(holder, true); stroke(LINE);
    const blade = shape(rounded(rect(ix - 24, iy + 9, ix + 12, iy + 16), 2), S.rubber, 0, AMP);
    path(blade, true); stroke(DETAIL);
  };
}

const mgsPal = () => [INK, MGS.cell, MGS.cellDark, MGS.frame, MGS.frameDark];
const dustPal = () => [INK, MGS.dust, MGS.dustDark];
registerProp('mg_solar_panel', { w: MGS.w, h: MGS.h, ox: 0, oy: 0, draw: mgsPanel, pal: mgsPal });
registerProp('mg_solar_dust_a', { w: DUST_W, h: DUST_H, ox: 0, oy: 0, draw: mgsDust(1501), pal: dustPal });
registerProp('mg_solar_dust_b', { w: DUST_W, h: DUST_H, ox: 0, oy: 0, draw: mgsDust(1777), pal: dustPal });
registerProp('mg_solar_dust_lip', { w: DUST_W, h: LIP_H, ox: 0, oy: 0, draw: mgsLip, pal: dustPal });
registerProp('mg_solar_squeegee', { w: 40, h: 56, ox: 12, oy: 38, draw: mgsSqueegee,
  pal: () => [INK, MGS.yellow, MGS.yellowDark, MGS.rubber, MGS.pole] });
registerProp('mg_solar_puff', { w: 26, h: 22, ox: 0, oy: 0, draw: mgsPuff, pal: dustPal });
registerProp('mg_solar_sparkle', { w: 13, h: 13, ox: 0, oy: 0, draw: mgsSparkle, pal: () => [INK, '#ffffff'] });
const btnPal = () => [INK, MGS.btn, MGS.btnDark, MGS.btnLip, MGS.yellow, MGS.yellowDark, MGS.rubber, MGS.pole];
registerProp('mg_solar_button', { w: 114, h: 120, ox: 0, oy: 0, draw: mgsButton(false), pal: btnPal });
registerProp('mg_solar_button_pressed', { w: 114, h: 120, ox: 0, oy: 0, draw: mgsButton(true), pal: btnPal });
