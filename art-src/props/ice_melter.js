// An ice melter: a steel boiler with a brass ice hopper on top and a glowing heater window, piping melt water into a glass tank.
const ICEMELT = {
  steel: '#a9bcc4', steelDark: '#6b818c', brass: '#c9a548', brassDark: '#8a6733',
  glass: '#c4d8d4', glassDark: '#93b0ae', water: '#4aa3e0', waterDark: '#2b6cb0', glow: '#f0913a',
  fore: 0.55, box: [-62, 0], front: 38, depth: 28, tank: [36, -22], tankR: 23,
};

function icemeltArc(cx, cy, r, t0, t1, n, fore = ICEMELT.fore) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([cx + r * Math.cos(t), cy + fore * r * Math.sin(t)]);
  }
  return out;
}

function icemeltDrum(cx, y0, y1, r, lit, dark, top) {
  const P = Math.PI;
  const sil = shape([...icemeltArc(cx, y0, r, 0, P, 18), ...icemeltArc(cx, y1, r, P, 2 * P, 18)], lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(cx + r * 0.3, y1 - 40, cx + r + 4, y0 + 20), dark);
    if (top) {
      blob(icemeltArc(cx, y1, r, 0, 2 * P, 32), top);
      pen(icemeltArc(cx, y1, r, -0.1, P + 0.1, 18), DETAIL, INK, AMP);
    }
  });
  return sil;
}

