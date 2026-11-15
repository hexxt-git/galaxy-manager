// Ice drill minigame: the hold target, a chunky drill lever on a console in the USE button's greys. Up (idle), pulled
// down (drilling) and done (green knob). The front plate is left blank for the HOLD / DONE label drawn in game.
const MGD_LEVER = {
  lit: '#d7dee4', mid: '#a5b1c0', dark: '#69778b', plate: '#3a4455', steel: '#a9bcc4', steelDark: '#6b818c',
  knob: ['#e0503c', '#a8322a'], done: ['#7ed05b', '#4f9a45'],
  pivot: [48, 38],
};

function mgdLever(knobAt, colours) {
  return () => {
    const L = MGD_LEVER, [px, py] = L.pivot;
    seed = 931;
    const box = shape(rounded(rect(6, 30, 90, 70), 6), L.lit, 0, AMP);
    clipTo(box, () => {
      blob(rect(2, 44, 94, 74), L.mid);
      pen([[6, 44], [90, 44]], LINE, INK, AMP);
      const plate = shape(rounded(rect(20, 50, 76, 65), 3), L.plate, 0, AMP);
      path(plate, true); stroke(DETAIL);
      for (const x of [12, 84]) {
        const bolt = smooth(rect(x - 2, 55, x + 2, 59), true, 2);
        blob(bolt, L.dark);
        path(bolt, true); stroke(DETAIL * 0.6);
      }
    });
    path(box, true); stroke(LINE);
    const slot = shape(rounded(rect(px - 16, py - 3, px + 16, py + 3), 2.5), L.plate, 0, 0);
    path(slot, true); stroke(DETAIL);

    const [kx, ky] = knobAt;
    pen([[px, py], [kx, ky]], 5 + 2 * DETAIL, INK, 0);
    pen([[px, py], [kx, ky]], 5, L.steel, 0);
    pen([[px + 1.2, py], [kx + 1.2, ky]], 1.6, L.steelDark, 0);
    const hub = shape(smooth(rect(px - 6, py - 5, px + 6, py + 4), true, 3), L.steelDark, 0, 0);
    path(hub, true); stroke(DETAIL);
    const knob = shape(Array.from({ length: 20 }, (_, i) => [kx + 8.5 * Math.cos(i / 20 * 6.283), ky + 8 * Math.sin(i / 20 * 6.283)]), colours[0], 0, 0);
    clipTo(knob, () => {
      blob(Array.from({ length: 20 }, (_, i) => [kx + 3 + 9 * Math.cos(i / 20 * 6.283), ky + 4 + 8 * Math.sin(i / 20 * 6.283)]), colours[1]);
      blob(smooth(rect(kx - 5, ky - 5, kx - 1.5, ky - 2.5), true, 2), L.lit);
    });
    path(knob, true); stroke(LINE);
  };
}

const MGD_LEVERS = { mg_drill_lever: [[66, 10], 'knob'], mg_drill_lever_down: [[32, 27], 'knob'], mg_drill_lever_done: [[66, 10], 'done'] };
for (const [name, [at, c]] of Object.entries(MGD_LEVERS)) {
  const L = MGD_LEVER;
  registerProp(name, {
    w: 96, h: 74, ox: 0, oy: 0, draw: mgdLever(at, L[c]),
    pal: () => [INK, L.lit, L.mid, L.dark, L.plate, L.steel, L.steelDark, L[c][0], L[c][1]],
  });
}
