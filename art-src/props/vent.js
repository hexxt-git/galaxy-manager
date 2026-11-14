// A floor grate seen from above: flush with the floor, so no ground shadow.
const VENT = {
  lit: '#8597ab', dark: '#536177',
  half: 27, depth: 30, r: 5, rim: 6,
  slats: [[-20, -17], [-15, -12], [-10, -6]],  // lit bars, on whole art pixels so the gaps stay even
};

// Splits each edge with collinear points (3r from the corners, then every ~10 px) so rounded()'s Chaikin pass,
// which bends the outer quarter of every segment, only curves the real corners and keeps long edges straight.
function ventEdges(pts, r) {
  const out = [];
  pts.forEach((a, i) => {
    const b = pts[(i + 1) % pts.length], len = Math.hypot(b[0] - a[0], b[1] - a[1]);
    const ts = [0];
    if (len > 6 * r) {
      const inner = len - 6 * r, n = Math.max(1, Math.round(inner / 10));
      for (let k = 0; k <= n; k++) ts.push((3 * r + inner * k / n) / len);
    }
    for (const t of ts) out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
  });
  return out;
}

function vent() {
  const V = VENT, a = V.half, yt = -V.depth, ai = a - V.rim;
  seed = 501;
  const sil = shape(rounded(ventEdges(rect(-a, yt, a, 0), V.r), V.r), V.lit, 0, AMP);
  clipTo(sil, () => {
    const hole = rounded(rect(-ai, yt + V.rim, ai, -V.rim), 2.5);
    blob(hole, V.dark);
    for (const [y0, y1] of V.slats) blob(rect(-ai, y0, ai, y1), V.lit);
    path(wobble(hole, AMP, 4, true), true); stroke(DETAIL);
  });
  path(sil, true); stroke(LINE);
}

registerProp('vent', { w: 66, h: 42, ox: 33, oy: 36, draw: vent, pal: () => [INK, VENT.lit, VENT.dark] });
