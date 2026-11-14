// A squat floor generator: lit top face over a front in shadow, a dark vent grille, a status light and two exhaust stacks.
const GENERATOR = {
  lit: '#c9a548', dark: '#8a6733', grille: '#2c2f3a', slat: '#4b505e',
  pipe: '#8a909c', pipeDark: '#555a68', light: '#7ed957',
  half: 26, depth: 22, front: 34, r: 5, fore: 0.55,
  stacks: [[-2, -12, 3.5, 7], [-13, -7, 4.5, 9]],  // [x, y on the top face from its front edge, radius, height]
};

function generatorArc(cx, cy, rx, t0, t1, n) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = t0 + (t1 - t0) * i / n;
    out.push([cx + rx * Math.cos(t), cy + GENERATOR.fore * rx * Math.sin(t)]);
  }
  return out;
}

function generatorStack([x, y, r, h]) {
  const G = GENERATOR, yb = -G.front + y, yt = yb - h;
  const tube = shape([...generatorArc(x, yb, r, 0, Math.PI, 10), ...generatorArc(x, yt, r, Math.PI, 2 * Math.PI, 10)], G.pipe, 0, AMP);
  clipTo(tube, () => {
    blob(rect(x + r * 0.2, yt - 10, x + r + 3, yb + 4), G.pipeDark);
    blob(generatorArc(x, yt, r, 0, 2 * Math.PI, 20), G.pipeDark);
    blob(generatorArc(x, yt + 0.4, r - 1.6, 0, 2 * Math.PI, 16), INK);
  });
  path(tube, true); stroke(LINE * 0.8);
}

function generator() {
  const G = GENERATOR, a = G.half, yf = -G.front, yt = yf - G.depth;
  seed = 701;
  blob(rounded(rect(-a - 1, -5, a + 3, 4.5), 4), GROUND);
  const sil = shape(rounded(rect(-a, yt, a, 0), G.r), G.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), G.dark);
    const grille = rounded(rect(-a + 6, yf + 6, 8, -6), 2);
    blob(grille, G.grille);
    for (let y = yf + 10; y < -9; y += 4) blob(rect(-a + 8, y, 6, y + 1.5), G.slat);
    path(wobble(grille, AMP, 4, true), true); stroke(DETAIL);
    const lamp = generatorArc(16, yf + 11, 3.2, 0, 2 * Math.PI, 16).map(([x, y]) => [x, y + (y - yf - 11) * 0.8]);
    blob(lamp, G.light);
    path(wobble(lamp, AMP, 4, true), true); stroke(DETAIL);
    pen([[12, yf + 20], [20, yf + 20]], DETAIL, INK, AMP);
    pen([[12, yf + 25], [20, yf + 25]], DETAIL, INK, AMP);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
  G.stacks.forEach(generatorStack);
}

registerProp('generator', {
  w: 82, h: 74, ox: 40, oy: 65, scale: [1.3, 1.05], draw: generator,
  pal: () => [INK, GENERATOR.lit, GENERATOR.dark, GENERATOR.grille, GENERATOR.slat, GENERATOR.pipe, GENERATOR.pipeDark, GENERATOR.light, GROUND],
});
