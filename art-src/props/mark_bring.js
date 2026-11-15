// Small hazard-yellow tag lettered "BRING HERE" in ink, with a notch pointing down at the station.
// Origin is the notch tip (bottom-centre).
const BRING_GLYPHS = {
  B: [[[0, 8], [0, 0], [3, 0], [4, 1], [4, 2.8], [3, 3.8], [0, 3.8]], [[3, 3.8], [4, 4.8], [4, 7], [3, 8], [0, 8]]],
  R: [[[0, 8], [0, 0], [3, 0], [4, 1], [4, 2.8], [3, 3.8], [0, 3.8]], [[2.2, 3.8], [4, 8]]],
  I: [[[0, 0], [0, 8]]],
  N: [[[0, 8], [0, 0], [4, 8], [4, 0]]],
  G: [[[4, 1], [3, 0], [1, 0], [0, 1.2], [0, 6.8], [1, 8], [3, 8], [4, 7], [4, 4.5], [2.4, 4.5]]],
  H: [[[0, 0], [0, 8]], [[4, 0], [4, 8]], [[0, 4], [4, 4]]],
  E: [[[4, 0], [0, 0], [0, 8], [4, 8]], [[0, 4], [3.2, 4]]],
};

function bringLetters(text, x, y) {
  for (const ch of text) {
    if (ch === ' ') { x += 4; continue; }
    for (const s of BRING_GLYPHS[ch]) pen(s.map(([px, py]) => [x + px, y + py]), 1.5, INK, 0);
    x += ch === 'I' ? 3 : 7;
  }
}

function markBring() {
  const x0 = -36, x1 = 36, y0 = -23, y1 = -6;
  seed = 1701;
  const tag = [[x0, y0], [x1, y0], [x1, y1], [4.5, y1], [0, -1], [-4.5, y1], [x0, y1]];
  const sil = shape(rounded(tag, 3), '#f2c230', 0, 0);
  clipTo(sil, () => {
    blob(rect(x0 - 2, y1 - 2.2, x1 + 2, 2), '#c99a22');
  });
  path(sil, true); stroke(1.8);
  bringLetters('BRING HERE', -30.5, y0 + 3.5);
}

registerProp('mark_bring', { w: 74, h: 25, ox: 37, oy: 24, draw: markBring, pal: () => [INK, '#f2c230', '#c99a22'] });
