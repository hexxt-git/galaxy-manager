// Electrolyzer minigame backdrop (scripts/colony/minigames/electrolyzer.gd): a cut-away water tank on the life
// support wall. A power box feeds two electrodes through the tank floor; over each one an inverted glass tube collects
// the gas (H2 over the − electrode, O2 over the +), and the O2 is piped to the AIR gauge. Gas, bubbles, current and
// the gauge fill are drawn in game. Authored top-left; the skin mirrors MGE's tube, wire and slot geometry.
const MGE = {
  wall: '#262b38', panel: '#2f3646', seam: '#1c202b', brass: '#c99a4a', brassDark: '#8f6834',
  steel: '#a9bcc4', steelDark: '#6b818c', glass: '#c4d8d4', back: '#1f2a36',
  water: '#3f8fb8', waterDark: '#2d6d93', waterLit: '#8fd0e6', hole: '#1b1e2b',
  plus: '#e0503c', plusDark: '#a8322a', minus: '#4a5568', bolt: '#f2c84b',
  w: 252, h: 222,
  tubes: [86, 166], tubeHalf: 12, tubeTop: 44, tubeBottom: 170, inner: 8,
  tank: [44, 96, 208, 202], waterTop: 108,
  box: [100, 6, 152, 34], wireY: 20, wireX: [36, 216], wireBottom: 212, rodTop: 160,
  gauge: [222, 52, 246, 210], slot: [231, 62, 237, 200],
};

function mgeBar(pts, w, fill) {
  pen(pts, w + 2 * DETAIL, INK, 0);
  pen(pts, w, fill, 0);
}

