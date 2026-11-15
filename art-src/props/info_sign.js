// A small info post: gunmetal stand on a round foot holding a yellow board with a big ink "i".
const INFO = { metal: '#8a909c', metalDark: '#555a68', lit: '#f2c230', dark: '#b88a1e' };

function infoSign() {
  const S = INFO;
  seed = 1331;
  blob(rounded(rect(-8, -4, 11, 3), 3), GROUND);
  const foot = shape(smooth([[-8, -2], [0, -5.5], [8, -2], [0, 1.5]], true, 3), S.metalDark, 0, AMP);
  path(foot, true); stroke(DETAIL);
  pen([[0, -2], [0, -30]], LINE + 3.5, INK, 0);
  pen([[0, -2], [0, -30]], 3.5, S.metal, 0);
  const sil = shape(rounded(rect(-12, -52, 12, -27), 5), S.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-14, -31, 14, -20), S.dark);
    pen([[-12, -31], [12, -31]], DETAIL, INK, AMP);
    blob(smooth([[0, -48.5], [2.3, -46], [0, -43.5], [-2.3, -46]], true, 3), INK);
    pen([[0, -40.5], [0, -34.5]], 4, INK, 0);
    pen([[-2.5, -40.5], [0, -40.5]], 2.4, INK, 0);
  });
  path(sil, true); stroke(LINE);
}

registerProp('info_sign', { w: 48, h: 60, ox: 24, oy: 55, draw: infoSign, pal: () => [INK, INFO.metal, INFO.metalDark, INFO.lit, INFO.dark, GROUND] });
