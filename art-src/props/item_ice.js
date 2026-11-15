// A carried cluster of water-ice crystals: three angular shards, lit left facets, shaded right facets, white glints.
const ICE = { lit: '#bfeeff', dark: '#6fc4e8', glint: '#ffffff' };

function iceShard(outline, split, glint) {
  const I = ICE;
  const sil = shape(rounded(outline, 0.5), I.lit, 0, AMP);
  clipTo(sil, () => {
    blob([...split, [14, 4], [14, -24]], I.dark);
    blob(rounded(glint, 0.4), I.glint);
  });
  path(sil, true); stroke(LINE);
}

function itemIce() {
  seed = 1301;
  blob(rounded(rect(-12, -2, 13, 2.5), 2), GROUND);
  iceShard([[-10, 0.5], [-13, -8], [-12, -15], [-4, -9], [-2, 0.5]],
    [[-12, -15], [-6, 2]], [[-11.5, -12], [-9.5, -11], [-10.5, -6.5], [-11.8, -7.5]]);
  iceShard([[2, 0.5], [5, -9], [12.5, -12.5], [12.5, -3], [10, 0.5]],
    [[12.5, -12.5], [7.5, 2]], [[5.5, -7.5], [9, -10], [7.5, -7], [6, -5]]);
  iceShard([[-5, 0.5], [-6.5, -11], [0, -21], [6.5, -11], [5, 0.5]],
    [[0, -21], [1, 2]], [[-4.5, -11.5], [-1.5, -17], [-1.8, -12], [-3.8, -6]]);
}

registerProp('item_ice', {
  w: 44, h: 41, ox: 22, oy: 37, scale: [1.65, 1.65], draw: itemIce, pal: () => [INK, ICE.lit, ICE.dark, ICE.glint, GROUND],
});
