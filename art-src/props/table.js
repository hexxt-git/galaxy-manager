// Round cafeteria table: a short drum. R is the floor radius, so a ring of BENCH arcs (R 116, seat 24) fits around it.
const TABLE = {
  lit: '#4a92c9', dark: '#2b5c91',
  R: 88, height: 26, inset: 10, fore: 0.72,
};

// Floor-plane ellipse around the table centre, lifted by `up`, from angle t0 to t1 (0 = nearest the camera).
function tableArc(R, up, t0, t1, n) {
  const T = TABLE, f = T.fore, out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([R * Math.sin(t), f * (R * Math.cos(t) - T.R) - up]);
  }
  return out;
}

function table() {
  const T = TABLE, H = T.height, P = Math.PI;
  seed = 501;
  blob([...tableArc(T.R + 3, -4.5, -P / 2, P / 2, 24), ...tableArc(T.R - 6, 0, P / 2, 3 * P / 2, 24)].map(([x, y]) => [x + 1.5, y]), GROUND);
  const sil = shape([...tableArc(T.R, 0, -P / 2, P / 2, 32), ...tableArc(T.R, H, P / 2, 3 * P / 2, 48)], T.lit, 0, AMP);
  clipTo(sil, () => {
    blob([...tableArc(T.R + 4, -6, -P / 2 - 0.1, P / 2 + 0.1, 24), ...tableArc(T.R, H, P / 2 + 0.1, -P / 2 - 0.1, 24)], T.dark);
    pen(tableArc(T.R, H, -P / 2 - 0.2, P / 2 + 0.2, 32), LINE, INK, AMP);
    path(wobble(tableArc(T.R - T.inset, H, 0, 2 * P, 56), AMP, 4, true), true); stroke(DETAIL);
  });
  path(sil, true); stroke(LINE);
}

registerProp('table', { w: 190, h: 170, ox: 94, oy: 159, draw: table, pal: () => [INK, TABLE.lit, TABLE.dark, GROUND] });
