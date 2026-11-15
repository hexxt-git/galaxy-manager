// A rounded stone with a little one tucked in front of it.
const fShift = (pts, dx) => pts.map(([x, y]) => [x + dx, y]);

function boulderF() {
  borderRock(967, {
    half: 30,
    sil: fShift([[-24, 0], [-26, -22], [-16, -44], [2, -50], [20, -40], [26, -18], [24, 0]], -12),
    edge: fShift([[-34, -22], [-8, -27], [14, -22], [34, -18]], -12),
    crack: fShift([[-2, -50], [0, -38]], -12),
    r: 8,
  });
  borderRock(971, {
    half: 14,
    sil: fShift([[-13, 0], [-14, -12], [-6, -21], [7, -21], [14, -11], [13, 0]], 27),
    edge: fShift([[-20, -9], [0, -12], [20, -8]], 27),
    r: 5,
  });
}

registerProp('boulder_f', { w: 92, h: 62, ox: 46, oy: 56, draw: boulderF, pal: rockPal });
