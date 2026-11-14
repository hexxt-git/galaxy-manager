// A bean-shaped hydroponics trough on stubby legs: lit rim, sunken nutrient water, rows of lime sprouts.
const HYDRO = {
  lit: '#b07cc6', dark: '#7a4f96', water: '#2b4f73', leaf: '#b5dc4f', leafDark: '#5f9a3a',
  leg: '#555a68', fore: 0.7, h0: 5, h1: 17, rim: 4.5, sink: 3, cut: 8,
  // floor-plane outline (x, z away from the camera), smoothed
  bean: [[-35, 2], [-31, 13], [-17, 17], [2, 14], [20, 17], [33, 11], [35, -1], [27, -11], [12, -12], [1, -6], [-11, -11], [-27, -10]],
  legs: [[-24, -7], [22, -7]],
  // [x, z, stem height, leaf length], back to front
  sprouts: [[-20, 9, 10, 13], [2, 9, 15, 14], [23, 8, 8, 12], [-12, -2, 5, 12], [15, -3, 3, 11]],
};

const hydroP = (x, z, h) => [x, -HYDRO.fore * (z - HYDRO.legs[0][1]) - h];

// Pushes each vertex of a closed floor polygon inward by d along its vertex normal.
function hydroInset(pts, d) {
  const n = pts.length;
  const area = pts.reduce((a, c, i) => { const q = pts[(i + 1) % n]; return a + c[0] * q[1] - q[0] * c[1]; }, 0);
  d *= Math.sign(area);
  return pts.map((c, i) => {
    const p = pts[(i + n - 1) % n], q = pts[(i + 1) % n];
    const tx = q[0] - p[0], tz = q[1] - p[1], l = Math.hypot(tx, tz);
    return [c[0] - tz / l * d, c[1] + tx / l * d];
  });
}

function hydroSprout([x, z, s, L], base) {
  const H = HYDRO, [bx, by] = hydroP(x, z, base), tip = [bx, by - s];
  const leaves = [[-2.3, L], [-0.9, L * 1.1], [0.6, L * 0.9]].map(([ang, len]) => {
    const d = [Math.cos(ang), Math.sin(ang)], n = [-d[1], d[0]];
    const at = (t, o) => [tip[0] + d[0] * len * t + n[0] * o, tip[1] + d[1] * len * t + n[1] * o];
    const w = len * 0.4;
    return { outline: wobble(smooth([at(0, 0), at(0.45, w), at(1.05, 0), at(0.45, -w)], true, 3), AMP, 4, true), shade: [at(-0.2, 0), at(1.2, 0), at(1.2, w * 2), at(-0.2, w * 2)] };
  });
  const stem = [[bx, by], [bx + 0.5, by - s / 2], tip];
  pen(stem, 2 + 2 * DETAIL, INK, 0);
  pen(stem, 2, H.leafDark, 0);
  for (const l of leaves) { path(l.outline, true); stroke(2 * DETAIL); }
  for (const l of leaves) {
    blob(l.outline, H.leaf);
    clipTo(l.outline, () => blob(l.shade, H.leafDark));
    path(l.outline, true); stroke(DETAIL);
  }
}

function hydroPlanter() {
  const H = HYDRO;
  seed = 1021;
  const bean = smooth(H.bean, true, 3);
  const at = h => bean.map(([x, z]) => hydroP(x, z, h));
  blob(bean.map(([x, z]) => { const [px, py] = hydroP(x * 1.04, z, 0); return [px + 3, py + 1]; }), GROUND);

  const legs = H.legs.map(([x, z]) => {
    const [px, py] = hydroP(x, z, 0);
    return rounded(rect(px - 2.5, py - H.h0 - 3, px + 2.5, py), 1);
  });
  const layers = [];
  for (let h = H.h0; h <= H.h1; h += 1) layers.push(at(h));
  const top = wobble(at(H.h1), AMP, 4, true);
  const inner = hydroInset(bean, H.rim);
  const well = inner.map(([x, z]) => hydroP(x, z, H.h1));
  const water = inner.map(([x, z]) => hydroP(x, z, H.h1 - H.sink));

  const halo = 2 * LINE - DETAIL;
  for (const p of [...legs, ...layers]) { path(p, true); stroke(halo); }

  for (const l of legs) { blob(l, H.leg); path(l, true); stroke(DETAIL); }
  for (const p of layers) { path(p, true); stroke(DETAIL); }
  for (const p of layers) blob(p, H.lit);
  clipTo(rect(H.cut, -80, 60, 10), () => { for (const p of layers) blob(p, H.dark); });
  blob(top, H.lit);
  path(top, true); stroke(DETAIL);

  blob(well, H.dark);
  clipTo(well, () => blob(water, H.water));
  path(wobble(well, AMP, 4, true), true); stroke(DETAIL);

  for (const sp of H.sprouts) hydroSprout(sp, H.h1 - H.sink);
}

registerProp('hydro_planter', {
  w: 83, h: 66, ox: 40, oy: 58, draw: hydroPlanter,
  pal: () => [INK, HYDRO.lit, HYDRO.dark, HYDRO.water, HYDRO.leaf, HYDRO.leafDark, HYDRO.leg, GROUND],
});
