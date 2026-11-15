// Bubbly hand-lettered capitals for the menu: fat round-brush strokes, the title also ringed in ink.
// Glyphs are on a grid 10 units tall; `w` is the advance width. Strokes marked round are smoothed into curves.
const MT_R = p => ({ round: p });
const MT_GLYPHS = {
  A: { w: 6, s: [[[0, 10], [2.2, 1.2], [3, 0], [3.8, 1.2], [6, 10]], [[1.3, 6.4], [4.7, 6.4]]] },
  B: { w: 5.8, s: [MT_R([[0, 5], [0, 0], [3.4, 0], [5.4, 1.2], [5.4, 3.8], [3.4, 5], [0, 5]]),
    MT_R([[0, 5], [3.6, 5], [5.8, 6.2], [5.8, 8.8], [3.6, 10], [0, 10], [0, 5]])] },
  C: { w: 6, s: [MT_R([[6, 1.6], [4.6, 0], [1.6, 0], [0, 2], [0, 8], [1.6, 10], [4.6, 10], [6, 8.4]])] },
  E: { w: 5.5, s: [[[5.5, 0], [0, 0], [0, 10], [5.5, 10]], [[0, 5], [4.5, 5]]] },
  G: { w: 6.2, s: [MT_R([[6, 1.6], [4.6, 0], [1.6, 0], [0, 2], [0, 8], [1.6, 10], [4.6, 10], [6.2, 8.4], [6.2, 5.6], [3.6, 5.6]])] },
  I: { w: 0, s: [[[0, 0], [0, 10]]] },
  K: { w: 5.8, s: [[[0, 0], [0, 10]], [[5.6, 0], [0.4, 5.6]], [[2.2, 4.2], [5.8, 10]]] },
  L: { w: 5.2, s: [[[0, 0], [0, 10], [5.2, 10]]] },
  M: { w: 7.4, s: [[[0, 10], [0, 0], [3.7, 6.2], [7.4, 0], [7.4, 10]]] },
  N: { w: 6, s: [[[0, 10], [0, 0], [6, 10], [6, 0]]] },
  O: { w: 6.6, s: [MT_R([[3.3, 0], [6, 1.4], [6.6, 5], [6, 8.6], [3.3, 10], [0.6, 8.6], [0, 5], [0.6, 1.4], [3.3, 0]])] },
  P: { w: 5.8, s: [MT_R([[0, 10], [0, 0], [3.6, 0], [5.8, 1.4], [5.8, 4.2], [3.6, 5.6], [0, 5.6]])] },
  Q: { w: 6.6, s: [MT_R([[3.3, 0], [6, 1.4], [6.6, 5], [6, 8.6], [3.3, 10], [0.6, 8.6], [0, 5], [0.6, 1.4], [3.3, 0]]), [[4.2, 7.4], [6.8, 10.4]]] },
  R: { w: 5.8, s: [MT_R([[0, 10], [0, 0], [3.6, 0], [5.8, 1.4], [5.8, 4.2], [3.6, 5.6], [0, 5.6]]), [[3, 5.6], [5.8, 10]]] },
  S: { w: 5.8, s: [MT_R([[5.8, 1.4], [4.4, 0], [1.4, 0], [0, 1.6], [0, 3.4], [1.6, 4.8], [4.2, 5.2], [5.8, 6.6], [5.8, 8.4], [4.4, 10], [1.4, 10], [0, 8.6]])] },
  T: { w: 6, s: [[[0, 0], [6, 0]], [[3, 0], [3, 10]]] },
  U: { w: 6, s: [MT_R([[0, 0], [0, 7.4], [1.4, 10], [4.6, 10], [6, 7.4], [6, 0]])] },
  W: { w: 8, s: [[[0, 0], [1.8, 10], [4, 3.8], [6.2, 10], [8, 0]]] },
  X: { w: 6, s: [[[0, 0], [6, 10]], [[6, 0], [0, 10]]] },
  Y: { w: 6, s: [[[0, 0], [3, 5.2]], [[6, 0], [3, 5.2], [3, 10]]] },
};

// size: art px per glyph unit; brush: fill stroke; ring: extra ink each side (0 = plain ink letters).
function mtWidth(text, size, brush, gap) {
  let w = 0;
  for (const ch of text) w += ch === ' ' ? 4 * size : MT_GLYPHS[ch].w * size + brush + gap;
  return w - gap;
}

function mtLine(text, x, y, size, brush, ring, fill) {
  const strokes = [];
  for (const ch of text) {
    if (ch === ' ') { x += 4 * size; continue; }
    const g = MT_GLYPHS[ch];
    for (const s of g.s) {
      const pts = (s.round || s).map(([px, py]) => [x + brush / 2 + px * size, y + brush / 2 + py * size]);
      strokes.push(s.round ? smooth(pts, false, 2) : pts);
    }
    x += g.w * size + brush + MT_GAP;
  }
  const draw = (w, c) => { for (const p of strokes) { path(p, false); stroke(w, c); } };
  if (ring) draw(brush + ring * 2, INK);
  draw(brush, fill);
}

const MT_GAP = 3;

// Titles: centred lines of yellow letters ringed in ink.
const MT_TITLE = { size: 3.4, brush: 8, ring: 4, lead: 8, fill: '#f2c230' };
function registerTitle(name, lines) {
  const T = MT_TITLE, pad = T.ring + 2, lineH = 10 * T.size + T.brush;
  const widths = lines.map(l => mtWidth(l, T.size, T.brush, MT_GAP));
  const w = Math.ceil(Math.max(...widths) + pad * 2), h = Math.ceil(lineH * lines.length + T.lead * (lines.length - 1) + pad * 2);
  registerProp(name, { w, h, ox: 0, oy: 0, pal: () => [INK, T.fill], draw: () => {
    lines.forEach((l, i) => mtLine(l, (w - widths[i]) / 2, pad + i * (lineH + T.lead), T.size, T.brush, T.ring, T.fill));
  } });
}
registerTitle('menu_title', ['MOON', 'CREW']);
registerTitle('menu_base_online', ['BASE', 'ONLINE']);

// Button labels: plain ink letters, laid over the menu buttons in-engine.
const MT_LABEL = { size: 1.25, brush: 3.6 };
for (const text of ['TUTORIAL', 'PLAY', 'QUIT', 'KEEP PLAYING', 'MENU']) {
  const L = MT_LABEL, pad = 2, tw = mtWidth(text, L.size, L.brush, MT_GAP);
  const w = Math.ceil(tw + pad * 2), h = Math.ceil(10 * L.size + L.brush + pad * 2);
  registerProp('menu_label_' + text.toLowerCase().replace(' ', '_'), { w, h, ox: 0, oy: 0, pal: () => [INK],
    draw: () => mtLine(text, pad, pad, L.size, L.brush, 0, INK) });
}
