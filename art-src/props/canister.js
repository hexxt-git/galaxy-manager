// A squat oxygen barrel: floor-plane circles squash vertically by FORE, lit on the left like the crate's shadow.
const CANISTER = {
  lit: '#6390bd', dark: '#3c6390', cap: '#555a68', capDark: '#33363f', label: '#c8453f', labelDark: '#8a2b33',
  R: 18, body: 40, fore: 0.55, cut: 5, capR: 14, capH: 2.5,
  label0: 13, label1: 22, labelT0: 0.35, labelT1: 1.75,  // label band: heights below the top rim, near-arc angles
};

// Floor-plane ellipse arc around (0, cy), angles in radians; t = 0..PI is the near (lower) half.
function canisterArc(cy, rx, t0, t1, n) {
  const C = CANISTER, out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([rx * Math.cos(t), cy + C.fore * rx * Math.sin(t)]);
  }
  return out;
}

function canister() {
  const C = CANISTER, R = C.R, yb = -C.fore * R, yt = yb - C.body, yc = yt - C.capH;
  seed = 501;
  blob(canisterArc(yb + 3, R + 3, 0, 2 * Math.PI, 32).map(([x, y]) => [x + 2, y]), GROUND);
  const sil = shape([...canisterArc(yb, R, 0, Math.PI, 18), ...canisterArc(yt, R, Math.PI, 2 * Math.PI, 18)], C.lit, 0, AMP);
  const label = [...canisterArc(yt + C.label0, R, C.labelT0, C.labelT1, 10), ...canisterArc(yt + C.label1, R, C.labelT1, C.labelT0, 10)];
  clipTo(sil, () => {
    blob(label, C.label);
    clipTo(rect(C.cut, yt - 30, R + 4, 4), () => {
      blob(rect(-R - 4, yt - 30, R + 4, 4), C.dark);
      blob(label, C.labelDark);
    });
    blob(canisterArc(yt, R, 0, 2 * Math.PI, 36), C.lit);
    pen(canisterArc(yt, R, 0, Math.PI, 18), DETAIL, INK, AMP);
  });
  path(sil, true); stroke(LINE);

  // the lid is a short cylinder of its own: near wall in shadow, top face lit
  const r = C.capR;
  const lid = shape([...canisterArc(yt, r, 0, Math.PI, 16), ...canisterArc(yc, r, Math.PI, 2 * Math.PI, 16)], C.capDark, 0, AMP);
  clipTo(lid, () => blob(canisterArc(yc, r, 0, 2 * Math.PI, 32), C.cap));
  path(lid, true); stroke(DETAIL);
}

registerProp('canister', {
  w: 51, h: 75, ox: 24, oy: 66, draw: canister,
  pal: () => [INK, CANISTER.lit, CANISTER.dark, CANISTER.cap, CANISTER.capDark, CANISTER.label, CANISTER.labelDark, GROUND],
});
