// A small round mess table on a pedestal, a stool either side and a red mug on top.
const MESS = {
  lit: '#4a92c9', dark: '#2b5c91', metal: '#8a909c', metalDark: '#555a68', mug: '#c8453f', mugDark: '#8a2b33',
  table: { rx: 28, ry: 13, y: -15, h: 22, t: 5 },
  stool: { x: 37, rx: 7, ry: 4, y: -12, h: 12, t: 4 },
};

function messEll(cx, cy, rx, ry, t0 = 0, t1 = 2 * Math.PI, n = 40) {
  const out = [];
  for (let i = 0; i <= n; i++) { const t = t0 + (t1 - t0) * i / n; out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); }
  return out;
}

// A round slab whose top sits `h` above the floor centre (cx, cy), `t` thick: lit top, dark rim.
function messSlab(cx, cy, rx, ry, h, t, lit, dark, w = LINE) {
  const yt = cy - h, P = Math.PI;
  const sil = shape([...messEll(cx, yt + t, rx, ry, 0, P, 24), ...messEll(cx, yt, rx, ry, P, 2 * P, 24)], lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(cx - rx - 4, yt, cx + rx + 4, yt + t + ry + 4), dark);
    blob(messEll(cx, yt, rx, ry), lit);
    pen(messEll(cx, yt, rx, ry, -0.1, P + 0.1, 24), w, INK, AMP);
  });
  path(sil, true); stroke(w);
}

function messStem(x, y0, y1, w) {
  pen([[x, y0], [x, y1]], LINE + w, INK, 0);
  pen([[x, y0], [x, y1]], w, MESS.metal, 0);
}

function messTable() {
  const M = MESS, T = M.table, S = M.stool;
  seed = 1351;
  for (const s of [-1, 1]) blob(messEll(s * S.x + 1.5, S.y + 1.5, S.rx + 1, S.ry + 1.5), GROUND);
  blob(messEll(1.5, T.y + 1.5, T.rx - 4, T.ry), GROUND);
  for (const s of [-1, 1]) {
    const x = s * S.x;
    const foot = shape(messEll(x, S.y, 4.5, 2), M.metalDark, 0, AMP);
    path(foot, true); stroke(DETAIL);
    messStem(x, S.y, S.y - S.h + S.t, 3);
    messSlab(x, S.y, S.rx, S.ry, S.h, S.t, M.lit, M.dark);
  }
  const foot = shape(messEll(0, T.y, 10, 4), M.metalDark, 0, AMP);
  path(foot, true); stroke(DETAIL);
  messStem(0, T.y, T.y - T.h + T.t, 5);
  messSlab(0, T.y, T.rx, T.ry, T.h, T.t, M.lit, M.dark);
  path(wobble(messEll(0, T.y - T.h, T.rx - 6, T.ry - 4), AMP, 4, true), true); stroke(DETAIL);

  const mx = 11, my = T.y - T.h - 1, mh = 9, mr = 4.5;
  const handle = smooth([[mx + mr - 0.5, my - mh + 1.5], [mx + mr + 4, my - mh + 2], [mx + mr + 4, my - 2.5], [mx + mr - 0.5, my - 2]], false, 2);
  pen(handle, LINE, INK, 0);
  messSlab(mx, my, mr, 1.8, mh, mh - 1.5, M.mug, M.mugDark, DETAIL);
  blob(messEll(mx, my - mh, mr - 1.5, 1), INK);
}

registerProp('mess_table', {
  w: 96, h: 64, ox: 48, oy: 58, draw: messTable,
  pal: () => [INK, MESS.lit, MESS.dark, MESS.metal, MESS.metalDark, MESS.mug, MESS.mugDark, GROUND],
});
