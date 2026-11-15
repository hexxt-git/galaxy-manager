// Wedge of rock leaning left: a high overhanging nose sloping down to the right, two cells wide.
function boulderD() {
  borderRock(919, {
    half: 42,
    sil: [[-38, 0], [-42, -26], [-48, -70], [-42, -88], [-28, -90], [2, -68], [30, -42], [44, -18], [42, 0]],
    edge: [[-56, -54], [-32, -60], [0, -40], [26, -20], [46, -4]],
    r: 9,
  });
}

registerProp('boulder_d', { w: 104, h: 102, ox: 54, oy: 94, draw: boulderD, pal: rockPal });