function icemeltBoiler() {
  const I = ICEMELT, [x0, x1] = I.box, yf = -I.front, yt = yf - I.depth;
  const sil = shape(rounded(rect(x0, yt, x1, 0), 5), I.steel, 0, AMP);
  clipTo(sil, () => {
    blob(rect(x0 - 4, yf, x1 + 4, 4), I.steelDark);
    const win = rounded(rect(x0 + 10, yf + 8, x1 - 14, -8), 4);
    blob(win, I.glow);
    clipTo(win, () => {
      const coil = [];
      for (let x = x0 + 8; x <= x1 - 12; x += 1) coil.push([x, yf + 19 + 5 * Math.sin((x - x0) * 0.55)]);
      pen(coil, DETAIL, INK, 0);
    });
    path(wobble(win, AMP, 4, true), true); stroke(DETAIL);
    for (const y of [yf + 12, yf + 20, yf + 28]) pen([[x1 - 9, y], [x1 - 5, y]], DETAIL, INK, AMP);
    pen([[x0, yf], [x1, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

function icemeltHopper() {
  const I = ICEMELT, P = Math.PI, cx = (I.box[0] + I.box[1]) / 2 + 2, cy = -I.front - I.depth / 2;
  const yr = cy - 34, rr = 24, f = 0.4;
  const neck = rounded(rect(cx - 9, cy - 12, cx + 9, cy + 2), 2);
  shape(neck, I.brassDark, 0, AMP);
  path(wobble(neck, AMP, 4, true), true); stroke(DETAIL);
  const funnel = shape([[cx + 10, cy - 10], [cx - 10, cy - 10], ...icemeltArc(cx, yr, rr, P, 0, 18, f)], I.brassDark, 0, AMP);
  clipTo(funnel, () => blob(rect(cx - rr - 4, yr - 20, cx - 4, cy), I.brass));
  path(funnel, true); stroke(LINE);
  const rim = icemeltArc(cx, yr, rr, 0, 2 * P, 32, f);
  shape(rim, I.brass, 0, AMP);
  const ri = rr - 4, hole = icemeltArc(cx, yr + 0.5, ri, 0, 2 * P, 32, f);
  blob(hole, I.glassDark);
  const above = [...icemeltArc(cx, yr + 0.5, ri, 0, P, 18, f), [cx - ri, yr - 40], [cx + ri, yr - 40]];
  clipTo(above, () => {
    for (const [x, y, s] of [[-12, -3, 7], [6, -5, 8], [-3, -8, 7], [14, 1, 5], [-17, 2, 5]]) {
      const c = [cx + x, yr + y];
      const chunk = rounded([[c[0] - s, c[1] + s * 0.6], [c[0] - s * 0.7, c[1] - s * 0.7], [c[0] + s * 0.4, c[1] - s], [c[0] + s, c[1] - s * 0.1], [c[0] + s * 0.7, c[1] + s * 0.7]], 2);
      const ch = shape(chunk, I.glass, 0, AMP);
      clipTo(ch, () => blob(rect(c[0] + s * 0.25, c[1] - s - 2, c[0] + s + 2, c[1] + s + 2), I.glassDark));
      path(ch, true); stroke(DETAIL);
    }
  });
  pen(icemeltArc(cx, yr + 0.5, ri, -0.15, P + 0.15, 18, f), DETAIL, INK, AMP);
  path(wobble(rim, AMP, 4, true), true); stroke(LINE);
}

function icemeltTank() {
  const I = ICEMELT, P = Math.PI, [cx, yc] = I.tank, R = I.tankR;
  const y1 = yc - 6, y2 = y1 - 48, y3 = y2 - 5, yl = y2 + 13;
  let sil = icemeltDrum(cx, yc, y1, R + 3, I.steel, I.steelDark, I.steel);
  path(sil, true); stroke(LINE);
  sil = icemeltDrum(cx, y1, y2, R, I.glass, I.glassDark, null);
  clipTo(sil, () => {
    const water = [...icemeltArc(cx, y1, R + 2, 0, P, 18), ...icemeltArc(cx, yl, R + 2, P, 2 * P, 18)];
    blob(water, I.water);
    clipTo(water, () => blob(rect(cx + R * 0.3, yl - 20, cx + R + 4, y1 + 20), I.waterDark));
    blob(icemeltArc(cx, yl, R, 0, 2 * P, 32), I.water);
    pen(icemeltArc(cx, yl, R, -0.05, P + 0.05, 18), DETAIL * 0.8, I.waterDark, AMP);
    for (const [bx, by, br] of [[-12, -22, 1.8], [-8, -32, 1.4], [-14, -40, 1.2], [4, -28, 1.5]]) {
      blob(icemeltArc(cx + bx, y1 + by, br, 0, 2 * P, 10, 1), I.glass);
    }
  });
  path(sil, true); stroke(LINE);
  for (const y of [y1 - 16, y1 - 32]) pen(icemeltArc(cx, y, R, 0.15, P - 0.15, 14), DETAIL * 0.8, I.glassDark, AMP);
  sil = icemeltDrum(cx, y2, y3, R + 2, I.brass, I.brassDark, I.brass);
  path(sil, true); stroke(LINE);
}

function icemeltPipe() {
  const I = ICEMELT, y = -30;
  const pipe = [[I.box[1] - 4, y], [I.tank[0] - 10, y]];
  pen(pipe, 8, INK, AMP);
  pen(pipe, 4, I.brassDark, 0);
  const fl = rounded(rect(I.box[1] + 1, y - 6, I.box[1] + 6, y + 6), 1.5);
  shape(fl, I.brass, 0, AMP);
  path(wobble(fl, AMP, 4, true), true); stroke(DETAIL);
}

function iceMelter() {
  seed = 1301;
  blob(rounded(rect(-64, -44, 66, 3), 8), GROUND);
  icemeltBoiler();
  icemeltHopper();
  icemeltPipe();
  icemeltTank();
}

registerProp('ice_melter', {
  w: 144, h: 115, ox: 72, oy: 108, draw: iceMelter,
  pal: () => [INK, ICEMELT.steel, ICEMELT.steelDark, ICEMELT.brass, ICEMELT.brassDark, ICEMELT.glass, ICEMELT.glassDark, ICEMELT.water, ICEMELT.waterDark, ICEMELT.glow, GROUND],
});
