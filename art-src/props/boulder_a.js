// Tall rounded tower of rock, a cell and a half wide.
function boulderA() {
  borderRock(871, {
    half: 34,
    sil: [[-34, 0], [-36, -34], [-31, -72], [-20, -96], [-2, -104], [17, -99], [29, -80], [35, -42], [34, 0]],
    edge: [[-42, -60], [-16, -68], [10, -64], [42, -70]],
    crack: [[6, -64], [3, -48], [7, -36]],
    r: 10,
  });
}

registerProp('boulder_a', { w: 82, h: 116, ox: 41, oy: 108, draw: boulderA, pal: rockPal });
