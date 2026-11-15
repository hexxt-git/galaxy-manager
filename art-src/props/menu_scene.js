// Title-screen scenery: a cream-and-red rocket standing on a launch pad, Earth hanging in the sky, a small ringed planet.
const MS = {
  body: '#ece9dd', bodyDark: '#b9bcc4', red: '#d8463a', redDark: '#9c2a33',
  glass: '#6fd0d8', glassDark: '#3f9aa8', shine: '#ffffff',
  pad: '#8a909c', padDark: '#555a68', bell: '#4b505e', tip: '#f2c230',
  ocean: '#3f7fd0', oceanDark: '#2b5c91', land: '#5fbf5a', landDark: '#3c8e4a', cloud: '#f4f4ee',
  planet: '#e8914a', planetDark: '#b5603a', ring: '#f2c230',
};

function msEllipse(cx, cy, a, b, n = 28, rot = 0) {
  const out = [], c = Math.cos(rot), s = Math.sin(rot);
  for (let i = 0; i < n; i++) {
    const t = 2 * Math.PI * i / n, x = a * Math.cos(t), y = b * Math.sin(t);
    out.push([cx + x * c - y * s, cy + x * s + y * c]);
  }
  return out;
}

function msFin(pts, fill, dark) {
  const f = shape(smooth(pts, true, 2), fill, 0, AMP);
  clipTo(f, () => blob(rect(-60, -34, 60, 0), dark));
  path(f, true); stroke(LINE);
}

function menuRocket() {
  const M = MS;
  seed = 2203;
  blob(rounded(rect(-44, -6, 44, 4), 5), GROUND);

  for (const s of [-1, 1]) {
    pen([[s * 30, -12], [s * 38, 0]], LINE + 3, INK, 0);
    pen([[s * 30, -12], [s * 38, 0]], 3, M.padDark, 0);
  }
  const pad = shape(rounded(rect(-38, -20, 38, -10), 3), M.pad, 0, AMP);
  clipTo(pad, () => blob(rect(-40, -15, 40, -8), M.padDark));
  path(pad, true); stroke(LINE);

  const bell = shape(rounded([[-9, -34], [9, -34], [13, -19], [-13, -19]], 2), M.bell, 0, AMP);
  clipTo(bell, () => blob(rect(4, -36, 16, -17), INK));
  path(bell, true); stroke(LINE);

  msFin([[-14, -76], [-33, -46], [-35, -24], [-15, -34]], M.red, M.redDark);
  msFin([[14, -76], [33, -46], [35, -24], [15, -34]], M.red, M.redDark);

  const body = shape(smooth([[-17, -32], [-19, -76], [-17, -108], [-10, -134], [0, -156],
    [10, -134], [17, -108], [19, -76], [17, -32]], true, 3), M.body, 0, AMP);
  clipTo(body, () => {
    blob(rect(9, -170, 30, -20), M.bodyDark);
    blob(rect(-30, -170, 30, -114), M.red);
    blob(rect(9, -170, 30, -114), M.redDark);
    pen([[-22, -114], [22, -114]], DETAIL, INK, AMP);
    blob(rect(-30, -56, 30, -48), M.red);
    blob(rect(9, -56, 30, -48), M.redDark);
    pen([[-22, -56], [22, -56]], DETAIL, INK, AMP);
    pen([[-22, -48], [22, -48]], DETAIL, INK, AMP);
    blob(smooth([[-13, -104], [-11, -82], [-13, -62], [-15, -82]], true, 2), M.shine);
  });
  path(body, true); stroke(LINE);

  const port = shape(msEllipse(0, -88, 8, 8, 24), M.pad, 0, AMP);
  path(port, true); stroke(LINE);
  const glass = shape(msEllipse(0, -88, 5, 5, 20), M.glass, 0, 0.5);
  clipTo(glass, () => {
    blob(msEllipse(3, -85, 5, 5, 16), M.glassDark);
    blob(msEllipse(-2, -90, 1.6, 1.6, 10), M.shine);
  });
  path(glass, true); stroke(DETAIL);

  msFin([[0, -64], [3, -40], [3, -24], [-3, -24], [-3, -40]], M.red, M.redDark);
  const tip = shape(msEllipse(0, -158, 3, 3, 12), M.tip, 0, 0);
  path(tip, true); stroke(DETAIL);
}

