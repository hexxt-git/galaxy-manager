// Empty construction pads (pad_large 3x2 cells, pad_small 2x1): flat concrete slab, faint dashed outline, yellow-black corner brackets.
const PAD = { lit: '#b4b2a8', dark: '#8a887f', dash: '#8f8d84', hazard: '#f2c230', lip: 3 };

function padBracket(x, y, sx, sy, L, t) {
  const pts = rounded([[x, y], [x + sx * L, y], [x + sx * L, y + sy * t], [x + sx * t, y + sy * t], [x + sx * t, y + sy * L], [x, y + sy * L]], 1.5);
  const s = shape(pts, PAD.hazard, 0, AMP);
  clipTo(s, () => {
    for (let k = -L; k < 2 * L; k += 10) blob([[x + sx * k, y], [x + sx * (k + 3.5), y], [x + sx * (k + 3.5 - L), y + sy * L], [x + sx * (k - L), y + sy * L]], INK);
  });
  path(s, true); stroke(DETAIL);
}

function padSlab(hw, hd, L) {
  const P = PAD, yt = -hd;
  seed = 1361;
  const sil = shape(rounded(rect(-hw, yt, hw, 0), 4), P.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-hw - 4, -P.lip, hw + 4, 4), P.dark);
    pen([[-hw, -P.lip], [hw, -P.lip]], DETAIL, INK, AMP);
  });
  path(sil, true); stroke(LINE);
  const m = 9, x0 = -hw + m, x1 = hw - m, y0 = yt + m, y1 = -P.lip - m + 2;
  ctx.save();
  ctx.setLineDash([5, 4]);
  path(rect(x0, y0, x1, y1), true); stroke(1.6, P.dash);
  ctx.restore();
  const t = 6;
  padBracket(-hw + 3, yt + 3, 1, 1, L, t);
  padBracket(hw - 3, yt + 3, -1, 1, L, t);
  padBracket(-hw + 3, -P.lip - 1, 1, -1, L, t);
  padBracket(hw - 3, -P.lip - 1, -1, -1, L, t);
}

registerProp('pad_large', {
  w: 144, h: 96, ox: 72, oy: 92, draw: () => padSlab(67, 86, 20),
  pal: () => [INK, PAD.lit, PAD.dark, PAD.dash, PAD.hazard],
});
registerProp('pad_small', {
  w: 96, h: 48, ox: 48, oy: 44, draw: () => padSlab(43, 38, 13),
  pal: () => [INK, PAD.lit, PAD.dark, PAD.dash, PAD.hazard],
});
