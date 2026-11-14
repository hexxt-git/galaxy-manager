// A squat specimen tank: metal plinth, a glass drum of green fluid with a curled specimen, and a lidded cap.
const SPECTANK = {
  metal: '#8a909c', metalDark: '#555a68', glass: '#c4d8d4', glassDark: '#93b0ae',
  fluid: '#8fcf63', fluidDark: '#4f9a4a', specimen: '#2f6b3c',
  fore: 0.55, cut: 5,
  baseR: 19, baseH: 6, R: 17, glassH: 30, air: 17, capR: 18, capH: 4, knobR: 4.5,
};

function spectankArc(cy, r, t0, t1, n) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([r * Math.cos(t), cy + SPECTANK.fore * r * Math.sin(t)]);
  }
  return out;
}

// Cylinder from floor-plane centre y0 up to y1; returns the silhouette for further clipping.
function spectankDrum(y0, y1, r, lit, dark, top, w) {
  const S = SPECTANK, P = Math.PI;
  const sil = shape([...spectankArc(y0, r, 0, P, 18), ...spectankArc(y1, r, P, 2 * P, 18)], lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(S.cut * r / S.R, y1 - 30, r + 4, y0 + 20), dark);
    if (top) {
      blob(spectankArc(y1, r, 0, 2 * P, 32), top);
      pen(spectankArc(y1, r, -0.1, P + 0.1, 18), DETAIL, INK, AMP);
    }
  });
  return sil;
}

function specimenTank() {
  const S = SPECTANK, f = S.fore, P = Math.PI;
  const y0 = -f * S.baseR, y1 = y0 - S.baseH, y2 = y1 - S.glassH, y3 = y2 - S.capH;
  seed = 823;
  blob(spectankArc(y0 + 2.5, S.baseR + 2.5, 0, 2 * P, 32).map(([x, y]) => [x + 2, y]), GROUND);

  let sil = spectankDrum(y0, y1, S.baseR, S.metal, S.metalDark, S.metal);
  path(sil, true); stroke(LINE);

  sil = spectankDrum(y1, y2, S.R, S.glass, S.glassDark, null);
  const yl = y2 + S.air;
  clipTo(sil, () => {
    const fluid = [...spectankArc(y1, S.R + 2, 0, P, 18), ...spectankArc(yl, S.R + 2, P, 2 * P, 18)];
    blob(fluid, S.fluid);
    clipTo(fluid, () => blob(rect(S.cut, yl - 20, S.R + 4, y1 + 20), S.fluidDark));
    blob(spectankArc(yl, S.R, P, 2 * P, 18).concat(spectankArc(yl, S.R, 0, P, 18).reverse().slice(0, 1)), S.fluid);
    pen(spectankArc(yl, S.R, -0.05, P + 0.05, 18), DETAIL * 0.8, S.fluidDark, AMP);
    const sp = smooth([[-7, -16], [-3, -20], [3, -19], [5, -14], [2, -10], [-3, -9], [-1, -13], [-4, -14]], true, 3);
    blob(sp, S.specimen);
    for (const [bx, by, br] of [[-11, -12, 1.8], [-9, -17, 1.4], [9, -15, 1.6]]) {
      blob(spectankArc(by, br, 0, 2 * P, 10).map(([x, y]) => [x + bx, y + (y - by) * 0.8]), S.glass);
    }
  });
  path(sil, true); stroke(LINE);

  sil = spectankDrum(y2, y3, S.capR, S.metal, S.metalDark, S.metal);
  path(sil, true); stroke(LINE);
  const knob = shape(spectankArc(y3, S.knobR, 0, 2 * P, 16), S.metalDark, 0, AMP);
  path(knob, true); stroke(DETAIL);
}

registerProp('specimen_tank', {
  w: 57, h: 81, ox: 27, oy: 73, scale: [1.1, 1.12], draw: specimenTank,
  pal: () => [INK, SPECTANK.metal, SPECTANK.metalDark, SPECTANK.glass, SPECTANK.glassDark, SPECTANK.fluid, SPECTANK.fluidDark, SPECTANK.specimen, GROUND],
});