function menuEarth() {
  const M = MS;
  seed = 2211;
  const lands = [
    smooth([[-16, -14], [-4, -18], [2, -10], [-4, -2], [-2, 8], [-10, 12], [-18, 2]], true, 3),
    smooth([[6, 2], [16, -4], [20, 6], [12, 16], [4, 12]], true, 3),
    smooth([[2, -20], [10, -19], [8, -15], [0, -16]], true, 2),
  ];
  const paint = (sea, land) => { blob(rect(-30, -30, 30, 30), sea); for (const l of lands) blob(l, land); };
  const disc = shape(msEllipse(0, 0, 22, 22, 40), M.ocean, 0, AMP);
  clipTo(disc, () => {
    paint(M.oceanDark, M.landDark);
    clipTo(msEllipse(-5, -5, 23, 23, 40), () => paint(M.ocean, M.land));
    pen([[-20, -4], [-12, -7], [-6, -5]], 2.4, M.cloud, AMP);
    pen([[2, 4], [10, 2], [16, 5]], 2.4, M.cloud, AMP);
    pen([[-10, 16], [-2, 14]], 2.4, M.cloud, AMP);
  });
  path(disc, true); stroke(LINE);
}

function menuPlanet() {
  const M = MS;
  seed = 2221;
  const tilt = -0.32;
  const ring = msEllipse(0, 0, 19, 5.5, 40, tilt);
  const back = ring.slice(20).concat([ring[0]]);
  const front = ring.slice(0, 21);
  pen(back, LINE + 2.6, INK, 0);
  pen(back, 2.6, M.ring, 0);
  const ball = shape(msEllipse(0, 0, 10, 10, 28), M.planet, 0, AMP);
  clipTo(ball, () => {
    blob(msEllipse(5, 5, 9, 9, 24), M.planetDark);
    pen([[-12, -1], [12, -6]], 2, M.planetDark, AMP);
  });
  path(ball, true); stroke(LINE);
  pen(front, LINE + 2.6, INK, 0);
  pen(front, 2.6, M.ring, 0);
}

registerProp('menu_rocket', {
  w: 88, h: 172, ox: 44, oy: 166, draw: menuRocket,
  pal: () => [INK, MS.body, MS.bodyDark, MS.red, MS.redDark, MS.glass, MS.glassDark, MS.shine, MS.pad, MS.padDark,
    MS.bell, MS.tip, GROUND],
});
registerProp('menu_earth', {
  w: 52, h: 52, ox: 26, oy: 26, draw: menuEarth,
  pal: () => [INK, MS.ocean, MS.oceanDark, MS.land, MS.landDark, MS.cloud],
});
registerProp('menu_planet', {
  w: 48, h: 32, ox: 24, oy: 16, draw: menuPlanet,
  pal: () => [INK, MS.planet, MS.planetDark, MS.ring],
});

// Distant hills behind the title-screen horizon, two layers. Tiles horizontally: every curve repeats over RIDGE.w.
const RIDGE = { w: 240, h: 56, far: '#6f7486', farDark: '#5b6072', near: '#878a92', nearDark: '#74777f' };

function ridgeLine(base, waves) {
  const pts = [];
  for (let x = -12; x <= RIDGE.w + 12; x += 2) {
    let y = base;
    for (const [amp, n, ph] of waves) y += amp * Math.sin(2 * Math.PI * n * x / RIDGE.w + ph);
    pts.push([x, y]);
  }
  return pts;
}

function ridgeLayer(top, fill, dark, craters) {
  const sil = [...top, [RIDGE.w + 12, RIDGE.h + 4], [-12, RIDGE.h + 4]];
  blob(sil, fill);
  clipTo(sil, () => {
    for (const [x, y, a] of craters) {
      for (const dx of [-RIDGE.w, 0, RIDGE.w]) {
        blob(msEllipse(x + dx, y, a, a * 0.38, 20), dark);
        blob(msEllipse(x + dx + a * 0.15, y + a * 0.1, a * 0.8, a * 0.26, 20), fill);
      }
    }
  });
  path(top, false); stroke(LINE);
}

function menuRidge() {
  const R = RIDGE;
  ridgeLayer(ridgeLine(22, [[9, 1, 0.4], [6, 3, 2.1], [2.5, 7, 0.9]]), R.far, R.farDark, [[40, 30, 7], [150, 26, 5], [205, 34, 6]]);
  ridgeLayer(ridgeLine(42, [[4, 2, 1.3], [3, 5, 0.2], [1.5, 9, 2.7]]), R.near, R.nearDark, [[90, 50, 8], [185, 52, 6]]);
}

registerProp('menu_ridge', {
  w: RIDGE.w, h: RIDGE.h, ox: 0, oy: 0, draw: menuRidge,
  pal: () => [INK, RIDGE.far, RIDGE.farDark, RIDGE.near, RIDGE.nearDark],
});
