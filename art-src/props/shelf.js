// Open wall shelving: a lit top face over a shadowed front, three lit shelf boards and a few small bins.
const SHELF = {
  lit: '#a9bcc4', dark: '#6b818c',
  half: 26, depth: 12, front: 62, r: 4, post: 5, plinth: 5, board: 6,
  levels: [-43, -24],
  // [x0, x1, shelf y, front h, top depth, lit, dark]
  bins: [
    [-16, -2, -43, 8, 4, '#5f9c80', '#336355'],
    [-17, -1, -24, 10, 4, '#c8453f', '#8a2b33'],
    [4, 16, -24, 7, 4, '#5f9c80', '#336355'],
    [2, 18, -5, 10, 4, '#6390bd', '#3c6390'],
  ],
};

// Collinear points along each edge keep rounded()'s Chaikin pass from bowing the long sides.
function shelfEdges(pts) {
  return pts.flatMap((a, i) => {
    const b = pts[(i + 1) % pts.length];
    const len = Math.hypot(b[0] - a[0], b[1] - a[1]), e = 2.5 * SHELF.r / len;
    return [0, e, 0.5, 1 - e].map(t => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
  });
}

function shelfBin([x0, x1, yb, h, d, lit, dark]) {
  const yf = yb - h, yt = yf - d;
  const sil = shape(rounded(rect(x0, yt, x1, yb), 2), lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(x0 - 2, yf, x1 + 2, yb + 2), dark);
    pen([[x0, yf], [x1, yf]], DETAIL, INK, AMP);
  });
  path(sil, true); stroke(DETAIL);
}

function shelf() {
  const S = SHELF, a = S.half, yf = -S.front, yt = yf - S.depth, p = S.post;
  seed = 701;
  blob(rounded(rect(-a - 1, -5, a + 3, 4.5), 4), GROUND);
  const sil = shape(rounded(shelfEdges(rect(-a, yt, a, 0)), S.r), S.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), S.dark);
    for (const y of [...S.levels, -S.plinth]) blob(rect(-a + p, y - S.board, a - p, y), S.lit);
    for (const b of S.bins) shelfBin(b);
    for (const y of S.levels) pen([[-a, y], [a, y]], DETAIL, INK, AMP);
    pen([[-a, -S.plinth], [a, -S.plinth]], DETAIL, INK, AMP);
    for (const x of [-a + p, a - p]) pen([[x, yf], [x, 0]], DETAIL, INK, AMP);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

registerProp('shelf', {
  w: 67, h: 92, ox: 33, oy: 83, scale: [1.05, 1.05], draw: shelf,
  pal: () => [INK, SHELF.lit, SHELF.dark, ...new Set(SHELF.bins.flatMap(b => b.slice(5))), GROUND],
});
