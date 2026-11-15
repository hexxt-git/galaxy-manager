// Electrolyzer minigame hold target: a chunky knife switch on a console in the USE button's greys. Open (blade raised),
// closed (blade down in the clip, current on) and done (green grip). The front plate is left blank for HOLD / DONE.
const MGE_SW = {
  lit: '#d7dee4', mid: '#a5b1c0', dark: '#69778b', plate: '#3a4455', copper: '#e09a5a', copperDark: '#a3623a',
  grip: ['#f2c84b', '#b8862a'], done: ['#7ed05b', '#4f9a45'],
  hinge: [24, 40], clip: [74, 40],
};

function mgeSwitch(tip, colours) {
  return () => {
    const S = MGE_SW, [hx, hy] = S.hinge, [cx, cy] = S.clip;
    seed = 977;
    const box = shape(rounded(rect(6, 30, 90, 70), 6), S.lit, 0, AMP);
    clipTo(box, () => {
      blob(rect(2, 46, 94, 74), S.mid);
      pen([[6, 46], [90, 46]], LINE, INK, AMP);
      const plate = shape(rounded(rect(20, 50, 76, 65), 3), S.plate, 0, AMP);
      path(plate, true); stroke(DETAIL);
      for (const x of [12, 84]) {
        const bolt = smooth(rect(x - 2, 55, x + 2, 59), true, 2);
        blob(bolt, S.dark);
        path(bolt, true); stroke(DETAIL * 0.6);
      }
    });
    path(box, true); stroke(LINE);

    // the clip the blade drops into, two copper jaws
    for (const dx of [-3, 3]) {
      const jaw = shape(rounded(rect(cx + dx - 2, cy - 7, cx + dx + 2, cy + 2), 1), S.copper, 0, 0);
      path(jaw, true); stroke(DETAIL);
    }
    const base = shape(rounded(rect(cx - 7, cy, cx + 7, cy + 4), 1.5), S.dark, 0, 0);
    path(base, true); stroke(DETAIL);

    const [kx, ky] = tip;
    pen([[hx, hy - 3], [kx, ky]], 5 + 2 * DETAIL, INK, 0);
    pen([[hx, hy - 3], [kx, ky]], 5, S.copper, 0);
    pen([[hx, hy - 1.8], [kx, ky + 1.2]], 1.6, S.copperDark, 0);
    const hub = shape(smooth(rect(hx - 6, hy - 8, hx + 6, hy + 3), true, 3), S.dark, 0, 0);
    path(hub, true); stroke(DETAIL);

    // insulated grip on the end of the blade, sticking up
    const grip = shape(rounded(rect(kx - 5, ky - 15, kx + 5, ky + 2), 4), colours[0], 0, 0);
    clipTo(grip, () => {
      blob(rect(kx + 1, ky - 16, kx + 6, ky + 3), colours[1]);
      blob(smooth(rect(kx - 4, ky - 13, kx - 1.5, ky - 8), true, 2), '#ffffff');
    });
    path(grip, true); stroke(LINE);
  };
}

const MGE_SWITCHES = { mg_electrolyzer_switch: [[52, 18], 'grip'], mg_electrolyzer_switch_on: [[74, 37], 'grip'],
  mg_electrolyzer_switch_done: [[74, 37], 'done'] };
for (const [name, [at, c]] of Object.entries(MGE_SWITCHES)) {
  const S = MGE_SW;
  registerProp(name, {
    w: 96, h: 74, ox: 0, oy: 0, draw: mgeSwitch(at, S[c]),
    pal: () => [INK, S.lit, S.mid, S.dark, S.plate, S.copper, S.copperDark, S[c][0], S[c][1], '#ffffff'],
  });
}
