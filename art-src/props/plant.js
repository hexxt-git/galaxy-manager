// A potted greenhouse plant: a few big two-tone leaves fanning out of a tapered pot. Lit from the upper left.
const PLANT = {
  leaf: '#5fbf45', leafDark: '#2e7d3d', pot: '#d0703f', potDark: '#93402c',
  rim: 14, foot: 10, pot_h: 20, fore: 0.55, cut: 4,
  // [base x, tip x, tip y, width], tip relative to the pot rim centre; back to front
  back: [[0, -2, -45, 20], [-3, -26, -26, 18], [3, 26, -30, 18]],
  front: [[-2, -27, -10, 16], [2, 23, -15, 16]],
};

function plantArc(cy, rx, t0, t1, n) {
  const P = PLANT, out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([rx * Math.cos(t), cy + P.fore * rx * Math.sin(t)]);
  }
  return out;
}

// An almond with a blunt tip, plus the half on the shadow side of its midrib.
function plantLeaf([bx, tx, ty, w]) {
  const y0 = -PLANT.pot_h, b = [bx, y0], t = [tx, y0 + ty];
  const L = Math.hypot(t[0] - b[0], t[1] - b[1]);
  const d = [(t[0] - b[0]) / L, (t[1] - b[1]) / L];
  let n = [-d[1], d[0]];
  if (n[0] + 1.5 * n[1] < 0) n = [-n[0], -n[1]];
  const at = (s, o) => [b[0] + d[0] * L * s + n[0] * o, b[1] + d[1] * L * s + n[1] * o];
  const outline = smooth([at(0, 0), at(0.42, w * 0.62), at(1.08, 0), at(0.42, -w * 0.62)], true, 4);
  const shade = [at(-0.2, 0), at(1.2, 0), at(1.2, w), at(-0.2, w)];
  return { outline, shade };
}

function plant() {
  const P = PLANT, yr = -P.pot_h, yf = -P.fore * P.foot;
  seed = 601;
  blob(plantArc(yf + 3, P.rim + 2, 0, 2 * Math.PI, 28).map(([x, y]) => [x + 2, y]), GROUND);
  const leaf = spec => { const l = plantLeaf(spec); return { ...l, outline: wobble(l.outline, AMP, 4, true) }; };
  const back = P.back.map(leaf), front = P.front.map(leaf);
  const pot = wobble([...plantArc(yf, P.foot, 0, Math.PI, 12), ...plantArc(yr, P.rim, Math.PI, 2 * Math.PI, 14)], AMP, 4, true);

  // Outer outline first, as a halo: later fills cover its inner half and their DETAIL strokes make up the rest,
  // so the silhouette ends up LINE wide while overlaps inside it stay DETAIL.
  for (const p of [...back.map(l => l.outline), pot, ...front.map(l => l.outline)]) { path(p, true); stroke(2 * LINE - DETAIL); }

  const drawLeaf = l => {
    blob(l.outline, P.leaf);
    clipTo(l.outline, () => blob(l.shade, P.leafDark));
    path(l.outline, true); stroke(DETAIL);
  };
  back.forEach(drawLeaf);
  blob(pot, P.pot);
  clipTo(pot, () => {
    blob(rect(P.cut, yr - 20, P.rim + 4, 4), P.potDark);
    blob(plantArc(yr, P.rim, 0, 2 * Math.PI, 28), P.pot);
    blob(plantArc(yr + 0.8, P.rim - 3.5, 0, 2 * Math.PI, 24), P.potDark);
    pen(plantArc(yr, P.rim, 0, Math.PI, 14), DETAIL, INK, AMP);
  });
  path(pot, true); stroke(DETAIL);
  front.forEach(drawLeaf);
}

registerProp('plant', {
  w: 66, h: 77, ox: 33, oy: 69, draw: plant,
  pal: () => [INK, PLANT.leaf, PLANT.leafDark, PLANT.pot, PLANT.potDark, GROUND],
});
