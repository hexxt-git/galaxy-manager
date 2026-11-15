// A small cartoon moon rover seen from the side-front: station-blue body on four chunky tyres, glass cab, whip antenna.
const ROVER = {
  lit: '#4a92c9', dark: '#2b5c91', tyre: '#4b505e', tyreDark: '#2c2f3a', hub: '#a9bcc4',
  glass: '#6fd0d8', glassDark: '#3f9aa8', tip: '#f2c230',
  front: [-29, 23], rear: [-17, 35],
};

function roverEllipse(cx, cy, a, b, n = 28) {
  const out = [];
  for (let i = 0; i < n; i++) { const t = 2 * Math.PI * i / n; out.push([cx + a * Math.cos(t), cy + b * Math.sin(t)]); }
  return out;
}

function roverWheel(x, y, r, tyre) {
  const w = shape(roverEllipse(x, y, r * 0.82, r), tyre, 0, AMP);
  clipTo(w, () => blob(rect(x - r, y + r * 0.35, x + r, y + r + 2), ROVER.tyreDark));
  path(w, true); stroke(LINE);
  const h = shape(roverEllipse(x, y - 1, r * 0.34, r * 0.4, 16), ROVER.hub, 0, 0.5);
  path(h, true); stroke(DETAIL);
}

function rover() {
  const R = ROVER;
  seed = 1411;
  blob(rounded(rect(-43, -15, 46, 4), 8), GROUND);
  for (const x of R.rear) roverWheel(x, -19, 10, R.tyreDark);

  pen([[-31, -46], [-34, -78]], LINE + 2.2, INK, 0);
  pen([[-31, -46], [-34, -78]], 2.2, R.hub, 0);
  const tip = shape(roverEllipse(-34, -79, 3.2, 3.2, 14), R.tip, 0, 0);
  path(tip, true); stroke(DETAIL);

  const cab = shape(smooth([[-16, -42], [-14, -60], [8, -62], [18, -52], [20, -42]], true, 3), R.glass, 0, AMP);
  clipTo(cab, () => {
    blob(rect(-18, -50, 22, -38), R.glassDark);
    blob(smooth([[-10, -56], [0, -58], [-4, -53]], true, 2), '#dfe7e4');
  });
  path(cab, true); stroke(LINE);

  const sil = shape(rounded(rect(-41, -46, 34, -19), 7), R.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-45, -34, 38, -9), R.dark);
    pen([[-41, -34], [34, -34]], DETAIL, INK, AMP);
    path(wobble(rounded(rect(-12, -30, 6, -23), 2.5), AMP, 4, true), true); stroke(DETAIL);
    for (const x of [-35, 28]) blob(roverEllipse(x, -27, 2, 2, 10), R.tip);
  });
  path(sil, true); stroke(LINE);

  for (const x of R.front) roverWheel(x, -11, 11, R.tyre);
}

registerProp('rover', {
  w: 96, h: 92, ox: 48, oy: 86, draw: rover,
  pal: () => [INK, ROVER.lit, ROVER.dark, ROVER.tyre, ROVER.tyreDark, ROVER.hub, ROVER.glass, ROVER.glassDark, ROVER.tip, '#dfe7e4', GROUND],
});
