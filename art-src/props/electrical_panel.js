// A wall bank of four electrical cabinets: warning-sign door, double door, two breaker grilles, cables out the bottom.
const EPANEL = {
  lit: '#bcd0cd', dark: '#86a1a2', grille: '#3d4250', warn: '#f2c230', cable: '#2a2d38',
  half: 80, depth: 14, front: 58, r: 4, plinth: 6, inset: 4.5, cells: 4,
};

// Collinear points along long edges so rounded() only curves the real corners.
function epanelEdges(pts, r) {
  const out = [];
  pts.forEach((a, i) => {
    const b = pts[(i + 1) % pts.length], len = Math.hypot(b[0] - a[0], b[1] - a[1]);
    const ts = [0];
    if (len > 8 * r) {
      const inner = len - 8 * r, n = Math.max(1, Math.round(inner / 10));
      for (let k = 0; k <= n; k++) ts.push((4 * r + inner * k / n) / len);
    }
    for (const t of ts) out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
  });
  return out;
}

function electricalPanel() {
  const E = EPANEL, a = E.half, yf = -E.front, yt = yf - E.depth, yp = -E.plinth, d = E.inset;
  const cw = 2 * a / E.cells, cx = i => -a + cw * i;
  seed = 701;
  blob(rounded(rect(-a - 1, -5, a + 3, 4.5), 4), GROUND);
  const sil = shape(rounded(epanelEdges(rect(-a, yt, a, 0), E.r), E.r), E.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), E.dark);
    for (let i = 1; i < E.cells; i++) {
      pen([[cx(i), yt + 3], [cx(i), yf]], DETAIL, INK, AMP);
      pen([[cx(i), yf], [cx(i), yp]], DETAIL, INK, AMP);
    }
    const y0 = yf + d, y1 = yp - 3;

    // warning door
    let door = rounded(rect(cx(0) + d, y0, cx(1) - d, y1), 2);
    blob(door, E.lit);
    path(wobble(door, AMP, 4, true), true); stroke(DETAIL);
    const tx = cx(0) + cw / 2 - 3, ty = y0 + 9;
    const tri = rounded([[tx, ty], [tx + 9, ty + 15], [tx - 9, ty + 15]], 1.8);
    blob(tri, E.warn);
    path(tri, true); stroke(DETAIL * 0.8);
    blob(rounded(rect(tx - 1.1, ty + 5, tx + 1.1, ty + 11), 1.1), INK);
    blob(rounded(rect(cx(1) - d - 6, y0 + 16, cx(1) - d - 3.4, y0 + 24), 1.3), INK);

    // double door
    for (const s of [-1, 1]) {
      const m = cx(1) + cw / 2, x0 = m + s * 1.5, x1 = m + s * (cw / 2 - d);
      door = rounded(rect(Math.min(x0, x1), y0, Math.max(x0, x1), y1), 2);
      blob(door, E.lit);
      path(wobble(door, AMP, 4, true), true); stroke(DETAIL);
      blob(rounded(rect(m + s * 5 - 1.3, y0 + 14, m + s * 5 + 1.3, y0 + 22), 1.3), INK);
    }

    // breaker grilles
    for (const i of [2, 3]) {
      const g = rounded(rect(cx(i) + d + 2, y0, cx(i + 1) - d - 2, y1), 2);
      blob(g, E.grille);
      const m = cx(i) + cw / 2;
      pen([[m, y0 + 2], [m, y1 - 2]], DETAIL * 0.7, INK, 0);
      for (let y = y0 + 5; y < y1 - 2; y += 4.5) {
        pen([[cx(i) + d + 4, y], [m - 2, y]], DETAIL * 0.6, INK, 0);
        pen([[m + 2, y], [cx(i + 1) - d - 4, y]], DETAIL * 0.6, INK, 0);
      }
      path(wobble(g, AMP, 4, true), true); stroke(DETAIL);
    }

    pen([[-a, yp], [a, yp]], DETAIL, INK, AMP);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);

  // cables: [start x, end x, end y, sag]
  const cables = [[cx(2) + 12, cx(2) - 8, 9, 4], [cx(2) + 20, cx(2) + 30, 12, 3], [cx(3) + 14, cx(3) + 2, 11, 5], [cx(3) + 24, cx(4) - 2, 8, 3]];
  for (const [x0, x1, y1, sag] of cables) {
    const c = smooth([[x0, yp - 1], [x0 + (x1 - x0) * 0.2, 0], [x0 + (x1 - x0) * 0.6, y1 - sag * 0.3], [x1, y1]], false, 3);
    pen(c, 4, INK, AMP);
    pen(c, 1.6, E.cable, 0);
  }
}

registerProp('electrical_panel', {
  w: 173, h: 96, ox: 86, oy: 78, draw: electricalPanel,
  pal: () => [INK, EPANEL.lit, EPANEL.dark, EPANEL.grille, EPANEL.warn, EPANEL.cable, GROUND],
});
