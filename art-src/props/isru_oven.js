// An ISRU oven: a chunky brass furnace with moon rock glowing behind its door window, a gauge and a little exhaust stack.
const ISRU = {
  lit: '#c9a548', dark: '#8a6733', metal: '#8a909c', metalDark: '#555a68',
  glow: '#f08a2c', hot: '#ffc35a',
  fore: 0.55, half: 40, front: 36, depth: 22, r: 6, stack: [25, -11, 5, 20],
};

function isruArc(cx, cy, r, t0, t1, n) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([cx + r * Math.cos(t), cy + ISRU.fore * r * Math.sin(t)]);
  }
  return out;
}

function isruStack() {
  const O = ISRU, [x, y, r, h] = O.stack, yb = -O.front + y, yt = yb - h;
  const tube = shape([...isruArc(x, yb, r, 0, Math.PI, 10), ...isruArc(x, yt, r, Math.PI, 2 * Math.PI, 10)], O.metal, 0, AMP);
  clipTo(tube, () => {
    blob(rect(x + r * 0.2, yt - 10, x + r + 3, yb + 4), O.metalDark);
    blob(isruArc(x, yt, r, 0, 2 * Math.PI, 20), O.metalDark);
    blob(isruArc(x, yt + 0.4, r - 1.6, 0, 2 * Math.PI, 16), INK);
  });
  path(tube, true); stroke(LINE * 0.8);
  const band = isruArc(x, yb - 6, r + 1, 0, Math.PI, 10);
  pen(band, DETAIL, INK, AMP);
}

function isruOven() {
  const O = ISRU, a = O.half, yf = -O.front, yt = yf - O.depth;
  seed = 1321;
  blob(rounded(rect(-a - 1, -O.depth - 6, a + 3, 3), 6), GROUND);
  const sil = shape(rounded(rect(-a, yt, a, 0), O.r), O.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), O.dark);
    const hatch = rounded(rect(-a + 7, yt + 5, -6, yf - 5), 2.5);
    path(wobble(hatch, AMP, 4, true), true); stroke(DETAIL);
    pen([[-a + 14, yt + 11], [-14, yt + 11]], DETAIL, INK, AMP);

    const door = rounded(rect(-a + 6, yf + 5, 12, -5), 4);
    blob(door, O.metalDark);
    path(wobble(door, AMP, 4, true), true); stroke(DETAIL);
    const win = rounded(rect(-a + 11, yf + 9, 7, -10), 4);
    blob(win, O.glow);
    clipTo(win, () => {
      blob(rounded(rect(-a + 15, yf + 11, 3, -14), 4), O.hot);
      for (const [x, s] of [[-25, 6], [-14, 7], [-3, 6]]) {
        blob(smooth([[x - s, -9], [x - s * 0.6, -9 - s * 0.9], [x + s * 0.3, -9 - s * 1.1], [x + s, -9 - s * 0.3], [x + s, -8]], true, 2), O.metalDark);
      }
    });
    path(wobble(win, AMP, 4, true), true); stroke(DETAIL);
    const handle = rounded(rect(15, yf + 12, 19, -12), 1.5);
    shape(handle, O.metal, 0, AMP);
    path(wobble(handle, AMP, 4, true), true); stroke(DETAIL);

    const g = [29.5, yf + 11];
    const dial = isruArc(g[0], g[1], 5, 0, 2 * Math.PI, 18).map(([x, y]) => [x, g[1] + (y - g[1]) / ISRU.fore]);
    shape(dial, O.hot, 0, AMP);
    pen([g, [g[0] + 2.5, g[1] - 3]], 1.6, INK, 0);
    path(wobble(dial, AMP, 4, true), true); stroke(DETAIL);
    for (const y of [yf + 22, yf + 27]) pen([[25, y], [34, y]], DETAIL, INK, AMP);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
  isruStack();
}

registerProp('isru_oven', {
  w: 96, h: 93, ox: 48, oy: 87, draw: isruOven,
  pal: () => [INK, ISRU.lit, ISRU.dark, ISRU.metal, ISRU.metalDark, ISRU.glow, ISRU.hot, GROUND],
});