function mgeScene() {
  const M = MGE, W = M.w, H = M.h, [tx0, ty0, tx1, ty1] = M.tank;
  seed = 1307;
  const frame = rounded(rect(2, 2, W - 2, H - 2), 8);
  clipTo(frame, () => {
    blob(rect(0, 0, W, H), M.wall);
    for (const [x0, x1] of [[0, 84], [84, 168], [168, W]]) {
      blob(rect(x0 + 3, 4, x1 - 3, H - 4), M.panel);
      pen([[x0, 0], [x0, H]], DETAIL, M.seam, 0);
    }
    for (const x of [8, 76, 92, 160, 176, 244]) for (const y of [10, H - 10]) {
      blob(smooth(rect(x - 1.6, y - 1.6, x + 1.6, y + 1.6), true, 2), M.seam);
    }

    // wires: − (dark) on the left, + (red) on the right, out of the power box, down the wall, under the tank, up into the rods
    for (const [i, col] of [[0, M.minus], [1, M.plus]]) {
      const ex = M.tubes[i], wx = M.wireX[i], bx = i ? M.box[2] : M.box[0];
      mgeBar([[bx, M.wireY], [wx, M.wireY], [wx, M.wireBottom], [ex, M.wireBottom], [ex, ty1 - 2]], 3, col);
    }

    // tank: dark back, water, then the glass rim
    const tank = rounded(rect(tx0, ty0, tx1, ty1), 6);
    blob(tank, M.back);
    clipTo(tank, () => {
      const top = wobble([[tx0 - 2, M.waterTop], [tx1 + 2, M.waterTop]], AMP, 6);
      blob([...top, [tx1 + 2, ty1 + 2], [tx0 - 2, ty1 + 2]], M.water);
      blob(rect(tx1 - 26, M.waterTop, tx1 + 2, ty1 + 2), M.waterDark);
      pen(top, DETAIL, M.waterLit, 0);
      blob(rect(tx0 + 4, ty0 + 4, tx0 + 8, ty1 - 8), M.glass);
    });
    path(tank, true); stroke(LINE);

    // electrode rods up through the tank floor
    for (const [i, x] of M.tubes.entries()) {
      const rod = rounded(rect(x - 3, M.rodTop, x + 3, ty1 + 1), 1.5);
      shape(rod, M.steelDark, 0, 0);
      clipTo(rod, () => blob(rect(x - 3, M.rodTop, x - 1, ty1), M.steel));
      path(rod, true); stroke(DETAIL);
    }

    // inverted collection tubes, full of water to start with
    for (const x of M.tubes) {
      const h = M.tubeHalf, n = M.inner;
      const tube = rounded(rect(x - h, M.tubeTop, x + h, M.tubeBottom), 6);
      shape(tube, M.glass, 0, AMP);
      clipTo(tube, () => blob(rect(x + h - 4, M.tubeTop, x + h + 2, M.tubeBottom + 2), M.steel));
      const hole = rounded(rect(x - n, M.tubeTop + 6, x + n, M.tubeBottom + 2), 3);
      blob(hole, M.water);
      clipTo(hole, () => blob(rect(x + n - 4, M.tubeTop, x + n + 1, M.tubeBottom + 2), M.waterDark));
      path(hole, true); stroke(DETAIL * 0.8);
      path(tube, true); stroke(LINE);
      for (let y = M.tubeTop + 20; y < M.tubeBottom - 10; y += 10) pen([[x + h - 3, y], [x + h, y]], DETAIL * 0.7, INK, 0);
      const valve = shape(rounded(rect(x - 5, M.tubeTop - 9, x + 5, M.tubeTop + 1), 2), M.brass, 0, 0);
      clipTo(valve, () => blob(rect(x + 1, M.tubeTop - 10, x + 6, M.tubeTop + 2), M.brassDark));
      path(valve, true); stroke(DETAIL);
    }

    // H2 vents off to the left; O2 runs over to the gauge tank
    const [hx, ox] = M.tubes, py = M.tubeTop - 13;
    mgeBar([[hx, M.tubeTop - 9], [hx, py], [hx - 30, py], [hx - 30, py - 8]], 3, M.brass);
    const cap = shape(rounded(rect(hx - 35, py - 14, hx - 25, py - 8), 2), M.steelDark, 0, 0);
    path(cap, true); stroke(DETAIL);
    mgeBar([[ox, M.tubeTop - 9], [ox, py], [234, py], [234, M.gauge[1]]], 3, M.brass);

    // power box: − on the left half, + on the right, a lamp in the middle
    const [bx0, by0, bx1, by1] = M.box;
    const box = shape(rounded(rect(bx0, by0, bx1, by1), 4), M.steel, 0, AMP);
    clipTo(box, () => {
      blob(rect(bx0 - 2, by1 - 8, bx1 + 2, by1 + 2), M.steelDark);
      pen([[bx0, by1 - 8], [bx1, by1 - 8]], DETAIL, INK, 0);
    });
    path(box, true); stroke(LINE);
    pen([[bx0 + 6, 15], [bx0 + 13, 15]], 2.2, INK, 0);
    pen([[bx1 - 13, 15], [bx1 - 6, 15]], 2.2, INK, 0);
    pen([[bx1 - 9.5, 11.5], [bx1 - 9.5, 18.5]], 2.2, INK, 0);
    const lamp = smooth(rect(120, 9, 132, 21), true, 3);
    blob(lamp, M.hole);
    path(lamp, true); stroke(DETAIL);

    // AIR gauge on the right, like the drill's
    const [gx0, gy0, gx1, gy1] = M.gauge;
    const plate = shape(rounded(rect(gx0, gy0, gx1, gy1), 4), M.steel, 0, AMP);
    clipTo(plate, () => blob(rect(gx0 + (gx1 - gx0) * 0.62, gy0 - 2, gx1 + 2, gy1 + 2), M.steelDark));
    path(plate, true); stroke(LINE);
    const [sx0, sy0, sx1, sy1] = M.slot;
    blob(rect(sx0, sy0, sx1, sy1), M.hole);
    path(rect(sx0 - 0.5, sy0 - 0.5, sx1 + 0.5, sy1 + 0.5), true); stroke(DETAIL * 0.8);
  });
  path(frame, true); stroke(LINE);
}

function mgeDot(r, fill, lit, w, ring) {
  return () => {
    const c = w / 2;
    const dot = smooth(rect(c - r, c - r, c + r, c + r), true, 3);
    shape(dot, fill, 0, 0);
    if (lit) clipTo(dot, () => blob(rect(c - r, c - r, c - r * 0.2, c - r * 0.2), lit));
    path(dot, true); stroke(ring);
  };
}

registerProp('mg_electrolyzer_tank', {
  w: MGE.w, h: MGE.h, ox: 0, oy: 0, draw: mgeScene,
  pal: () => [INK, MGE.wall, MGE.panel, MGE.seam, MGE.brass, MGE.brassDark, MGE.steel, MGE.steelDark, MGE.glass, MGE.back,
    MGE.water, MGE.waterDark, MGE.waterLit, MGE.hole, MGE.plus, MGE.minus],
});
registerProp('mg_electrolyzer_bubble', {
  w: 7, h: 7, ox: 0, oy: 0, draw: mgeDot(2.4, '#d8f1f6', '#ffffff', 7, 1.4),
  pal: () => [INK, '#d8f1f6', '#ffffff'],
});
registerProp('mg_electrolyzer_spark', {
  w: 7, h: 7, ox: 0, oy: 0, draw: mgeDot(2.2, MGE.bolt, '#fff3b8', 7, 1.4),
  pal: () => [INK, MGE.bolt, '#fff3b8'],
});
