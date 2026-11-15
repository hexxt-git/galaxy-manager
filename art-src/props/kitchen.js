// A compact galley: station-blue cabinets under a pale counter, a stove with a red pot, a fridge at the right end.
const KITCHEN = {
  lit: '#dfe7e4', top: '#c4d8d4', blue: '#4a92c9', blueDark: '#2b5c91',
  steel: '#bcd0cd', steelDark: '#86a1a2', hob: '#3d4250', pot: '#c8453f', potDark: '#8a2b33',
  half: 66, depth: 36, front: 28, r: 5, fridgeX: 34, fridgeFront: 66,
};

function kitchenEll(cx, cy, rx, ry, n = 20) {
  const out = [];
  for (let i = 0; i < n; i++) { const t = i / n * 2 * Math.PI; out.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); }
  return out;
}

function kitchen() {
  const K = KITCHEN, a = K.half, yf = -K.front, yt = yf - K.depth, fx = K.fridgeX;
  seed = 1601;
  blob(rounded(rect(-a - 1, -5, a + 3, 4.5), 4), GROUND);

  const counter = shape(rounded(rect(-a, yt, fx + 6, 0), K.r), K.lit, 0, AMP);
  clipTo(counter, () => {
    blob(rect(-a - 4, yf, fx + 8, 4), K.blue);
    blob(rect(-a - 4, yf, fx + 8, yf + 4), K.blueDark);
    for (const [x0, x1] of [[-a + 5, -36], [-31, -2], [3, fx - 4]]) {
      path(wobble(rounded(rect(x0, yf + 7, x1, -4), 2), AMP, 4, true), true); stroke(DETAIL);
      pen([[x1 - 5, yf + 11], [x1 - 5, yf + 15]], DETAIL, INK, 0);
    }
    pen([[-a, yf + 4], [fx + 6, yf + 4]], DETAIL, INK, AMP);
    pen([[-a, yf], [fx + 6, yf]], LINE, INK, AMP);
  });
  path(counter, true); stroke(LINE);

  // stove
  const hob = shape(rounded(rect(-6, yt + 6, 26, yf - 5), 3), K.hob, 0, AMP);
  path(hob, true); stroke(DETAIL);
  for (const [x, y] of [[2, -44], [18, -54]]) { path(wobble(kitchenEll(x, y, 5, 3), AMP, 3, true), true); stroke(DETAIL, K.steelDark); }
  const potY = -48, px = 5;
  const pot = shape(rounded([[px - 11, potY - 16], [px + 11, potY - 16], [px + 10, potY], [px - 10, potY]], 3), K.pot, 0, AMP);
  clipTo(pot, () => {
    blob(rect(px - 14, potY - 6, px + 14, potY + 4), K.potDark);
    blob(kitchenEll(px, potY - 16, 7, 2.2), K.potDark);
    pen([[px - 11, potY - 6], [px + 11, potY - 6]], DETAIL, INK, AMP);
  });
  path(pot, true); stroke(LINE);
  pen([[px - 11, potY - 13], [px - 15, potY - 14]], DETAIL + 1, INK, 0);
  pen([[px + 11, potY - 13], [px + 15, potY - 14]], DETAIL + 1, INK, 0);
  path(wobble(kitchenEll(px, potY - 16, 11, 3.5), AMP, 3, true), true); stroke(DETAIL);

  // sink
  const sink = wobble(rounded(rect(-56, yt + 8, -30, yf - 6), 3), AMP, 4, true);
  blob(sink, K.steelDark);
  path(sink, true); stroke(DETAIL);
  pen([[-43, yt + 8], [-43, yt + 2], [-38, yt + 2]], DETAIL + 1, INK, 0);

  // fridge
  const ff = -K.fridgeFront, ft = ff - 20;
  const fridge = shape(rounded(rect(fx, ft, a, 0), K.r), K.steel, 0, AMP);
  clipTo(fridge, () => {
    blob(rect(fx - 4, ff, a + 4, 4), K.steelDark);
    pen([[fx, ff + 24], [a, ff + 24]], DETAIL, INK, AMP);
    for (const y of [[ff + 6, ff + 16], [ff + 30, ff + 42]]) pen([[fx + 6, y[0]], [fx + 6, y[1]]], DETAIL + 1, INK, 0);
    pen([[fx, ff], [a, ff]], LINE, INK, AMP);
  });
  path(fridge, true); stroke(LINE);
}

registerProp('kitchen', {
  w: 144, h: 98, ox: 72, oy: 90, draw: kitchen,
  pal: () => [INK, KITCHEN.lit, KITCHEN.top, KITCHEN.blue, KITCHEN.blueDark, KITCHEN.steel, KITCHEN.steelDark, KITCHEN.hob, KITCHEN.pot, KITCHEN.potDark, GROUND],
});
