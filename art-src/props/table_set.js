// The round table ringed by 6 benches, baked into one sprite. Self-contained (view.html may load it alone), so it
// repeats the table and bench numbers; names are prefixed to avoid clashing with table.js / bench.js globals.
// Origin is the table's floor centre, so y-sort puts characters behind the rear benches and in front of the front ones.
const TSET = {
  lit: '#4a92c9', dark: '#2b5c91', fore: 0.72,
  table: { R: 88, height: 26, inset: 10 },
  bench: { R: 116, seat: 24, span: 0.46, lip: 15, r: 5.5 },
  n: 6,
};

// Floor-plane point around the centre at angle t (0 = nearest the camera), lifted by `up` (a number or t => number).
function tsArc(r, t0, t1, n, up) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([r * Math.sin(t), TSET.fore * r * Math.cos(t) - (typeof up === 'function' ? up(t) : up)]);
  }
  return out;
}

// Bench arc centred on angle c. The silhouette takes each wall's floor edge where that wall faces the camera.
function tsBench(c) {
  const B = TSET.bench, s = B.span, ro = B.R, ri = B.R - B.seat, L = B.lip;
  const outer = tsArc(ro, c + s, c - s, 24, t => Math.cos(t) > 0 ? 0 : L);
  const inner = tsArc(ri, c - s, c + s, 20, t => Math.cos(t) < 0 ? 0 : L);
  const corner = t => tsArc(ro, t, t, 1, L)[0];
  const sil = shape(rounded([...inner, corner(c + s), ...outer, corner(c - s)], B.r), TSET.dark, 0, AMP);
  const top = rounded([...tsArc(ro, c - s, c + s, 24, L), ...tsArc(ri, c + s, c - s, 20, L)], B.r);
  clipTo(sil, () => { blob(top, TSET.lit); path(top, true); stroke(LINE); });
  path(sil, true); stroke(LINE);
}

function tsBenchShadow(c) {
  const B = TSET.bench, s = B.span + 0.01;
  blob(rounded([...tsArc(B.R + 3, c - s, c + s, 24, 0), ...tsArc(B.R - B.seat - 2, c + s, c - s, 20, 0)], 4)
    .map(([x, y]) => [x + 1.5, y + 4.5]), GROUND);
}

function tsTable() {
  const T = TSET.table, H = T.height, P = Math.PI;
  const sil = shape([...tsArc(T.R, -P / 2, P / 2, 32, 0), ...tsArc(T.R, P / 2, 3 * P / 2, 48, H)], TSET.lit, 0, AMP);
  clipTo(sil, () => {
    blob([...tsArc(T.R + 4, -P / 2 - 0.1, P / 2 + 0.1, 24, -6), ...tsArc(T.R, P / 2 + 0.1, -P / 2 - 0.1, 24, H)], TSET.dark);
    pen(tsArc(T.R, -P / 2 - 0.2, P / 2 + 0.2, 32, H), LINE, INK, AMP);
    path(wobble(tsArc(T.R - T.inset, 0, 2 * P, 56, H), AMP, 4, true), true); stroke(DETAIL);
  });
  path(sil, true); stroke(LINE);
}

function tableSet() {
  const S = TSET, P = Math.PI, s = S.bench.span;
  const angles = Array.from({ length: S.n }, (_, k) => k * 2 * P / S.n);
  // a bench whose nearest point is behind the centre goes under the table's raised top
  const near = c => Math.max(Math.cos(c - s), Math.cos(c + s), Math.cos(c));
  seed = 601;
  angles.forEach(tsBenchShadow);
  blob(tsArc(S.table.R + 3, 0, 2 * P, 64, 0).map(([x, y]) => [x + 1.5, y + 4.5]), GROUND);
  angles.filter(c => near(c) < 0).forEach(tsBench);
  tsTable();
  angles.filter(c => near(c) >= 0).forEach(tsBench);
}

registerProp('table_set', { w: 246, h: 198, ox: 122, oy: 104, draw: tableSet, pal: () => [INK, TSET.lit, TSET.dark, GROUND] });
