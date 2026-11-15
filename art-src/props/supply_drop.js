// A landed supply pod: a squat steel cargo crate with a slumped orange parachute draped over it, tied down with cords.
const DROP = {
  lit: '#a9bcc4', dark: '#6b818c', chute: '#e07a3a', chuteDark: '#a24f2a', strap: '#555a68',
  half: 20, top: -44, edge: -24,
};

function supplyDrop() {
  const D = DROP, a = D.half;
  seed = 1433;
  blob(rounded(rect(-a - 1, -6, a + 3, 4), 4), GROUND);
  const sil = shape(rounded(rect(-a, D.top, a, 0), 6), D.lit, 0, AMP);
  clipTo(sil, () => {
    blob(rect(-a - 4, D.edge, a + 4, 4), D.dark);
    pen([[-a, D.edge], [a, D.edge]], LINE, INK, AMP);
    for (const x of [-a + 6, a - 6]) pen([[x, D.edge + 5], [x, -4]], DETAIL, INK, AMP);
    pen([[-4, D.edge + 8], [4, D.edge + 8], [0, D.edge + 13], [-4, D.edge + 8]], DETAIL, INK, 0);
  });
  path(sil, true); stroke(LINE);

  const chute = shape(smooth([[-17, -42], [-14, -52], [-4, -57], [8, -55], [17, -48], [19, -40], [18, -30],
    [12, -32], [8, -38], [-2, -37], [-12, -36]], true, 3), D.chute, 0, AMP);
  clipTo(chute, () => {
    blob(smooth([[-20, -44], [-6, -41], [6, -43], [21, -44], [21, -26], [-20, -26]], true, 2), D.chuteDark);
    pen([[-8, -54], [-4, -46], [-6, -39]], DETAIL, INK, AMP);
    pen([[6, -54], [8, -46], [12, -36]], DETAIL, INK, AMP);
  });
  path(chute, true); stroke(LINE);
  for (const [p, q] of [[[-12, -38], [-a + 2, D.edge - 2]], [[16, -32], [a - 2, D.edge + 2]]]) pen([p, q], DETAIL * 0.8, INK, 0.3);
}

registerProp('supply_drop', {
  w: 48, h: 72, ox: 24, oy: 66, draw: supplyDrop,
  pal: () => [INK, DROP.lit, DROP.dark, DROP.chute, DROP.chuteDark, GROUND],
});
