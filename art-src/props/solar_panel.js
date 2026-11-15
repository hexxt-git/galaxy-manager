// A ground-mounted solar array: a frame of dark-blue cells tilted up at the sky on two short posts.
const SOLAR = {
  cell: '#3d78c4', cellDark: '#25497f', frame: '#bcd0cd', frameDark: '#86a1a2', leg: '#8a909c', legDark: '#555a68',
  half: 67, top: -100, bot: -37, edge: -30, cols: 6, rows: 3, gap: 3, posts: [-44, 44],
};

function solarPanel() {
  const S = SOLAR, a = S.half;
  seed = 821;
  blob(rounded(rect(-a + 1, -60, a + 2, 4), 8), GROUND);
  for (const x of S.posts) {
    const post = shape(rounded(rect(x - 4, S.edge - 2, x + 4, -3), 2), S.leg, 0, AMP);
    clipTo(post, () => blob(rect(x + 0.5, S.edge - 4, x + 6, 0), S.legDark));
    path(post, true); stroke(DETAIL);
    const foot = shape(rounded(rect(x - 9, -6, x + 9, 0), 2.5), S.legDark, 0, AMP);
    path(foot, true); stroke(DETAIL);
  }
  const sil = shape(rounded(rect(-a, S.top, a, S.edge), 5), S.frame, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, S.bot, a + 4, S.edge + 4), S.frameDark);
    const x0 = -a + 5, x1 = a - 5, y0 = S.top + 5, y1 = S.bot - 4;
    const cw = (x1 - x0 - S.gap * (S.cols - 1)) / S.cols, ch = (y1 - y0 - S.gap * (S.rows - 1)) / S.rows;
    for (let j = 0; j < S.rows; j++) for (let i = 0; i < S.cols; i++) {
      const cx = x0 + i * (cw + S.gap), cy = y0 + j * (ch + S.gap);
      const cell = rounded(rect(cx, cy, cx + cw, cy + ch), 1.5);
      blob(cell, S.cellDark);
      clipTo(cell, () => blob([[cx - 1, cy - 1], [cx + cw * 0.85, cy - 1], [cx - 1, cy + ch * 0.95]], S.cell));
    }
    path(wobble(rounded(rect(x0 - 1, y0 - 1, x1 + 1, y1 + 1), 2), AMP, 4, true), true); stroke(DETAIL);
    pen([[-a, S.bot], [a, S.bot]], DETAIL, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

registerProp('solar_panel', {
  w: 144, h: 108, ox: 72, oy: 103, draw: solarPanel,
  pal: () => [INK, SOLAR.cell, SOLAR.cellDark, SOLAR.frame, SOLAR.frameDark, SOLAR.leg, SOLAR.legDark, GROUND],
});
