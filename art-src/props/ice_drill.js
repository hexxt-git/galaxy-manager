// An ice drill on the crater floor: a steel derrick driving an auger into the ground, a hopper heaped with ice beside it.
const DRILL = {
  steel: '#a9bcc4', steelDark: '#6b818c', gun: '#8a909c', gunDark: '#555a68', ice: '#c6ecf4', iceDark: '#7cbcd8', hole: '#2c2f3a',
  hx: -18, apex: -96, feet: [-37, 1],
  // [x, y, rx, ry], back to front
  chunks: [[18, -40, 7, 6], [31, -41, 8, 6], [24, -47, 7, 5], [11, -31, 6, 5], [38, -31, 6, 5], [24, -33, 8, 6]],
};

function drillEllipse(cx, cy, rx, ry, n = 24) {
  return Array.from({ length: n }, (_, i) => [cx + rx * Math.cos(2 * Math.PI * i / n), cy + ry * Math.sin(2 * Math.PI * i / n)]);
}

function drillBar(a, b, w, fill) {
  pen([a, b], w + 2 * DETAIL, INK, AMP);
  pen([a, b], w, fill, 0);
}

function drillChunk([cx, cy, rx, ry]) {
  const D = DRILL, n = 6, ph = rr(0, 1);
  const pts = Array.from({ length: n }, (_, i) => {
    const t = 2 * Math.PI * (i + ph) / n, k = rr(0.8, 1.1);
    return [cx + rx * k * Math.cos(t), cy + ry * k * Math.sin(t)];
  });
  const c = shape(rounded(pts, 1.5), D.ice, 0, AMP);
  clipTo(c, () => blob(c.map(([x, y]) => [x + rx * 0.5, y + ry * 0.7]), D.iceDark));
  path(c, true); stroke(DETAIL);
}

function iceDrill() {
  const D = DRILL, hx = D.hx, lerpX = (x, y) => x + (hx - x) * (y + 12) / (D.apex + 12);
  seed = 833;
  blob(rounded(rect(-44, -18, 46, 4), 7), GROUND);

  const skid = shape(rounded(rect(-41, -17, 5, 0), 3), D.steel, 0, AMP);
  clipTo(skid, () => {
    blob(rect(-45, -7, 9, 4), D.steelDark);
    pen([[-41, -7], [5, -7]], DETAIL, INK, AMP);
  });
  path(skid, true); stroke(LINE);
  const hole = drillEllipse(hx, -11.5, 8, 3);
  shape(hole, D.hole, 0, 0);
  path(hole, true); stroke(DETAIL);

  for (const y of [-38, -62]) drillBar([lerpX(D.feet[0], y), y], [lerpX(D.feet[1], y), y], 2, D.steelDark);
  drillBar([D.feet[0], -12], [hx, D.apex], 3, D.steel);
  drillBar([D.feet[1], -12], [hx, D.apex], 3, D.steelDark);

  drillBar([hx, -70], [hx, -36], 3, D.gun);
  const bit = shape([[hx - 5, -37], [hx + 5, -37], [hx + 4, -16], [hx, -11], [hx - 4, -16]], D.gun, 0, AMP);
  clipTo(bit, () => {
    blob(rect(hx + 1, -40, hx + 6, -10), D.gunDark);
    for (let y = -34; y < -14; y += 5) pen([[hx - 6, y], [hx + 6, y + 4]], DETAIL, INK, 0);
  });
  path(bit, true); stroke(DETAIL);

  const motor = shape(rounded(rect(hx - 11, -88, hx + 11, -68), 3), D.steel, 0, AMP);
  clipTo(motor, () => {
    blob(rect(hx - 14, -80, hx + 14, -60), D.steelDark);
    pen([[hx - 11, -80], [hx + 11, -80]], DETAIL, INK, AMP);
    for (const x of [hx - 5, hx, hx + 5]) pen([[x, -77], [x, -71]], DETAIL, INK, AMP);
  });
  path(motor, true); stroke(LINE);
  const sheave = drillEllipse(hx, D.apex + 1, 4, 3.5, 16);
  shape(sheave, D.gun, 0, 0);
  path(sheave, true); stroke(DETAIL);

  const bin = shape(rounded([[5, -29], [45, -29], [43, 0], [7, 0]], 3), D.steel, 0, AMP);
  path(bin, true); stroke(LINE);
  D.chunks.forEach(drillChunk);
  clipTo(bin, () => {
    blob(rect(0, -22, 50, 5), D.steelDark);
    pen([[5, -22], [45, -22]], LINE, INK, AMP);
    pen([[9, -11], [41, -11]], DETAIL, INK, AMP);
  });
  path(bin, true); stroke(LINE);
}

registerProp('ice_drill', {
  w: 96, h: 108, ox: 48, oy: 103, draw: iceDrill,
  pal: () => [INK, DRILL.steel, DRILL.steelDark, DRILL.gun, DRILL.gunDark, DRILL.ice, DRILL.iceDark, DRILL.hole, GROUND],
});
