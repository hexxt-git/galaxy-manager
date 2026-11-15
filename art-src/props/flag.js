// A planted lunar flag: gunmetal pole with a top crossbar holding a plain teal banner with a pale moon emblem.
const FLAG = {
  pole: '#8a909c', poleDark: '#555a68', lit: '#4fb3a6', dark: '#2f7d78', moon: '#dfe7e4', moonDark: '#a9bcc4',
  x: -13, top: -82, fx1: 20, fy1: -54,
};

function flag() {
  const F = FLAG;
  seed = 1427;
  blob(rounded(rect(F.x - 9, -4, F.x + 12, 3), 3), GROUND);
  const mound = shape(smooth([[F.x - 8, -1], [F.x - 3, -5], [F.x + 4, -5], [F.x + 9, -1], [F.x, 1]], true, 3), F.moonDark, 0, AMP);
  path(mound, true); stroke(DETAIL);
  pen([[F.x, -2], [F.x, F.top - 2]], LINE + 3, INK, 0);
  pen([[F.x, -2], [F.x, F.top - 2]], 3, F.pole, 0);

  const cloth = shape(smooth([[F.x + 1, F.top], [F.fx1 + 1, F.top], [F.fx1 + 2, F.fy1 - 1], [F.fx1 - 4, F.fy1 + 3],
    [F.x + 14, F.fy1 - 1], [F.x + 1, F.fy1 + 1]], true, 2), F.lit, 0, AMP);
  clipTo(cloth, () => {
    blob(smooth([[F.x + 13, F.top - 2], [F.x + 20, F.top - 2], [F.x + 17, F.fy1 + 4], [F.x + 9, F.fy1 + 4]], true, 2), F.dark);
    const disc = (cx, cy, r) => { const m = []; for (let i = 0; i < 20; i++) { const t = 2 * Math.PI * i / 20; m.push([cx + r * Math.cos(t), cy + r * Math.sin(t)]); } return m; };
    const mx = F.x + 14, my = F.top + 13;
    blob(disc(mx, my, 7.5), INK);
    blob(disc(mx, my, 6), F.moon);
    blob(disc(mx + 4.5, my - 2.5, 6.5), F.lit);
  });
  path(cloth, true); stroke(LINE);
  pen([[F.x, F.top], [F.fx1 + 2, F.top]], LINE + 2, INK, 0);
  pen([[F.x, F.top], [F.fx1 + 2, F.top]], 2, F.pole, 0);
  const cap = shape(rounded(rect(F.x - 3, F.top - 6, F.x + 3, F.top - 1), 2), F.poleDark, 0, 0);
  path(cap, true); stroke(DETAIL);
}

registerProp('flag', {
  w: 48, h: 96, ox: 24, oy: 90, draw: flag,
  pal: () => [INK, FLAG.pole, FLAG.poleDark, FLAG.lit, FLAG.dark, FLAG.moon, FLAG.moonDark, GROUND],
});
