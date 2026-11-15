// Ice drill minigame: the auger bit at the bottom of the shaft, cold, warming and glowing hot. 16 wide like the shaft,
// tip at the bottom centre (8, 25).
const MGD_BIT = {
  cold: ['#8a909c', '#555a68'], warm: ['#e0904f', '#a8553a'], hot: ['#ffd27a', '#ec5638'],
};

function mgdBit(lit, dark) {
  return () => {
    seed = 911;
    const body = shape([[1.5, 5], [14.5, 5], [12, 17], [8, 24.5], [4, 17]], lit, 0, 0);
    clipTo(body, () => {
      blob([[9, 3], [16, 3], [16, 26], [8, 26]], dark);
      for (let y = 6; y < 22; y += 5) pen([[0, y], [16, y + 4]], DETAIL, INK, 0);
    });
    path(body, true); stroke(DETAIL);
    const collar = shape(rounded(rect(3, 0.5, 13, 6), 1.5), lit, 0, 0);
    clipTo(collar, () => blob(rect(9, 0, 14, 7), dark));
    path(collar, true); stroke(DETAIL);
  };
}

for (const [k, c] of Object.entries(MGD_BIT)) {
  registerProp(k === 'cold' ? 'mg_drill_bit' : 'mg_drill_bit_' + k, {
    w: 16, h: 27, ox: 0, oy: 0, draw: mgdBit(c[0], c[1]), pal: () => [INK, c[0], c[1]],
  });
}
