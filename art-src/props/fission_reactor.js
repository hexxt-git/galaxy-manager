// A compact fission power unit: a squat steel drum with a hazard band and trefoil plate, a domed cap and radiator fin banks either side.
const FISSION = {
  steel: '#bcd0cd', steelDark: '#86a1a2', mach: '#4b505e', machDark: '#2c2f3a',
  hazard: '#f2c230', hazardDark: '#b88a1e', led: '#7ed957',
  fore: 0.55, yc: -18, R: 22, bodyH: 36,
};

function fissionArc(cx, cy, r, t0, t1, n, fore = FISSION.fore) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([cx + r * Math.cos(t), cy + fore * r * Math.sin(t)]);
  }
  return out;
}

function fissionDrum(y0, y1, r, lit, dark, top) {
  const P = Math.PI;
  const sil = shape([...fissionArc(0, y0, r, 0, P, 18), ...fissionArc(0, y1, r, P, 2 * P, 18)], lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(r * 0.3, y1 - 40, r + 4, y0 + 20), dark);
    if (top) {
      blob(fissionArc(0, y1, r, 0, 2 * P, 32), top);
      pen(fissionArc(0, y1, r, -0.1, P + 0.1, 18), DETAIL, INK, AMP);
    }
  });
  return sil;
}

function fissionFins(x0, x1) {
  const F = FISSION, yb = -6, yf = yb - 30, yt = yf - 7;
  const sil = shape(rounded(rect(x0, yt, x1, yb), 3), F.mach, 0, AMP);
  clipTo(sil, () => {
    blob(rect(x0 - 4, yf, x1 + 4, yb + 4), F.machDark);
    for (let x = x0 + 4; x < x1 - 2; x += 4) blob(rect(x, yf + 3, x + 1.6, yb - 3), F.mach);
    pen([[x0, yf], [x1, yf]], DETAIL, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

function fissionTrefoil(c, r) {
  const P = Math.PI;
  for (let k = 0; k < 3; k++) {
    const t0 = -P / 2 + k * 2 * P / 3 - P / 6, t1 = t0 + P / 3, w = [[c[0], c[1]]];
    for (let i = 0; i <= 6; i++) { const t = t0 + (t1 - t0) * i / 6; w.push([c[0] + r * Math.cos(t), c[1] + r * Math.sin(t)]); }
    blob(w, INK);
  }
  blob(fissionArc(c[0], c[1], r * 0.42, 0, 2 * P, 12, 1), FISSION.hazard);
  blob(fissionArc(c[0], c[1], r * 0.26, 0, 2 * P, 12, 1), INK);
}

function fissionReactor() {
  const F = FISSION, P = Math.PI, y0 = F.yc, y1 = y0 - 4, y2 = y1 - F.bodyH, y3 = y2 - 4;
  seed = 1331;
  blob(rounded(rect(-45, -38, 47, 3), 8), GROUND);
  fissionFins(-44, -22);
  fissionFins(22, 44);
  for (const s of [-1, 1]) {
    const p = [[s * 18, -30], [s * 25, -30]];
    pen(p, 7, INK, AMP); pen(p, 3.4, F.steelDark, 0);
  }
  let sil = fissionDrum(y0, y1, F.R + 2, F.mach, F.machDark, F.mach);
  path(sil, true); stroke(LINE);
  sil = fissionDrum(y1, y2, F.R, F.steel, F.steelDark, null);
  clipTo(sil, () => {
    const b0 = y1 - 5, b1 = b0 - 7;
    const band = [...fissionArc(0, b0, F.R + 2, 0, P, 18), ...fissionArc(0, b1, F.R + 2, P, 0, 18)];
    blob(band, F.hazard);
    clipTo(band, () => {
      blob(rect(F.R * 0.3, b1 - 10, F.R + 4, b0 + 20), F.hazardDark);
      for (let x = -F.R - 10; x < F.R + 10; x += 7) pen([[x, b0 + 16], [x + 10, b1 - 4]], 2.6, INK, 0);
    });
    pen(fissionArc(0, b0, F.R, 0, P, 18), DETAIL, INK, AMP);
    pen(fissionArc(0, b1, F.R, 0, P, 18), DETAIL, INK, AMP);
    const pc = [-3, y2 + F.fore * F.R + 10];
    const plate = rounded(rect(pc[0] - 8, pc[1] - 7, pc[0] + 8, pc[1] + 7), 2.5);
    blob(plate, F.hazard);
    fissionTrefoil(pc, 5.6);
    path(wobble(plate, AMP, 4, true), true); stroke(DETAIL);
  });
  path(sil, true); stroke(LINE);
  sil = fissionDrum(y2, y3, F.R + 1.5, F.mach, F.machDark, F.mach);
  path(sil, true); stroke(LINE);
  const dr = 14, dome = shape([...fissionArc(0, y3, dr, 0, P, 16), ...fissionArc(0, y3, dr, P, 2 * P, 16, 0.85)], F.steel, 0, AMP);
  clipTo(dome, () => blob(rect(dr * 0.3, y3 - 20, dr + 4, y3 + 10), F.steelDark));
  path(dome, true); stroke(LINE);
  const led = fissionArc(-6, y3 - 6, 2.4, 0, 2 * P, 12, 0.9);
  blob(led, F.led);
  path(wobble(led, AMP, 4, true), true); stroke(DETAIL);
}

registerProp('fission_reactor', {
  w: 96, h: 89, ox: 48, oy: 83, draw: fissionReactor,
  pal: () => [INK, FISSION.steel, FISSION.steelDark, FISSION.mach, FISSION.machDark, FISSION.hazard, FISSION.hazardDark, FISSION.led, GROUND],
});
