// Lab minigame spectrometer monitor: pale lab bezel around a dark display; the spectrum and scan line are drawn in-engine
// inside the display hole (art px 12,12 .. 252,74).
const MG_LAB = {
  lit: '#bcd0cd', dark: '#86a1a2', metal: '#8a909c', metalDark: '#555a68',
  display: '#1f3440', screen: '#6fd0d8', red: '#e0554a',
};

function mgLabEll(cx, cy, rx, ry, n = 20) {
  const out = [];
  for (let i = 0; i < n; i++) { const t = i / n * 2 * Math.PI; out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); }
  return out;
}

function mgLabPart(pts, fill, w = DETAIL, shade, shadeFill) {
  const p = shape(pts, fill, 0, AMP);
  if (shade) clipTo(p, () => blob(shade, shadeFill));
  path(p, true); stroke(w);
  return p;
}

function mgLabScreen() {
  const M = MG_LAB;
  seed = 2101;
  const sil = shape(rounded(rect(3, 3, 261, 89), 8), M.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(0, 77, 264, 92), M.dark);
    pen([[3, 77], [261, 77]], LINE, INK, AMP);
    for (let x = 18; x < 70; x += 7) pen([[x, 81], [x, 85]], DETAIL, INK, 0);
  });
  path(sil, true); stroke(LINE);
  blob(rounded(rect(12, 12, 252, 74), 3), M.display);
  path(rounded(rect(12, 12, 252, 74), 3), true); stroke(LINE);
  mgLabPart(mgLabEll(226, 83, 4, 3.2), M.screen);
  mgLabPart(mgLabEll(242, 83, 4, 3.2), M.red);
  mgLabPart(rounded(rect(150, 80, 206, 86), 2), M.metalDark);
}

registerProp('mg_lab_screen', {
  w: 264, h: 92, ox: 0, oy: 0, draw: mgLabScreen,
  pal: () => [INK, MG_LAB.lit, MG_LAB.dark, MG_LAB.metalDark, MG_LAB.display, MG_LAB.screen, MG_LAB.red],
});
