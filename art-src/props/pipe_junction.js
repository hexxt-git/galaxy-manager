// Thick pipes rise out of floor flanges, bend and meet at a hub topped by a valve wheel.
const PIPES = {
  lit: '#a9bcc4', dark: '#6b818c', flange: '#c9a548', flangeDark: '#8a6733', wheel: '#c8453f', wheelDark: '#8a2b33',
  fore: 0.55, r: 6,
  // control polygons from the floor up; the first segment is vertical
  runs: [
    [[-25, -8], [-25, -22], [-24, -32], [-16, -34], [-8, -36]],
    [[22, -12], [22, -48], [20, -60], [8, -60], [-2, -56], [-3, -46]],
  ],
  hub: { y: -30, r: 10, h: 12 },
};

function pipesArc(cx, cy, rx, t0, t1, n) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([cx + rx * Math.cos(t), cy + PIPES.fore * rx * Math.sin(t)]);
  }
  return out;
}

function pipesCyl(x, yb, r, h, lit, dark, w = LINE) {
  const yt = yb - h;
  const sil = shape([...pipesArc(x, yb, r, 0, Math.PI, 16), ...pipesArc(x, yt, r, Math.PI, 2 * Math.PI, 16)], lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(x + r * 0.3, yt - 30, x + r + 4, yb + 30), dark);
    blob(pipesArc(x, yt, r, 0, 2 * Math.PI, 32), lit);
    pen(pipesArc(x, yt, r, 0, Math.PI, 16), DETAIL, INK, AMP);
  });
  path(sil, true); stroke(w);
  return yt;
}

// Offsets a centreline both ways; the floor end is closed by the near half of the pipe's floor-plane circle.
function pipesTube(c, r) {
  const L = [], R = [];
  c.forEach((p, i) => {
    const a = c[Math.max(0, i - 1)], b = c[Math.min(c.length - 1, i + 1)];
    const len = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1, nx = -(b[1] - a[1]) / len, ny = (b[0] - a[0]) / len;
    L.push([p[0] + nx * r, p[1] + ny * r]);
    R.push([p[0] - nx * r, p[1] - ny * r]);
  });
  const [x0, y0] = c[0];
  return [...pipesArc(x0, y0, r, 0, Math.PI, 10), ...L.slice(1), ...R.slice(1).reverse()];
}

function pipesRun(ctrl) {
  const P = PIPES, r = P.r, [x0, y0] = ctrl[0];
  pipesCyl(x0, y0 + 3, r + 4, 5, P.flange, P.flangeDark);
  const c = smooth(ctrl, false, 4);
  const tube = shape(pipesTube(c, r), P.lit, 0, AMP);
  clipTo(tube, () => pen(c.map(([x, y]) => [x + r * 0.9, y + r * 0.6]), 2 * r, P.dark, 0));
  path(tube, true); stroke(LINE);
}

function pipeJunction() {
  const P = PIPES, H = P.hub;
  seed = 911;
  blob(rounded(rect(-31, -18, 32, 4), 9), GROUND);
  pipesCyl(0, -10, 9, 5, P.flange, P.flangeDark);
  pipesCyl(0, -15, 4.5, -H.y - 15, P.lit, P.dark, DETAIL);
  P.runs.forEach(pipesRun);
  const yt = pipesCyl(0, H.y, H.r, H.h, P.flange, P.flangeDark);
  const ys = pipesCyl(0, yt, 2.2, 4, P.dark, P.dark, DETAIL);
  // wheel: a floor-plane ring with four spokes, near half in shadow
  const wr = 12, yw = ys + 1;
  for (const t of [0.4, 0.4 + Math.PI / 2, 0.4 + Math.PI, 0.4 + 1.5 * Math.PI]) {
    const sp = [[0, yw], [wr * Math.cos(t), yw + P.fore * wr * Math.sin(t)]];
    pen(sp, 4, INK, 0);
    pen(sp, 1.4, P.wheel, 0);
  }
  const ring = pipesArc(0, yw, wr, 0, 2 * Math.PI, 40);
  path(ring, true); stroke(5.4);
  path(ring, true); stroke(2.4, P.wheel);
  clipTo(rect(wr * 0.3, yw - 20, wr + 6, yw + 20), () => { path(ring, true); stroke(2.4, P.wheelDark); });
  blob(pipesArc(0, yw, 2.6, 0, 2 * Math.PI, 16), INK);
}

registerProp('pipe_junction', {
  w: 98, h: 97, ox: 51, oy: 88, scale: [1.3, 1.25], draw: pipeJunction,
  pal: () => [INK, PIPES.lit, PIPES.dark, PIPES.flange, PIPES.flangeDark, PIPES.wheel, PIPES.wheelDark, GROUND],
});
