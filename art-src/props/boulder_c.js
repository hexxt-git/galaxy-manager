// Lumpy double-hump rock: a taller left lump leaning on a lower right one, two cells wide.
function boulderC() {
  borderRock(907, {
    half: 45,
    sil: [[-45, 0], [-47, -36], [-40, -66], [-24, -80], [-9, -76], [-1, -58], [8, -64], [26, -64], [40, -50], [46, -26], [45, 0]],
    edge: [[-52, -38], [-30, -46], [-6, -38], [2, -34], [24, -40], [52, -32]],
    crack: [[-1, -58], [-3, -44]],
    r: 9,
  });
}

registerProp('boulder_c', { w: 104, h: 92, ox: 52, oy: 84, draw: boulderC, pal: rockPal });
