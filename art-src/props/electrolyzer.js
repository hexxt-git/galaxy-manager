// An electrolyzer: two glass cells on a steel base, the oxygen cell fizzing cyan, joined overhead by a pipe, with a status screen.
const ELECTRO = {
  steel: '#a9bcc4', steelDark: '#6b818c', pipe: '#8a909c', pipeDark: '#555a68',
  glass: '#c4d8d4', glassDark: '#93b0ae', o2: '#6fd0d8', o2Dark: '#3a9aae', bubble: '#eef7f6',
  fore: 0.55, half: 42, front: 16, depth: 22, cells: [-19, 19], R: 11, cellH: 40,
};

function electroArc(cx, cy, r, t0, t1, n, fore = ELECTRO.fore) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([cx + r * Math.cos(t), cy + fore * r * Math.sin(t)]);
  }
  return out;
}

function electroDrum(cx, y0, y1, r, lit, dark, top) {
  const P = Math.PI;
  const sil = shape([...electroArc(cx, y0, r, 0, P, 16), ...electroArc(cx, y1, r, P, 2 * P, 16)], lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(cx + r * 0.3, y1 - 40, cx + r + 4, y0 + 20), dark);
    if (top) {
      blob(electroArc(cx, y1, r, 0, 2 * P, 28), top);
      pen(electroArc(cx, y1, r, -0.1, P + 0.1, 16), DETAIL, INK, AMP);
    }
  });
  return sil;
}

function electroBase() {
  const E = ELECTRO, a = E.half, yf = -E.front, yt = yf - E.depth;
  const sil = shape(rounded(rect(-a, yt, a, 0), 5), E.steel, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), E.steelDark);
    const scr = rounded(rect(-13, yf + 3, 13, -3), 2);
    blob(scr, E.o2);
    for (const [x, h] of [[-6, 3], [-1, 5], [4, 4]]) pen([[x, -6], [x, -6 - h]], 2, INK, 0);
    path(wobble(scr, AMP, 4, true), true); stroke(DETAIL);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

function electroCell(cx, fizz) {
  const E = ELECTRO, P = Math.PI, y0 = -E.front - E.depth / 2, y1 = y0 - 4, y2 = y1 - E.cellH, y3 = y2 - 5;
  let sil = electroDrum(cx, y0, y1, E.R + 2, E.pipe, E.pipeDark, E.pipe);
  path(sil, true); stroke(LINE);
  sil = electroDrum(cx, y1, y2, E.R, E.glass, E.glassDark, null);
  const yl = y2 + 7, lit = fizz ? E.o2 : E.glass, dark = fizz ? E.o2Dark : E.glassDark;
  clipTo(sil, () => {
    const fl = [...electroArc(cx, y1, E.R + 2, 0, P, 16), ...electroArc(cx, yl, E.R + 2, P, 2 * P, 16)];
    blob(fl, lit);
    clipTo(fl, () => blob(rect(cx + E.R * 0.3, yl - 20, cx + E.R + 4, y1 + 20), dark));
    blob(electroArc(cx, yl, E.R, 0, 2 * P, 24), lit);
    pen(electroArc(cx, yl, E.R, -0.05, P + 0.05, 16), DETAIL * 0.8, dark, AMP);
    const bubbles = fizz
      ? [[-5, -5, 1.9], [-3, -13, 1.5], [-6, -21, 1.9], [-2, -28, 1.4], [3, -9, 1.6], [5, -18, 1.9], [2, -25, 1.5], [-5, -32, 1.3]]
      : [[-4, -10, 1.3], [3, -22, 1.2]];
    for (const [bx, by, br] of bubbles) blob(electroArc(cx + bx, y1 + by, br, 0, 2 * P, 10, 1), fizz ? E.bubble : E.glassDark);
  });
  path(sil, true); stroke(LINE);
  sil = electroDrum(cx, y2, y3, E.R + 1, E.pipe, E.pipeDark, E.pipe);
  path(sil, true); stroke(LINE);
  return y3;
}

function electroPipe(yTop) {
  const E = ELECTRO, [l, r] = E.cells, yp = yTop - 9;
  const run = smooth([[l, yTop + 2], [l, yp], [r, yp], [r, yTop + 2]], false, 2);
  pen(run, 7.5, INK, AMP);
  pen(run, 3.6, E.pipeDark, 0);
  const v = rounded(rect(-4, yp - 4.5, 4, yp + 4.5), 2);
  shape(v, E.pipe, 0, AMP);
  path(wobble(v, AMP, 4, true), true); stroke(DETAIL);
}

function electrolyzer() {
  const E = ELECTRO;
  seed = 1311;
  blob(rounded(rect(-E.half - 1, -E.front - 10, E.half + 3, 3), 6), GROUND);
  electroBase();
  let yTop = 0;
  for (const [i, x] of E.cells.entries()) yTop = electroCell(x, i === 0);
  electroPipe(yTop - E.fore * (E.R + 1));
}

registerProp('electrolyzer', {
  w: 96, h: 103, ox: 48, oy: 97, draw: electrolyzer,
  pal: () => [INK, ELECTRO.steel, ELECTRO.steelDark, ELECTRO.pipe, ELECTRO.pipeDark, ELECTRO.glass, ELECTRO.glassDark, ELECTRO.o2, ELECTRO.o2Dark, ELECTRO.bubble, GROUND],
});
