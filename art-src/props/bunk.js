// A cozy crew bed: rounded station-blue frame, thick mattress, fat pillow and headboard on the left, folded blanket with a turned-down sheet.
const BUNK = {
  lit: '#4a92c9', dark: '#2b5c91', sheet: '#eef2ee', sheetDark: '#a3b4b6', blanket: '#d8794f', blanketDark: '#9e4a33',
  a: 44, frame: 12, depth: 34, mat: 10, matIn: 3, head: 16, headRise: 10, pillow: 20, blanketX: -10, cuff: 7,
};

function bunkBox(x0, x1, yb, front, depth, lit, dark, r) {
  const yf = yb - front, yt = yf - depth;
  const sil = shape(rounded(rect(x0, yt, x1, yb), r), lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(x0 - 4, yf, x1 + 4, yb + 4), dark);
    pen([[x0, yf], [x1, yf]], LINE, INK, AMP);
  });
  path(sil, true); stroke(LINE);
  return { yf, yt };
}

function bunk() {
  const B = BUNK, a = B.a;
  seed = 1341;
  blob(rounded(rect(-a - 1, -6, a + 3, 4.5), 4), GROUND);
  const fr = bunkBox(-a, a, 0, B.frame, B.depth, B.lit, B.dark, 6);

  // mattress: a thick pale slab sitting on the frame
  const x0 = -a + B.head - 2, x1 = a - B.matIn, yb = fr.yf + 1, yf = yb - B.mat, yt = fr.yt - B.mat + 3;
  const m = shape(rounded(rect(x0, yt, x1, yb), 5), B.sheet, 0, AMP);
  clipTo(m, () => {
    blob(rect(x0 - 4, yf, x1 + 4, yb + 4), B.sheetDark);

    // blanket: lit top, draped front with a wavy hem, sheet cuff turned down over its head end
    const bx = B.blanketX;
    blob(rect(bx, yt - 4, x1 + 4, yf), B.blanket);
    const hem = smooth([[bx, yf], [bx + 1, yb - 1], [bx + 12, yb], [bx + 24, yb - 1.5], [bx + 38, yb], [x1 + 4, yb - 1], [x1 + 4, yf]], true, 2);
    blob(hem, B.blanketDark);
    pen(hem.slice(1, -2), DETAIL, INK, AMP);
    blob(rect(bx, yt - 4, bx + B.cuff, yf), B.sheet);
    blob(rect(bx, yf, bx + B.cuff, yb - 1), B.sheetDark);
    pen([[bx, yt], [bx + 0.5, yb - 1]], DETAIL, INK, AMP);
    pen([[bx + B.cuff, yt + 1], [bx + B.cuff + 0.5, yb - 1]], DETAIL, INK, AMP);
    pen([[x0, yf], [x1, yf]], LINE, INK, AMP);
  });
  path(m, true); stroke(LINE);

  // fat pillow with a rounded near face
  const px0 = x0 + 4, px1 = px0 + B.pillow, py0 = yt + 4, py1 = yf - 1, ph = 4;
  const pil = shape(smooth([[px0 + 2, py0 - ph], [px1 - 2, py0 - ph - 1], [px1 + 1, (py0 + py1) / 2 - ph], [px1 - 1, py1],
    [(px0 + px1) / 2, py1 + 1.5], [px0 + 1, py1], [px0 - 1, (py0 + py1) / 2 - ph]], true, 3), B.sheet, 0, AMP);
  clipTo(pil, () => {
    blob(smooth([[px0 - 4, py1 - 4], [(px0 + px1) / 2, py1 - 5.5], [px1 + 4, py1 - 4.5], [px1 + 4, py1 + 6], [px0 - 4, py1 + 6]], true, 2), B.sheetDark);
  });
  path(pil, true); stroke(LINE);

  const hb = bunkBox(-a, -a + B.head, 0, B.frame + B.mat + B.headRise, B.depth, B.lit, B.dark, 5);
  pen([[-a + B.head / 2, hb.yt + 6], [-a + B.head / 2, hb.yf - 6]], DETAIL, INK, AMP);
}

registerProp('bunk', {
  w: 96, h: 80, ox: 48, oy: 72, draw: bunk,
  pal: () => [INK, BUNK.lit, BUNK.dark, BUNK.sheet, BUNK.sheetDark, BUNK.blanket, BUNK.blanketDark, GROUND],
});
