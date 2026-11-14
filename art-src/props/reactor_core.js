// A stacked reactor column: floor-plane discs squash by FORE, lit on the left, shadow right of CUT.
const REACTOR = {
  metal: '#bcd0cd', metalDark: '#86a1a2', collar: '#c9a548', collarDark: '#8a6733',
  base: '#a9bcc4', baseDark: '#6b818c', core: '#5fc9b8', coreDark: '#2f8a86',
  fore: 0.55, cut: 0.3,
  // bottom up: [radius, height, lit, dark]
  stack: () => {
    const R = REACTOR;
    return [
      [25, 9, R.base, R.baseDark], [11, 5, R.metal, R.metalDark], [20, 7, R.collar, R.collarDark],
      [11, 20, R.core, R.coreDark], [20, 7, R.collar, R.collarDark], [11, 4, R.metal, R.metalDark],
      [15, 7, R.base, R.baseDark], [6, 6, R.metal, R.metalDark],
    ];
  },
  rods: [0.45, 1.25, 2.1, 2.85], rodR: 15.5,
};

function reactorArc(cy, rx, t0, t1, n) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([rx * Math.cos(t), cy + REACTOR.fore * rx * Math.sin(t)]);
  }
  return out;
}

function reactorDisc(yb, [r, h, lit, dark]) {
  const R = REACTOR, yt = yb - h;
  const sil = shape([...reactorArc(yb, r, 0, Math.PI, 18), ...reactorArc(yt, r, Math.PI, 2 * Math.PI, 18)], lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(r * R.cut, yt - 30, r + 4, yb + 30), dark);
    blob(reactorArc(yt, r, 0, 2 * Math.PI, 36), lit);
    pen(reactorArc(yt, r, 0, Math.PI, 18), DETAIL, INK, AMP);
  });
  path(sil, true); stroke(r > 9 ? LINE : DETAIL);
  return yt;
}

function reactorRods(y0, y1) {
  const R = REACTOR;
  for (const t of R.rods) {
    const x = R.rodR * Math.cos(t), dy = R.fore * R.rodR * Math.sin(t);
    const line = [[x, y0 + dy], [x, y1 + dy]];
    pen(line, 4.4, INK, 0);
    pen(line, 1.6, x > R.rodR * R.cut ? R.metalDark : R.metal, 0);
  }
}

function reactorCore() {
  const R = REACTOR, stack = R.stack();
  seed = 811;
  let y = -R.fore * stack[0][0];
  blob(reactorArc(y + 2, stack[0][0] + 3, 0, 2 * Math.PI, 36).map(([x, yy]) => [x + 2, yy]), GROUND);
  stack.forEach((s, i) => {
    const yb = y;
    y = reactorDisc(y, s);
    if (s[2] === R.core) reactorRods(yb + 1, y - 1);
  });
}

registerProp('reactor_core', {
  w: 98, h: 137, ox: 46, oy: 128, scale: [1.6, 1.5], draw: reactorCore,
  pal: () => [INK, ...new Set([REACTOR.metal, REACTOR.metalDark, REACTOR.collar, REACTOR.collarDark, REACTOR.base, REACTOR.baseDark]), REACTOR.core, REACTOR.coreDark, GROUND],
});
