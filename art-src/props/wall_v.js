var WALL = { lit: '#76878f', face: '#47535c', dark: '#313a43', W: 18, D: 15, H: 92, P: 64, base: 13 };

// Flat tiles the map repeats to any width: side wall tops, the ink seams between pieces, and the
// wall_h column types (see wallBand in wall_h.js) where a side wall meets a horizontal one.
registerProp('wall_v', {
  w: 4, h: 4, ox: 0, oy: 0, draw: () => blob(rect(0, 0, 4, 4), WALL.lit), pal: () => [WALL.lit],
});
registerProp('wall_ink', {
  w: 4, h: 4, ox: 0, oy: 0, draw: () => blob(rect(0, 0, 4, 4), INK), pal: () => [INK],
});
for (const [name, kind] of [['wall_fill_a', 1], ['wall_fill_b', 2]]) {
  registerProp(name, {
    w: 4, h: 115, ox: 0, oy: 109, draw: () => wallBand(kind, -8, 12),
    pal: () => [INK, WALL.lit, WALL.face, WALL.dark, GROUND],
  });
}
