// A wall cabinet: a lit top face over a front in shadow, with two inset door panels. Straight sides so a row tiles.
const LOCKER = {
  lit: '#bcd0cd', dark: '#86a1a2',
  half: 24, depth: 14, front: 66, r: 4, plinth: 6, inset: 4.5,
};

// Splits each edge with collinear points (4r from the corners, then every ~10 px) so rounded()'s Chaikin pass,
// which bends the outer quarter of every segment, only curves the real corners and keeps long edges straight.
function lockerEdges(pts, r) {
  const out = [];
  pts.forEach((a, i) => {
    const b = pts[(i + 1) % pts.length], len = Math.hypot(b[0] - a[0], b[1] - a[1]);
    const ts = [0];
    if (len > 8 * r) {
      const inner = len - 8 * r, n = Math.max(1, Math.round(inner / 10));
      for (let k = 0; k <= n; k++) ts.push((4 * r + inner * k / n) / len);
    }
    for (const t of ts) out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
  });
  return out;
}

function locker() {
  const L = LOCKER, a = L.half, yf = -L.front, yt = yf - L.depth, yp = -L.plinth, d = L.inset;
  seed = 601;
  blob(rounded(rect(-a - 1, -5, a + 3, 4.5), 4), GROUND);
  const sil = shape(rounded(lockerEdges(rect(-a, yt, a, 0), L.r), L.r), L.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), L.dark);
    for (const s of [-1, 1]) {
      const x0 = s * 1.5, x1 = s * (a - d);
      const door = rounded(rect(Math.min(x0, x1), yf + d, Math.max(x0, x1), yp - 3), 2);
      blob(door, L.lit);
      path(wobble(door, AMP, 4, true), true); stroke(DETAIL);
      blob(rounded(rect(s * 6 - 1.3, yf + 24, s * 6 + 1.3, yf + 33), 1.3), INK);
    }
    pen([[-a, yp], [a, yp]], DETAIL, INK, AMP);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

registerProp('locker', { w: 61, h: 95, ox: 30, oy: 86, draw: locker, pal: () => [INK, LOCKER.lit, LOCKER.dark, GROUND] });
