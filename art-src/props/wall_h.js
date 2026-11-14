var WALL = { lit: '#76878f', face: '#47535c', dark: '#313a43', W: 18, D: 15, H: 92, P: 64, base: 13 };

// One wall column type from x0 to x1. Bit 1: a side wall comes in from above, so the top edge stays open;
// bit 2: a side wall continues below, so the column is lit wall top down to the floor line and past it.
// Edge-crossing lines are unwobbled so pieces butt together pixel-exactly.
function wallBand(kind, x0, x1) {
  const { H, D } = WALL, yt = -H - D;
  const top = kind & 1 ? yt - 3 : yt;
  if (kind & 2) {
    blob(rect(x0, top, x1, 7), WALL.lit);
  } else {
    blob(rect(x0, -2, x1, 5), GROUND);
    blob(rect(x0, top, x1, -H), WALL.lit);
    blob(rect(x0, -H, x1, 0), WALL.face);
    blob(rect(x0, -WALL.base, x1, 0), WALL.dark);
    blob(rect(x0, -H + 7, x1, -H + 9), WALL.lit);
    for (const y of [-H, 0]) pen([[x0, y], [x1, y]], LINE, INK, 0);
  }
  if (!(kind & 1)) pen([[x0, yt], [x1, yt]], LINE, INK, 0);
}

function wallH() {
  seed = 811;
  wallBand(0, -8, WALL.P + 8);
  pen([[WALL.P / 2, -WALL.H + 12], [WALL.P / 2, -WALL.base - 4]], DETAIL, INK, AMP);
}

registerProp('wall_h', {
  w: WALL.P, h: 115, ox: 0, oy: 109, draw: wallH,
  pal: () => [INK, WALL.lit, WALL.face, WALL.dark, GROUND],
});
