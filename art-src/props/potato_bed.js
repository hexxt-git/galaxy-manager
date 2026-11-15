// A raised hydroponic grow bed: steel trough of dark soil, bushy potato plants, a few spuds peeking out of the soil.
const POTATO = {
  lit: '#a9bcc4', dark: '#6b818c', soil: '#5a4034', soilDark: '#3b2a26',
  spud: '#d1a463', spudDark: '#94673a', leaf: '#5fbf45', leafDark: '#2e7d3d',
  half: 42, depth: 22, front: 15, r: 5,
  spuds: [[-30, -21], [-4, -20], [21, -22], [35, -20]],
  // [x of the bush base on the soil, scale]
  bushes: [[-25, 1], [1, 1.1], [26, 0.95]],
  // [tip dx, tip dy, width] relative to the bush base, back to front
  leaves: [[-1, -30, 13], [-15, -22, 12], [14, -24, 12], [-17, -9, 11], [16, -11, 11], [-4, -15, 11], [6, -17, 11]],
};

function potatoEll(cx, cy, rx, ry, n = 20) {
  const out = [];
  for (let i = 0; i < n; i++) { const t = i / n * 2 * Math.PI; out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); }
  return out;
}

function potatoLeaf(b, [dx, dy, w], s) {
  const t = [b[0] + dx * s, b[1] + dy * s];
  const L = Math.hypot(t[0] - b[0], t[1] - b[1]);
  const d = [(t[0] - b[0]) / L, (t[1] - b[1]) / L];
  let n = [-d[1], d[0]];
  if (n[0] + 1.5 * n[1] < 0) n = [-n[0], -n[1]];
  const at = (k, o) => [b[0] + d[0] * L * k + n[0] * o, b[1] + d[1] * L * k + n[1] * o];
  const outline = wobble(smooth([at(0, 0), at(0.45, w * s * 0.6), at(1.06, 0), at(0.45, -w * s * 0.6)], true, 4), AMP, 4, true);
  return { outline, shade: [at(-0.2, 0), at(1.2, 0), at(1.2, w * s), at(-0.2, w * s)] };
}

function potatoBed() {
  const P = POTATO, a = P.half, yf = -P.front, yt = yf - P.depth;
  seed = 1301;
  blob(rounded(rect(-a - 1, -5, a + 3, 4.5), 4), GROUND);
  const sil = shape(rounded(rect(-a, yt, a, 0), P.r), P.lit, 0, AMP);
  const soil = wobble(rounded(rect(-a + 5, yt + 4, a - 5, yf - 3), 3), AMP, 4, true);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), P.dark);
    for (const x of [-a / 3, a / 3]) pen([[x, yf + 3], [x, -3]], DETAIL, INK, AMP);
    blob(soil, P.soil);
    clipTo(soil, () => blob(rect(-a, yt + 4, a, yt + 9), P.soilDark));
    path(soil, true); stroke(DETAIL);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);

  const spuds = P.spuds.map(([x, y]) => wobble(potatoEll(x, y, 4.2, 3), AMP, 3, true));
  for (const s of spuds) {
    blob(s, P.spud);
    clipTo(s, () => blob(rect(-60, s[0][1] + 0.6, 60, 0), P.spudDark));
    path(s, true); stroke(DETAIL);
  }

  const bushes = P.bushes.map(([x, s]) => P.leaves.map(l => potatoLeaf([x, yt + 9], l, s)));
  for (const b of bushes) for (const l of b) { path(l.outline, true); stroke(2 * LINE - DETAIL); }
  for (const b of bushes) for (const l of b) {
    blob(l.outline, P.leaf);
    clipTo(l.outline, () => blob(l.shade, P.leafDark));
    path(l.outline, true); stroke(DETAIL);
  }
}

registerProp('potato_bed', {
  w: 96, h: 80, ox: 48, oy: 72, draw: potatoBed,
  pal: () => [INK, POTATO.lit, POTATO.dark, POTATO.soil, POTATO.soilDark, POTATO.spud, POTATO.spudDark, POTATO.leaf, POTATO.leafDark, GROUND],
});
