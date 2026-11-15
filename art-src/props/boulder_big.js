// Huge low dome of rock, three cells wide.
function boulderBig() {
  borderRock(937, {
    half: 67,
    sil: [[-67, 0], [-70, -22], [-62, -52], [-42, -78], [-12, -90], [18, -90], [46, -78], [64, -54], [70, -22], [67, 0]],
    edge: [[-76, -36], [-40, -46], [0, -50], [40, -46], [76, -34]],
    r: 16,
  });
}

registerProp('boulder_big', { w: 152, h: 102, ox: 76, oy: 94, draw: boulderBig, pal: rockPal });
