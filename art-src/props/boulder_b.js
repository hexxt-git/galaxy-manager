// Long low flat-topped slab, two and a half cells wide.
function boulderB() {
  borderRock(883, {
    half: 57,
    sil: [[-57, 0], [-59, -20], [-54, -44], [-34, -52], [10, -54], [44, -50], [58, -34], [57, 0]],
    edge: [[-64, -26], [-24, -31], [24, -29], [64, -24]],
    r: 8,
  });
}

registerProp('boulder_b', { w: 128, h: 66, ox: 64, oy: 58, draw: boulderB, pal: rockPal });
