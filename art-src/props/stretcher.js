// A wheeled stretcher: sheet-covered mattress on a metal frame, a curved head rail, a puffy pillow and a folded blanket.
const STRETCHER = {
  sheet: '#dfe7e4', sheetDark: '#a3b4b6', metal: '#8a909c', metalDark: '#555a68',
  blanket: '#6390bd', blanketDark: '#3c6390',
  half: 37, depth: 22, mattress: 7, frame: 3, legs: 12, r: 5, wheel: 3,
  blanketX: 6,
};

function stretcherEdges(pts, r) {
  return pts.flatMap((a, i) => {
    const b = pts[(i + 1) % pts.length];
    const len = Math.hypot(b[0] - a[0], b[1] - a[1]), e = 2.5 * r / len;
    return [0, e, 0.5, 1 - e].map(t => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
  });
}

function stretcher() {
  const S = STRETCHER, a = S.half, yu = -S.legs, yfr = yu - S.frame, yf = yfr - S.mattress, yt = yf - S.depth;
  seed = 837;
  blob(rounded(rect(-a + 1, -S.depth + 2, a + 3, 4.5), 4), GROUND);

  // legs, a lower crossbar and casters
  for (const x of [-a + 6, a - 6]) {
    pen([[x, yu], [x, -S.wheel - 1]], LINE + 2.4, INK, 0);
    pen([[x, yu], [x, -S.wheel - 1]], 2.4, S.metal, 0);
  }
  pen([[-a + 6, -9], [a - 6, -9]], LINE + 2, INK, 0);
  pen([[-a + 6, -9], [a - 6, -9]], 2, S.metalDark, 0);
  for (const x of [-a + 6, a - 6]) {
    const wh = shape(smooth([[x - S.wheel, -S.wheel], [x, -2 * S.wheel], [x + S.wheel, -S.wheel], [x, 0]], true, 3), S.metalDark, 0, AMP);
    path(wh, true); stroke(DETAIL);
  }

  // head rail hoops behind the pillow
  const rx = -a + 3, hoop = smooth([[rx, yf + 1], [rx - 3, yf - 16], [rx + 1, yt - 12], [rx + 3, yt + 3]], false, 3);
  pen(hoop, LINE + 2.2, INK, AMP);
  pen(hoop, 2.2, S.metal, 0);

  const sil = shape(rounded(stretcherEdges(rect(-a, yt, a, yu), S.r), S.r), S.sheet, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, yf, a + 4, yu + 4), S.sheetDark);
    blob(rect(-a - 4, yfr, a + 4, yu + 4), S.metalDark);
    pen([[-a, yfr], [a, yfr]], DETAIL, INK, AMP);

    // folded blanket: lit top, a turned-down cuff, a draped front with a wavy hem
    const bx = S.blanketX;
    blob(rect(bx, yt - 4, a + 4, yf), S.blanket);
    const hem = smooth([[bx, yf], [bx + 1, yf + 6], [bx + 9, yf + 7.5], [bx + 18, yf + 6.5], [a - 3, yf + 8], [a + 4, yf + 7], [a + 4, yf]], true, 2);
    blob(hem, S.blanketDark);
    pen(hem.slice(1, -2), DETAIL, INK, AMP);
    blob(rect(bx, yt - 4, bx + 7, yf), S.blanketDark);
    pen([[bx, yt], [bx + 1, yf]], DETAIL, INK, AMP);
    pen([[bx + 7, yt + 1], [bx + 7.5, yf]], DETAIL, INK, AMP);
    pen([[-a, yf], [a, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);

  // pillow: a puffy cushion with a rounded near face
  const px0 = -a + 4, px1 = -a + 20, py0 = yt + 3, py1 = yf - 1, ph = 4;
  const pil = shape(smooth([[px0 + 2, py0 - ph], [px1 - 2, py0 - ph - 1], [px1 + 1, (py0 + py1) / 2 - ph], [px1 - 1, py1],
    [(px0 + px1) / 2, py1 + 1.5], [px0 + 1, py1], [px0 - 1, (py0 + py1) / 2 - ph]], true, 3), S.sheet, 0, AMP);
  clipTo(pil, () => {
    blob(smooth([[px0 - 4, py1 - 3.5], [(px0 + px1) / 2, py1 - 5], [px1 + 4, py1 - 4], [px1 + 4, py1 + 6], [px0 - 4, py1 + 6]], true, 2), S.sheetDark);
  });
  path(pil, true); stroke(LINE);
}

registerProp('stretcher', {
  w: 87, h: 68, ox: 43, oy: 59, draw: stretcher,
  pal: () => [INK, STRETCHER.sheet, STRETCHER.sheetDark, STRETCHER.metal, STRETCHER.metalDark, STRETCHER.blanket, STRETCHER.blanketDark, GROUND],
});
