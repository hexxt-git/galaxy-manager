// Jagged shard of rock leaning right, a cell wide and tall.
function boulderG() {
  borderRock(983, {
    half: 25,
    sil: [[-25, 0], [-27, -30], [-18, -58], [-4, -78], [6, -72], [14, -50], [24, -36], [27, -14], [25, 0]],
    edge: [[-34, -42], [-10, -48], [8, -36], [34, -28]],
    crack: [[-6, -72], [-4, -56]],
    r: 6,
  });
}

registerProp('boulder_g', { w: 64, h: 90, ox: 32, oy: 84, draw: boulderG, pal: rockPal });
