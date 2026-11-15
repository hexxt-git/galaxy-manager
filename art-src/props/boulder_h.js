// Squat rounded rock with a flat top, a cell and a half wide.
function boulderH() {
  borderRock(997, {
    half: 36,
    sil: [[-36, 0], [-38, -20], [-30, -40], [-10, -46], [16, -45], [32, -36], [38, -18], [36, 0]],
    edge: [[-44, -22], [-14, -28], [16, -25], [44, -20]],
    crack: [[18, -25], [15, -14]],
    r: 9,
  });
}

registerProp('boulder_h', { w: 88, h: 58, ox: 44, oy: 52, draw: boulderH, pal: rockPal });
