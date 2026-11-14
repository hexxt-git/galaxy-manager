const CRATE = {
  lit: '#5f9c80', dark: '#336355',
  half: 27, depth: 30, front: 22, r: 5,
};

function crate() {
  const C = CRATE, a = C.half, yt = -C.front - C.depth, yf = -C.front;
  seed = 301;
  blob(rounded(rect(-a - 1, -5, a + 3, 4.5), 4), GROUND);
  const sil = shape(rounded(rect(-a, yt, a, 0), C.r), C.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, 4), C.dark);
    path(wobble(rounded(rect(-a + 6, yt + 6, a - 6, yf - 5.5), 2.5), AMP, 4, true), true); stroke(LINE * 0.68);
    for (const x of [-a + 6, a - 6]) pen([[x, yf + 5], [x, -4]], LINE * 0.68, INK, AMP);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
}

registerProp('crate', { w: 67, h: 67, ox: 33, oy: 58, draw: crate, pal: () => [INK, CRATE.lit, CRATE.dark, GROUND] });
