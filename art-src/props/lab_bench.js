// A pale lab workstation: a tray of moon rocks, a microscope and a teal scan screen on a cabinet bench.
const LAB = {
  lit: '#bcd0cd', dark: '#86a1a2', metal: '#8a909c', metalDark: '#555a68',
  frame: '#3d4250', screen: '#6fd0d8', tray: '#dfe7e4',
  half: 42, depth: 50, front: 26, r: 5,
  rocks: [[-28, -40, 4.5, 3.4], [-19, -42, 3.6, 2.8], [-11, -39, 4, 3]],
};

function labEll(cx, cy, rx, ry, n = 20) {
  const out = [];
  for (let i = 0; i < n; i++) { const t = i / n * 2 * Math.PI; out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); }
  return out;
}

function labPart(pts, fill, w = DETAIL, shade, shadeFill) {
  const p = shape(pts, fill, 0, AMP);
  if (shade) clipTo(p, () => blob(shade, shadeFill));
  path(p, true); stroke(w);
  return p;
}

function labBench() {
  const L = LAB, a = L.half, yf = -L.front, yt = yf - L.depth;
  seed = 1401;
  blob(rounded(rect(-a - 1, -5, a + 3, 4.5), 4), GROUND);
  const sil = shape(rounded(rect(-a, yt, a, 0), L.r), L.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), L.dark);
    for (const [x0, x1] of [[-a + 5, -2], [2, a - 5]]) {
      path(wobble(rounded(rect(x0, yf + 4, x1, -4), 2), AMP, 4, true), true); stroke(DETAIL);
    }
    for (const x of [-7, 7]) pen([[x, yf + 9], [x, yf + 14]], DETAIL, INK, 0);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);

  // scan screen
  labPart(rounded(rect(-25, -70, -17, -62), 1), L.metal, DETAIL, rect(-21, -80, -10, -50), L.metalDark);
  labPart(rounded(rect(-39, -100, -3, -70), 4), L.frame, LINE);
  labPart(rounded(rect(-35, -96, -7, -74), 2.5), L.screen);
  pen([[-32, -80], [-27, -85], [-23, -82], [-18, -91], [-14, -86], [-10, -88]], DETAIL, INK, AMP);
  pen([[-32, -77], [-20, -77]], DETAIL, INK, AMP);

  // microscope
  labPart(rounded(rect(12, -62, 36, -54), 3), L.metal, LINE, rect(12, -58, 40, -50), L.metalDark);
  labPart(rounded([[27, -56], [33, -56], [33, -84], [26, -90], [22, -86]], 2), L.metal, DETAIL, rect(30, -95, 40, -50), L.metalDark);
  labPart(rounded(rect(13, -69, 28, -65), 1.5), L.tray);
  labPart(rounded([[15, -88], [21, -94], [29, -79], [23, -73]], 1.5), L.lit, DETAIL, [[23, -73], [29, -79], [40, -79], [40, -73]], L.dark);
  labPart(labEll(18, -91, 3.4, 2.4), L.metalDark);

  // rock sample tray
  labPart(rounded(rect(-36, -48, -4, -33), 3), L.tray, LINE, rect(-40, -37, 0, -30), L.dark);
  for (const [x, y, rx, ry] of L.rocks) labPart(labEll(x, y, rx, ry), L.metal, DETAIL, rect(x - 6, y + ry * 0.2, x + 6, y + 6), L.metalDark);
}

registerProp('lab_bench', {
  w: 96, h: 112, ox: 48, oy: 104, draw: labBench,
  pal: () => [INK, LAB.lit, LAB.dark, LAB.metal, LAB.metalDark, LAB.frame, LAB.screen, LAB.tray, GROUND],
});
