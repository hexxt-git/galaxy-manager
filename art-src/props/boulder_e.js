// Small round stone, about a third of a cell.
function boulderE() {
  borderRock(953, {
    half: 18,
    sil: [[-18, 0], [-20, -16], [-12, -30], [4, -33], [16, -26], [20, -12], [18, 0]],
    edge: [[-26, -14], [-6, -18], [12, -15], [26, -12]],
    r: 6,
  });
}

registerProp('boulder_e', { w: 46, h: 44, ox: 23, oy: 38, draw: boulderE, pal: rockPal });
