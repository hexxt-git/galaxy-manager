var WALL = { lit: '#76878f', face: '#47535c', dark: '#313a43', W: 18, D: 15, H: 92, P: 64, base: 13 };

// Outer left end of a wall column type (see wallBand in wall_h.js), outline on x = 0. Corners chamfer
// where the outline turns; a side wall running on above or below keeps that end straight.
function wallEnd(kind) {
  const { H, D } = WALL, yt = -H - D, c = 8, x1 = 14;
  const top = kind & 1 ? [[x1, yt - 4], [0, yt - 4]] : [[x1, yt], [c, yt], [0, yt + c]];
  const bot = kind & 2 ? [[0, 9], [x1, 9]] : [[0, -c], [c, 0], [x1, 0]];
  clipTo([...top, ...bot], () => wallBand(kind, -8, x1 + 8));
  const outline = [...top, ...bot].slice(kind & 1 ? 1 : 0, kind & 2 ? -1 : undefined);
  path(outline, false);
  stroke(LINE);
}

for (const [name, kind] of [['wall_corner', 0], ['wall_corner_a', 1], ['wall_corner_b', 2]]) {
  registerProp(name, {
    w: 12, h: 115, ox: 2, oy: 109, draw: () => { seed = 831; wallEnd(kind); },
    pal: () => [INK, WALL.lit, WALL.face, WALL.dark, GROUND],
  });
}
