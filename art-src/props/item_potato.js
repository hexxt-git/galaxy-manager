// A single potato: chunky kidney-bean tuber, warm brown, a few dark eyes.
const POTC = { lit: '#c9945a', dark: '#8a5a33' };

// Ellipse with a fuller lower half and a dent pressed into the top edge, tilted, resting on y=0.
function kidney(a, bTop, bBot, dent, tilt) {
  const pts = [];
  for (let i = 0; i < 28; i++) {
    const t = (i / 28) * Math.PI * 2, x = a * Math.cos(t), sn = Math.sin(t);
    let y = sn * (sn < 0 ? bTop : bBot);
    if (sn < 0) y += dent * Math.exp(-((x / (a * 0.4)) ** 2)) * -sn;
    pts.push([x * Math.cos(tilt) - y * Math.sin(tilt), x * Math.sin(tilt) + y * Math.cos(tilt)]);
  }
  const bottom = Math.max(...pts.map((q) => q[1]));
  return pts.map(([x, y]) => [x, y - bottom]);
}

function itemPotato() {
  const P = POTC;
  seed = 1331;
  blob(rounded(rect(-9, -2, 10, 2.5), 2), GROUND);
  const sil = shape(smooth(kidney(10.5, 5.6, 7.2, 2.2, -0.14), true, 2), P.lit, 0, AMP);
  clipTo(sil, () => {
    const horizon = smooth([[-12, -4.5], [-4, -4.2], [4, -5.6], [12, -7.8]], false, 2);
    blob([...horizon, [12, 3], [-12, 3]], P.dark);
    pen(horizon, 1.4, INK, AMP);
    for (const [x, y] of [[-6, -8.2], [5.5, -10.2], [0, -7.6], [-3, -2.4]]) blob(rounded(rect(x - 1, y - 0.8, x + 1, y + 0.8), 0.7), INK);
  });
  path(sil, true); stroke(LINE);
}

registerProp('item_potato', { w: 42, h: 36, ox: 21, oy: 30, scale: [1.73, 1.73], draw: itemPotato, pal: () => [INK, POTC.lit, POTC.dark, GROUND] });
