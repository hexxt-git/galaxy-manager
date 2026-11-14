// A small dish on a tripod, tilted up-left so its concave face shows; the back shell peeks out lower right.
const DISH = {
  shell: '#bcd0cd', shellDark: '#86a1a2', leg: '#555a68', legDark: '#33363f', feed: '#c8453f',
  c: [-2, -54], a: 22, b: 15, tilt: -0.42, back: [9, 11], backScale: 0.6,
  hub: [2, -26], feet: [[6, -16], [-20, -3], [20, -4]], feedAt: [-6, -61],
};

function dishEllipse([cx, cy], a, b, rot, n = 40) {
  const out = [], c = Math.cos(rot), s = Math.sin(rot);
  for (let i = 0; i < n; i++) {
    const t = 2 * Math.PI * i / n, x = a * Math.cos(t), y = b * Math.sin(t);
    out.push([cx + x * c - y * s, cy + x * s + y * c]);
  }
  return out;
}

function dishHull(pts) {
  const p = [...pts].sort((u, v) => u[0] - v[0] || u[1] - v[1]);
  const cross = (o, a, b) => (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
  const half = list => {
    const h = [];
    for (const q of list) {
      while (h.length > 1 && cross(h[h.length - 2], h[h.length - 1], q) <= 0) h.pop();
      h.push(q);
    }
    h.pop();
    return h;
  };
  return [...half(p), ...half(p.reverse())];
}

function dishLeg(a, b, lit) {
  pen([a, b], 6.2, INK, AMP);
  pen([a, b], 2.6, lit, 0);
}

function dishAntenna() {
  const D = DISH, [cx, cy] = D.c;
  seed = 611;
  blob(rounded(rect(-25, -20, 26, 3), 9), GROUND);
  dishLeg(D.hub, D.feet[0], D.legDark);
  const mastTop = [cx + D.back[0] + 1, cy + D.back[1] + 1];
  dishLeg(D.hub, mastTop, D.leg);
  dishLeg(D.hub, D.feet[1], D.leg);
  dishLeg(D.hub, D.feet[2], D.legDark);
  const hub = rounded(rect(D.hub[0] - 5.5, D.hub[1] - 5, D.hub[0] + 5.5, D.hub[1] + 4), 3);
  shape(hub, D.legDark, 0, AMP);
  clipTo(hub, () => blob(rect(D.hub[0] - 6, D.hub[1] - 6, D.hub[0] + 1, D.hub[1] + 6), D.leg));
  path(hub, true); stroke(DETAIL);

  const rim = dishEllipse(D.c, D.a, D.b, D.tilt);
  const backC = [cx + D.back[0], cy + D.back[1]];
  const sil = shape(dishHull([...rim, ...dishEllipse(backC, D.a * D.backScale, D.b * D.backScale, D.tilt)]), D.shellDark, 0, AMP);
  clipTo(sil, () => {
    blob(rim, D.shellDark);
    clipTo(rim, () => blob(rim.map(([x, y]) => [x + 5, y + 7]), D.shell));
  });
  path(wobble(rim, AMP, 4, true), true); stroke(DETAIL);
  path(sil, true); stroke(LINE);

  // feed arm: two struts from the near rim to the horn at the focus
  const f = D.feedAt, near = [rim[5], rim[15]];
  for (const p of near) { pen([p, f], 3.6, INK, AMP); pen([p, f], 1.2, D.legDark, 0); }
  const horn = dishEllipse(f, 3.2, 2.6, D.tilt, 16);
  shape(horn, D.feed, 0, 0);
  path(horn, true); stroke(DETAIL);
}

registerProp('dish_antenna', {
  w: 72, h: 102, ox: 35, oy: 94, scale: [1.25, 1.25], draw: dishAntenna,
  pal: () => [INK, DISH.shell, DISH.shellDark, DISH.leg, DISH.legDark, DISH.feed, GROUND],
});
