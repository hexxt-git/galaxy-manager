// An office chair turned a little to the right: five-star base on casters, gas column, round seat, curved shell back.
const SWIVEL = {
  lit: '#c8453f', dark: '#8a2b33', metal: '#8a909c', metalDark: '#555a68',
  fore: 0.62, turn: 0.45, legs: 5, leg: 17, legW: 2.6, caster: 2.6,
  seatRx: 16, seatRz: 14, seat0: 15, seat1: 21, cut: 4,
  backHalf: 14, backZ: 14, bow: 6, back0: 27, back1: 52, shoulder: 5, shell: 3.5,
};

// Chair-local floor coords (x right, z away from the camera, h up) to screen, before the floor offset.
function swivelP(x, z, h) {
  const S = SWIVEL, c = Math.cos(S.turn), s = Math.sin(S.turn);
  return [x * c - z * s, -S.fore * (x * s + z * c) - h];
}

function swivelSeat(h) {
  const S = SWIVEL, out = [];
  for (let i = 0; i < 40; i++) {
    const t = 2 * Math.PI * i / 40, c = Math.cos(t), s = Math.sin(t);
    out.push(swivelP(S.seatRx * Math.sign(c) * Math.abs(c) ** 0.8, S.seatRz * Math.sign(s) * Math.abs(s) ** 0.8, h));
  }
  return out;
}

// u in -1..1 across the backrest; dz pushes toward the shell's back surface.
function swivelBack(u, dz, top) {
  const S = SWIVEL;
  const h = top ? S.back1 - S.shoulder * u ** 4 : S.back0;
  return swivelP(S.backHalf * u, S.backZ - S.bow * u * u + dz, h);
}

function swivelChair() {
  const S = SWIVEL, N = 16, us = [...Array(N + 1).keys()].map(i => -1 + 2 * i / N);
  seed = 811;
  const legs = [...Array(S.legs).keys()].map(i => {
    const a = S.turn + Math.PI / 2 + 2 * Math.PI * i / S.legs;
    return { tip: [S.leg * Math.cos(a), -S.leg * Math.sin(a)], depth: -Math.sin(a) };
  }).sort((p, q) => q.depth - p.depth);
  const y0 = Math.max(...legs.map(l => swivelP(l.tip[0], l.tip[1], 0)[1]));
  ctx.translate(0, -y0);

  blob(smooth(swivelSeat(-2).map(([x, y]) => [x * 1.25 + 2, y * 1.25 + 5]), true, 2), GROUND);

  const legPts = l => [swivelP(0, 0, 6), swivelP(l.tip[0], l.tip[1], 4)];
  const caster = l => {
    const [x, y] = swivelP(l.tip[0], l.tip[1], S.caster);
    return smooth([[x - S.caster, y], [x, y - S.caster], [x + S.caster, y], [x, y + S.caster]], true, 3);
  };
  const column = rounded(rect(-2.4, swivelP(0, 0, S.seat0 + 2)[1], 2.4, swivelP(0, 0, 6)[1]), 1);
  const post = [swivelP(0, 9, S.seat0 + 1), swivelP(0, S.backZ + 2, S.seat0 + 3), swivelP(0, S.backZ + 2, S.back0 + 6)];
  const front = [...us.map(u => swivelBack(u, 0, false)), ...us.slice().reverse().map(u => swivelBack(u, 0, true))];
  const backFace = [...us.map(u => swivelBack(u, S.shell, false)), ...us.slice().reverse().map(u => swivelBack(u, S.shell, true))];
  const rim = [...us.map(u => swivelBack(u, 0, true)), ...us.slice().reverse().map(u => swivelBack(u, S.shell, true))];
  const layers = [];
  for (let h = S.seat0; h <= S.seat1; h += 1) layers.push(swivelSeat(h));
  const top = layers[layers.length - 1];

  // halo: the union of every part, LINE wide outside; inner overlaps get DETAIL from each part below
  const halo = 2 * LINE - DETAIL;
  for (const l of legs) { pen(legPts(l), S.legW + halo, INK, 0); path(caster(l), true); stroke(halo); }
  for (const p of [column, front, backFace, rim, ...layers]) { path(p, true); stroke(halo); }
  pen(post, 3 + halo, INK, 0);

  const drawLeg = l => {
    pen(legPts(l), S.legW + 2 * DETAIL, INK, 0);
    pen(legPts(l), S.legW, S.metal, 0);
    const c = caster(l);
    blob(c, S.metalDark); path(c, true); stroke(DETAIL);
  };
  const back = legs.filter(l => l.depth > 0.1), near = legs.filter(l => l.depth <= 0.1);
  back.forEach(drawLeg);
  blob(column, S.metal); clipTo(column, () => blob(rect(0.6, -80, 4, 4), S.metalDark)); path(column, true); stroke(DETAIL);
  near.forEach(drawLeg);

  pen(post, 3 + 2 * DETAIL, INK, 0);
  pen(post, 3, S.metalDark, 0);

  blob(backFace, S.dark); path(backFace, true); stroke(DETAIL);
  blob(rim, S.lit); path(rim, true); stroke(DETAIL);
  const fw = wobble(front, AMP, 4, true);
  blob(fw, S.dark);
  clipTo(fw, () => {
    const a = swivelBack(0.25, 0, true), b = swivelBack(0.45, 0, false);
    blob(smooth([[a[0], a[1] - 4], [a[0] - 1, (a[1] + b[1]) / 2], [b[0], b[1] + 4], [b[0] + 30, b[1] + 4], [a[0] + 30, a[1] - 4]], true, 2), S.lit);
  });
  path(fw, true); stroke(DETAIL);

  for (const p of layers) { path(p, true); stroke(DETAIL); }
  for (const p of layers) blob(p, S.lit);
  clipTo(rect(S.cut, -120, 40, 10), () => { for (const p of layers) blob(p, S.dark); });
  const tw = wobble(top, AMP, 4, true);
  blob(tw, S.lit);
  path(tw, true); stroke(DETAIL);
  path(wobble(smooth(swivelSeat(S.seat1).map(([x, y]) => [x * 0.7, (y + S.seat1) * 0.7 - S.seat1 - 1]), true, 1), AMP, 4, true), true);
  stroke(DETAIL * 0.8);
}

registerProp('swivel_chair', {
  w: 43, h: 77, ox: 21, oy: 66, scale: [0.82, 0.82], draw: swivelChair,
  pal: () => [INK, SWIVEL.lit, SWIVEL.dark, SWIVEL.metal, SWIVEL.metalDark, GROUND],
});
