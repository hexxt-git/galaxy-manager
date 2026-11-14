// A low platform cart: steel deck on four casters, a push handle off the right end, a tied burlap sack and a small crate.
const CART = {
  lit: '#8fa3c0', dark: '#5a6b8c', tube: '#8a909c', tubeDark: '#555a68',
  sack: '#b08a5a', sackDark: '#7a5a3c', rope: '#e3cf8e', box: '#5f9c80', boxDark: '#336355',
  half: 30, depth: 26, thick: 5, lift: 8, r: 4, wheelX: 21, wheel: 4.5,
  handle: { x: 26, lean: 9, rise: 26, zf: 4, zb: 22 },
  crate: [7, 25, -19, 11, 10],  // x0, x1, front bottom y, front h, top depth
};

function cargoCart() {
  const C = CART, a = C.half, yf = -C.lift - C.thick, yt = yf - C.depth, H = C.handle;
  seed = 911;
  blob(rounded(rect(-a - 1, -5, a + 4, 4.5), 4), GROUND);

  const deck = wobble(rounded(rect(-a, yt, a, -C.lift), C.r), AMP, 4, true);
  const wheels = [-1, 1].map(s => smooth(rect(s * C.wheelX - C.wheel, -2 * C.wheel, s * C.wheelX + C.wheel, 0), true, 3));
  const post = z => [[H.x, yf - z + 1], [H.x + H.lean, yf - z - H.rise]];
  const grip = [[H.x + H.lean, yf - H.zf - H.rise + 1], [H.x + H.lean, yf - H.zb - H.rise - 1]];
  const [x0, x1, yb, bh, bd] = C.crate;
  const box = wobble(rounded(rect(x0, yb - bh - bd, x1, yb), 2.5), AMP, 4, true);
  const sack = wobble(smooth([
    [-27, -15], [-29, -26], [-26, -37], [-19, -44], [-14, -47], [-6, -47], [0, -43], [6, -36], [8, -26], [5, -16], [-4, -13], [-17, -13],
  ], true, 3), AMP, 4, true);
  const tuft = wobble(smooth([[-14, -46], [-19, -53], [-15, -57], [-11, -53], [-8, -58], [-4, -53], [-6, -46]], true, 2), AMP, 4, true);
  const tube = 3;

  const halo = 2 * LINE - DETAIL;
  for (const p of [deck, ...wheels, box, sack, tuft]) { path(p, true); stroke(halo); }
  for (const p of [post(H.zf), post(H.zb), grip]) pen(p, tube + halo, INK, 0);

  wheels.forEach((w, i) => {
    blob(w, C.tubeDark); path(w, true); stroke(DETAIL);
    const cx = (2 * i - 1) * C.wheelX, cy = -C.wheel;
    blob(smooth(rect(cx - 1.4, cy - 1.4, cx + 1.4, cy + 1.4), true, 3), INK);
  });

  blob(deck, C.lit);
  clipTo(deck, () => {
    blob(rect(-a - 4, yf, a + 4, 4), C.dark);
    for (const y of [yt + 9, yt + 17]) pen([[-a + 5, y], [a - 5, y]], DETAIL * 0.8, INK, AMP);
    pen([[-a, yf], [a, yf]], DETAIL * 1.3, INK, AMP);
  });
  path(deck, true); stroke(DETAIL);

  const tubeLine = p => { pen(p, tube + 2 * DETAIL, INK, 0); pen(p, tube, C.tube, 0); };
  tubeLine(post(H.zb));
  tubeLine(grip);

  blob(box, C.box);
  clipTo(box, () => {
    blob(rect(x0 - 3, yb - bh, x1 + 3, yb + 3), C.boxDark);
    pen([[x0, yb - bh], [x1, yb - bh]], DETAIL, INK, AMP);
    path(wobble(rounded(rect(x0 + 3.5, yb - bh - bd + 3, x1 - 3.5, yb - bh - 3), 1.5), AMP, 4, true), true); stroke(DETAIL * 0.7);
  });
  path(box, true); stroke(DETAIL);

  for (const p of [tuft, sack]) {
    blob(p, C.sack);
    clipTo(p, () => blob(smooth([[-6, -62], [-1, -40], [-3, -24], [-10, -8], [20, -8], [20, -62]], false, 3), C.sackDark));
    path(p, true); stroke(DETAIL);
  }
  clipTo(sack, () => {
    pen([[-22, -34], [-18, -29], [-17, -24]], DETAIL * 0.8, INK, AMP);
    const strap = smooth([[-31, -30], [-14, -25], [10, -31]], false, 3);
    pen(strap, 3 + 2 * DETAIL, INK, 0);
    pen(strap, 3, C.rope, 0);
  });
  const tie = [[-15, -46.5], [-10, -45], [-5, -46.5]];
  pen(tie, 3 + 2 * DETAIL, INK, 0);
  pen(tie, 3, C.rope, 0);

  tubeLine(post(H.zf));
}

registerProp('cargo_cart', {
  w: 79, h: 79, ox: 36, oy: 70, draw: cargoCart,
  pal: () => [INK, CART.lit, CART.dark, CART.tube, CART.tubeDark, CART.sack, CART.sackDark, CART.rope, CART.box, CART.boxDark, GROUND],
});
