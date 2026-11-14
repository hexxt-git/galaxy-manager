// A gentle arc of the cafeteria table benches: floor-plane circles squash vertically by FORE.
const BENCH = {
  lit: '#4a92c9', dark: '#2b5c91',
  R: 150, seat: 28, span: 0.46, lip: 9, fore: 0.72, r: 5.5,
};

function benchArc(R, cy, t0, t1, n) {
  const B = BENCH, out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([R * Math.sin(t), cy + B.fore * (R * Math.cos(t) - B.R)]);
  }
  return out;
}

function bench() {
  const B = BENCH, s = B.span, ri = B.R - B.seat, yl = -B.lip;
  const outerTop = benchArc(B.R, yl, -s, s, 12);
  const outerBot = benchArc(B.R, 0, s, -s, 12);
  const inner = benchArc(ri, yl, -s, s, 10);
  seed = 401;
  blob(rounded([...benchArc(B.R + 3, 4.5, -s - 0.01, s + 0.01, 12), ...benchArc(B.R - 8, -2, s, -s, 12)], 4), GROUND);
  const sil = shape(rounded([...inner, outerTop[outerTop.length - 1], ...outerBot, outerTop[0]], B.r), B.lit, 0, AMP);
  clipTo(sil, () => {
    blob([...benchArc(B.R, yl, -s - 0.05, s + 0.05, 12), ...benchArc(B.R + 10, 10, s + 0.05, -s - 0.05, 12)], B.dark);
    pen(outerTop, LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

registerProp('bench', { w: 140, h: 50, ox: 70, oy: 44, draw: bench, pal: () => [INK, BENCH.lit, BENCH.dark, GROUND] });
