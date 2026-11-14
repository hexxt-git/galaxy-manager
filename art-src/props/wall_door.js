var WALL = { lit: '#76878f', face: '#47535c', dark: '#313a43', W: 18, D: 15, H: 92, P: 64, base: 13 };

const DOOR = { x0: 34, x1: 94, top: -80, r: 6, frame: 4, slab: 5 };

function wallDoor() {
  const { H, D, P } = WALL, { x0, x1, top, r, frame, slab } = DOOR;
  const w = 2 * P;
  seed = 841;
  blob(rect(-8, -2, w + 8, 5), GROUND);
  blob(rect(-8, -H - D, w + 8, -H), WALL.lit);
  blob(rect(-8, -H, w + 8, 0), WALL.face);
  blob(rect(-8, -WALL.base, w + 8, 0), WALL.dark);
  blob(rect(-8, -H + 7, w + 8, -H + 9), WALL.lit);
  clipTo(rect(-8, -H, w + 8, 0), () => blob(rounded(rect(x0 - frame, top - frame, x1 + frame, 20), r + frame), WALL.dark));
  for (const y of [-H - D, -H]) pen([[-8, y], [w + 8, y]], LINE, INK, 0);
  for (const x of [P / 4, w - P / 4]) pen([[x, -H + 12], [x, -WALL.base - 4]], DETAIL, INK, AMP);

  const hole = rounded(rect(x0, top, x1, 20), r);
  ctx.globalCompositeOperation = 'destination-out';
  blob(hole, '#000');
  ctx.globalCompositeOperation = 'source-over';

  blob(rect(x0, -2.5, x1, 2.5), GROUND);
  clipTo(hole, () => {
    blob(rect(x0 - 2, top - 2, x0 + slab, 0), WALL.lit);
    blob(rect(x1 - slab, top - 2, x1 + 2, 0), WALL.lit);
    for (const x of [x0 + slab, x1 - slab]) pen([[x, top], [x, 0]], DETAIL, INK, 0);
  });
  clipTo(rect(-8, -H, w + 8, 0), () => { path(hole, true); stroke(LINE); });
  for (const [a, b] of [[-8, x0], [x1, w + 8]]) pen([[a, 0], [b, 0]], LINE, INK, 0);
}

registerProp('wall_door', {
  w: 2 * WALL.P, h: 115, ox: 0, oy: 109, draw: wallDoor,
  pal: () => [INK, WALL.lit, WALL.face, WALL.dark, GROUND],
});
